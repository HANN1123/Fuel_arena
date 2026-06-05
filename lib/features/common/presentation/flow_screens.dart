import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController(text: 'new.driver@fuelarena.net');
  final _nicknameController = TextEditingController(text: 'NeonDriver');
  final _passwordController = TextEditingController(text: 'fuelarena!');
  var _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    setState(() => _loading = true);
    await ref.read(authRepositoryProvider).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          nickname: _nicknameController.text.trim(),
        );
    if (!mounted) {
      return;
    }
    context.go('/consent');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '회원가입', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('연비로 증명할\n계정을 만드세요', style: AppTypography.displayScore.copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.sm),
          Text('개발 모드에서는 실제 메일 인증 없이 mock 계정으로 전체 흐름을 검증합니다.', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: '이메일', prefixIcon: Icon(Icons.email_rounded)),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(labelText: '닉네임', prefixIcon: Icon(Icons.person_rounded)),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '비밀번호', prefixIcon: Icon(Icons.lock_rounded)),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: '가입하고 동의로 이동',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _loading,
                  onPressed: _signup,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  var _terms = true;
  var _privacy = true;
  var _location = true;
  var _ads = false;
  var _marketing = false;

  bool get _requiredComplete => _terms && _privacy && _location;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '필수 동의', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('공정한 경쟁을 위한\n동의가 필요해요', style: AppTypography.displayScore.copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.sm),
          Text('위치 원본 경로는 공개 랭킹에 노출하지 않고, 본인 기록 검증과 점수 계산에만 사용합니다.', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: AppSpacing.xl),
          _ConsentTile(title: '서비스 이용약관', requiredConsent: true, value: _terms, onChanged: (value) => setState(() => _terms = value)),
          _ConsentTile(title: '개인정보 처리방침', requiredConsent: true, value: _privacy, onChanged: (value) => setState(() => _privacy = value)),
          _ConsentTile(title: '위치정보 수집 및 주행 검증', requiredConsent: true, value: _location, onChanged: (value) => setState(() => _location = value)),
          _ConsentTile(title: '맞춤형 광고', requiredConsent: false, value: _ads, onChanged: (value) => setState(() => _ads = value)),
          _ConsentTile(title: '마케팅 수신', requiredConsent: false, value: _marketing, onChanged: (value) => setState(() => _marketing = value)),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: _requiredComplete ? '권한 안내로 이동' : '필수 동의를 확인하세요',
            icon: Icons.verified_user_rounded,
            onPressed: _requiredComplete ? () => context.go('/permissions') : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('선택 동의는 설정에서 언제든 변경할 수 있어요.', style: AppTypography.dataUnit.copyWith(color: AppColors.onSurfaceMuted)),
        ],
      ),
    );
  }
}

class PermissionIntroScreen extends StatelessWidget {
  const PermissionIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '권한 안내', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('주행 거리와\n지역 리그를 계산해요', style: AppTypography.displayScore.copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.sm),
          Text('권한 요청은 실제 주행 시작 시점에 진행합니다. 개발 모드는 권한 없이 mock 기록을 만들 수 있어요.', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: AppSpacing.xl),
          const _PermissionCard(
            icon: Icons.location_on_rounded,
            title: '위치 권한',
            description: '주행 거리와 지역 리그 계산을 위해 위치 정보가 필요합니다.',
          ),
          const _PermissionCard(
            icon: Icons.notifications_active_rounded,
            title: '알림 권한',
            description: '랭킹 추월, 배틀 결과, 시즌 보상을 알려드리기 위해 알림을 사용합니다.',
          ),
          const _PermissionCard(
            icon: Icons.shield_rounded,
            title: '안전 모드',
            description: '주행 중에는 광고, 팝업, 도전장, 불필요한 알림을 표시하지 않습니다.',
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: '차량 등록하기',
            icon: Icons.directions_car_rounded,
            onPressed: () => context.go('/vehicle/register'),
          ),
        ],
      ),
    );
  }
}

