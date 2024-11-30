import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/squat_counter.dart';

class SquatCounterDisplay extends StatelessWidget {
  const SquatCounterDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 32,
      right: 32,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              '스쿼트',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Consumer<SquatCounter>(
              builder: (context, counter, child) => Text(
                '${counter.count}회',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
