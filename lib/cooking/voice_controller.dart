import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'voice_commands.dart';

enum VoiceState { off, starting, listening, unavailable, denied }

/// Keeps the microphone listening for short commands while cooking mode is
/// open. The platform recognizer stops after each phrase or silence, so this
/// restarts it in a loop and turns each phrase into a [CookCommand].
class VoiceController extends ChangeNotifier {
  VoiceController({required this.onCommand});

  final void Function(CookCommand command) onCommand;

  final SpeechToText _speech = SpeechToText();
  VoiceState _state = VoiceState.off;
  bool _active = false;
  bool _suspended = false;
  bool _handled = false;
  String? _localeId;
  Timer? _restart;
  DateTime _lastCommandAt = DateTime.fromMillisecondsSinceEpoch(0);
  CookCommand? _lastCommand;
  String _lastHeard = '';

  VoiceState get state => _state;
  bool get isListening => _state == VoiceState.listening;
  String get lastHeard => _lastHeard;

  Future<void> start({required bool arabic}) async {
    _active = true;
    _set(VoiceState.starting);
    bool ok;
    try {
      ok = await _speech.initialize(onError: _onError, onStatus: _onStatus, debugLogging: false);
    } catch (_) {
      ok = false;
    }
    if (!_active) return;
    if (!ok) {
      var denied = false;
      try {
        denied = !(await _speech.hasPermission);
      } catch (_) {}
      _set(denied ? VoiceState.denied : VoiceState.unavailable);
      return;
    }
    _localeId = await _pickLocale(arabic);
    await _listen();
  }

  Future<void> stop() async {
    _active = false;
    _restart?.cancel();
    try {
      await _speech.stop();
    } catch (_) {}
    _set(VoiceState.off);
  }

  /// Stops listening while the app is talking, so it does not hear itself.
  Future<void> suspend() async {
    _suspended = true;
    _restart?.cancel();
    try {
      await _speech.stop();
    } catch (_) {}
  }

  void resumeListening() {
    _suspended = false;
    _scheduleRestart(const Duration(milliseconds: 300));
  }

  Future<String?> _pickLocale(bool arabic) async {
    try {
      final locales = await _speech.locales();
      final ids = locales.map((l) => l.localeId).toList();
      final wanted = arabic ? ['ar_EG', 'ar-EG', 'ar_SA', 'ar-SA', 'ar'] : ['en_US', 'en-US', 'en_GB', 'en-GB', 'en'];
      for (final w in wanted) {
        if (ids.contains(w)) return w;
      }
      final prefix = arabic ? 'ar' : 'en';
      for (final id in ids) {
        if (id.toLowerCase().startsWith(prefix)) return id;
      }
    } catch (_) {}
    return arabic ? 'ar_EG' : 'en_US';
  }

  Future<void> _listen() async {
    if (!_active || _suspended || _speech.isListening) return;
    _handled = false;
    try {
      await _speech.listen(
        onResult: _onResult,
        localeId: _localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.confirmation,
        ),
      );
      _set(VoiceState.listening);
    } catch (_) {
      _scheduleRestart(const Duration(seconds: 1));
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords;
    if (words.isEmpty) return;
    _lastHeard = words;
    if (_handled) return;
    final command = VoiceCommands.parse(words);
    if (command == null) return;
    final now = DateTime.now();
    // The recognizer can report the same phrase twice; ignore quick repeats.
    if (command == _lastCommand && now.difference(_lastCommandAt) < const Duration(milliseconds: 1500)) return;
    _handled = true;
    _lastCommand = command;
    _lastCommandAt = now;
    onCommand(command);
    // Start a fresh phrase so the next command is heard on its own.
    _speech.stop();
  }

  void _onStatus(String status) {
    if (status == 'listening') {
      _set(VoiceState.listening);
    } else if (status == 'done' || status == 'notListening') {
      _scheduleRestart(const Duration(milliseconds: 250));
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (error.errorMsg.contains('permission')) {
      _active = false;
      _set(VoiceState.denied);
      return;
    }
    // No match and timeouts are normal in a quiet kitchen; keep going.
    _scheduleRestart(Duration(milliseconds: error.permanent ? 1200 : 400));
  }

  void _scheduleRestart(Duration delay) {
    if (!_active || _suspended) return;
    _restart?.cancel();
    _restart = Timer(delay, _listen);
  }

  void _set(VoiceState s) {
    if (_state == s) return;
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _active = false;
    _restart?.cancel();
    _speech.cancel();
    super.dispose();
  }
}

/// Reads steps and alerts aloud.
class Speaker {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> init({required bool arabic}) async {
    try {
      await _tts.setLanguage(arabic ? 'ar-EG' : 'en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.awaitSpeakCompletion(true);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> say(String text) async {
    if (!_ready || text.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
