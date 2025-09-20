import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MusicService {
  final _supabase = Supabase.instance.client;
  final _player = AudioPlayer();
  List<dynamic> _allTracks = [];
  int _currentTrackIndex = 0;
  bool _isLooping = false;

  Future<void> _loadAllTracks() async {
    if (_allTracks.isNotEmpty) return;
    
    try {
      final response = await _supabase
          .from('soundtrack')
          .select()
          .eq('enabled', true);

      _allTracks = response as List<dynamic>;
      
      // Verify each track has a valid URL
      _allTracks = _allTracks.where((track) {
        final url = track['url'] as String?;
        return url != null && url.isNotEmpty;
      }).toList();

      if (_allTracks.isEmpty) {
        print('No valid tracks found in Supabase');
        return;
      }

      _allTracks.shuffle(); // Shuffle once for random order
    } catch (e) {
      print('Error loading tracks from Supabase: $e');
      _allTracks = [];
    }
  }

  Future<void> preloadAllTracks() async {
  await _loadAllTracks();
  if (_allTracks.isEmpty) return;

  // Preload the first track into the buffer
  final firstUrl = _allTracks.first['url'] as String;
  await _player.setUrl(firstUrl);
  }
  
  Future<void> playRandomTrack() async {
    await _loadAllTracks();
    if (_allTracks.isEmpty) return;

    final track = _allTracks.first;
    final url = track['url'] as String;
    await _player.setUrl(url);
    _player.play();
  }

  Future<void> startLooping() async {
    if (_isLooping) return;
    
    _isLooping = true;
    await _loadAllTracks();
    if (_allTracks.isEmpty) return;

    _currentTrackIndex = 0;
    await _playCurrentTrack();
    _setupLoopListener();
  }

  Future<void> _playCurrentTrack() async {
    if (_currentTrackIndex >= _allTracks.length) {
      _currentTrackIndex = 0;
    }

    try {
      final track = _allTracks[_currentTrackIndex];
      final url = track['url'] as String;
      
      // Try to load and play the URL
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      print('Error playing track: $e');
      // Skip to next track if current one fails
      _currentTrackIndex++;
      if (_isLooping && _currentTrackIndex < _allTracks.length) {
        await _playCurrentTrack();
      }
    }
  }

  Future<void> nextSong() async {
    if (_allTracks.isEmpty) return;
    
    // Stop current track
    await _player.stop();
    
    // Select a different random track from the list
    final random = Random();
    int newIndex;
    
    // If there's only one track, we can't avoid repetition
    if (_allTracks.length == 1) {
      newIndex = 0;
    } else {
      // Keep selecting random index until we get a different one
      do {
        newIndex = random.nextInt(_allTracks.length);
      } while (newIndex == _currentTrackIndex);
    }
    
    _currentTrackIndex = newIndex;
    
    // Play the random track
    await _playCurrentTrack();
    
    // Resume looping if it was active
    if (_isLooping) {
      _setupLoopListener();
    }
  }

  
  StreamSubscription? _playerSubscription;

  void _setupLoopListener() {
    // Cancel any existing subscription
    _playerSubscription?.cancel();
    
    // Setup new listener
    _playerSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && _isLooping) {
        _currentTrackIndex++;
        _playCurrentTrack();
      }
    });
  }

  void stopLooping() {
    _isLooping = false;
    _player.stop();
  }

  void stop() {
    _playerSubscription?.cancel();
    _player.stop();
  }
}
