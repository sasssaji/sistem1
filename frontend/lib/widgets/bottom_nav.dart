import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color(0xFF176B87);
    final Color inactiveColor = const Color(0xFF6D8795);
    final Color highlightColor = const Color(0xFF2F86A5);

    Widget buildItem({
      required IconData icon,
      required String label,
      required int index,
    }) {
      final isActive = index == currentIndex;

      return Expanded(
        child: GestureDetector(
          onTap: () => onTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  width: isActive ? 56 : 0,
                  height: isActive ? 56 : 0,
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? highlightColor.withValues(alpha: 0.18)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: isActive ? activeColor : inactiveColor,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive ? activeColor : inactiveColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 255, 255, 255),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildItem(icon: Icons.home_outlined, label: 'Home', index: 0),
          buildItem(icon: Icons.help_outline, label: 'Quiz', index: 1),
          Expanded(
            child: GestureDetector(
              onTap: () => onTap(2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      width: currentIndex == 2 ? 64 : 0,
                      height: currentIndex == 2 ? 64 : 0,
                      decoration: BoxDecoration(
                        color:
                            currentIndex == 2
                                ? highlightColor.withValues(alpha: 0.2)
                                : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color:
                              currentIndex == 2 ? activeColor : inactiveColor,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Scan',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                currentIndex == 2 ? activeColor : inactiveColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          buildItem(icon: Icons.search, label: 'Explore', index: 3),
          buildItem(icon: Icons.campaign_outlined, label: 'Advisory', index: 4),
        ],
      ),
    );
  }
}
