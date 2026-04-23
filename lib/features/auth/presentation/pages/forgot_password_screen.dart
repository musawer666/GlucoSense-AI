import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_result_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/soft_blob_background.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../bloc/forgot_password_bloc.dart';
import '../constants/login_ui.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_screen_entrance.dart';
import '../widgets/brand_wordmark/brand_wordmark.dart';

/// Route-level wrapper: provisions the [ForgotPasswordBloc] and the
/// repository graph. Keeps the pure view below decoupled from any DI.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ForgotPasswordBloc>(
      create: (_) => ForgotPasswordBloc(
        authRepository: AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(),
        ),
      ),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    FocusScope.of(context).unfocus();

    context
        .read<ForgotPasswordBloc>()
        .add(ForgotPasswordSubmitted(email: _email.text));
  }

  Future<void> _onSent(String email) async {
    await AppResultDialog.show(
      context,
      variant: AppResultVariant.success,
      title: 'Link sent',
      message:
          'We\u2019ve sent a reset link to $email. Check your inbox to continue.',
      autoDismiss: true,
      autoDismissAfter: const Duration(milliseconds: 1800),
    );
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  Future<void> _onFailure(String message) async {
    await AppResultDialog.show(
      context,
      variant: AppResultVariant.error,
      title: 'Could not send link',
      message: message,
      autoDismiss: false,
    );
    if (!mounted) return;
    context.read<ForgotPasswordBloc>().add(const ForgotPasswordStatusReset());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          switch (state.status) {
            case ForgotPasswordStatus.sent:
              _onSent(state.email ?? _email.text.trim());
              break;
            case ForgotPasswordStatus.failure:
              _onFailure(
                state.errorMessage ?? 'Something went wrong. Please try again.',
              );
              break;
            case ForgotPasswordStatus.initial:
            case ForgotPasswordStatus.sending:
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
                            card: _ForgotPasswordCard(
                              formKey: _formKey,
                              emailController: _email,
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

class _ForgotPasswordCard extends StatelessWidget {
  const _ForgotPasswordCard({
    required this.formKey,
    required this.emailController,
    required this.maxWidth,
    required this.cardRadius,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
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
                          Icons.mark_email_unread_outlined,
                          size: (maxWidth * 0.065).clamp(22.0, 26.0),
                          color: AppColors.primary700,
                        ),
                      ),
                      SizedBox(height: (maxWidth * 0.04).clamp(12.0, 16.0)),
                      Text(
                        'Reset your password',
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
                    'Enter your email and we\u2019ll send you a secure link '
                    'to choose a new password.',
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
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return 'Enter your email';
                      if (!s.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  SizedBox(height: (maxWidth * 0.07).clamp(22.0, 30.0)),
                  BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                    buildWhen: (prev, curr) => prev.status != curr.status,
                    builder: (context, state) {
                      final isSending = state.isSending;
                      return AppGradientButton(
                        label: 'Send reset link',
                        isLoading: isSending,
                        onPressed: isSending ? null : onSubmit,
                      );
                    },
                  ),
                  SizedBox(height: (maxWidth * 0.06).clamp(20.0, 26.0)),
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
                          'Remember it?',
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
                  SizedBox(height: (maxWidth * 0.04).clamp(12.0, 18.0)),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        'Back to sign in',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary700,
                        ),
                      ),
                    ),
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
