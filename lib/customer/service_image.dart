// lib/customer/service_image.dart

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shows a network image for http(s) paths, otherwise a local asset.
/// If it fails to load, tries [fallbackPath] (e.g. the category banner),
/// and finally a soft gradient.
class ServiceImage extends StatelessWidget {
  final String path;
  final String? fallbackPath;
  final double? height;
  final double? width;

  const ServiceImage(
    this.path, {
    super.key,
    this.fallbackPath,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Widget onError(BuildContext context, Object error, StackTrace? stack) {
      if (fallbackPath != null && fallbackPath != path) {
        return ServiceImage(fallbackPath!, height: height, width: width);
      }
      return Container(
        height: height,
        width: width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFBDBDBD), AppColors.muted],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }

    final image = path.startsWith('http')
        ? Image.network(
            path,
            height: height,
            width: width,
            fit: BoxFit.cover,
            errorBuilder: onError,
          )
        : Image.asset(
            path,
            height: height,
            width: width,
            fit: BoxFit.cover,
            errorBuilder: onError,
          );

    // Force the requested size so a failed image never collapses to a thin strip.
    return SizedBox(height: height, width: width, child: image);
  }
}
