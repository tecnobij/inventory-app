import 'package:flutter/material.dart';

class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({super.key, required this.tabs});
  final List<(IconData, String)> tabs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Check screen width for responsiveness
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: TabBar(
          isScrollable: isMobile || tabs.length > 3, // Allow scrolling if more than 3 tabs
          tabAlignment: isMobile ? TabAlignment.start : TabAlignment.center,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
          labelColor: scheme.onSurface,
          unselectedLabelColor: scheme.onSurface,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          tabs: [
            for (final t in tabs)
              Tab(
                height: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$1, size: isMobile ? 16 : 18), // Smaller icon on mobile
                    SizedBox(width: isMobile ? 6 : 8), // Adjust spacing for mobile
                    Text(
                      t.$2,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 12 : 14, // Smaller text on mobile
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
