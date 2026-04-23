import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/colors/app_colors.dart';
import '../../../../../core/widgets/app_toast.dart';

/// Avatar + teal camera FAB — opens **gallery** via [image_picker].
/// Camera sits on the bottom-right rim of the circle (slight overlap).
class ProfileAvatarPicker extends StatefulWidget {
  const ProfileAvatarPicker({
    super.key,
    this.onImagePicked,
    this.onImageBytesPicked,
  });

  final ValueChanged<XFile?>? onImagePicked;
  final ValueChanged<Uint8List?>? onImageBytesPicked;

  @override
  State<ProfileAvatarPicker> createState() => _ProfileAvatarPickerState();
}

class _ProfileAvatarPickerState extends State<ProfileAvatarPicker> {
  final _picker = ImagePicker();
  Uint8List? _imageBytes;

  Future<void> _pickFromGallery() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 88,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
      });
      widget.onImagePicked?.call(x);
      widget.onImageBytesPicked?.call(bytes);
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Could not open gallery: $e',
          variant: AppToastVariant.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Smaller avatar: diameter tied to width, capped.
        final diameter = (constraints.maxWidth * 0.24).clamp(76.0, 96.0);
        final fabSize = (diameter * 0.34).clamp(26.0, 32.0);
        // Nudge FAB so it straddles the circle edge (not floating with a gap).
        final inset = fabSize * 0.42;

        return Center(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: inset * 0.35,
              right: inset * 0.35,
            ),
            child: SizedBox(
              width: diameter,
              height: diameter,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Material(
                      color: const Color(0xFF1E3A4C),
                      shape: const CircleBorder(),
                      elevation: 2,
                      shadowColor: Colors.black26,
                      child: ClipOval(
                        child: _imageBytes != null
                            ? Image.memory(
                                _imageBytes!,
                                fit: BoxFit.cover,
                                width: diameter,
                                height: diameter,
                                gaplessPlayback: true,
                              )
                            : Icon(
                                Icons.person_rounded,
                                size: diameter * 0.42,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -inset * 0.15,
                    bottom: -inset * 0.15,
                    child: Material(
                      color: AppColors.primary600,
                      shape: const CircleBorder(),
                      elevation: 4,
                      shadowColor: AppColors.primary900.withValues(alpha: 0.25),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _pickFromGallery,
                        child: SizedBox(
                          width: fabSize,
                          height: fabSize,
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: fabSize * 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
