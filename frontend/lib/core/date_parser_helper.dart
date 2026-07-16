import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/events_provider.dart';
import 'theme.dart';

class DateParserHelper {
  // Regex pattern for dates matching any of the 5 requested formats:
  // 1. tomorrow morning 10AM / today afternoon 3pm (Relative tokens optionally followed by morning/afternoon and time)
  // 2. 12-8-2026 / 12/8/2026
  // 3. 12 august / 13 sep 2026
  static final RegExp _dateRegex = RegExp(
    r'\b(?:'
    // Pattern 1: Relative day words (today|tomorrow|yesterday) optionally followed by time details
    r'(?:today|tomorrow|yesterday)(?:\s+(?:morning|afternoon|evening|night))?(?:\s+\d{1,2}\s*(?:am|pm|AM|PM))?'
    r'|'
    // Pattern 2: Numeric date format (e.g., 12-8-2026, 12/8/2026)
    r'\d{1,2}[-\/.]\d{1,2}[-\/.]\d{4}'
    r'|'
    // Pattern 3: Named month date format (e.g., 12 august, 13 sep 2026)
    r'\d{1,2}\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s*(?:\d{4})?'
    r')\b',
    caseSensitive: false,
  );

  /// Helper to convert matches into a DateTime object
  static DateTime parseDateText(String text) {
    final cleanText = text.toLowerCase().trim();
    final now = DateTime.now();

    // 1. Handle relative tokens
    if (cleanText.contains('today')) {
      return DateTime(now.year, now.month, now.day);
    }
    if (cleanText.contains('tomorrow')) {
      final tomorrow = now.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    }
    if (cleanText.contains('yesterday')) {
      final yesterday = now.subtract(const Duration(days: 1));
      return DateTime(yesterday.year, yesterday.month, yesterday.day);
    }

    // 2. Handle Numeric Date (e.g., 12-8-2026, 12/8/2026)
    final numericMatch = RegExp(r'(\d{1,2})[-\/.](\d{1,2})[-\/.](\d{4})').firstMatch(cleanText);
    if (numericMatch != null) {
      final day = int.parse(numericMatch.group(1)!);
      final month = int.parse(numericMatch.group(2)!);
      final year = int.parse(numericMatch.group(3)!);
      return DateTime(year, month, day);
    }

    // 3. Handle Month name strings (e.g. 12 august, 13 sep 2026)
    final monthWords = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
    };

    final monthMatch = RegExp(r'(\d{1,2})\s+([a-z]{3})[a-z]*(?:\s+(\d{4}))?').firstMatch(cleanText);
    if (monthMatch != null) {
      final day = int.parse(monthMatch.group(1)!);
      final monthKey = monthMatch.group(2)!;
      final month = monthWords[monthKey] ?? now.month;
      final yearStr = monthMatch.group(3);
      final year = yearStr != null ? int.parse(yearStr) : now.year;
      return DateTime(year, month, day);
    }

    return DateTime(now.year, now.month, now.day);
  }

  /// Builds a RichText widget that detects dates in raw text, formats them as blue links,
  /// and opens an event addition dialog when clicked.
  static Widget buildClickableText(
    BuildContext context,
    WidgetRef ref,
    String text, {
    TextStyle? style,
  }) {
    final List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    final matches = _dateRegex.allMatches(text);
    if (matches.isEmpty) {
      return Text(text, style: style);
    }

    for (final match in matches) {
      // Append preceding normal text
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: style,
        ));
      }

      final dateText = text.substring(match.start, match.end);
      final parsedDate = parseDateText(dateText);

      // Append clickable blue date link
      spans.add(TextSpan(
        text: dateText,
        style: const TextStyle(
          color: Colors.blueAccent,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.bold,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            _showAddEventDialog(context, ref, parsedDate, dateText);
          },
      ));

      lastMatchEnd = match.end;
    }

    // Append remaining trailing text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(children: spans, style: style),
    );
  }

  /// Dialog popup to log an event for the pre-parsed date
  static void _showAddEventDialog(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    String originalText,
  ) {
    final textController = TextEditingController();
    final formattedDate = "${date.day} ${_monthName(date.month)} ${date.year}";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Schedule Event',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scheduling event parsed from:'),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '"$originalText"',
                  style: const TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Date: $formattedDate',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Event Details',
                  hintText: 'e.g. Annual day rehearsals',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final title = textController.text.trim();
                if (title.isNotEmpty) {
                  ref.read(eventsProvider.notifier).addEvent(date, title);
                  Navigator.pop(context);
                  
                  // Show success snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Scheduled "$title" on $formattedDate!'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                }
              },
              child: const Text('Save Event'),
            ),
          ],
        );
      },
    );
  }

  static String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month >= 1 && month <= 12) return names[month - 1];
    return '';
  }
}
