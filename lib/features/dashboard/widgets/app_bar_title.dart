import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/subject_provider.dart';
import '../../../providers/quotes_provider.dart';

class AppBarTitle extends ConsumerWidget {
  const AppBarTitle({super.key});

  void _showRandomQuote(BuildContext context, WidgetRef ref, Color accentColor) {
    final quote = ref.read(quotesProvider.notifier).randomQuote();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Quote',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return MotivationalQuoteDialog(quote: quote, accentColor: accentColor);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(scale: curve, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressColor = ref.watch(overallProgressColorProvider);
    // Watch to ensure the provider is initialized and fetching in background.
    ref.watch(quotesProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _showRandomQuote(context, ref, progressColor),
          behavior: HitTestBehavior.translucent,
          child: const Text(
            'GATE\nPROGRESS\nTRACKER',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'BatmanForever',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'v1.1.1 ',
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: progressColor.withAlpha(51),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Stable',
                style: TextStyle(
                  color: progressColor,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class MotivationalQuoteDialog extends StatefulWidget {
  final String quote;
  final Color accentColor;

  const MotivationalQuoteDialog({
    super.key,
    required this.quote,
    required this.accentColor,
  });

  @override
  State<MotivationalQuoteDialog> createState() => _MotivationalQuoteDialogState();
}

class _MotivationalQuoteDialogState extends State<MotivationalQuoteDialog> {
  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 3.5 seconds.
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: widget.accentColor.withAlpha(50),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withAlpha(25),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: widget.accentColor,
                  size: 40,
                ),
                const SizedBox(height: 18),
                Text(
                  widget.quote,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tap to dismiss',
                  style: GoogleFonts.outfit(
                    color: Colors.white30,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
