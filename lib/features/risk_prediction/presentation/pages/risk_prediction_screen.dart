import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/widgets/gluco_sliver_app_bar.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../../profile/presentation/cubit/shell_profile_cubit.dart';
import '../../../reminders/presentation/widgets/gluco_app_bar_reminders_actions.dart';
import '../../data/datasources/glucoiq_ml_remote_data_source.dart';
import '../../data/datasources/inference_api_config_remote_data_source.dart';
import '../../data/repositories/ml_inference_repository_impl.dart';
import '../bloc/risk_prediction_bloc.dart';
import '../widgets/ai_risk_analysis_view.dart';

/// Route-level wrapper: provisions the risk-prediction bloc graph
/// and wires it to the realtime Firestore profile stream.
class RiskPredictionScreen extends StatelessWidget {
  const RiskPredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RiskPredictionBloc>(
      create: (context) => RiskPredictionBloc(
        profileRepository: ProfileRepositoryImpl(
          remoteDataSource: ProfileRemoteDataSourceImpl(),
        ),
        authRepository: AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(),
        ),
        mlInferenceRepository: MlInferenceRepositoryImpl(
          configDataSource: InferenceApiConfigRemoteDataSourceImpl(),
          mlRemoteDataSource: GlucoiqMlRemoteDataSourceImpl(),
        ),
        shellProfileCubit: context.read<ShellProfileCubit>(),
      )..add(const RiskSubscribed()),
      child: const _RiskPredictionView(),
    );
  }
}

class _RiskPredictionView extends StatelessWidget {
  const _RiskPredictionView();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final pad = (w * 0.06).clamp(16.0, 24.0);

        return Stack(
          children: [
            Positioned(
              top: -120,
              left: -70,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary200.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -140,
              right: -90,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary100.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            CustomScrollView(
              slivers: [
                GlucoSliverAppBar(
                  title: 'Risk Prediction',
                  actions: glucoAppBarRemindersActions(),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad, 18, pad, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeaderCard(width: w),
                        SizedBox(height: (w * 0.045).clamp(14.0, 18.0)),
                        const AiRiskAnalysisView(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.primary50.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary200),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary200.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diabetes Risk Analysis',
            style: GoogleFonts.manrope(
              fontSize: (width * 0.06).clamp(20.0, 24.0),
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: (width * 0.02).clamp(6.0, 10.0)),
          Text(
            'Predicted from your saved profile, medical details, and latest glucose readings.',
            style: GoogleFonts.inter(
              fontSize: (width * 0.038).clamp(13.5, 15.0),
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
