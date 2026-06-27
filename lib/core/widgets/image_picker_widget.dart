import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/app_colors.dart';
import '../utils/text_styles.dart';

class ImagePickerWidget extends StatelessWidget {
  final Function(String path) onImagePicked;
  final Widget child;

  const ImagePickerWidget({
    super.key,
    required this.onImagePicked,
    required this.child,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image != null) {
        String finalPath;
        if (kIsWeb) {
          finalPath = image.path;
        } else {
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedFile = await File(image.path).copy('${appDir.path}/$fileName');
          finalPath = savedFile.path;
        }
        onImagePicked(finalPath);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture photo: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSourceBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Photo Source',
                style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceButton(
                    context,
                    Icons.camera_alt_outlined,
                    'Camera',
                    ImageSource.camera,
                  ),
                  _buildSourceButton(
                    context,
                    Icons.photo_library_outlined,
                    'Gallery',
                    ImageSource.gallery,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButton(
    BuildContext context,
    IconData icon,
    String label,
    ImageSource source,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        _pickImage(context, source);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.surfaceLight.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSourceBottomSheet(context),
      child: child,
    );
  }
}