class VehicleCompleteScreen extends StatelessWidget {
  const VehicleCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FuelArenaInfoScreen(
      title: '차량 등록 완료',
      subtitle: '대표 차량이 설정됐습니다. 이제 첫 주행으로 시즌 점수를 받을 수 있어요.',
      icon: Icons.verified_rounded,
      primaryLabel: '홈으로 이동',
      onPrimary: () => context.go('/home'),
      sections: const [
        InfoSection(title: '공정 매칭', body: '같은 차급과 연료 타입 운전자들과 우선 비교합니다.'),
        InfoSection(title: '비공개 위치', body: '정확한 좌표는 개인 기록 검증에만 사용되고 공개 화면에는 표시하지 않습니다.'),
      ],
    );
  }
}

class BattleCreateScreen extends StatefulWidget {
  const BattleCreateScreen({super.key});

  @override
  State<BattleCreateScreen> createState() => _BattleCreateScreenState();
}

class _BattleCreateScreenState extends State<BattleCreateScreen> {
  String _rule = '최고 효율 점수';
  String _period = '24시간';
  String _opponent = 'NightCruise';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '배틀 만들기', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('현금 없이\n점수로만 겨뤄요', style: AppTypography.displayScore.copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.lg),
          _ChoiceBlock(title: '상대', values: const ['NightCruise', 'EcoBlade', '공개 매칭'], selected: _opponent, onChanged: (value) => setState(() => _opponent = value)),
          _ChoiceBlock(title: '규칙', values: const ['최고 효율 점수', '평균 안정 점수', '주간 평균 연비'], selected: _rule, onChanged: (value) => setState(() => _rule = value)),
          _ChoiceBlock(title: '기간', values: const ['24시간', '3일', '이번 주'], selected: _period, onChanged: (value) => setState(() => _period = value)),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusChip(label: '비금전 보상', color: AppColors.amber),
                const SizedBox(height: AppSpacing.md),
                Text('시즌 XP 120 · 배지 조각 2개', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text('배틀은 현금성 베팅 없이 앱 내 보상과 기록으로만 정산됩니다.', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: '배틀 생성',
            icon: Icons.sports_mma_rounded,
            onPressed: () => context.go('/battle/detail/battle-001'),
          ),
        ],
      ),
    );
  }
}

class BattleDetailScreen extends ConsumerWidget {
  const BattleDetailScreen({super.key, required this.battleId});

  final String battleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final battles = ref.watch(battlesProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '배틀 상세', showBack: true),
      child: battles.when(
        loading: () => const LoadingSkeletonView(lines: 4),
        error: (error, stackTrace) => const ErrorStateView(message: '배틀 정보를 불러오지 못했어요.'),
        data: (items) {
          final battle = items.firstWhere((item) => item.id == battleId, orElse: () => items.first);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BattleCard(battle: battle),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: '정산 기준'),
              const _InfoList(items: ['검증된 주행 기록만 반영', '동급 차량 보정 계수 적용', 'GPS 이상 기록은 공정성 검토로 보류']),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(label: '결과 확인', icon: Icons.emoji_events_rounded, onPressed: () => context.go('/battle/result/$battleId')),
            ],
          );
        },
      ),
    );
  }
}

class BattleResultScreen extends ConsumerWidget {
  const BattleResultScreen({super.key, required this.battleId});

  final String battleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final battles = ref.watch(battlesProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '배틀 결과', showBack: true),
      child: battles.when(
        loading: () => const LoadingSkeletonView(lines: 3),
        error: (error, stackTrace) => const ErrorStateView(message: '배틀 결과를 불러오지 못했어요.'),
        data: (items) {
          final battle = items.firstWhere((item) => item.id == battleId, orElse: () => items.first);
          final won = battle.myScore >= battle.opponentScore;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusChip(label: won ? '승리' : '복수전 가능', color: won ? AppColors.neonGreen : AppColors.amber, icon: won ? Icons.emoji_events_rounded : Icons.replay_rounded),
              const SizedBox(height: AppSpacing.lg),
              BattleCard(battle: battle),
              const SizedBox(height: AppSpacing.lg),
              RewardCard(title: won ? '시즌 XP 지급 완료' : '기본 참가 보상 지급', description: won ? battle.rewardSummary : '검증된 주행 참여 보상이 지급됐어요.'),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(label: '복수전 신청', icon: Icons.replay_rounded, onPressed: () => context.go('/battle/create')),
            ],
          );
        },
      ),
    );
  }
}

