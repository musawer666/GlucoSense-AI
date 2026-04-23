import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_result_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/soft_blob_background.dart';
import '../../../home/presentation/pages/home_shell_screen.dart';
import '../../../profile_setup/presentation/pages/profile_setup_screen.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../bloc/login_bloc.dart';
import '../constants/login_ui.dart';
import '../widgets/auth_screen_entrance.dart';
import '../widgets/brand_wordmark/brand_wordmark.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

/// Route-level wrapper: provisions the [LoginBloc] and the repository
/// graph. Keeps the pure view below decoupled from any DI / Firebase.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginBloc>(
      create: (_) => LoginBloc(
        authRepository: AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(),
        ),
      ),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    FocusScope.of(context).unfocus();

    context.read<LoginBloc>().add(
          LoginSubmitted(
            email: _email.text,
            password: _password.text,
            rememberMe: _rememberMe,
          ),
        );
  }

  Future<void> _onSuccess(LoginState state) async {
    await AppResultDialog.show(
      context,
      variant: AppResultVariant.success,
      title: 'Welcome back',
      message: 'You\u2019re signed in.',
    );
    if (!mounted) return;

    final goHome = state.user?.profileComplete ?? false;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) =>
            goHome ? const HomeShellScreen() : const ProfileSetupScreen(),
      ),
      (_) => false,
    );
  }

  Future<void> _onFailure(String message) async {
    await AppResultDialog.show(
      context,
      variant: AppResultVariant.error,
      title: 'Sign-in failed',
      message: message,
      autoDismiss: false,
    );
    if (!mounted) return;
    context.read<LoginBloc>().add(const LoginStatusReset());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<LoginBloc, LoginState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          switch (state.status) {
            case LoginStatus.success:
              _onSuccess(state);
              break;
            case LoginStatus.failure:
              _onFailure(
                state.errorMessage ?? 'Something went wrong. Please try again.',
              );
              break;
            case LoginStatus.initial:
            case LoginStatus.submitting:
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
                          SizedBox(
                            height: (constraints.maxHeight * 0.02)
                                .clamp(8.0, 24.0),
                          ),
                          AuthScreenEntrance(
                            gapAfterBrand: gap,
                            brand: const LoginBrandWordmark(),
                            card: _LoginCard(
                              formKey: _formKey,
                              emailController: _email,
                              passwordController: _password,
                              rememberMe: _rememberMe,
                              onRememberMeChanged: (v) =>
                                  setState(() => _rememberMe = v),
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

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.maxWidth,
    required this.cardRadius,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;
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
                              Icons.lock_outline_rounded,
                              size: (maxWidth * 0.065).clamp(22.0, 26.0),
                              color: AppColors.primary700,
                            ),
                          ),
                          SizedBox(height: (maxWidth * 0.04).clamp(12.0, 16.0)),
                          Text(
                            'Welcome back',
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
                        'Sign in to access your glucose insights, logs, and '
                        'meal predictions.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: (maxWidth * 0.038).clamp(14.0, 16.0),
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: (maxWidth * 0.08).clamp(24.0, 32.0)),
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
                        fillColor: LoginUi.inputFill,
                        textInputAction: TextInputAction.done,
                        validator: (v) {
                          final s = v ?? '';
                          if (s.isEmpty) return 'Enter your password';
                          return null;
                        },
                      ),
                      SizedBox(height: (maxWidth * 0.035).clamp(12.0, 16.0)),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary50.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary100),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: rememberMe,
                                  onChanged: (v) =>
                                      onRememberMeChanged(v ?? false),
                                  shape: const CircleBorder(),
                                  side: const BorderSide(
                                    color: AppColors.neutral400,
                                    width: 1.6,
                                  ),
                                  fillColor:
                                      WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return AppColors.primary600;
                                    }
                                    return Colors.transparent;
                                  }),
                                  checkColor: Colors.white,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Remember me',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.neutral700,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: (maxWidth * 0.06).clamp(18.0, 26.0)),
                      // Isolated rebuild so inputs above never rebuild and
                      // keyboard focus stays anchored mid-request.
                      BlocBuilder<LoginBloc, LoginState>(
                        buildWhen: (prev, curr) =>
                            prev.status != curr.status,
                        builder: (context, state) {
                          final isSubmitting = state.isSubmitting;
                          return AppGradientButton(
                            label: 'Sign In',
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
                              'New here?',
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
                            "Don't have an account? ",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Create account',
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
