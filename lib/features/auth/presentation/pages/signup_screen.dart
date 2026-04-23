import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_result_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/soft_blob_background.dart';
import '../../../profile_setup/presentation/pages/profile_setup_screen.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../bloc/signup_bloc.dart';
import '../constants/login_ui.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_screen_entrance.dart';
import '../widgets/brand_wordmark/brand_wordmark.dart';

/// Route-level wrapper: provisions the [SignupBloc] and the repository
/// graph it depends on. Keeps the pure UI widget below decoupled from
/// any DI / Firebase wiring.
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignupBloc>(
      create: (_) => SignupBloc(
        authRepository: AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(),
        ),
      ),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatefulWidget {
  const _SignupView();

  @override
  State<_SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<_SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    FocusScope.of(context).unfocus();

    context.read<SignupBloc>().add(
          SignupSubmitted(
            email: _email.text,
            password: _password.text,
          ),
        );
  }

  Future<void> _onSignupSuccess() async {
    await AppResultDialog.show(
      context,
      variant: AppResultVariant.success,
      title: 'Account created',
      message: 'Let\u2019s set up your profile.',
    );
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const ProfileSetupScreen(),
      ),
    );
  }

  Future<void> _onSignupFailure(String message) async {
    await AppResultDialog.show(
      context,
      variant: AppResultVariant.error,
      title: 'Sign-up failed',
      message: message,
      autoDismiss: false,
    );
    if (!mounted) return;
    context.read<SignupBloc>().add(const SignupStatusReset());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: BlocListener<SignupBloc, SignupState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          switch (state.status) {
            case SignupStatus.success:
              _onSignupSuccess();
              break;
            case SignupStatus.failure:
              _onSignupFailure(
                state.errorMessage ?? 'Something went wrong. Please try again.',
              );
              break;
            case SignupStatus.initial:
            case SignupStatus.submitting:
              break;
          }
        },
        child: SoftBlobBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth;
                final hPad = (maxW * 0.055).clamp(16.0, 28.0);
                final cardRadius = (maxW * 0.1).clamp(36.0, 48.0);
                final contentMax = maxW.clamp(0, 480).toDouble();
                final gap = (maxW * 0.055).clamp(18.0, 28.0);

                return Center(
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMax),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: AuthBackButton(),
                          ),
                          const SizedBox(height: 10),
                          AuthScreenEntrance(
                            gapAfterBrand: gap,
                            brand: const LoginBrandWordmark(),
                            card: _SignupCard(
                              formKey: _formKey,
                              emailController: _email,
                              passwordController: _password,
                              confirmPasswordController: _confirmPassword,
                              maxWidth: maxW,
                              cardRadius: cardRadius,
                              onSubmit: _submit,
                            ),
                          ),
                          SizedBox(height: (maxW * 0.06).clamp(16.0, 24.0)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SignupCard extends StatelessWidget {
  const _SignupCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.maxWidth,
    required this.cardRadius,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final double maxWidth;
  final double cardRadius;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final hInset = (maxWidth * 0.065).clamp(18.0, 26.0);
    final topPad = (maxWidth * 0.085).clamp(24.0, 34.0);
    final bottomPad = (maxWidth * 0.08).clamp(26.0, 34.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary900.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.neutral200),
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(hInset, topPad, hInset, bottomPad),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary50,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary200),
                        ),
                        child: Icon(
                          Icons.person_add_alt_1_rounded,
                          size: (maxWidth * 0.065).clamp(22.0, 26.0),
                          color: AppColors.primary700,
                        ),
                      ),
                      SizedBox(height: (maxWidth * 0.04).clamp(12.0, 16.0)),
                      Text(
                        'Create account',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: (maxWidth * 0.065).clamp(22.0, 28.0),
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: (maxWidth * 0.025).clamp(8.0, 12.0)),
                  Text(
                    'Join GlucoIQ to log readings, track trends, and get '
                    'smarter meal guidance.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: (maxWidth * 0.038).clamp(14.0, 16.0),
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: (maxWidth * 0.07).clamp(22.0, 30.0)),
                  AppTextField(
                    controller: emailController,
                    hintText: 'Email Address',
                    fillColor: LoginUi.inputFill,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return 'Enter your email';
                      if (!s.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  SizedBox(height: (maxWidth * 0.04).clamp(12.0, 16.0)),
                  AppPasswordField(
                    controller: passwordController,
                    hintText: 'Password',
                    fillColor: LoginUi.inputFill,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final s = v ?? '';
                      if (s.isEmpty) return 'Enter your password';
                      if (s.length < 6) return 'Use at least 6 characters';
                      return null;
                    },
                  ),
                  SizedBox(height: (maxWidth * 0.04).clamp(12.0, 16.0)),
                  AppPasswordField(
                    controller: confirmPasswordController,
                    hintText: 'Confirm Password',
                    fillColor: LoginUi.inputFill,
                    textInputAction: TextInputAction.done,
                    validator: (v) {
                      final s = v ?? '';
                      if (s.isEmpty) return 'Confirm your password';
                      if (s != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: (maxWidth * 0.07).clamp(22.0, 30.0)),
                  BlocBuilder<SignupBloc, SignupState>(
                    buildWhen: (prev, curr) => prev.status != curr.status,
                    builder: (context, state) {
                      final isSubmitting = state.isSubmitting;
                      return AppGradientButton(
                        label: 'Create account',
                        isLoading: isSubmitting,
                        onPressed: isSubmitting ? null : onSubmit,
                      );
                    },
                  ),
                  SizedBox(height: (maxWidth * 0.06).clamp(20.0, 28.0)),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.neutral200,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Already registered?',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.neutral200,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: (maxWidth * 0.045).clamp(14.0, 20.0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Have an account? ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Sign in',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
