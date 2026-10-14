import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../shared/app_colors.dart';
import '../shared/app_toast.dart';

/// 押すと話した言葉を文字にする。文字にするのは端末の中だけ
class VoiceInputButton extends StatefulWidget {
  const VoiceInputButton({super.key, required this.onResult});

  /// 確定した文だけを渡す(呼ぶ側が欄の末尾に足す)
  final void Function(String text) onResult;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final _speech = SpeechToText();
  bool _ready = false;
  bool _listening = false;
  bool _toldUnavailable = false;

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    try {
      _ready = _ready ||
          await _speech.initialize(
            onStatus: (status) {
              if (status == SpeechToText.doneStatus ||
                  status == SpeechToText.notListeningStatus) {
                if (mounted) setState(() => _listening = false);
              }
            },
            onError: (error) {
              if (mounted) setState(() => _listening = false);
              // 聞き取れなかっただけのときは何も言わない。使えない理由があるときだけ知らせる
              if (error.permanent) _tellUnavailable();
            },
          );
    } catch (_) {
      _ready = false;
    }
    if (!_ready) {
      _tellUnavailable();
      return;
    }
    if (!mounted) return;
    setState(() => _listening = true);
    try {
      await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: 'ja_JP',
        onDevice: true,
        partialResults: false,
        cancelOnError: true,
      ),
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          widget.onResult(result.recognizedWords);
        }
      },
    );
    } catch (_) {
      // マイクが使えない、この端末の中で文字にできない、など
      if (mounted) setState(() => _listening = false);
      _tellUnavailable();
    }
  }

  void _tellUnavailable() {
    if (_toldUnavailable || !mounted) return;
    _toldUnavailable = true;
    AppToast.error(context, '声で入力できませんでした。設定アプリでマイクと音声認識を許可すると使えます');
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggle,
      tooltip: _listening ? '話すのをやめる' : '声で入力する',
      icon: Icon(
        _listening ? Icons.stop_circle_outlined : Icons.mic_none,
        color: _listening ? AppColors.accent : AppColors.textMuted,
      ),
    );
  }
}
