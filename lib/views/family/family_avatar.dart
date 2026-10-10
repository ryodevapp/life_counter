import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/photo_store.dart';
import '../shared/app_colors.dart';

/// 家族の丸い写真。写真が無ければ、呼び名の1文字目を出す
class FamilyAvatar extends StatelessWidget {
  const FamilyAvatar({
    super.key,
    required this.name,
    required this.photoFile,
    this.size = 44,
  });

  final String name;
  final String? photoFile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final file = PhotoStore.file(photoFile);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accentSurface2,
        image: file != null
            ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: file == null
          ? Text(name.isEmpty ? '' : name.characters.first,
              style: GoogleFonts.zenKakuGothicNew(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accent))
          : null,
    );
  }
}

/// 記録の写真(角丸)
class LogPhoto extends StatelessWidget {
  const LogPhoto({super.key, required this.photoFile, this.height = 180});

  final String? photoFile;
  final double height;

  @override
  Widget build(BuildContext context) {
    final file = PhotoStore.file(photoFile);
    if (file == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(file,
          height: height, width: double.infinity, fit: BoxFit.cover),
    );
  }
}
