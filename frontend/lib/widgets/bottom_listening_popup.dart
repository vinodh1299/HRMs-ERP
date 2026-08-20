import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/voice_helper.dart';
import '../services/mark_voice_assistant_service.dart';

/// Animated Bottom-Middle Listening Pop-Up Badge for "Mark" Voice Assistant
class BottomListeningPopUpWidget extends StatefulWidget {
  const BottomListeningPopUpWidget({super.key});

  @override
  State<BottomListeningPopUpWidget> createState() => _BottomListeningPopUpWidgetState();
}

class _BottomListeningPopUpWidgetState extends State<BottomListeningPopUpWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mark — Voice Assistant',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        Text(
                          '🎙️ Always Listening (Say "Hey Mark")',
                          style: TextStyle(fontSize: 12.5, color: AppTheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: MarkVoiceAssistantService.markEnabledNotifier.value,
                    activeTrackColor: AppTheme.primary,
                    onChanged: (val) {
                      MarkVoiceAssistantService.toggleMarkAssistant(context);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<String>(
                valueListenable: MarkVoiceAssistantService.lastResponseNotifier,
                builder: (context, lastResponse, _) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.record_voice_over_rounded, size: 16, color: Colors.blueAccent),
                            SizedBox(width: 6),
                            Text(
                              'Mark Last Spoken Response',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lastResponse.isEmpty ? '🎙️ Mark Listening...' : lastResponse,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Example Voice Triggers:\n'
                      '• "Hey Mark, show me the team section"\n'
                      '• "Hello Mark, open helpdesk"\n'
                      '• "Mark, apply casual leave for tomorrow"\n'
                      '• "Hey Mark, send message to Vinodh that I\'m on the way"\n'
                      '• "Hello Mark, send a mail to Vinodh that the meeting is postponed"',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.textDark, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MarkVoiceAssistantService.markEnabledNotifier,
      builder: (context, markEnabled, _) {
        if (!markEnabled) return const SizedBox.shrink();

        return ValueListenableBuilder<bool>(
          valueListenable: VoiceHelper.isSpeakingNotifier,
          builder: (context, isSpeaking, _) {
            return ValueListenableBuilder<String>(
              valueListenable: MarkVoiceAssistantService.lastResponseNotifier,
              builder: (context, lastResponse, _) {
                return Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showModal(context),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 440),
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade900.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: isSpeaking ? Colors.amber : AppTheme.primary.withValues(alpha: 0.7),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Animated Soundwave Equalizer Mic Icon
                              AnimatedBuilder(
                                animation: _animController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 + (_animController.value * 0.18),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSpeaking ? Colors.amber : AppTheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isSpeaking ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),

                              // Response / Listening Text
                              Expanded(
                                child: Text(
                                  lastResponse.isEmpty ? '🎙️ Mark Listening... (Say "Hey Mark")' : lastResponse,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Mute / Turn OFF Button
                              Tooltip(
                                message: 'Turn OFF Mark Voice Assistant',
                                child: InkWell(
                                  onTap: () {
                                    MarkVoiceAssistantService.toggleMarkAssistant(context);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
