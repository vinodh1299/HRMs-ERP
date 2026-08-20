import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../services/voice_helper.dart';
import '../services/mark_voice_assistant_service.dart';

/// Interactive Voice Assistant ("Mark") & Always-Listening Wake Word Toggle Control Widget
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
              valueListenable: MarkVoiceAssistantService.markEnabledNotifier,
              builder: (context, markEnabled, _) {
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

                              // Header with Mark Toggle Switch
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: markEnabled ? AppTheme.primaryGradient : null,
                                      color: markEnabled ? null : Colors.grey.shade300,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      markEnabled ? Icons.graphic_eq_rounded : Icons.mic_off_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Mark — Voice Assistant',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                        Text(
                                          markEnabled
                                              ? '🎙️ Always-Listening (Say "Hey Mark")'
                                              : 'OFF — Tap switch to activate Mark',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: markEnabled ? AppTheme.primary : AppTheme.textMuted,
                                            fontWeight: markEnabled ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Mark Assistant ON/OFF Toggle Switch
                                  Switch.adaptive(
                                    value: markEnabled,
                                    activeColor: AppTheme.primary,
                                    onChanged: (val) {
                                      MarkVoiceAssistantService.toggleMarkAssistant(context);
                                      setModalState(() {});
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Screen Context Card
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
                                              'Hands-Free Voice Commands',
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
                                                  isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                                                  size: 14,
                                                  color: AppTheme.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isSpeaking ? 'Stop Voice' : 'Read Summary (Male Voice)',
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Example Voice Triggers:\n'
                                      '• "Hey Mark, show me the team section"\n'
                                      '• "Hello Mark, open helpdesk"\n'
                                      '• "Mark, apply casual leave for tomorrow"\n'
                                      '• "Hey Mark, send message to Vinodh that I\'m on the way"\n'
                                      '• "Hello Mark, send a mail to Vinodh that the meeting is postponed"',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppTheme.textDark,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Quick Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: markEnabled ? AppTheme.primary : Colors.grey.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        elevation: 0,
                                      ),
                                      icon: Icon(markEnabled ? Icons.mic_rounded : Icons.mic_off_rounded),
                                      label: Text(
                                        markEnabled ? 'Mark Assistant ON' : 'Turn ON Mark Assistant',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                      ),
                                      onPressed: () {
                                        MarkVoiceAssistantService.toggleMarkAssistant(context);
                                        setModalState(() {});
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MarkVoiceAssistantService.markEnabledNotifier,
      builder: (context, markEnabled, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: VoiceHelper.isSpeakingNotifier,
          builder: (context, isSpeaking, child) {
            final active = markEnabled || isSpeaking;

            if (widget.compact) {
              return Tooltip(
                message: markEnabled ? 'Mark Always-Listening (Say "Hey Mark")' : 'Enable Mark Voice Assistant',
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
                              scale: active ? 1.0 + (_pulseController.value * 0.18) : 1.0,
                              child: Icon(
                                markEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                                color: active ? Colors.white : AppTheme.primary,
                                size: 16,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          markEnabled ? 'Mark ON' : 'Voice Assistant',
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
              heroTag: 'mark_voice_assistant_fab',
              onPressed: () => _showVoiceModal(context),
              backgroundColor: markEnabled ? AppTheme.primary : Colors.white,
              foregroundColor: markEnabled ? Colors.white : AppTheme.primary,
              elevation: 4,
              icon: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: markEnabled ? 1.0 + (_pulseController.value * 0.18) : 1.0,
                    child: Icon(
                      markEnabled ? Icons.graphic_eq_rounded : Icons.record_voice_over_rounded,
                      size: 20,
                    ),
                  );
                },
              ),
              label: Text(
                markEnabled ? 'Mark Listening...' : 'Mark Voice Assistant',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            );
          },
        );
      },
    );
  }
}
