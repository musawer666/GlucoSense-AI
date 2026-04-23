import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/widgets/app_result_dialog.dart';
import '../../../../core/widgets/gluco_sliver_app_bar.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/user_profile_store.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/profile_display_data.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_edit_bottom_sheet.dart';
import '../widgets/profile_target_range_card.dart';

/// Route-level wrapper: provisions the profile repository graph,
/// subscribes the Bloc to the realtime snapshot stream, and renders
/// the live profile below.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (_) => ProfileBloc(
        profileRepository: ProfileRepositoryImpl(
          remoteDataSource: ProfileRemoteDataSourceImpl(),
        ),
        authRepository: AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(),
        ),
      )..add(const ProfileSubscribed()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final ImagePicker _picker = ImagePicker();

  // ─── Field editing ─────────────────────────────────────────────

  Future<void> _edit(ProfileField field, UserProfile current) async {
    await showProfileFieldEditor(
      context: context,
      current: _toDisplay(current),
      field: field,
      onSaved: (next) => _submitFieldPatch(field, next),
    );
  }

  void _submitFieldPatch(ProfileField field, ProfileDisplayData next) {
    final patch = _patchFor(field, next);
    if (patch.isEmpty) return;
    context.read<ProfileBloc>().add(ProfileFieldsUpdated(fields: patch));
  }

  // ─── Avatar ────────────────────────────────────────────────────

  Future<void> _pickAvatarFromGallery() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      // Cache locally too so the Profile tab can render the new
      // avatar instantly even before the Storage URL comes back.
      UserProfileStore.setAvatarBytes(bytes);
      context.read<ProfileBloc>().add(ProfileAvatarChanged(bytes: bytes));
    } catch (e) {
      if (mounted) {
        AppResultDialog.show(
          context,
          variant: AppResultVariant.error,
          title: 'Update failed',
          message: 'Could not open gallery: $e',
          autoDismiss: false,
        );
      }
    }
  }

  // ─── Mutation feedback ─────────────────────────────────────────

  Future<void> _onMutationSuccess(String label) async {
    await AppResultDialog.show(
      context,
      variant: AppResultVariant.success,
      title: 'Updated',
      message: label == 'Photo updated'
          ? 'Your profile photo was updated successfully.'
          : 'Your profile detail was updated successfully.',
    );
    if (!mounted) return;
    context.read<ProfileBloc>().add(const ProfileMutationAcknowledged());
  }

  Future<void> _onMutationFailure(String message) async {
    await AppResultDialog.show(
      context,
      variant: AppResultVariant.error,
      title: 'Update failed',
      message: message,
      autoDismiss: false,
    );
    if (!mounted) return;
    context.read<ProfileBloc>().add(const ProfileMutationAcknowledged());
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Do you want to logout from your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
      ).signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      await AppResultDialog.show(
        context,
        variant: AppResultVariant.error,
        title: 'Logout failed',
        message: 'Could not logout right now. Please try again.',
        autoDismiss: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (prev, curr) =>
          prev.lastMutation != curr.lastMutation ||
          (prev.status != curr.status &&
              curr.status == ProfileStatus.failure),
      listener: (context, state) {
        if (state.status == ProfileStatus.failure &&
            state.errorMessage != null) {
          _onMutationFailure(state.errorMessage!);
          return;
        }
        final label = state.lastMutation;
        if (label != null) _onMutationSuccess(label);
      },
      builder: (context, state) {
        return Stack(
          children: [
            _ProfileBackdrop(),
            _buildContent(state),
            if (state.isUpdating)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x33FFFFFF),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildContent(ProfileState state) {
    switch (state.status) {
      case ProfileStatus.initial:
      case ProfileStatus.loading:
        return const _ProfileLoadingScaffold();
      case ProfileStatus.missing:
        return const _ProfileMissingScaffold();
      case ProfileStatus.failure:
        if (state.profile == null) {
          return _ProfileErrorScaffold(
            message:
                state.errorMessage ?? 'Could not load profile.',
            onRetry: () =>
                context.read<ProfileBloc>().add(const ProfileSubscribed()),
          );
        }
        // Fall through to render existing data — the failure is for
        // a mutation attempt and the dialog already surfaces it.
        return _ProfileLoaded(
          profile: state.profile!,
          onEdit: _edit,
          onPickAvatar: _pickAvatarFromGallery,
          onLogout: _logout,
        );
      case ProfileStatus.updating:
      case ProfileStatus.ready:
        if (state.profile == null) return const _ProfileLoadingScaffold();
        return _ProfileLoaded(
          profile: state.profile!,
          onEdit: _edit,
          onPickAvatar: _pickAvatarFromGallery,
          onLogout: _logout,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Adapters — bridge UserProfile ↔ ProfileDisplayData for the
// existing edit sheet, and map ProfileField → partial Firestore
// patch for a single edit.
// ─────────────────────────────────────────────────────────────────

ProfileDisplayData _toDisplay(UserProfile p) {
  return ProfileDisplayData(
    fullName: p.fullName,
    email: p.email ?? '',
    age: p.age,
    biologicalSex: p.biologicalSex,
    heightCm: p.heightCm,
    weightKg: p.weightKg,
    bmi: p.bmi,
    diabetesTypeLabel: p.diabetesTypeLabel,
    familyHistory: p.familyHistory,
    hypertension: p.hypertension,
    heartDisease: p.heartDisease,
    smokingLabel: p.smokingLabel,
    activityLabel: p.activityLabel,
    hba1cDisplay: p.hba1c?.toString(),
    medicationDisplay: p.medication,
    targetGlucoseMinMgDl: p.targetGlucoseMinMgDl,
    targetGlucoseMaxMgDl: p.targetGlucoseMaxMgDl,
  );
}

Map<String, dynamic> _patchFor(ProfileField field, ProfileDisplayData next) {
  switch (field) {
    case ProfileField.fullName:
      return {'fullName': next.fullName};
    case ProfileField.email:
      return {'email': next.email};
    case ProfileField.age:
      return {'age': next.age};
    case ProfileField.biologicalSex:
      return {'biologicalSex': next.biologicalSex};
    case ProfileField.heightCm:
      return {
        'heightCm': next.heightCm,
        if (next.bmi != null) 'bmi': next.bmi,
      };
    case ProfileField.weightKg:
      return {
        'weightKg': next.weightKg,
        if (next.bmi != null) 'bmi': next.bmi,
      };
    case ProfileField.bmi:
      return {
        'heightCm': next.heightCm,
        'weightKg': next.weightKg,
        if (next.bmi != null) 'bmi': next.bmi,
      };
    case ProfileField.diabetesType:
      return {'diabetesTypeLabel': next.diabetesTypeLabel};
    case ProfileField.familyHistory:
      return {'familyHistory': next.familyHistory};
    case ProfileField.hypertension:
      return {'hypertension': next.hypertension};
    case ProfileField.heartDisease:
      return {'heartDisease': next.heartDisease};
    case ProfileField.smoking:
      return {'smokingLabel': next.smokingLabel};
    case ProfileField.activity:
      return {'activityLabel': next.activityLabel};
    case ProfileField.hba1c:
      final raw = next.hba1cDisplay?.trim();
      final parsed = (raw == null || raw.isEmpty)
          ? null
          : double.tryParse(raw);
      return {'hba1c': parsed};
    case ProfileField.medication:
      final raw = next.medicationDisplay?.trim();
      return {'medication': (raw == null || raw.isEmpty) ? null : raw};
    case ProfileField.targetRange:
      return {
        'targetGlucoseMinMgDl': next.targetGlucoseMinMgDl,
        'targetGlucoseMaxMgDl': next.targetGlucoseMaxMgDl,
      };
  }
}

// ─────────────────────────────────────────────────────────────────
// Visual subtrees
// ─────────────────────────────────────────────────────────────────

class _ProfileBackdrop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -90,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary200.withValues(alpha: 0.36),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 60,
          right: -110,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary100.withValues(alpha: 0.42),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileLoadingScaffold extends StatelessWidget {
  const _ProfileLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        GlucoSliverAppBar(title: 'Profile'),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileMissingScaffold extends StatelessWidget {
  const _ProfileMissingScaffold();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const GlucoSliverAppBar(title: 'Profile'),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No profile yet — complete setup to see your details here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileErrorScaffold extends StatelessWidget {
  const _ProfileErrorScaffold({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const GlucoSliverAppBar(title: 'Profile'),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.primary700,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.45,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileLoaded extends StatelessWidget {
  const _ProfileLoaded({
    required this.profile,
    required this.onEdit,
    required this.onPickAvatar,
    required this.onLogout,
  });

  final UserProfile profile;
  final void Function(ProfileField, UserProfile) onEdit;
  final Future<void> Function() onPickAvatar;
  final Future<void> Function() onLogout;

  static String _fmt(String? s) => (s == null || s.isEmpty) ? '—' : s;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final d = profile;
    final avatar = (w * 0.26).clamp(88.0, 108.0);
    final fab = (avatar * 0.24).clamp(26.0, 30.0);

    return CustomScrollView(
      slivers: [
        const GlucoSliverAppBar(title: 'Profile'),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              (w * 0.06).clamp(16.0, 24.0),
              18,
              (w * 0.06).clamp(16.0, 24.0),
              8,
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        AppColors.primary50.withValues(alpha: 0.72),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.primary200),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary200.withValues(alpha: 0.34),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: avatar + fab * 0.35,
                        height: avatar + fab * 0.35,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Material(
                              color: AppColors.neutral200,
                              shape: const CircleBorder(),
                              elevation: 2,
                              shadowColor: Colors.black26,
                              child: ClipOval(
                                child: _AvatarImage(
                                  url: d.avatarUrl,
                                  size: avatar,
                                ),
                              ),
                            ),
                            Positioned(
                              right: fab * 0.02,
                              bottom: fab * 0.02,
                              child: Material(
                                color: AppColors.primary700,
                                shape: const CircleBorder(),
                                elevation: 4,
                                shadowColor: Colors.black38,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: onPickAvatar,
                                  child: SizedBox(
                                    width: fab,
                                    height: fab,
                                    child: Icon(
                                      Icons.edit_outlined,
                                      color: AppColors.onPrimary,
                                      size: fab * 0.45,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: (w * 0.045).clamp(14.0, 20.0)),
                      InkWell(
                        onTap: () => onEdit(ProfileField.fullName, d),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            d.fullName.isEmpty ? '—' : d.fullName,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: (w * 0.058).clamp(20.0, 24.0),
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => onEdit(ProfileField.email, d),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            d.email ?? '',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: (w * 0.05).clamp(18.0, 24.0)),
                      ProfileTargetRangeCard(
                        minMgDl: d.targetGlucoseMinMgDl,
                        maxMgDl: d.targetGlucoseMaxMgDl,
                        onEdit: () => onEdit(ProfileField.targetRange, d),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: (w * 0.045).clamp(16.0, 22.0)),
                _SectionHeading(
                  title: 'Your details',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 10),
                _InfoCard(
                  children: [
                    _InfoRow(
                      label: 'Age',
                      value: '${d.age}',
                      onTap: () => onEdit(ProfileField.age, d),
                    ),
                    _InfoRow(
                      label: 'Biological sex',
                      value: d.biologicalSex.isEmpty ? '—' : d.biologicalSex,
                      onTap: () => onEdit(ProfileField.biologicalSex, d),
                    ),
                    _InfoRow(
                      label: 'Height',
                      value: '${d.heightCm} cm',
                      onTap: () => onEdit(ProfileField.heightCm, d),
                    ),
                    _InfoRow(
                      label: 'Weight',
                      value: '${d.weightKg.toStringAsFixed(1)} kg',
                      onTap: () => onEdit(ProfileField.weightKg, d),
                    ),
                    _InfoRow(
                      label: 'BMI',
                      value:
                          d.bmi != null ? d.bmi!.toStringAsFixed(1) : '—',
                      onTap: () => onEdit(ProfileField.bmi, d),
                    ),
                    _InfoRow(
                      label: 'Diabetes type',
                      value: d.diabetesTypeLabel,
                      onTap: () => onEdit(ProfileField.diabetesType, d),
                    ),
                    _InfoRow(
                      label: 'Family history',
                      value: d.familyHistory ? 'Yes' : 'No',
                      onTap: () => onEdit(ProfileField.familyHistory, d),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionHeading(
                  title: 'Medical',
                  icon: Icons.health_and_safety_outlined,
                ),
                const SizedBox(height: 10),
                _InfoCard(
                  children: [
                    _InfoRow(
                      label: 'Hypertension',
                      value: d.hypertension ? 'Yes' : 'No',
                      onTap: () => onEdit(ProfileField.hypertension, d),
                    ),
                    _InfoRow(
                      label: 'Heart disease',
                      value: d.heartDisease ? 'Yes' : 'No',
                      onTap: () => onEdit(ProfileField.heartDisease, d),
                    ),
                    _InfoRow(
                      label: 'Smoking',
                      value: d.smokingLabel,
                      onTap: () => onEdit(ProfileField.smoking, d),
                    ),
                    _InfoRow(
                      label: 'Activity',
                      value: d.activityLabel,
                      onTap: () => onEdit(ProfileField.activity, d),
                    ),
                    _InfoRow(
                      label: 'HbA1c',
                      value: _fmt(d.hba1c?.toString()),
                      onTap: () => onEdit(ProfileField.hba1c, d),
                    ),
                    _InfoRow(
                      label: 'Medication',
                      value: _fmt(d.medication),
                      onTap: () => onEdit(ProfileField.medication, d),
                    ),
                  ],
                ),
                SizedBox(height: (w * 0.04).clamp(14.0, 22.0)),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(
                      'Logout',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: (w * 0.06).clamp(18.0, 30.0)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Remote avatar takes precedence; local in-memory bytes act as a
    // warm fallback when the user just picked one and the download
    // URL has not yet echoed back through the Firestore stream.
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 180),
        placeholder: (context, url) =>
            _AvatarFallback(size: size, showSpinner: true),
        errorWidget: (context, url, error) => _AvatarFallback(size: size),
      );
    }

    final local = UserProfileStore.avatarBytes;
    if (local != null && local.isNotEmpty) {
      return Image.memory(
        Uint8List.fromList(local),
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    return _AvatarFallback(size: size);
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.size, this.showSpinner = false});

  final double size;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFE8F4F2),
      alignment: Alignment.center,
      child: showSpinner
          ? SizedBox(
              width: size * 0.28,
              height: size * 0.28,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary600),
              ),
            )
          : Icon(
              Icons.person_rounded,
              size: size * 0.52,
              color: AppColors.primary600,
            ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary100,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary700),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final r = (w * 0.04).clamp(16.0, 20.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.primary50.withValues(alpha: 0.38)],
        ),
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: AppColors.primary100),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary200.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.neutral200),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(label);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, size: 16, color: AppColors.primary700),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF51617E),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.primary100),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.primary700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String key) {
    final k = key.toLowerCase();
    if (k.contains('age')) return Icons.cake_outlined;
    if (k.contains('sex') || k.contains('gender')) return Icons.wc_rounded;
    if (k.contains('height')) return Icons.height_rounded;
    if (k.contains('weight') || k.contains('bmi')) {
      return Icons.monitor_weight_outlined;
    }
    if (k.contains('diabetes')) return Icons.bloodtype_outlined;
    if (k.contains('family')) return Icons.family_restroom_outlined;
    if (k.contains('hypertension')) return Icons.favorite_border_rounded;
    if (k.contains('heart')) return Icons.heart_broken_outlined;
    if (k.contains('smoking')) return Icons.smoke_free_rounded;
    if (k.contains('activity')) return Icons.directions_run_rounded;
    if (k.contains('hba1c')) return Icons.opacity_rounded;
    if (k.contains('medication')) return Icons.medication_outlined;
    return Icons.tune_rounded;
  }
}
