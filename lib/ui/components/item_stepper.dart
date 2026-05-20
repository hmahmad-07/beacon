import 'package:flutter/material.dart';
import '../../core/resources/app_colors.dart';

class ItemStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final double size;

  const ItemStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.size = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.appColor1.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDecrement,
            child: Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                color: AppColor.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColor.grey.withValues(alpha: .1),
                    blurRadius: 3,
                    spreadRadius: 2,
                    offset: const Offset(0, .3),
                  )
                ]
              ),
              child: Icon(Icons.remove, size: size * 0.5, color: AppColor.appColor1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColor.appColor1,
                fontSize: 14,
              ),
            ),
          ),
          GestureDetector(
            onTap: onIncrement,
            child: Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                color: AppColor.appColor1,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColor.grey.withValues(alpha: .1),
                    blurRadius: 3,
                    spreadRadius: 2,
                    offset: const Offset(0, .3),
                  )
                ]
              ),
              child: Icon(Icons.add, size: size * 0.5, color: AppColor.white),
            ),
          ),
        ],
      ),
    );
  }
}
