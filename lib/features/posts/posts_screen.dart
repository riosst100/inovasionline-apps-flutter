import 'package:flutter/material.dart';
import '../../config/theme.dart';

class PostsScreen extends StatelessWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Postingan')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dynamic_feed_outlined, size: 56, color: AppColors.mutedForeground),
            SizedBox(height: 12),
            Text('Belum ada postingan', style: TextStyle(color: AppColors.mutedForeground)),
          ],
        ),
      ),
    );
  }
}
