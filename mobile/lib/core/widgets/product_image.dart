import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProductImage extends StatelessWidget {
  final String? imageUri;
  final int? categoryId;
  final double width;
  final double height;
  final double borderRadius;
  final double iconSize;

  const ProductImage({
    super.key,
    this.imageUri,
    this.categoryId,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = 8,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: imageUri != null && imageUri!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image(
                image: imageUri!.startsWith('http')
                    ? NetworkImage(imageUri!) as ImageProvider
                    : FileImage(File(imageUri!)),
                fit: BoxFit.cover,
                width: width,
                height: height,
                errorBuilder: (context, error, stackTrace) =>
                    _buildImagePlaceholder(categoryId, iconSize),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: iconSize * 0.8,
                      height: iconSize * 0.8,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                  );
                },
              ),
            )
          : _buildImagePlaceholder(categoryId, iconSize),
    );
  }

  static IconData getCategoryIcon(int? categoryId) {
    switch (categoryId) {
      case 1:
        return Icons.restaurant_rounded;
      case 2:
        return Icons.local_cafe_rounded;
      case 3:
        return Icons.cookie_rounded;
      default:
        return Icons.fastfood_rounded;
    }
  }

  Widget _buildImagePlaceholder(int? categoryId, double size) {
    return Center(
      child: Icon(
        getCategoryIcon(categoryId),
        color: AppTheme.primaryColor.withValues(alpha: 0.4),
        size: size,
      ),
    );
  }
}
