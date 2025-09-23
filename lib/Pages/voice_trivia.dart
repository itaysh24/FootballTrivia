import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/voice_service.dart';

class VoiceTriviaPage extends StatefulWidget {
  const VoiceTriviaPage({super.key});

  @override
  State<VoiceTriviaPage> createState() => _VoiceTriviaPageState();
}

class _VoiceTriviaPageState extends State<VoiceTriviaPage> {
  final _supabase = Supabase.instance.client;
  final _voice = VoiceService();

  String? _question;
  String? _answer;
  String? _feedback;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await _voice.init();
    await _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    setState(() => _loading = true);

    final response = await _supabase
        .from('questions') // <-- Supabase table name
        .select()
        .limit(1)
        .maybeSingle();

    if (response != null) {
      setState(() {
        _question = response['career_path'] as String;
        _answer = response['answer'] as String;
        _loading = false;
      });
    }
  }

  void _startListening() {
    setState(() => _feedback = null);
    _voice.listen((spoken) {
      if (_answer != null && spoken.toLowerCase().contains(_answer!.toLowerCase())) {
        setState(() => _feedback = "✅ Correct!");
      } else {
        setState(() => _feedback = "❌ Wrong: $spoken");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Voice Trivia",
                      style: TextStyle(
                        color: Colors.orange.shade400,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      color: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _question ?? "...",
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade400,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _startListening,
                      icon: const Icon(Icons.mic, color: Colors.black),
                      label: const Text(
                        "Speak Answer",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_feedback != null)
                      Text(
                        _feedback!,
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
