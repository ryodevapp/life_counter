import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_toast.dart';

/// 欄の中の右下に置くマイクのボタン。話している間も文字にして渡す(文字にするのは端末の中だけ)
class VoiceInputButton extends StatefulWidget {
  const VoiceInputButton({
    super.key,
    required this.onStart,
    required this.onWords,
    required this.onStop,
  });

  /// 聞き始めた
  final VoidCallback onStart;

  /// 今回話した分の文字(途中も含む)。呼ぶたびに今回の分の全体が来る
  final void Function(String words, bool isFinal) onWords;

  /// 聞き終わった
  final VoidCallback onStop;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final _speech = SpeechToText();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _ready = false;
  bool _listening = false;
  bool _toldUnavailable = false;

  void _setListening(bool on) {
    if (!mounted || _listening == on) return;
    setState(() => _listening = on);
    if (on) {
      _pulse.repeat(reverse: true);
      widget.onStart();
    } else {
      _pulse
        ..stop()
        ..value = 0;
      widget.onStop();
    }
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      _setListening(false);
      return;
    }
    try {
      _ready =
          _ready ||
          await _speech.initialize(
            onStatus: (status) {
              if (status == SpeechToText.doneStatus ||
                  status == SpeechToText.notListeningStatus) {
                _setListening(false);
              }
            },
            onError: (error) {
              _setListening(false);
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
    _setListening(true);
    try {
      await _speech.listen(
        listenOptions: SpeechListenOptions(
          // 1回は最長1分(iOS の音声認識の上限)。話さないまま5秒たったら止まる
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 5),
          localeId: 'ja_JP',
          onDevice: true,
          partialResults: true,
          cancelOnError: true,
        ),
        onResult: (result) =>
            widget.onWords(result.recognizedWords, result.finalResult),
      );
    } catch (_) {
      // マイクが使えない、この端末の中で文字にできない、など
      _setListening(false);
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
    _pulse.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _listening ? '話すのをやめる' : '声で入力する',
      excludeSemantics: true,
      // 見た目は 36 の丸のまま、押せる範囲は 44 に広げる
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: SizedBox.square(
          dimension: AppSpacing.minTap,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) => Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _listening ? AppColors.accent : AppColors.card,
                  boxShadow: [
                    if (_listening)
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 4 + 10 * _pulse.value,
                        spreadRadius: 1 + 4 * _pulse.value,
                      )
                    else
                      ...AppColors.cardShadow,
                  ],
                ),
                child: Icon(
                  _listening ? CupertinoIcons.stop_fill : CupertinoIcons.mic,
                  size: 20,
                  color: _listening ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
