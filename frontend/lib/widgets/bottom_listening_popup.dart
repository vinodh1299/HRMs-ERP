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
                      MarkVoiceAssistantService.setMarkAssistantEnabled(context, val);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Pending Action Confirmation Box if active
              ValueListenableBuilder<PendingVoiceAction?>(
                valueListenable: MarkVoiceAssistantService.pendingActionNotifier,
                builder: (context, pending, _) {
                  if (pending != null) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.shade600, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber),
                              SizedBox(width: 6),
                              Text(
                                '⚠️ Action Read-Back Confirmation Required',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            pending.readBackText,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                icon: const Icon(Icons.check, size: 16, color: Colors.white),
                                label: const Text('Confirm (Say YES)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  MarkVoiceAssistantService.confirmPendingAction();
                                  Navigator.pop(ctx);
                                },
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                label: const Text('Cancel (Say NO)', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  MarkVoiceAssistantService.cancelPendingAction();
                                  Navigator.pop(ctx);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

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
                      'Verbal Read-Back Safety Gate Active:\n'
                      '• Say "Apply casual leave" → Mark reads back details → Say "YES" to execute!\n'
                      '• Say "Send message to Vinodh" → Mark reads back details → Say "YES" to send!',
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

        return ValueListenableBuilder<PendingVoiceAction?>(
          valueListenable: MarkVoiceAssistantService.pendingActionNotifier,
          builder: (context, pending, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: VoiceHelper.isSpeakingNotifier,
              builder: (context, isSpeaking, _) {
                return ValueListenableBuilder<String>(
                  valueListenable: MarkVoiceAssistantService.lastResponseNotifier,
                  builder: (context, lastResponse, _) {
                    final isPending = pending != null;

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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              constraints: const BoxConstraints(maxWidth: 480),
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isPending ? Colors.amber.shade900 : Colors.blueGrey.shade900.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: isPending ? Colors.amber.withValues(alpha: 0.6) : AppTheme.primary.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: isPending ? Colors.amberAccent : (isSpeaking ? Colors.amber : AppTheme.primary.withValues(alpha: 0.7)),
                                  width: 1.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Animated Soundwave Equalizer / Warning Icon
                                  AnimatedBuilder(
                                    animation: _animController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: 1.0 + (_animController.value * 0.18),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isPending ? Colors.amber : (isSpeaking ? Colors.amber : AppTheme.primary),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isPending ? Icons.priority_high_rounded : (isSpeaking ? Icons.graphic_eq_rounded : Icons.mic_rounded),
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),

                                  // Response / Read-Back Text
                                  Expanded(
                                    child: Text(
                                      isPending ? '⚠️ ${pending.readBackText}' : (lastResponse.isEmpty ? '🎙️ Mark Listening... (Say "Hey Mark")' : lastResponse),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isPending ? Colors.amber.shade100 : Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  if (isPending) ...[
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 22),
                                      tooltip: 'Say YES to Confirm',
                                      onPressed: () => MarkVoiceAssistantService.confirmPendingAction(),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 22),
                                      tooltip: 'Say NO to Cancel',
                                      onPressed: () => MarkVoiceAssistantService.cancelPendingAction(),
                                    ),
                                  ] else ...[
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
      },
    );
  }
}