class SeasonPassScreen extends ConsumerWidget {
  const SeasonPassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(seasonProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '시즌패스', showBack: true),
      child: season.when(
        loading: () => const LoadingSkeletonView(lines: 4),
        error: (error, stackTrace) => const ErrorStateView(message: '시즌패스를 불러오지 못했어요.'),
        data: (value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SeasonProgressCard(season: value),
            const SizedBox(height: AppSpacing.lg),
            const RewardCard(title: '무료 트랙', description: '시즌 XP, 배지 조각, 쿠폰 응모권이 열립니다.'),
            const SizedBox(height: AppSpacing.md),
            LockedPremiumCard(title: '프리미엄 트랙', description: '광고 없이 추가 보상과 한정 골드 배지를 받을 수 있어요.', onTap: () => context.go('/premium')),
          ],
        ),
      ),
    );
  }
}

class MissionScreen extends ConsumerWidget {
  const MissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missions = ref.watch(seasonMissionsProvider);
    return _MissionListScaffold(title: '미션', missions: missions);
  }
}

class RivalScreen extends StatelessWidget {
  const RivalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FuelArenaInfoScreen(
      title: '라이벌',
      subtitle: '바로 위 운전자를 추월하면 시즌 XP와 라이벌 배지가 쌓입니다.',
      icon: Icons.local_fire_department_rounded,
      primaryLabel: '배틀 만들기',
      onPrimary: () => context.go('/battle/create'),
      sections: const [
        InfoSection(title: 'NightCruise', body: '24점 앞서 있습니다. 안정 주행 점수에서 차이가 납니다.'),
        InfoSection(title: 'BlueTorque', body: '이번 주 평균 연비가 1.8km/L 높습니다.'),
        InfoSection(title: 'EcoBlade', body: '상위 리그 승급권에 근접한 목표 라이벌입니다.'),
      ],
    );
  }
}

class CrewScreen extends StatelessWidget {
  const CrewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FuelArenaInfoScreen(
      title: '크루',
      subtitle: '크루원 8명이 이번 주 312km를 검증 완료했습니다.',
      icon: Icons.groups_rounded,
      primaryLabel: '크루 배틀 만들기',
      onPrimary: () => context.go('/battle/create'),
      sections: const [
        InfoSection(title: 'Neon Commuters', body: '주간 크루 안정 점수 91점 · 지역 리그 4위'),
        InfoSection(title: '오늘의 기여', body: 'ApexDriver 24.8km, VoltRunner 18.2km, GreenLine 12.7km'),
      ],
    );
  }
}

class OtherUserProfileScreen extends StatelessWidget {
  const OtherUserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return FuelArenaInfoScreen(
      title: '운전자 프로필',
      subtitle: '$userId 님의 공개 경쟁 정보입니다. 정확한 주행 경로는 공개되지 않습니다.',
      icon: Icons.person_search_rounded,
      primaryLabel: '도전장 보내기',
      onPrimary: () => context.go('/battle/create'),
      sections: const [
        InfoSection(title: '티어', body: 'Gold III · 시즌 점수 2,811'),
        InfoSection(title: '대표 차량', body: '준중형 · Hybrid · 공개 프로필 정보만 표시'),
        InfoSection(title: '최근 성과', body: '검증 완료 주행 18회 · 동급 상위 22%'),
      ],
    );
  }
}

