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
    
    final response = await _supabase
        .from('soundtrack')
        .select()
        .eq('enabled', true);

    _allTracks = response as List<dynamic>;
    _allTracks.shuffle(); // Shuffle once for random order
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
      _currentTrackIndex = 0; // Reset to beginning
    }

    final track = _allTracks[_currentTrackIndex];
    final url = track['url'] as String;
    await _player.setUrl(url);
    _player.play();
  }

  void _setupLoopListener() {
    _player.playerStateStream.listen((state) {
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

  void stop() => _player.stop();
}
