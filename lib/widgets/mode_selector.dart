import 'package:flutter/material.dart';

class ModeSelector extends StatelessWidget {
  final int currentIndex;
  final Function(int) onModeChanged;

  const ModeSelector({
    Key? key,
    required this.currentIndex,
    required this.onModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.black54,
      child: PageView(
        onPageChanged: onModeChanged,
        children: [
          _buildModeItem('Color Recognition', Icons.color_lens, 0),
          _buildModeItem('Color Detection', Icons.palette, 1),
          _buildModeItem('Wardrobe Matching', Icons.checkroom, 2),
        ],
      ),
    );
  }

  Widget _buildModeItem(String label, IconData icon, int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: currentIndex == index ? Colors.white : Colors.grey,
          size: 40,
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: currentIndex == index ? Colors.white : Colors.grey,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}