class BadgeCollectionScreen extends ConsumerWidget {
  const BadgeCollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(badgesProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '배지 컬렉션', showBack: true),
      child: badges.when(
        loading: () => const LoadingSkeletonView(lines: 4),
        error: (error, stackTrace) => const ErrorStateView(message: '배지를 불러오지 못했어요.'),
        data: (items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('내 기록을\n자랑하세요', style: AppTypography.displayScore.copyWith(color: AppColors.neonGreen)),
            const SizedBox(height: AppSpacing.lg),
            ...items.map((badge) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: _BadgeCard(badge: badge))),
          ],
        ),
      ),
    );
  }
}

class SponsorChallengeDetailScreen extends ConsumerWidget {
  const SponsorChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(sponsorChallengesProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '스폰서 챌린지', showBack: true),
      child: challenges.when(
        loading: () => const LoadingSkeletonView(lines: 3),
        error: (error, stackTrace) => const ErrorStateView(message: '챌린지를 불러오지 못했어요.'),
        data: (items) {
          final challenge = items.firstWhere((item) => item.id == challengeId, orElse: () => items.first);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SponsorChallengeCard(challenge: challenge),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: '참가 조건'),
              const _InfoList(items: ['15km 이상 검증 주행', '동급 대비 상위 30% 이내', '챌린지 기간 안에 결과 확정']),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(label: '챌린지 참가', icon: Icons.flag_rounded, onPressed: () => context.go('/drive/start')),
            ],
          );
        },
      ),
    );
  }
}

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FuelArenaInfoScreen(
      title: '개인정보 설정',
      subtitle: '동의 내역, 데이터 다운로드, 삭제 요청을 관리합니다.',
      icon: Icons.privacy_tip_rounded,
      sections: [
        InfoSection(title: '동의 내역', body: '서비스, 개인정보, 위치정보, 광고 동의 상태를 확인하고 철회할 수 있습니다.'),
        InfoSection(title: '데이터 다운로드', body: '내 프로필, 차량, 주행 요약, 보상 내역을 요청할 수 있습니다.'),
        InfoSection(title: '데이터 삭제 요청', body: '회원 탈퇴 전 민감 데이터 삭제 요청 흐름을 제공합니다.'),
      ],
    );
  }
}

class AdsSettingsScreen extends StatefulWidget {
  const AdsSettingsScreen({super.key});

  @override
  State<AdsSettingsScreen> createState() => _AdsSettingsScreenState();
}

class _AdsSettingsScreenState extends State<AdsSettingsScreen> {
  var _personalized = false;
  var _marketing = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '광고 설정', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('광고는 선택 보상으로만', style: AppTypography.displayScore.copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.lg),
          SwitchListTile(
            value: _personalized,
            onChanged: (value) => setState(() => _personalized = value),
            title: const Text('맞춤형 광고 동의'),
            subtitle: const Text('끄더라도 기본 앱 기능과 기본 보상은 유지됩니다.'),
          ),
          SwitchListTile(
            value: _marketing,
            onChanged: (value) => setState(() => _marketing = value),
            title: const Text('마케팅 수신'),
            subtitle: const Text('스폰서 챌린지와 쿠폰 소식을 선택적으로 받습니다.'),
          ),
          const SizedBox(height: AppSpacing.md),
          LockedPremiumCard(
            title: '프리미엄 광고 제거',
            description: '프리미엄은 광고 없이 보상과 분석을 받을 수 있습니다.',
            onTap: () => context.go('/premium'),
          ),
        ],
      ),
    );
  }
}

class SafetyModeSettingsScreen extends StatefulWidget {
  const SafetyModeSettingsScreen({super.key});

  @override
  State<SafetyModeSettingsScreen> createState() => _SafetyModeSettingsScreenState();
}

