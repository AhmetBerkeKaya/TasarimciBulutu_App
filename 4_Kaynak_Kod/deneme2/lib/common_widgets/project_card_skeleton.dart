// lib/common_widgets/project_card_skeleton.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProjectCardSkeleton extends StatelessWidget {
  const ProjectCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: double.infinity, height: 24.0, color: Colors.white),
              const SizedBox(height: 8),
              Container(width: 150.0, height: 16.0, color: Colors.white),
              const SizedBox(height: 16),
              Container(width: double.infinity, height: 1.0, color: Colors.white),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 100.0, height: 20.0, color: Colors.white),
                  Container(width: 80.0, height: 20.0, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}