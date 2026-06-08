import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  var _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) {
      return;
    }
    setState(() => _signingOut = true);
    try {
      await ref.read(appSessionServiceProvider).signOut();
      invalidateUserScopedSessionProviders(ref);
      if (!mounted) {
        return;
      }
      context.go('/auth/login');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _signingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃을 완료하지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final badges = ref.watch(badgesProvider);
    final achievements = ref.watch(achievementsProvider);
    final primaryVehicle = ref.watch(primaryVehicleProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.mobileMargin, AppSpacing.md, AppSpacing.mobileMargin, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('프로필',
              style: AppTypography.displayScore
                  .copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.lg),
          profile.when(
            loading: () => const LoadingSkeletonView(lines: 1),
            error: (error, stackTrace) =>
                const ErrorStateView(message: '프로필을 불러오지 못했어요.'),
            data: (value) => ProfileHeader(profile: value),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '계정'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Google 계정 세션',
                    style: AppTypography.titleMedium
                        .copyWith(color: AppColors.onSurface)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '로그아웃하면 인증 세션과 사용자별 로컬 주행 큐, 동의/차량 설정 힌트를 함께 정리합니다.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.onSurfaceMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                SecondaryButton(
                  label: _signingOut ? '로그아웃 중' : '로그아웃',
                  icon: Icons.logout_rounded,
                  onPressed: _signingOut ? null : _signOut,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '대표 차량'),
          primaryVehicle.when(
            loading: () => const LoadingSkeletonView(lines: 1),
            error: (error, stackTrace) =>
                const ErrorStateView(message: '대표 차량을 불러오지 못했어요.'),
            data: (vehicle) {
              if (vehicle == null) {
                return EmptyStateView(
                  title: '대표 차량이 없어요',
                  message: '공개 프로필에는 정확한 위치나 raw 주행 경로 없이 차량 리그와 차급만 표시됩니다.',
                  actionLabel: '차량 설정하기',
                  onAction: () => context.go('/setup/vehicle'),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VehicleCard(vehicle: vehicle),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '공개 프로필에는 닉네임, 티어, 점수, 차급, 연료 리그만 표시합니다.',
                    style: AppTypography.dataUnit
                        .copyWith(color: AppColors.onSurfaceMuted),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '대표 배지'),
          badges.when(
            loading: () => const LoadingSkeletonView(lines: 1),
            error: (error, stackTrace) =>
                const ErrorStateView(message: '배지를 불러오지 못했어요.'),
            data: (items) => items.isEmpty
                ? const EmptyStateView(
                    title: '아직 대표 배지가 없어요',
                    message: '검증 주행, 배틀, 시즌 미션을 완료하면 획득한 배지가 여기에 표시됩니다.',
                  )
                : BadgeGrid(badges: items),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: '배지 컬렉션 전체 보기',
            icon: Icons.workspace_premium_rounded,
            onPressed: () => context.push('/profile/badges'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '업적'),
          achievements.when(
            loading: () => const LoadingSkeletonView(lines: 2),
            error: (error, stackTrace) =>
                const ErrorStateView(message: '업적을 불러오지 못했어요.'),
            data: (items) => items.isEmpty
                ? const EmptyStateView(
                    title: '업적 데이터가 아직 없어요',
                    message: '운영 seed가 적용되면 주행과 경쟁 업적 진행률을 확인할 수 있습니다.',
                  )
                : Column(
                    children: items
                        .map(
                          (achievement) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: AchievementTile(achievement: achievement),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
