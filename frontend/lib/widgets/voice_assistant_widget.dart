import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../services/voice_helper.dart';

/// Interactive Voice Assistant & Voice-Over Control Button / Dialog
class VoiceAssistantWidget extends StatefulWidget {
  final bool compact;

  const VoiceAssistantWidget({
    super.key,
    this.compact = false,
  });

  @override
  State<VoiceAssistantWidget> createState() => _VoiceAssistantWidgetState();
}

class _VoiceAssistantWidgetState extends State<VoiceAssistantWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showVoiceModal(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final contextSummary = VoiceHelper.getScreenContextSummary(location);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ValueListenableBuilder<bool>(
              valueListenable: VoiceHelper.isSpeakingNotifier,
              builder: (context, isSpeaking, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: VoiceHelper.isListeningNotifier,
                  builder: (context, isListening, _) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle pill bar
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.borderGrey,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Title and status header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Voice-Over & Context Assistant',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    Text(
                                      isSpeaking
                                          ? '🔊 Speaking context summary...'
                                          : (isListening ? '🎙️ Listening to your query...' : 'Ready for voice interaction'),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: isSpeaking || isListening ? AppTheme.primary : AppTheme.textMuted,
                                        fontWeight: isSpeaking || isListening ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  VoiceHelper.autoSpeak ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                                  color: VoiceHelper.autoSpeak ? AppTheme.primary : AppTheme.textMuted,
                                ),
                                tooltip: VoiceHelper.autoSpeak ? 'Mute Voice-Over' : 'Enable Voice-Over',
                                onPressed: () {
                                  VoiceHelper.toggleAutoSpeak();
                                  setModalState(() {});
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Spoken Context Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.bgLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.borderGrey),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.primary),
                                        SizedBox(width: 6),
                                        Text(
                                          'Current Screen Context',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () {
                                        if (isSpeaking) {
                                          VoiceHelper.stopSpeaking();
                                        } else {
                                          VoiceHelper.readScreenContext(location);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isSpeaking ? Icons.stop_circle_outlined : Icons.play_arrow_rounded,
                                              size: 14,
                                              color: AppTheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isSpeaking ? 'Stop Voice' : 'Read Aloud',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  contextSummary,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: AppTheme.textDark,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Quick Voice Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  icon: AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: isSpeaking ? 1.0 + (_pulseController.value * 0.15) : 1.0,
                                        child: Icon(isSpeaking ? Icons.graphic_eq_rounded : Icons.record_voice_over_rounded),
                                      );
                                    },
                                  ),
                                  label: Text(
                                    isSpeaking ? 'Pause Voice-Over' : 'Listen Context',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  onPressed: () {
                                    if (isSpeaking) {
                                      VoiceHelper.stopSpeaking();
                                    } else {
                                      VoiceHelper.readScreenContext(location);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isListening ? Colors.red : AppTheme.primary,
                                    side: BorderSide(color: isListening ? Colors.red : AppTheme.primary, width: 1.5),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: Icon(isListening ? Icons.mic_rounded : Icons.mic_none_rounded),
                                  label: Text(
                                    isListening ? 'Listening...' : 'Voice Query',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  onPressed: () {
                                    if (isListening) return;
                                    VoiceHelper.startRecognition(
                                      onResult: (text) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Voice Query: "$text"')),
                                        );
                                        VoiceHelper.speak("You said: $text. Processing your request now.");
                                      },
                                      onError: (err) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Voice error: $err')),
                                        );
                                      },
                                      onEnd: () {},
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: VoiceHelper.isSpeakingNotifier,
      builder: (context, isSpeaking, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: VoiceHelper.isListeningNotifier,
          builder: (context, isListening, child) {
            final active = isSpeaking || isListening;

            if (widget.compact) {
              return Tooltip(
                message: 'Voice-Over Context Reader & Assistant',
                child: InkWell(
                  onTap: () => _showVoiceModal(context),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: active ? 1.0 + (_pulseController.value * 0.2) : 1.0,
                              child: Icon(
                                isSpeaking
                                    ? Icons.volume_up_rounded
                                    : (isListening ? Icons.mic_rounded : Icons.record_voice_over_rounded),
                                color: active ? Colors.white : AppTheme.primary,
                                size: 16,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSpeaking ? 'Speaking...' : 'Voice Over',
                          style: TextStyle(
                            color: active ? Colors.white : AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return FloatingActionButton.extended(
              heroTag: 'voice_assistant_fab',
              onPressed: () => _showVoiceModal(context),
              backgroundColor: active ? AppTheme.primary : Colors.white,
              foregroundColor: active ? Colors.white : AppTheme.primary,
              elevation: 4,
              icon: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: active ? 1.0 + (_pulseController.value * 0.18) : 1.0,
                    child: Icon(
                      isSpeaking ? Icons.graphic_eq_rounded : Icons.record_voice_over_rounded,
                      size: 20,
                    ),
                  );
                },
              ),
              label: Text(
                isSpeaking ? 'Voice-Over Active' : 'Voice Assistant',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            );
          },
        );
      },
    );
  }
}
