import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// A widget that detects URLs in message text and makes them clickable,
/// opening them in an external browser just like WhatsApp and Messenger.
class ClickableMessageText extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final TextStyle? linkStyle;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const ClickableMessageText({
    super.key,
    required this.text,
    this.textStyle,
    this.linkStyle,
    this.textAlign = TextAlign.left,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  State<ClickableMessageText> createState() => _ClickableMessageTextState();
}

class _ClickableMessageTextState extends State<ClickableMessageText> {
  final List<TapGestureRecognizer> _recognizers = [];

  static final RegExp _urlRegex = RegExp(
    r'(https?:\/\/[^\s<>()]+|www\.[^\s<>()]+)',
    caseSensitive: false,
  );

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  Future<void> _launchUrl(String rawUrl) async {
    try {
      String urlToLaunch = rawUrl.trim();
      if (urlToLaunch.toLowerCase().startsWith('www.')) {
        urlToLaunch = 'https://$urlToLaunch';
      }
      final uri = Uri.parse(urlToLaunch);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('ClickableMessageText: Error launching URL "$rawUrl": $e');
    }
  }

  List<InlineSpan> _buildSpans() {
    _disposeRecognizers();

    final List<InlineSpan> spans = [];
    final String content = widget.text;

    final TextStyle defaultStyle = widget.textStyle ??
        GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          height: 1.4,
        );

    final TextStyle defaultLinkStyle = widget.linkStyle ??
        defaultStyle.copyWith(
          color: const Color(0xFFFEDB9B),
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xFFFEDB9B),
          fontWeight: FontWeight.w600,
        );

    int currentIndex = 0;
    final matches = _urlRegex.allMatches(content);

    for (final match in matches) {
      // Add plain text before URL
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: content.substring(currentIndex, match.start),
            style: defaultStyle,
          ),
        );
      }

      String url = match.group(0)!;
      String trailingPunctuation = '';

      // Separate trailing punctuation (e.g. "https://google.com." or "?")
      final pMatch = RegExp(r'[.,!?;:)]+$').firstMatch(url);
      if (pMatch != null) {
        trailingPunctuation = pMatch.group(0)!;
        url = url.substring(0, url.length - trailingPunctuation.length);
      }

      if (url.isNotEmpty) {
        final recognizer = TapGestureRecognizer()
          ..onTap = () => _launchUrl(url);
        _recognizers.add(recognizer);

        spans.add(
          TextSpan(
            text: url,
            style: defaultLinkStyle,
            recognizer: recognizer,
          ),
        );
      }

      if (trailingPunctuation.isNotEmpty) {
        spans.add(
          TextSpan(
            text: trailingPunctuation,
            style: defaultStyle,
          ),
        );
      }

      currentIndex = match.end;
    }

    // Add any remaining text
    if (currentIndex < content.length) {
      spans.add(
        TextSpan(
          text: content.substring(currentIndex),
          style: defaultStyle,
        ),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text.rich(
      TextSpan(children: _buildSpans()),
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
