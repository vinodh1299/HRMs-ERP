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
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
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
                            color: isSpeaking ? Colors.amber : AppTheme.primary.withValues(alpha: 0.6),
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
                                  scale: 1.0 + (_animController.value * 0.15),
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
                                lastResponse.isEmpty ? '🎙️ Mark Listening...' : lastResponse,
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
                );
              },
            );
          },
        );
      },
    );
  }
}