class _SafetyModeSettingsScreenState extends State<SafetyModeSettingsScreen> {
  var _holdNotifications = true;
  var _blockAds = true;
  var _autoStart = true;
  var _confirmEnd = true;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '안전 모드 설정', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SafetyModePanel(),
          const SizedBox(height: AppSpacing.lg),
          _SwitchTile(title: '주행 중 알림 보류', value: _holdNotifications, onChanged: (value) => setState(() => _holdNotifications = value)),
          _SwitchTile(title: '주행 중 광고 차단', value: _blockAds, onChanged: (value) => setState(() => _blockAds = value)),
          _SwitchTile(title: '자동 안전 모드', value: _autoStart, onChanged: (value) => setState(() => _autoStart = value)),
          _SwitchTile(title: '종료 버튼 확인 단계', value: _confirmEnd, onChanged: (value) => setState(() => _confirmEnd = value)),
        ],
      ),
    );
  }
}

class VehicleManagementScreen extends ConsumerWidget {
  const VehicleManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(primaryVehicleProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '차량 관리', showBack: true),
      child: vehicle.when(
        loading: () => const LoadingSkeletonView(lines: 3),
        error: (error, stackTrace) => const ErrorStateView(message: '차량 정보를 불러오지 못했어요.'),
        data: (value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (value != null) VehicleCard(vehicle: value),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: '차량 추가', icon: Icons.add_rounded, onPressed: () => context.go('/vehicle/register')),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: '대표 차량 변경',
              icon: Icons.swap_horiz_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('mock 차고에서 대표 차량 변경이 반영됐어요.')),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: '차량 삭제 요청',
              icon: Icons.delete_outline_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('차량 삭제 요청 흐름이 접수됐어요.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  var _section = 'System Overview';

  static const _sections = [
    'System Overview',
    'User Management',
    'Drive Data Management',
    'Ranking Management',
    'Battle Management',
    'Season Management',
    'Mission Management',
    'Badge/Achievement Management',
    'Ad Management',
    'Rewarded Ad Management',
    'Native Ad Management',
    'Sponsor Challenge Management',
    'Coupon Management',
    'Premium Subscription Management',
    'Fraud Review',
    'Report Center',
    'Push Notification Management',
    'Consent Log Management',
    'App Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final metrics = ref.watch(adminMetricsProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: 'ADMIN', subtitle: 'Operations Dashboard', showBack: true),
      child: profile.when(
        loading: () => const LoadingSkeletonView(lines: 3),
        error: (error, stackTrace) => const ErrorStateView(message: '관리자 권한을 확인하지 못했어요.'),
        data: (user) {
          if (!user.isAdmin) {
            return const ErrorStateView(message: '관리자만 접근할 수 있는 화면입니다.');
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 760;
              final content = metrics.when(
                loading: () => const LoadingSkeletonView(lines: 6),
                error: (error, stackTrace) => const ErrorStateView(message: '관리자 지표를 불러오지 못했어요.'),
                data: (items) => _AdminContent(section: _section, metrics: items),
              );
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AdminSectionPicker(sections: _sections, selected: _section, onChanged: (value) => setState(() => _section = value)),
                    const SizedBox(height: AppSpacing.lg),
                    content,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 260,
                    child: _AdminSideBar(sections: _sections, selected: _section, onChanged: (value) => setState(() => _section = value)),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: content),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class FuelArenaInfoScreen extends StatelessWidget {
  const FuelArenaInfoScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.primaryLabel,
    this.onPrimary,
    this.sections = const [],
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final List<InfoSection> sections;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: FuelArenaAppBar(title: title, showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            glowColor: AppColors.neonGreen,
            child: Row(
              children: [
                Icon(icon, color: AppColors.neonGreen, size: 42),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.titleLarge.copyWith(color: AppColors.neonGreen)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(subtitle, style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...sections.map((section) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: _InfoSectionCard(section: section))),
          if (primaryLabel != null) ...[
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: primaryLabel!, icon: Icons.arrow_forward_rounded, onPressed: onPrimary),
          ],
        ],
      ),
    );
  }
}

class InfoSection {
  const InfoSection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

class _MissionListScaffold extends StatelessWidget {
  const _MissionListScaffold({
    required this.title,
    required this.missions,
  });

  final String title;
  final AsyncValue<List<SeasonMission>> missions;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: FuelArenaAppBar(title: title, showBack: true),
      child: missions.when(
        loading: () => const LoadingSkeletonView(lines: 5),
        error: (error, stackTrace) => const ErrorStateView(message: '미션을 불러오지 못했어요.'),
        data: (items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('오늘 놓치면\n아쉬운 미션', style: AppTypography.displayScore.copyWith(color: AppColors.neonGreen)),
            const SizedBox(height: AppSpacing.lg),
            ...items.map((mission) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: MissionCard(mission: mission))),
          ],
        ),
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.title,
    required this.requiredConsent,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool requiredConsent;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: CheckboxListTile(
          value: value,
          onChanged: (next) => onChanged(next ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(title, style: AppTypography.titleMedium),
          subtitle: Text(requiredConsent ? '필수' : '선택', style: AppTypography.dataUnit),
          activeColor: AppColors.neonGreen,
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Row(
          children: [
            Icon(icon, color: AppColors.electricBlue, size: 34),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(description, style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceBlock extends StatelessWidget {
  const _ChoiceBlock({
    required this.title,
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          Wrap(
            spacing: AppSpacing.sm,
            children: values.map((value) {
              final active = selected == value;
              return ChoiceChip(
                selected: active,
                label: Text(value),
                onSelected: (_) => onChanged(value),
                selectedColor: AppColors.neonGreen.withOpacity(0.18),
                backgroundColor: AppColors.surfaceLow,
                side: BorderSide(color: active ? AppColors.neonGreen : Colors.white.withOpacity(0.1)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _InfoList extends StatelessWidget {
  const _InfoList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(item, style: AppTypography.bodyMedium)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final Badge badge;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: badge.rarity == 'Gold' ? AppColors.gold.withOpacity(0.35) : AppColors.electricBlue.withOpacity(0.22),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge.name, style: AppTypography.titleMedium),
                Text(badge.description, style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted)),
              ],
            ),
          ),
          StatusChip(label: badge.rarity, color: badge.rarity == 'Gold' ? AppColors.gold : AppColors.electricBlue),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          title: Text(title, style: AppTypography.titleMedium),
          activeColor: AppColors.neonGreen,
        ),
      ),
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  const _InfoSectionCard({required this.section});

  final InfoSection section;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(section.body, style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted)),
        ],
      ),
    );
  }
}

class _AdminSectionPicker extends StatelessWidget {
  const _AdminSectionPicker({
    required this.sections,
    required this.selected,
    required this.onChanged,
  });

  final List<String> sections;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selected,
      items: sections.map((section) => DropdownMenuItem(value: section, child: Text(section))).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _AdminSideBar extends StatelessWidget {
  const _AdminSideBar({
    required this.sections,
    required this.selected,
    required this.onChanged,
  });

  final List<String> sections;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections
            .map(
              (section) => ListTile(
                dense: true,
                selected: section == selected,
                selectedColor: AppColors.neonGreen,
                title: Text(section),
                onTap: () => onChanged(section),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AdminContent extends StatelessWidget {
  const _AdminContent({
    required this.section,
    required this.metrics,
  });

  final String section;
  final List<AdminMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(section, style: AppTypography.titleLarge.copyWith(color: AppColors.neonGreen)),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: 220,
                  child: StatMetricCard(
                    label: metric.label,
                    value: metric.value,
                    unit: metric.unit,
                    color: metric.healthy ? AppColors.neonGreen : AppColors.amber,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusChip(label: '운영 데이터', color: AppColors.electricBlue),
              const SizedBox(height: AppSpacing.md),
              Text('$section 데이터 테이블', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('검색, 필터, 상태 배지, 검토 큐를 한 화면에서 관리합니다. 실제 Supabase 연결 시 admin view와 RLS 정책을 통해 접근합니다.', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted)),
            ],
          ),
        ),
      ],
    );
  }
}
