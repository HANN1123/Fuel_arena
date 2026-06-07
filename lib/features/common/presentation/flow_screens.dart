import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/errors/app_error.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../core/utils/input_validators.dart';
import '../../../core/utils/formatters.dart';
import '../../admin/presentation/admin_widgets.dart';
import '../../../shared/models/fuel_arena_models.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/widgets.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: 'Google 로그인', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Google 계정으로\n바로 시작하세요',
              style: AppTypography.displayScore
                  .copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.sm),
          Text('Fuel Arena는 Google OAuth로 가입과 로그인을 처리합니다.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Google 로그인으로 이동',
            icon: Icons.login_rounded,
            onPressed: () => context.go('/auth/login'),
          ),
        ],
      ),
    );
  }
}

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  var _terms = true;
  var _privacy = true;
  var _location = true;
  var _ads = false;
  var _marketing = false;
  var _saving = false;
  String? _errorMessage;

  bool get _requiredComplete => _terms && _privacy && _location;

  Future<void> _completeConsent() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await ref.read(consentRepositoryProvider).saveConsent(
            termsAccepted: _terms,
            privacyAccepted: _privacy,
            locationAccepted: _location,
            personalizedAdsAccepted: _ads,
            marketingAccepted: _marketing,
          );
      await ref.read(localStateServiceProvider).markConsentCompleted();
      ref
        ..invalidate(appConsentProvider)
        ..invalidate(restoredSessionProvider);
      try {
        await ref
            .read(analyticsRepositoryProvider)
            .track('consent_completed', properties: {
          'personalized_ads': _ads,
          'marketing': _marketing,
        });
      } catch (_) {}
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      context.go('/setup');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _errorMessage = '동의 저장을 완료하지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '필수 동의', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('공정한 경쟁을 위한\n동의가 필요해요',
              style: AppTypography.displayScore
                  .copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.sm),
          Text('위치 원본 경로는 공개 랭킹에 노출하지 않고, 본인 기록 검증과 점수 계산에만 사용합니다.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: AppSpacing.xl),
          _ConsentTile(
              title: '서비스 이용약관',
              detailRoute: '/legal/terms',
              requiredConsent: true,
              value: _terms,
              onChanged: (value) => setState(() => _terms = value)),
          _ConsentTile(
              title: '개인정보 처리방침',
              detailRoute: '/legal/privacy',
              requiredConsent: true,
              value: _privacy,
              onChanged: (value) => setState(() => _privacy = value)),
          _ConsentTile(
              title: '위치정보 수집 및 주행 검증',
              detailRoute: '/legal/location',
              requiredConsent: true,
              value: _location,
              onChanged: (value) => setState(() => _location = value)),
          _ConsentTile(
              title: '맞춤형 광고',
              requiredConsent: false,
              value: _ads,
              onChanged: (value) => setState(() => _ads = value)),
          _ConsentTile(
              title: '마케팅 수신',
              requiredConsent: false,
              value: _marketing,
              onChanged: (value) => setState(() => _marketing = value)),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            ErrorStateView(
              message: _errorMessage!,
              onRetry: _requiredComplete && !_saving ? _completeConsent : null,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: _requiredComplete ? '추가 설정으로 이동' : '필수 동의를 확인하세요',
            icon: Icons.verified_user_rounded,
            isLoading: _saving,
            onPressed:
                _requiredComplete && !_saving ? () => _completeConsent() : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('선택 동의는 설정에서 언제든 변경할 수 있어요.',
              style: AppTypography.dataUnit
                  .copyWith(color: AppColors.onSurfaceMuted)),
        ],
      ),
    );
  }
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final String document;

  @override
  Widget build(BuildContext context) {
    final item = _legalDocument(document);
    return AppScaffold(
      appBar: FuelArenaAppBar(title: item.title, showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.headline,
            style:
                AppTypography.displayScore.copyWith(color: AppColors.neonGreen),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '시행일 ${item.effectiveDate}',
            style: AppTypography.dataUnit
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Text(item.summary, style: AppTypography.bodyMedium),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...item.sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.title, style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    ...section.items.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text('• $line', style: AppTypography.bodyMedium),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusChip(
                  label: '요청과 문의',
                  color: AppColors.electricBlue,
                  icon: Icons.support_agent_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(item.supportCopy, style: AppTypography.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: item.ctaLabel,
                  icon: item.ctaIcon,
                  onPressed: () => context.push(item.ctaRoute),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalDocument {
  const _LegalDocument({
    required this.title,
    required this.headline,
    required this.effectiveDate,
    required this.summary,
    required this.sections,
    required this.supportCopy,
    required this.ctaLabel,
    required this.ctaIcon,
    required this.ctaRoute,
  });

  final String title;
  final String headline;
  final String effectiveDate;
  final String summary;
  final List<_LegalSection> sections;
  final String supportCopy;
  final String ctaLabel;
  final IconData ctaIcon;
  final String ctaRoute;
}

class _LegalSection {
  const _LegalSection({required this.title, required this.items});

  final String title;
  final List<String> items;
}

_LegalDocument _legalDocument(String document) {
  return switch (document) {
    'terms' => const _LegalDocument(
        title: '서비스 이용약관',
        headline: '연비 경쟁을 안전하고 공정하게 운영합니다',
        effectiveDate: '2026.06.06',
        summary:
            'Fuel Arena는 주행 효율을 게임처럼 비교하는 플랫폼입니다. 사용자는 안전 운전 의무를 지키며, 기록 조작이나 위험 운전으로 획득한 점수는 보류 또는 무효 처리될 수 있습니다.',
        sections: [
          _LegalSection(title: '서비스 범위', items: [
            'Google 계정 기반 가입, 동의, 차량 설정, 주행 기록, 점수 계산, 랭킹, 배틀, 시즌, 보상, 고객지원 기능을 제공합니다.',
            '차량 카탈로그에 없는 차량은 직접 입력 요청으로 접수되며 운영자 검수 전까지 공식 랭킹 반영이 제한될 수 있습니다.',
            '일부 광고, 프리미엄, 쿠폰, 스폰서 챌린지 기능은 외부 콘솔과 스토어 설정 상태에 따라 제공 범위가 달라질 수 있습니다.',
          ]),
          _LegalSection(title: '공정성 기준', items: [
            '모의 위치, 비정상 속도, 낮은 GPS 정확도, 중복 세션, 조작 의심 기록은 검토 대기 상태로 전환됩니다.',
            '공식 점수는 서버 검증과 리그 조건을 통과한 주행에 대해서만 랭킹과 배틀 정산에 반영됩니다.',
            '현금성 배틀 보상은 제공하지 않으며, 보상은 앱 내 포인트, 쿠폰, 배지, 시즌 혜택 중심으로 운영됩니다.',
          ]),
          _LegalSection(title: '안전 운전', items: [
            '주행 중에는 광고, 팝업, 도전장, 불필요한 알림을 표시하지 않습니다.',
            '사용자는 실제 도로 상황과 법규를 우선해야 하며, 위험 운전으로 얻은 기록은 인정되지 않습니다.',
          ]),
        ],
        supportCopy: '약관 또는 기록 처리에 이의가 있으면 고객지원으로 문의하거나 검토 요청을 남길 수 있습니다.',
        ctaLabel: '고객지원으로 이동',
        ctaIcon: Icons.support_agent_rounded,
        ctaRoute: '/support',
      ),
    'location' => const _LegalDocument(
        title: '위치정보 이용 고지',
        headline: '위치는 주행 검증에만 필요한 만큼 사용합니다',
        effectiveDate: '2026.06.06',
        summary:
            'Fuel Arena는 주행 거리, 속도, GPS 정확도, 모의 위치 신호를 검증하기 위해 위치정보를 사용합니다. 정확한 좌표와 원본 주행 포인트는 공개 화면에 노출하지 않습니다.',
        sections: [
          _LegalSection(title: '수집하는 위치정보', items: [
            '주행 중 위치 좌표, 측정 시간, 정확도, 속도, 이동 거리 계산에 필요한 신호를 수집할 수 있습니다.',
            '모의 위치 여부와 비정상 속도 판단 값은 부정 기록 방지 목적으로만 사용합니다.',
            '앱이 백그라운드 위치를 요구하지 않는 흐름에서는 실제 주행 시작 시점에 필요한 권한만 요청합니다.',
          ]),
          _LegalSection(title: '이용 목적', items: [
            '주행 거리와 효율 점수 계산, 리그 배정, 부정 기록 탐지, 배틀 및 랭킹 정산에 사용합니다.',
            '정확한 경로 재현이 필요한 원본 drive_points는 private table로 보관하고 공개 랭킹에는 요약 지표만 표시합니다.',
          ]),
          _LegalSection(title: '공개 제한', items: [
            '공개 프로필, 랭킹, 라이벌 화면에는 이메일, 정확한 위치 좌표, 상세 주행 경로, raw drive_points를 표시하지 않습니다.',
            '운영자는 신고, 이의제기, 부정 기록 검토 목적에 필요한 범위에서만 관련 기록을 확인합니다.',
          ]),
        ],
        supportCopy:
            '위치 권한을 거부한 경우 앱 설정에서 권한을 다시 열 수 있으며, 위치정보 이용 문의는 고객지원에서 접수합니다.',
        ctaLabel: '권한 설정 안내',
        ctaIcon: Icons.location_on_rounded,
        ctaRoute: '/permissions/settings-guide?type=location',
      ),
    'account-deletion' => const _LegalDocument(
        title: '계정 및 데이터 삭제',
        headline: '삭제 요청은 운영 큐에서 상태를 확인합니다',
        effectiveDate: '2026.06.06',
        summary:
            '사용자는 데이터 다운로드, 데이터 삭제, 계정 삭제, 동의 철회를 요청할 수 있습니다. 진행 중인 같은 유형의 요청은 중복 접수를 막고 요청 내역에서 상태를 확인합니다.',
        sections: [
          _LegalSection(title: '요청 가능한 항목', items: [
            '데이터 다운로드: 계정, 차량, 주행 요약, 보상 내역의 내보내기를 요청합니다.',
            '데이터 삭제: 불필요한 개인정보 또는 선택한 기록 삭제 범위를 지정합니다.',
            '계정 삭제: Fuel Arena 계정 삭제와 탈퇴 처리를 요청합니다.',
            '동의 철회: 광고, 마케팅, 데이터 활용 동의 철회를 요청합니다.',
          ]),
          _LegalSection(title: '처리 방식', items: [
            '요청은 privacy_requests 운영 큐에 접수되고 open, review, completed, rejected 상태로 처리됩니다.',
            '법적 보관 의무, 결제 검증, 부정 기록 조사에 필요한 최소 기록은 별도 보관 기간을 안내한 뒤 처리합니다.',
            '처리 완료 또는 보류 결과는 요청 내역과 운영 알림을 통해 확인할 수 있습니다.',
          ]),
          _LegalSection(title: '삭제 후 영향', items: [
            '계정 삭제가 완료되면 로그인, 랭킹, 배틀, 시즌 보상, 프리미엄 이용 내역 접근이 제한됩니다.',
            '공정성 및 정산 무결성에 필요한 익명화된 요약 통계는 개인 식별이 불가능한 형태로 유지될 수 있습니다.',
          ]),
        ],
        supportCopy: '앱 안의 개인정보 설정에서 삭제 요청을 접수하면 운영자가 상태를 갱신합니다.',
        ctaLabel: '개인정보 설정으로 이동',
        ctaIcon: Icons.lock_person_rounded,
        ctaRoute: '/settings/privacy',
      ),
    _ => const _LegalDocument(
        title: '개인정보 처리방침',
        headline: '필요한 데이터만 수집하고 공개 범위를 제한합니다',
        effectiveDate: '2026.06.06',
        summary:
            'Fuel Arena는 연비 경쟁 서비스 제공, 주행 검증, 랭킹과 배틀 정산, 보상 지급, 고객지원 처리를 위해 필요한 정보를 수집합니다. service_role key와 결제 검증 secret은 Flutter 앱에 포함하지 않습니다.',
        sections: [
          _LegalSection(title: '수집하는 정보', items: [
            'Google 계정 식별자, 닉네임, 프로필 상태, 동의 기록, 보안 세션 힌트를 처리합니다.',
            '차량 제조사, 모델, 기준 연식, 엔진·미션 파워트레인, 대표 차량, 연료 리그와 차급 정보를 처리합니다.',
            '주행 세션 요약, 검증 점수, 보상, 쿠폰, 미션, 배틀, 고객지원, 신고, 개인정보 요청 기록을 처리합니다.',
            '결제 검증은 Edge Function에서 수행하며 앱에는 영수증 원문이나 스토어 secret을 저장하지 않습니다.',
          ]),
          _LegalSection(title: '이용 목적', items: [
            '가입, 동의, 차량 설정, 주행 기록, 점수 계산, 랭킹, 배틀, 시즌, 보상, 광고, 프리미엄 기능 제공에 사용합니다.',
            '부정 기록 탐지, 신고 및 이의제기 처리, 고객지원 답변, 운영 감사 로그 작성에 사용합니다.',
            '맞춤형 광고와 마케팅 수신은 선택 동의가 있는 경우에만 사용합니다.',
          ]),
          _LegalSection(title: '보호 원칙', items: [
            '정확한 위치 좌표와 raw drive_points는 공개 화면에 노출하지 않습니다.',
            '공개 랭킹과 공개 프로필에는 제한된 요약 정보만 표시합니다.',
            '사용자는 데이터 다운로드, 삭제, 계정 삭제, 동의 철회 요청을 개인정보 설정에서 접수할 수 있습니다.',
          ]),
        ],
        supportCopy:
            '개인정보 열람, 삭제, 처리 제한 요청은 앱의 개인정보 설정 또는 고객지원 화면에서 접수할 수 있습니다.',
        ctaLabel: '개인정보 설정으로 이동',
        ctaIcon: Icons.lock_person_rounded,
        ctaRoute: '/settings/privacy',
      ),
  };
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
          Text('주행 거리와\n지역 리그를 계산해요',
              style: AppTypography.displayScore
                  .copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.sm),
          Text('권한 요청은 실제 주행 시작 시점에 진행합니다. 개발 모드는 권한 없이 기록 흐름을 확인할 수 있어요.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted)),
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
            label: '추가 설정으로 이동',
            icon: Icons.directions_car_rounded,
            onPressed: () => context.go('/setup'),
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
      title: '차량 설정 완료',
      subtitle: '대표 차량이 설정됐습니다. 이제 첫 주행으로 시즌 점수를 받을 수 있어요.',
      icon: Icons.verified_rounded,
      primaryLabel: '홈으로 이동',
      onPrimary: () => context.go('/home'),
      sections: const [
        InfoSection(title: '공정 매칭', body: '같은 연료 리그와 차급 운전자들과 우선 비교합니다.'),
        InfoSection(
            title: '비공개 위치',
            body: '정확한 좌표는 개인 기록 검증에만 사용되고 공개 화면에는 표시하지 않습니다.'),
      ],
    );
  }
}

class BattleCreateScreen extends ConsumerStatefulWidget {
  const BattleCreateScreen({super.key});

  @override
  ConsumerState<BattleCreateScreen> createState() => _BattleCreateScreenState();
}

class _BattleCreateScreenState extends ConsumerState<BattleCreateScreen> {
  String _rule = '최고 효율 점수';
  String _period = '24시간';
  String _opponent = 'NightCruise';
  var _creating = false;

  @override
  Widget build(BuildContext context) {
    final primaryVehicle = ref.watch(primaryVehicleProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '배틀 만들기', showBack: true),
      child: primaryVehicle.when(
        loading: () => const LoadingSkeletonView(lines: 3),
        error: (error, stackTrace) =>
            const ErrorStateView(message: '대표 차량을 확인하지 못했어요.'),
        data: (vehicle) {
          if (vehicle == null) {
            return EmptyStateView(
              title: '차량 설정이 필요해요',
              message: '배틀 생성은 내 연료 리그와 차급을 기준으로 제한됩니다.',
              actionLabel: '차량 설정하기',
              onAction: () => context.go('/setup/vehicle'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('현금 없이\n점수로만 겨뤄요',
                  style: AppTypography.displayScore
                      .copyWith(color: AppColors.neonGreen)),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                borderColor: AppColors.neonGreen.withValues(alpha: 0.25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip(
                        label: vehicle.leagueDisplayName,
                        color: AppColors.neonGreen),
                    const SizedBox(height: AppSpacing.sm),
                    Text('매칭 조건: ${vehicle.fuelType} · ${vehicle.vehicleClass}',
                        style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text('다른 연료 리그와 겨루는 경우 랭킹 점수에 반영하지 않는 친선전으로 표시합니다.',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.onSurfaceMuted)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ChoiceBlock(
                  title: '상대',
                  values: const ['NightCruise', 'EcoBlade', '공개 매칭'],
                  selected: _opponent,
                  onChanged: (value) => setState(() => _opponent = value)),
              _ChoiceBlock(
                  title: '규칙',
                  values: const ['최고 효율 점수', '평균 안정 점수', '주간 평균 연비'],
                  selected: _rule,
                  onChanged: (value) => setState(() => _rule = value)),
              _ChoiceBlock(
                  title: '기간',
                  values: const ['24시간', '3일', '이번 주'],
                  selected: _period,
                  onChanged: (value) => setState(() => _period = value)),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatusChip(label: '비금전 보상', color: AppColors.amber),
                    const SizedBox(height: AppSpacing.md),
                    Text('시즌 XP 120 · 배지 조각 2개',
                        style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text('배틀은 현금성 베팅 없이 앱 내 보상과 기록으로만 정산됩니다.',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.onSurfaceMuted)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: '배틀 생성',
                icon: Icons.sports_mma_rounded,
                isLoading: _creating,
                onPressed: () => _createBattle(vehicle),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createBattle(Vehicle vehicle) async {
    setState(() => _creating = true);
    try {
      final battle = await ref.read(battleRepositoryProvider).createBattle(
            title: _opponent == '공개 매칭'
                ? '${vehicle.leagueDisplayName} 공개 배틀'
                : '$_opponent에게 도전',
            battleType: _opponent == '공개 매칭' ? '공개 매칭' : '1:1 배틀',
            ruleType: _rule,
            duration: _durationForPeriod(_period),
            rewardSummary: '시즌 XP 120 · 배지 조각 2개',
            requiredFuelLeague: vehicle.leagueKey,
            requiredVehicleClass: vehicle.vehicleClass,
            opponentNickname: _opponent,
          );
      ref.invalidate(battlesProvider);
      if (!mounted) return;
      context.go('/battle/detail/${battle.id}');
    } catch (error) {
      if (!mounted) return;
      final message = const ErrorMapper().messageFor(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('배틀을 만들 수 없어요. $message')),
      );
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  Duration _durationForPeriod(String period) {
    return switch (period) {
      '3일' => const Duration(days: 3),
      '이번 주' => const Duration(days: 7),
      _ => const Duration(hours: 24),
    };
  }
}

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  var _requesting = false;

  Future<void> _request() async {
    setState(() => _requesting = true);
    final status = await Permission.locationWhenInUse.request();
    if (!mounted) {
      return;
    }
    setState(() => _requesting = false);
    if (status.isGranted || status.isLimited) {
      context.go('/drive/start');
      return;
    }
    context.go('/permissions/denied?type=location');
  }

  @override
  Widget build(BuildContext context) {
    return FuelArenaInfoScreen(
      title: '위치 권한',
      subtitle: '주행 거리와 리그 계산을 위해 위치 권한이 필요해요',
      icon: Icons.location_on_rounded,
      primaryLabel: '권한 요청하기',
      onPrimary: _requesting ? null : _request,
      secondaryLabel: '둘러보기',
      onSecondary: () => context.go('/home'),
      sections: const [
        InfoSection(
            title: '주행 기록', body: '권한이 없어도 앱을 둘러볼 수 있지만, 주행 기록은 사용할 수 없어요.'),
        InfoSection(title: '공개 제한', body: '정확한 좌표는 공개 화면에 표시하지 않습니다.'),
      ],
    );
  }
}

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  var _requesting = false;

  Future<void> _request() async {
    setState(() => _requesting = true);
    final status = await Permission.notification.request();
    if (!mounted) {
      return;
    }
    setState(() => _requesting = false);
    if (status.isGranted) {
      context.go('/notifications');
      return;
    }
    context.go('/permissions/denied?type=notification');
  }

  @override
  Widget build(BuildContext context) {
    return FuelArenaInfoScreen(
      title: '알림 권한',
      subtitle: '랭킹 추월, 배틀 결과, 시즌 보상, 쿠폰 만료를 알려드려요',
      icon: Icons.notifications_active_rounded,
      primaryLabel: '알림 허용하기',
      onPrimary: _requesting ? null : _request,
      secondaryLabel: '나중에',
      onSecondary: () => context.go('/home'),
      sections: const [
        InfoSection(title: '주행 중 보류', body: '주행 중에는 팝업을 띄우지 않고 완료 후 요약합니다.'),
        InfoSection(title: '설정에서 변경', body: '설정에서 알림을 다시 관리할 수 있습니다.'),
      ],
    );
  }
}

class PermissionDeniedScreen extends StatelessWidget {
  const PermissionDeniedScreen({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final isLocation = type == 'location';
    return FuelArenaInfoScreen(
      title: '권한이 필요해요',
      subtitle: isLocation
          ? '위치 권한이 없어도 앱을 둘러볼 수 있지만, 주행 기록은 사용할 수 없어요.'
          : '알림을 허용하지 않아도 앱은 사용할 수 있어요.',
      icon: Icons.block_rounded,
      primaryLabel: '설정 안내 보기',
      onPrimary: () => context.go('/permissions/settings-guide?type=$type'),
      secondaryLabel: '홈으로 이동',
      onSecondary: () => context.go('/home'),
      sections: const [
        InfoSection(title: '다시 허용 가능', body: '설정에서 권한을 다시 허용할 수 있어요.'),
      ],
    );
  }
}

class PermissionSettingsGuideScreen extends StatelessWidget {
  const PermissionSettingsGuideScreen({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return FuelArenaInfoScreen(
      title: '설정에서 허용하기',
      subtitle: '휴대폰 설정에서 Fuel Arena 권한을 다시 허용할 수 있어요.',
      icon: Icons.settings_rounded,
      primaryLabel: '앱 설정 열기',
      onPrimary: () => openAppSettings(),
      secondaryLabel: '홈으로 이동',
      onSecondary: () => context.go('/home'),
      sections: [
        InfoSection(title: '1단계', body: '앱 설정에서 Fuel Arena를 선택합니다.'),
        InfoSection(
            title: '2단계',
            body: type == 'location'
                ? '위치 권한을 앱 사용 중 허용으로 변경합니다.'
                : '알림 권한을 허용으로 변경합니다.'),
      ],
    );
  }
}

class BattleDetailScreen extends ConsumerWidget {
  const BattleDetailScreen({super.key, required this.battleId});

  final String battleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final battleDetail = ref.watch(battleDetailProvider(battleId));
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '배틀 상세', showBack: true),
      child: battleDetail.when(
        loading: () => const LoadingSkeletonView(lines: 4),
        error: (error, stackTrace) => ErrorStateView(
          message: '배틀 정보를 불러오지 못했어요.',
          onRetry: () => ref.invalidate(battleDetailProvider(battleId)),
        ),
        data: (battle) {
          if (battle == null) {
            return EmptyStateView(
              title: '배틀 정보를 찾지 못했어요',
              message: '이미 종료되었거나 접근할 수 없는 배틀입니다. 배틀 목록에서 다시 선택해 주세요.',
              actionLabel: '배틀 목록 보기',
              onAction: () => context.go('/home?tab=battle'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BattleCard(battle: battle),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: '정산 기준'),
              const _InfoList(items: [
                '검증된 주행 기록만 반영',
                '동급 차량 보정 계수 적용',
                'GPS 이상 기록은 공정성 검토로 보류'
              ]),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                  label: '결과 확인',
                  icon: Icons.emoji_events_rounded,
                  onPressed: () => context.go('/battle/result/$battleId')),
            ],
          );
        },
      ),
    );
  }
}

class BattleResultScreen extends ConsumerStatefulWidget {
  const BattleResultScreen({super.key, required this.battleId});

  final String battleId;

  @override
  ConsumerState<BattleResultScreen> createState() => _BattleResultScreenState();
}

class _BattleResultScreenState extends ConsumerState<BattleResultScreen> {
  var _settling = false;

  Future<void> _settleBattle(Battle battle) async {
    if (_settling) {
      return;
    }
    setState(() => _settling = true);
    try {
      await ref.read(analyticsRepositoryProvider).track(
        'battle_settle_requested',
        properties: {'battle_id': battle.id},
      );
      await ref.read(battleRepositoryProvider).settleBattle(
            battleId: battle.id,
            myScore: battle.myScore,
            opponentScore: battle.opponentScore,
          );
      ref.invalidate(battleDetailProvider(battle.id));
      ref.invalidate(battlesProvider);
      await ref.read(analyticsRepositoryProvider).track(
        'battle_settle_succeeded',
        properties: {'battle_id': battle.id},
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('배틀 정산을 완료했어요.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = const ErrorMapper().messageFor(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('배틀 정산을 요청하지 못했어요. $message')),
      );
    } finally {
      if (mounted) {
        setState(() => _settling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final battleDetail = ref.watch(battleDetailProvider(widget.battleId));
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '배틀 결과', showBack: true),
      child: battleDetail.when(
        loading: () => const LoadingSkeletonView(lines: 3),
        error: (error, stackTrace) => ErrorStateView(
          message: '배틀 결과를 불러오지 못했어요.',
          onRetry: () => ref.invalidate(battleDetailProvider(widget.battleId)),
        ),
        data: (battle) {
          if (battle == null) {
            return EmptyStateView(
              title: '배틀 결과가 없어요',
              message: '결과가 정산되지 않았거나 접근할 수 없는 배틀입니다. 배틀 목록에서 다시 확인해 주세요.',
              actionLabel: '배틀 목록 보기',
              onAction: () => context.go('/home?tab=battle'),
            );
          }
          final settled = battle.status == 'completed' ||
              battle.status == '종료' ||
              battle.status == '완료';
          final won = battle.myScore >= battle.opponentScore;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusChip(
                label: settled ? (won ? '승리' : '복수전 가능') : '정산 대기',
                color: won || !settled ? AppColors.neonGreen : AppColors.amber,
                icon: settled
                    ? (won ? Icons.emoji_events_rounded : Icons.replay_rounded)
                    : Icons.rule_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
              BattleCard(battle: battle),
              const SizedBox(height: AppSpacing.lg),
              if (settled)
                RewardCard(
                    title: won ? '시즌 XP 지급 완료' : '기본 참가 보상 지급',
                    description:
                        won ? battle.rewardSummary : '검증된 주행 참여 보상이 지급됐어요.')
              else
                const RewardCard(
                  title: '정산 대기',
                  description: '검증된 주행 점수로 배틀 결과와 참가 보상을 확정할 수 있어요.',
                ),
              const SizedBox(height: AppSpacing.lg),
              if (settled)
                PrimaryButton(
                    label: '복수전 신청',
                    icon: Icons.replay_rounded,
                    onPressed: () => context.go('/battle/create'))
              else
                PrimaryButton(
                  label: '배틀 정산 요청',
                  icon: Icons.rule_rounded,
                  isLoading: _settling,
                  onPressed: () => _settleBattle(battle),
                ),
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
        error: (error, stackTrace) =>
            const ErrorStateView(message: '시즌패스를 불러오지 못했어요.'),
        data: (value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SeasonProgressCard(season: value),
            const SizedBox(height: AppSpacing.lg),
            const RewardCard(
                title: '무료 트랙', description: '시즌 XP, 배지 조각, 쿠폰 응모권이 열립니다.'),
            const SizedBox(height: AppSpacing.md),
            LockedPremiumCard(
                title: '프리미엄 트랙',
                description: '광고 없이 추가 보상과 한정 골드 배지를 받을 수 있어요.',
                onTap: () => context.go('/premium')),
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

class RivalScreen extends ConsumerWidget {
  const RivalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankings = ref.watch(rankingEntriesProvider('내 리그'));
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '라이벌', showBack: true),
      child: rankings.when(
        loading: () => const LoadingSkeletonView(lines: 4),
        error: (error, stackTrace) => ErrorStateView(
          message: '라이벌 정보를 불러오지 못했어요.',
          onRetry: () => ref.invalidate(rankingEntriesProvider('내 리그')),
        ),
        data: (items) {
          final current = _currentRankingEntry(items);
          final rivals = _rivalEntriesFor(items, current);
          if (current == null && rivals.isEmpty) {
            return EmptyStateView(
              title: '비교할 라이벌이 없어요',
              message: '검증된 주행 기록이 랭킹에 반영되면 내 주변 운전자를 확인할 수 있습니다.',
              actionLabel: '주행 시작하기',
              onAction: () => context.go('/drive/start'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '바로 위를\n추월하세요',
                style:
                    AppTypography.displayScore.copyWith(color: AppColors.amber),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '닉네임, 티어, 점수, 차급, 연료 리그만 사용해 공개 라이벌을 비교합니다.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (current != null)
                AppCard(
                  borderColor: AppColors.neonGreen.withValues(alpha: 0.25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StatusChip(
                          label: '내 위치', color: AppColors.neonGreen),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '#${current.rank} ${current.nickname}',
                        style: AppTypography.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${formatNumber(current.score)}점 · ${current.tier} · ${current.fuelType} ${current.vehicleClass}',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.onSurfaceMuted),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: '추월 목표'),
              const SizedBox(height: AppSpacing.sm),
              if (rivals.isEmpty)
                const EmptyStateView(
                  title: '가까운 라이벌이 없어요',
                  message: '현재 리그에서 내 주변 순위가 더 쌓이면 목표가 표시됩니다.',
                )
              else
                for (final rival in rivals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _RivalCard(
                      rival: rival,
                      currentScore: current?.score,
                    ),
                  ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: '배틀 만들기',
                icon: Icons.sports_mma_rounded,
                onPressed: () => context.go('/battle/create'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RivalCard extends StatelessWidget {
  const _RivalCard({
    required this.rival,
    required this.currentScore,
  });

  final RankingEntry rival;
  final int? currentScore;

  @override
  Widget build(BuildContext context) {
    final gap = currentScore == null ? null : rival.score - currentScore!;
    return AppCard(
      borderColor: AppColors.amber.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${rival.rank} ${rival.nickname}',
                  style: AppTypography.titleMedium,
                ),
              ),
              StatusChip(label: rival.tier, color: AppColors.gold),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${formatNumber(rival.score)}점 · ${rival.fuelType} ${rival.vehicleClass}',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          if (gap != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              gap > 0 ? '${formatNumber(gap)}점 차이' : '이미 앞서고 있어요',
              style: AppTypography.dataUnit.copyWith(
                color: gap > 0 ? AppColors.amber : AppColors.neonGreen,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

RankingEntry? _currentRankingEntry(List<RankingEntry> items) {
  return _firstWhereOrNull(items, (entry) => entry.isCurrentUser);
}

List<RankingEntry> _rivalEntriesFor(
  List<RankingEntry> items,
  RankingEntry? current,
) {
  final candidates = items.where((entry) => !entry.isCurrentUser).toList()
    ..sort((a, b) => a.rank.compareTo(b.rank));
  if (current == null) {
    return candidates.take(3).toList();
  }
  final above = candidates.where((entry) => entry.rank < current.rank).toList()
    ..sort((a, b) => b.rank.compareTo(a.rank));
  if (above.isNotEmpty) {
    return above.take(3).toList();
  }
  return candidates.take(3).toList();
}

class CrewScreen extends ConsumerWidget {
  const CrewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crew = ref.watch(myCrewProvider);
    final members = ref.watch(crewMembersProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '크루', showBack: true),
      child: crew.when(
        loading: () => const LoadingSkeletonView(lines: 5),
        error: (error, stackTrace) =>
            const ErrorStateView(message: '크루 정보를 불러오지 못했어요.'),
        data: (item) {
          if (item == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EmptyStateView(
                  title: '아직 소속 크루가 없어요',
                  message: '공식 주행 기록이 쌓이면 같은 리그 운전자와 크루 경쟁을 시작할 수 있습니다.',
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: '배틀에서 크루 찾기',
                  icon: Icons.groups_rounded,
                  onPressed: () => context.go('/battle'),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                glowColor: AppColors.electricBlue,
                child: Row(
                  children: [
                    const Icon(Icons.groups_rounded,
                        color: AppColors.electricBlue, size: 42),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: AppTypography.titleLarge
                                  .copyWith(color: AppColors.electricBlue)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(item.description,
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.onSurfaceMuted)),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              StatusChip(
                                  label: '크루원 ${item.memberCount}명',
                                  color: AppColors.neonGreen),
                              StatusChip(
                                  label:
                                      '주간 ${formatNumber(item.weeklyScore)}점',
                                  color: AppColors.gold),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: '크루 배틀 만들기',
                icon: Icons.emoji_events_rounded,
                onPressed: () => context.go('/battle/create'),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: '크루원 기여도'),
              const SizedBox(height: AppSpacing.sm),
              members.when(
                loading: () => const LoadingSkeletonView(lines: 4),
                error: (error, stackTrace) =>
                    const ErrorStateView(message: '크루원 목록을 불러오지 못했어요.'),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyStateView(
                      title: '표시할 크루원이 없어요',
                      message: '크루 가입과 주간 기여도가 반영되면 여기에 표시됩니다.',
                    );
                  }
                  return Column(
                    children: items
                        .map(
                          (member) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _CrewMemberCard(member: member),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class OtherUserProfileScreen extends ConsumerWidget {
  const OtherUserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(publicRankingProfileProvider(userId));
    return AppScaffold(
      appBar: const FuelArenaAppBar(
        title: '공개 프로필',
        showBack: true,
        fallbackLocation: '/home?tab=ranking',
      ),
      child: profile.when(
        loading: () => const LoadingSkeletonView(lines: 4),
        error: (error, stackTrace) => ErrorStateView(
          message: '공개 프로필을 불러오지 못했어요.',
          onRetry: () => ref.invalidate(publicRankingProfileProvider(userId)),
        ),
        data: (entry) {
          if (entry == null) {
            return EmptyStateView(
              title: '공개 프로필을 찾을 수 없어요',
              message: '랭킹에 반영된 공개 기록이 없거나 접근할 수 없는 사용자입니다.',
              actionLabel: '랭킹으로 돌아가기',
              onAction: () => context.go('/home?tab=ranking'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.nickname,
                style: AppTypography.displayScore
                    .copyWith(color: AppColors.neonGreen),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '공개 랭킹 기록으로만 구성한 프로필입니다.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                borderColor: AppColors.neonGreen.withValues(alpha: 0.28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip(label: entry.tier, color: AppColors.gold),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '#${entry.rank} · ${formatNumber(entry.score)}점',
                      style: AppTypography.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${entry.vehicleClass} · ${FuelLeague.nameForKey(entry.leagueKey)}',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('공개 제한', style: AppTypography.titleMedium),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      '정확한 위치, 상세 주행 경로, 원본 주행 포인트, 이메일은 표시하지 않습니다.',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: '배틀 만들기',
                icon: Icons.sports_mma_rounded,
                onPressed: () => context.go('/battle/create'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: '사용자 신고',
                icon: Icons.flag_rounded,
                onPressed: () => context.go('/support/report-user/$userId'),
              ),
            ],
          );
        },
      ),
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
        error: (error, stackTrace) =>
            const ErrorStateView(message: '배지를 불러오지 못했어요.'),
        data: (items) => items.isEmpty
            ? const EmptyStateView(
                title: '획득한 배지가 아직 없어요',
                message: '검증 주행, 시즌 미션, 배틀 승리를 쌓으면 컬렉션이 채워집니다.',
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('내 기록을\n자랑하세요',
                      style: AppTypography.displayScore
                          .copyWith(color: AppColors.neonGreen)),
                  const SizedBox(height: AppSpacing.lg),
                  ...items.map((badge) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _BadgeCard(badge: badge))),
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
        error: (error, stackTrace) => ErrorStateView(
          message: '챌린지를 불러오지 못했어요.',
          onRetry: () => ref.invalidate(sponsorChallengesProvider),
        ),
        data: (items) {
          final challenge =
              _firstWhereOrNull(items, (item) => item.id == challengeId);
          if (challenge == null) {
            return EmptyStateView(
              title: '챌린지를 찾을 수 없어요',
              message: '기간이 종료되었거나 참여 조건이 바뀐 챌린지입니다. 현재 열린 챌린지를 확인해 주세요.',
              actionLabel: '챌린지 목록 보기',
              onAction: () => context.go('/sponsor'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SponsorChallengeCard(challenge: challenge),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: '참가 조건'),
              const _InfoList(items: [
                '15km 이상 검증 주행',
                '동급 대비 상위 30% 이내',
                '챌린지 기간 안에 결과 확정'
              ]),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                  label: '챌린지 참가',
                  icon: Icons.flag_rounded,
                  onPressed: () => context.go('/drive/start')),
            ],
          );
        },
      ),
    );
  }
}

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  var _submittingType = '';

  Future<void> _submitRequest(String requestType) async {
    final activeRequest = _activePrivacyRequestForType(
      ref.read(privacyRequestsProvider).asData?.value ?? const [],
      requestType,
    );
    if (activeRequest != null) {
      _showPrivacyRequestAlreadyActiveSnack();
      return;
    }

    final description = await _showPrivacyRequestDialog(requestType);
    if (description == null || description.isEmpty) {
      return;
    }
    setState(() => _submittingType = requestType);
    var message = '개인정보 요청을 접수했어요.';
    try {
      await ref.read(privacyRequestRepositoryProvider).createRequest(
            PrivacyRequestSubmission(
              requestType: requestType,
              description: description,
            ),
          );
      await ref.read(analyticsRepositoryProvider).track(
        'privacy_request_submitted',
        properties: {'request_type': requestType},
      );
    } on ActivePrivacyRequestException {
      message = '이미 진행 중인 개인정보 요청이 있어요. 요청 내역에서 상태를 확인해 주세요.';
    } catch (_) {
      message = '개인정보 요청 접수에 실패했어요. 잠시 후 다시 시도해 주세요.';
    } finally {
      ref.invalidate(privacyRequestsProvider);
      if (mounted) {
        setState(() => _submittingType = '');
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showPrivacyRequestAlreadyActiveSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('이미 진행 중인 개인정보 요청이 있어요. 요청 내역에서 상태를 확인해 주세요.'),
      ),
    );
  }

  Future<String?> _showPrivacyRequestDialog(String requestType) async {
    var descriptionText = _privacyRequestDefaultBody(requestType);
    var confirmationText = '';
    String? validationMessage;
    String? confirmationMessage;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final requiresConfirmation =
                _privacyRequestRequiresConfirmation(requestType);
            return AlertDialog(
              title: Text(_privacyRequestTypeLabel(requestType)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _privacyRequestDialogCopy(requestType),
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      initialValue: descriptionText,
                      onChanged: (value) => descriptionText = value,
                      minLines: 4,
                      maxLines: 7,
                      maxLength: 600,
                      decoration: InputDecoration(
                        labelText: '요청 내용',
                        errorText: validationMessage,
                      ),
                    ),
                    if (requiresConfirmation) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '계속하려면 확인 문구를 직접 입력해 주세요.',
                        style: AppTypography.dataUnit
                            .copyWith(color: AppColors.amber),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        onChanged: (value) => confirmationText = value,
                        decoration: InputDecoration(
                          labelText: '확인 문구',
                          hintText: _privacyRequestConfirmationPhrase,
                          errorText: confirmationMessage,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('취소'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final text = descriptionText.trim();
                    final error = InputValidators.supportBody(text);
                    if (error != null) {
                      setDialogState(() => validationMessage = error);
                      return;
                    }
                    if (requiresConfirmation &&
                        confirmationText.trim() !=
                            _privacyRequestConfirmationPhrase) {
                      setDialogState(
                        () => confirmationMessage =
                            '정확히 "$_privacyRequestConfirmationPhrase"를 입력해 주세요.',
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop(text);
                  },
                  icon: const Icon(Icons.lock_person_rounded),
                  label: Text(requiresConfirmation ? '계정 삭제 요청 접수' : '요청 접수'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(privacyRequestsProvider);
    final requestItems = requests.asData?.value ?? const <PrivacyRequest>[];
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '개인정보 설정', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('데이터와 동의 관리',
              style: AppTypography.displayScore
                  .copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.lg),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusChip(
                    label: '공개 제한 원칙',
                    color: AppColors.electricBlue,
                    icon: Icons.privacy_tip_rounded),
                SizedBox(height: AppSpacing.md),
                Text(
                    '정확한 위치 좌표와 원본 주행 포인트는 공개 화면에 노출하지 않습니다. 데이터 요청은 운영자 검토 큐에 안전하게 접수됩니다.',
                    style: AppTypography.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PrivacyRequestTypeCard(
            title: '데이터 다운로드 요청',
            description: '계정, 차량, 주행 요약, 보상 내역의 내보내기를 요청합니다.',
            icon: Icons.download_rounded,
            isLoading: _submittingType == 'data_download',
            hasActiveRequest:
                _activePrivacyRequestForType(requestItems, 'data_download') !=
                    null,
            onPressed: () => _submitRequest('data_download'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PrivacyRequestTypeCard(
            title: '데이터 삭제 요청',
            description: '불필요한 개인정보 또는 기록 삭제 범위를 지정해 요청합니다.',
            icon: Icons.delete_outline_rounded,
            isLoading: _submittingType == 'data_delete',
            hasActiveRequest:
                _activePrivacyRequestForType(requestItems, 'data_delete') !=
                    null,
            onPressed: () => _submitRequest('data_delete'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PrivacyRequestTypeCard(
            title: '계정 삭제 요청',
            description: '탈퇴와 계정 삭제 처리를 요청합니다. 운영자 확인 후 진행됩니다.',
            icon: Icons.person_remove_rounded,
            isLoading: _submittingType == 'account_deletion',
            hasActiveRequest: _activePrivacyRequestForType(
                  requestItems,
                  'account_deletion',
                ) !=
                null,
            onPressed: () => _submitRequest('account_deletion'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PrivacyRequestTypeCard(
            title: '동의 철회 요청',
            description: '필수 동의 외 광고, 마케팅, 데이터 활용 동의 철회를 요청합니다.',
            icon: Icons.gpp_maybe_rounded,
            isLoading: _submittingType == 'consent_withdrawal',
            hasActiveRequest: _activePrivacyRequestForType(
                  requestItems,
                  'consent_withdrawal',
                ) !=
                null,
            onPressed: () => _submitRequest('consent_withdrawal'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '공개 고지'),
          _LegalNoticeCard(
            title: '개인정보 처리방침',
            description: '수집 정보, 이용 목적, 공개 제한 원칙을 확인합니다.',
            icon: Icons.privacy_tip_rounded,
            onTap: () => context.push('/legal/privacy'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _LegalNoticeCard(
            title: '위치정보 이용 고지',
            description: '주행 검증에 쓰는 위치정보와 비공개 범위를 확인합니다.',
            icon: Icons.location_on_rounded,
            onTap: () => context.push('/legal/location'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _LegalNoticeCard(
            title: '계정 및 데이터 삭제 안내',
            description: '다운로드, 삭제, 탈퇴 요청 처리 방식을 확인합니다.',
            icon: Icons.person_remove_rounded,
            onTap: () => context.push('/legal/account-deletion'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '요청 내역'),
          requests.when(
            loading: () => const LoadingSkeletonView(lines: 2),
            error: (error, stackTrace) => ErrorStateView(
              message: '개인정보 요청 내역을 불러오지 못했어요.',
              onRetry: () => ref.invalidate(privacyRequestsProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyStateView(
                  title: '접수된 요청이 없어요',
                  message:
                      '다운로드, 삭제, 계정 삭제, 동의 철회 요청을 이곳에서 접수하고 상태를 확인할 수 있습니다.',
                );
              }
              return Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _PrivacyRequestHistoryCard(request: item),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LegalNoticeCard extends StatelessWidget {
  const _LegalNoticeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.electricBlue),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.onSurfaceMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '내용 보기',
            onPressed: onTap,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _PrivacyRequestTypeCard extends StatelessWidget {
  const _PrivacyRequestTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isLoading,
    required this.hasActiveRequest,
    required this.onPressed,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isLoading;
  final bool hasActiveRequest;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.neonGreen),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.onSurfaceMuted),
                ),
                if (hasActiveRequest) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '이미 접수된 요청이 진행 중입니다.',
                    style:
                        AppTypography.dataUnit.copyWith(color: AppColors.amber),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 112,
            child: PrimaryButton(
              label: hasActiveRequest ? '진행 중' : '요청',
              icon: hasActiveRequest
                  ? Icons.hourglass_top_rounded
                  : Icons.chevron_right_rounded,
              isLoading: isLoading,
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyRequestHistoryCard extends StatelessWidget {
  const _PrivacyRequestHistoryCard({required this.request});

  final PrivacyRequest request;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatusChip(
                label: _privacyRequestTypeLabel(request.requestType),
                color: AppColors.electricBlue,
              ),
              StatusChip(
                label: _privacyRequestStatusLabel(request.status),
                color: _privacyRequestStatusColor(request.status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(request.description, style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '접수 ${_formatDateTime(request.createdAt)}',
            style: AppTypography.dataUnit
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}

PrivacyRequest? _activePrivacyRequestForType(
  Iterable<PrivacyRequest> requests,
  String requestType,
) {
  for (final request in requests) {
    if (request.requestType == requestType &&
        _isActivePrivacyRequestStatus(request.status)) {
      return request;
    }
  }
  return null;
}

bool _isActivePrivacyRequestStatus(String status) {
  final normalized = status.toLowerCase();
  return normalized == 'open' || normalized == 'review';
}

const _privacyRequestConfirmationPhrase = '계정 삭제';

bool _privacyRequestRequiresConfirmation(String requestType) {
  return requestType == 'account_deletion';
}

String _privacyRequestTypeLabel(String type) {
  return switch (type) {
    'data_download' => '데이터 다운로드',
    'data_delete' => '데이터 삭제',
    'account_deletion' => '계정 삭제',
    'consent_withdrawal' => '동의 철회',
    _ => type,
  };
}

String _privacyRequestDialogCopy(String type) {
  return switch (type) {
    'account_deletion' => '계정 삭제는 되돌릴 수 없으므로 운영자가 본인 요청과 보관 의무를 확인한 뒤 처리합니다.',
    'data_delete' => '삭제할 데이터 범위를 남겨 주세요. 법적 보관 의무가 있는 기록은 별도로 안내됩니다.',
    'consent_withdrawal' =>
      '철회할 동의 항목을 남겨 주세요. 필수 동의 철회는 서비스 이용 가능 범위를 함께 안내합니다.',
    _ => '내보내기 또는 확인이 필요한 데이터 범위를 남겨 주세요.',
  };
}

String _privacyRequestDefaultBody(String type) {
  return switch (type) {
    'account_deletion' => 'Fuel Arena 계정 삭제와 탈퇴 처리를 요청합니다.',
    'data_delete' => '내 계정에 연결된 개인정보와 선택한 기록 삭제를 요청합니다.',
    'consent_withdrawal' => '광고, 마케팅, 데이터 활용 동의 철회를 요청합니다.',
    _ => '내 계정에 연결된 개인정보와 주행/보상 요약 데이터 다운로드를 요청합니다.',
  };
}

String _privacyRequestStatusLabel(String status) {
  return switch (status.toLowerCase()) {
    'open' => '접수',
    'review' => '검토 중',
    'completed' => '처리 완료',
    'rejected' => '보류',
    _ => status,
  };
}

Color _privacyRequestStatusColor(String status) {
  return switch (status.toLowerCase()) {
    'open' => AppColors.amber,
    'review' => AppColors.electricBlue,
    'completed' => AppColors.neonGreen,
    'rejected' => AppColors.danger,
    _ => AppColors.outline,
  };
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}.${two(local.month)}.${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}

class AdsSettingsScreen extends ConsumerStatefulWidget {
  const AdsSettingsScreen({super.key});

  @override
  ConsumerState<AdsSettingsScreen> createState() => _AdsSettingsScreenState();
}

class _AdsSettingsScreenState extends ConsumerState<AdsSettingsScreen> {
  var _personalized = false;
  var _marketing = false;
  var _localInitialized = false;
  var _saving = false;

  Future<void> _saveConsent({
    required bool personalizedAdsAccepted,
    required bool marketingAccepted,
  }) async {
    final current = ref.read(appConsentProvider).asData?.value;
    setState(() {
      _personalized = personalizedAdsAccepted;
      _marketing = marketingAccepted;
      _localInitialized = true;
      _saving = true;
    });
    await ref.read(consentRepositoryProvider).saveConsent(
          termsAccepted: current?.termsAccepted ?? true,
          privacyAccepted: current?.privacyAccepted ?? true,
          locationAccepted: current?.locationAccepted ?? true,
          personalizedAdsAccepted: personalizedAdsAccepted,
          marketingAccepted: marketingAccepted,
        );
    await ref.read(analyticsRepositoryProvider).track(
      'consent_preferences_updated',
      properties: {
        'personalized_ads': personalizedAdsAccepted,
        'marketing': marketingAccepted,
      },
    );
    ref.invalidate(appConsentProvider);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('광고 동의 설정을 저장했어요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final consent = ref.watch(appConsentProvider);
    final consentValue = consent.asData?.value;
    final personalized = _localInitialized
        ? _personalized
        : consentValue?.personalizedAdsAccepted ?? _personalized;
    final marketing = _localInitialized
        ? _marketing
        : consentValue?.marketingAccepted ?? _marketing;
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '광고 설정', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('광고는 선택 보상으로만',
              style: AppTypography.displayScore
                  .copyWith(color: AppColors.neonGreen)),
          const SizedBox(height: AppSpacing.lg),
          if (consent.isLoading || _saving) ...[
            const LoadingSkeletonView(lines: 1),
            const SizedBox(height: AppSpacing.md),
          ],
          SwitchListTile(
            value: personalized,
            onChanged: _saving
                ? null
                : (value) => _saveConsent(
                      personalizedAdsAccepted: value,
                      marketingAccepted: marketing,
                    ),
            title: const Text('맞춤형 광고 동의'),
            subtitle: const Text('끄더라도 기본 앱 기능과 기본 보상은 유지됩니다.'),
          ),
          SwitchListTile(
            value: marketing,
            onChanged: _saving
                ? null
                : (value) => _saveConsent(
                      personalizedAdsAccepted: personalized,
                      marketingAccepted: value,
                    ),
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

class SafetyModeSettingsScreen extends ConsumerStatefulWidget {
  const SafetyModeSettingsScreen({super.key});

  @override
  ConsumerState<SafetyModeSettingsScreen> createState() =>
      _SafetyModeSettingsScreenState();
}

class _SafetyModeSettingsScreenState
    extends ConsumerState<SafetyModeSettingsScreen> {
  var _confirmEnd = true;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final localState = ref.read(localStateServiceProvider);
    final confirmEnd =
        await localState.getBool('safety_confirm_end', fallback: true);
    if (!mounted) {
      return;
    }
    setState(() {
      _confirmEnd = confirmEnd;
      _loaded = true;
    });
  }

  Future<void> _setConfirmEnd(bool value) async {
    setState(() => _confirmEnd = value);
    await ref.read(localStateServiceProvider).setBool(
          'safety_confirm_end',
          value,
        );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '안전 모드 설정', showBack: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SafetyModePanel(),
          const SizedBox(height: AppSpacing.lg),
          if (!_loaded) ...[
            const LoadingSkeletonView(lines: 1),
            const SizedBox(height: AppSpacing.md),
          ],
          const _SwitchTile(
            title: '주행 중 알림 보류',
            subtitle: '주행 중 랭킹, 배틀, 마케팅 알림은 항상 보류됩니다.',
            value: true,
            onChanged: null,
          ),
          const _SwitchTile(
            title: '주행 중 광고 차단',
            subtitle: '광고는 주행 종료 후 선택 보상으로만 표시됩니다.',
            value: true,
            onChanged: null,
          ),
          const _SwitchTile(
            title: '자동 안전 모드',
            subtitle: '주행 시작 시 안전 모드 화면으로 바로 전환합니다.',
            value: true,
            onChanged: null,
          ),
          _SwitchTile(
            title: '종료 버튼 확인 단계',
            subtitle: '실수로 주행을 끝내지 않도록 종료 확인 단계를 유지합니다.',
            value: _confirmEnd,
            onChanged: _setConfirmEnd,
          ),
        ],
      ),
    );
  }
}

class VehicleManagementScreen extends ConsumerWidget {
  const VehicleManagementScreen({super.key});

  Future<void> _deleteVehicle(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('차량을 삭제할까요?'),
        content: Text(
          '${vehicle.displayName} 차량을 삭제하면 대표 차량과 리그 배정이 해제됩니다. '
          '새 차량을 설정하면 다시 리그에 참가할 수 있어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(vehicleRepositoryProvider).deleteVehicle(vehicle.id);
      await ref.read(localStateServiceProvider).remove(
            'recent_primary_vehicle_id',
          );
      ref
        ..invalidate(primaryVehicleProvider)
        ..invalidate(vehiclesProvider)
        ..invalidate(homeSnapshotProvider)
        ..invalidate(profileProvider);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('차량을 삭제했어요. 새 차량을 설정해 리그에 다시 참가하세요.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final message = const ErrorMapper().messageFor(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('차량을 삭제하지 못했어요. $message')),
      );
    }
  }

  Future<void> _setPrimaryVehicle(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    try {
      await ref.read(vehicleRepositoryProvider).setPrimaryVehicle(vehicle.id);
      await ref
          .read(localStateServiceProvider)
          .saveRecentPrimaryVehicle(vehicle.id);
      await ref.read(analyticsRepositoryProvider).track(
        'primary_vehicle_changed',
        properties: {
          'vehicle_id': vehicle.id,
          'fuel_league': vehicle.leagueKey,
          'vehicle_class': vehicle.vehicleClass,
        },
      );
      ref
        ..invalidate(primaryVehicleProvider)
        ..invalidate(vehiclesProvider)
        ..invalidate(homeSnapshotProvider)
        ..invalidate(profileProvider);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('대표 차량을 변경했어요. 리그가 다시 계산됩니다.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final message = const ErrorMapper().messageFor(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('대표 차량을 변경하지 못했어요. $message')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryVehicle = ref.watch(primaryVehicleProvider);
    final vehicles = ref.watch(vehiclesProvider);
    return AppScaffold(
      appBar: const FuelArenaAppBar(title: '차량 관리', showBack: true),
      child: primaryVehicle.when(
        loading: () => const LoadingSkeletonView(lines: 3),
        error: (error, stackTrace) =>
            const ErrorStateView(message: '차량 정보를 불러오지 못했어요.'),
        data: (primary) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (primary != null)
              VehicleCard(vehicle: primary)
            else
              EmptyStateView(
                title: '대표 차량이 없어요',
                message: '차량을 설정하면 연료 리그와 차급에 맞는 리그가 자동 배정됩니다.',
                actionLabel: '차량 설정하기',
                onAction: () => context.go('/setup/vehicle'),
              ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
                label: '차량 추가',
                icon: Icons.add_rounded,
                onPressed: () => context.go('/settings/vehicles/add')),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: '대표 차량 변경',
              icon: Icons.swap_horiz_rounded,
              onPressed: () => context.go('/setup/vehicle'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '내 리그 변경은 대표 차량 변경 시 자동 적용됩니다.',
              style: AppTypography.dataUnit
                  .copyWith(color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: '내 차량 목록'),
            vehicles.when(
              loading: () => const LoadingSkeletonView(lines: 2),
              error: (error, stackTrace) =>
                  const ErrorStateView(message: '차량 목록을 불러오지 못했어요.'),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyStateView(
                    title: '등록된 차량이 없어요',
                    message: '차량을 추가하면 대표 차량과 리그를 선택할 수 있습니다.',
                  );
                }
                return Column(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _VehicleManagementListCard(
                            vehicle: item,
                            isPrimary: primary?.id == item.id,
                            onSetPrimary: () =>
                                _setPrimaryVehicle(context, ref, item),
                            onDelete: () => _deleteVehicle(context, ref, item),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _VehicleManagementListCard extends StatelessWidget {
  const _VehicleManagementListCard({
    required this.vehicle,
    required this.isPrimary,
    required this.onSetPrimary,
    required this.onDelete,
  });

  final Vehicle vehicle;
  final bool isPrimary;
  final VoidCallback onSetPrimary;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (isPrimary)
                const StatusChip(
                  label: '대표 차량',
                  color: AppColors.neonGreen,
                  icon: Icons.star_rounded,
                ),
              StatusChip(
                label: vehicle.leagueDisplayName,
                color: AppColors.electricBlue,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(vehicle.displayName, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            vehicle.nickname.isEmpty ? vehicle.fuelType : vehicle.nickname,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: isPrimary ? null : onSetPrimary,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(isPrimary ? '대표 사용 중' : '대표 지정'),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('삭제'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  var _section = 'System Overview';

  static const _sections = [
    'System Overview',
    'Users',
    'Vehicles Catalog',
    'User Vehicles',
    'Drive Sessions',
    'Drive Scores',
    'Rankings',
    'Battles',
    'Seasons',
    'Missions',
    'Ads',
    'Sponsors',
    'Coupons',
    'Premium',
    'Fraud Reviews',
    'Reports',
    'Support Tickets',
    'Privacy Requests',
    'Consent Logs',
    'App Settings',
    'Admin Actions',
  ];

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final metrics = ref.watch(adminMetricsProvider);
    return profile.when(
      loading: () => const AppScaffold(
        maxWidth: null,
        appBar:
            FuelArenaAppBar(title: '관리자', subtitle: '운영 대시보드', showBack: true),
        child: LoadingSkeletonView(lines: 3),
      ),
      error: (error, stackTrace) => const AppScaffold(
        maxWidth: null,
        appBar:
            FuelArenaAppBar(title: '관리자', subtitle: '운영 대시보드', showBack: true),
        child: ErrorStateView(message: '관리자 권한을 확인하지 못했어요.'),
      ),
      data: (user) {
        if (!user.isAdmin) {
          return const AppScaffold(
            maxWidth: null,
            appBar: FuelArenaAppBar(
                title: '관리자', subtitle: '운영 대시보드', showBack: true),
            child: ErrorStateView(message: '관리자만 접근할 수 있는 화면입니다.'),
          );
        }
        return AdminScaffold(
          title: '관리자',
          subtitle: '운영 대시보드',
          sections: _sections,
          selectedSection: _section,
          onSectionChanged: (value) => setState(() => _section = value),
          child: metrics.when(
            loading: () => const LoadingSkeletonView(lines: 6),
            error: (error, stackTrace) =>
                const ErrorStateView(message: '관리자 지표를 불러오지 못했어요.'),
            data: (items) => _AdminContent(section: _section, metrics: items),
          ),
        );
      },
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
    this.secondaryLabel,
    this.onSecondary,
    this.sections = const [],
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
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
                      Text(title,
                          style: AppTypography.titleLarge
                              .copyWith(color: AppColors.neonGreen)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(subtitle,
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.onSurfaceMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...sections.map((section) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _InfoSectionCard(section: section))),
          if (primaryLabel != null) ...[
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
                label: primaryLabel!,
                icon: Icons.arrow_forward_rounded,
                onPressed: onPrimary),
          ],
          if (secondaryLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(label: secondaryLabel!, onPressed: onSecondary),
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
        error: (error, stackTrace) =>
            const ErrorStateView(message: '미션을 불러오지 못했어요.'),
        data: (items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('오늘 놓치면\n아쉬운 미션',
                style: AppTypography.displayScore
                    .copyWith(color: AppColors.neonGreen)),
            const SizedBox(height: AppSpacing.lg),
            ...items.map((mission) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: MissionCard(mission: mission))),
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
    this.detailRoute,
  });

  final String title;
  final bool requiredConsent;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? detailRoute;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: CheckboxListTile(
                value: value,
                onChanged: (next) => onChanged(next ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(title, style: AppTypography.titleMedium),
                subtitle: Text(
                  requiredConsent ? '필수' : '선택',
                  style: AppTypography.dataUnit,
                ),
                activeColor: AppColors.neonGreen,
              ),
            ),
            if (detailRoute != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => context.push(detailRoute!),
                  icon: const Icon(Icons.article_rounded),
                  label: const Text('내용 보기'),
                ),
              ),
          ],
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
                  Text(description,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.onSurfaceMuted)),
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
                selectedColor: AppColors.neonGreen.withValues(alpha: 0.18),
                backgroundColor: AppColors.surfaceLow,
                side: BorderSide(
                    color: active
                        ? AppColors.neonGreen
                        : Colors.white.withValues(alpha: 0.1)),
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
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.neonGreen, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: Text(item, style: AppTypography.bodyMedium)),
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
      borderColor: badge.rarity == 'Gold'
          ? AppColors.gold.withValues(alpha: 0.35)
          : AppColors.electricBlue.withValues(alpha: 0.22),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: AppColors.gold, size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge.name, style: AppTypography.titleMedium),
                Text(badge.description,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.onSurfaceMuted)),
              ],
            ),
          ),
          StatusChip(
              label: badge.rarity,
              color: badge.rarity == 'Gold'
                  ? AppColors.gold
                  : AppColors.electricBlue),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Material(
          type: MaterialType.transparency,
          child: SwitchListTile(
            value: value,
            onChanged: onChanged,
            title: Text(title, style: AppTypography.titleMedium),
            subtitle: subtitle == null
                ? null
                : Text(
                    subtitle!,
                    style: AppTypography.dataUnit
                        .copyWith(color: AppColors.onSurfaceMuted),
                  ),
            activeThumbColor: AppColors.neonGreen,
          ),
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
          Text(section.body,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.onSurfaceMuted)),
        ],
      ),
    );
  }
}

class _CrewMemberCard extends StatelessWidget {
  const _CrewMemberCard({required this.member});

  final CrewMember member;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.neonGreen.withValues(alpha: 0.16),
            foregroundColor: AppColors.neonGreen,
            child: Text(
              member.nickname.isEmpty ? '?' : member.nickname.substring(0, 1),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.nickname, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text('${formatNumber(member.weeklyContribution)}점 기여',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.onSurfaceMuted)),
              ],
            ),
          ),
          StatusChip(label: _crewRoleLabel(member.role), color: AppColors.gold),
        ],
      ),
    );
  }
}

String _crewRoleLabel(String role) {
  return switch (role) {
    'owner' => '리더',
    'admin' => '운영',
    _ => '멤버',
  };
}

class _AdminContent extends ConsumerStatefulWidget {
  const _AdminContent({
    required this.section,
    required this.metrics,
  });

  final String section;
  final List<AdminMetric> metrics;

  @override
  ConsumerState<_AdminContent> createState() => _AdminContentState();
}

class _AdminContentState extends ConsumerState<_AdminContent> {
  var _query = '';
  var _filter = '전체';
  var _page = 0;

  @override
  void didUpdateWidget(covariant _AdminContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      _page = 0;
      _query = '';
      _filter = '전체';
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _adminSubtitle(widget.section);
    final recordQuery = AdminRecordQuery(
      section: widget.section,
      search: _query,
      status: _filter,
      page: _page,
      pageSize: 10,
    );
    final records = ref.watch(adminRecordPageProvider(recordQuery));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminTopBar(
          title: adminSectionLabel(widget.section),
          subtitle: subtitle,
          trailing: AdminActionMenu(
            actions: _adminActionsFor(widget.section),
            onSelected: (action) {
              final items =
                  records.asData?.value.items ?? const <AdminRecord>[];
              _handleAdminAction(action, items.isEmpty ? null : items.first);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: widget.metrics
              .map(
                (metric) => SizedBox(
                  width: 220,
                  child: AdminMetricCard(
                    label: metric.label,
                    value: metric.value,
                    unit: metric.unit,
                    healthy: metric.healthy,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AdminFilterBar(
          searchHint: '${adminSectionLabel(widget.section)} 검색',
          filters: _adminFiltersFor(widget.section),
          selectedFilter: _filter,
          onFilterChanged: (value) => setState(() {
            _filter = value;
            _page = 0;
          }),
          onSearchChanged: (value) => setState(() {
            _query = value.trim();
            _page = 0;
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        AdminChartCard(
          title: '${adminSectionLabel(widget.section)} 상태 추이',
          values: _adminChartValues(widget.section),
        ),
        const SizedBox(height: AppSpacing.lg),
        records.when(
          loading: () => const LoadingSkeletonView(lines: 5),
          error: (error, stackTrace) =>
              const ErrorStateView(message: '운영 목록을 불러오지 못했어요.'),
          data: (page) {
            final rows = page.items
                .map(
                  (record) => [
                    Text(record.id),
                    Text(record.title),
                    AdminStatusBadge(status: record.status),
                    Text(record.owner),
                    AdminActionMenu(
                      actions: _adminActionsFor(widget.section),
                      onSelected: (action) =>
                          _handleAdminAction(action, record),
                    ),
                  ],
                )
                .toList();
            return Column(
              children: [
                AdminDataTable(
                  columns: const ['ID', '항목', '상태', '담당', '액션'],
                  rows: rows,
                  emptyMessage: '검색 조건에 맞는 운영 데이터가 없어요.',
                  onRowTap: (index) =>
                      _showAdminRecordDetail(page.items[index]),
                ),
                const SizedBox(height: AppSpacing.sm),
                AdminPaginationBar(
                  page: page.page,
                  totalPages: page.totalPages,
                  totalCount: page.totalCount,
                  onPrevious: page.hasPrevious
                      ? () => setState(() => _page -= 1)
                      : null,
                  onNext:
                      page.hasNext ? () => setState(() => _page += 1) : null,
                ),
              ],
            );
          },
        ),
        if (widget.section == 'Vehicles Catalog') ...[
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: '차량 카탈로그 운영 화면 열기',
            icon: Icons.directions_car_rounded,
            onPressed: () => context.go('/admin/vehicles'),
          ),
        ],
      ],
    );
  }

  Future<void> _handleAdminAction(String action, AdminRecord? record) async {
    if (record != null && action.contains('상세')) {
      _showAdminRecordDetail(record);
      return;
    }
    if (record != null &&
        widget.section == 'Support Tickets' &&
        action == '답변 보내기') {
      await _showSupportReplyDialog(record);
      return;
    }
    if (record != null &&
        widget.section == 'Support Tickets' &&
        action == '처리 완료') {
      await ref
          .read(supportRepositoryProvider)
          .updateTicketStatus(record.id, 'resolved');
      final log = await ref.read(adminRepositoryProvider).recordAction(
            AdminActionRequest(
              section: widget.section,
              action: action,
              record: record,
            ),
          );
      ref.invalidate(adminRecordPageProvider(_currentRecordQuery()));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${log.action} 작업을 완료했어요.')),
      );
      return;
    }
    if (record != null && widget.section == 'Reports' && action == '검토 완료') {
      await ref
          .read(reportRepositoryProvider)
          .updateReportStatus(record.id, 'resolved');
      final log = await ref.read(adminRepositoryProvider).recordAction(
            AdminActionRequest(
              section: widget.section,
              action: action,
              record: record,
            ),
          );
      ref.invalidate(adminRecordPageProvider(_currentRecordQuery()));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${log.action} 작업을 완료했어요.')),
      );
      return;
    }
    if (record != null &&
        widget.section == 'Privacy Requests' &&
        (action == '검토 시작' || action == '완료 처리' || action == '보류 처리')) {
      final nextStatus = switch (action) {
        '검토 시작' => 'review',
        '보류 처리' => 'rejected',
        _ => 'completed',
      };
      await ref
          .read(privacyRequestRepositoryProvider)
          .updateRequestStatus(record.id, nextStatus);
      final log = await ref.read(adminRepositoryProvider).recordAction(
            AdminActionRequest(
              section: widget.section,
              action: action,
              record: record,
            ),
          );
      ref.invalidate(adminRecordPageProvider(_currentRecordQuery()));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${log.action} 작업을 완료했어요.')),
      );
      return;
    }
    final log = await ref.read(adminRepositoryProvider).recordAction(
          AdminActionRequest(
            section: widget.section,
            action: action,
            record: record,
          ),
        );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${log.action} 작업을 운영 로그에 기록했어요.')),
    );
  }

  AdminRecordQuery _currentRecordQuery() {
    return AdminRecordQuery(
      section: widget.section,
      search: _query,
      status: _filter,
      page: _page,
      pageSize: 10,
    );
  }

  Future<void> _showSupportReplyDialog(AdminRecord record) async {
    final controller = TextEditingController();
    String? validationMessage;
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('문의 답변 보내기'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.title, style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: controller,
                    minLines: 4,
                    maxLines: 7,
                    maxLength: 600,
                    decoration: InputDecoration(
                      labelText: '운영자 답변',
                      errorText: validationMessage,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('취소'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final text = controller.text.trim();
                    final error = InputValidators.supportBody(text);
                    if (error != null) {
                      setDialogState(() => validationMessage = error);
                      return;
                    }
                    Navigator.of(dialogContext).pop(text);
                  },
                  icon: const Icon(Icons.reply_rounded),
                  label: const Text('답변 보내기'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    if (message == null || message.isEmpty) {
      return;
    }
    await ref.read(supportRepositoryProvider).addMessage(
          record.id,
          message,
          isAdminReply: true,
        );
    await ref
        .read(supportRepositoryProvider)
        .updateTicketStatus(record.id, 'review');
    final log = await ref.read(adminRepositoryProvider).recordAction(
          AdminActionRequest(
            section: widget.section,
            action: '답변 보내기',
            record: record,
          ),
        );
    ref.invalidate(adminRecordPageProvider(_currentRecordQuery()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${log.action} 작업을 완료했어요.')),
    );
  }

  void _showAdminRecordDetail(AdminRecord record) {
    AdminRecordDetailDrawer.show(
      context,
      section: adminSectionLabel(widget.section),
      record: record,
    );
  }
}

String _adminSubtitle(String section) {
  return switch (section) {
    'System Overview' => '사용자, 주행, 보상, 부정 기록을 한 화면에서 추적합니다.',
    'Vehicles Catalog' => '제조사, 모델, 연식, 파워트레인, 연료 리그와 검증 상태를 관리합니다.',
    'Drive Sessions' || 'Drive Scores' => '검증된 주행만 공식 랭킹에 반영되도록 관리합니다.',
    'Reports' || 'Support Tickets' => '신고와 문의를 상태별로 분류하고 처리합니다.',
    'Privacy Requests' => '데이터 다운로드, 삭제, 계정 삭제, 동의 철회 요청을 상태별로 처리합니다.',
    'App Settings' => '광고 한도, 시즌 기준, 공식 주행 기준을 원격 설정으로 조정합니다.',
    'Admin Actions' => '관리자 액션 요청과 대상 레코드를 감사 로그로 추적합니다.',
    _ => '${adminSectionLabel(section)} 운영 데이터를 검색, 필터, 상태 변경할 수 있습니다.',
  };
}

Map<String, double> _adminChartValues(String section) {
  if (section.contains('Drive')) {
    return const {'verified': 84, 'pending': 12, 'rejected': 4};
  }
  if (section.contains('Privacy')) {
    return const {'open': 18, 'review': 9, 'completed': 42, 'rejected': 3};
  }
  if (section.contains('Report') || section.contains('Support')) {
    return const {'open': 18, 'review': 9, 'resolved': 42};
  }
  if (section.contains('Ad') || section.contains('Premium')) {
    return const {'view': 72, 'claim': 38, 'purchase': 7};
  }
  return const {'active': 64, 'pending': 22, 'blocked': 6};
}

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) {
      return item;
    }
  }
  return null;
}

List<String> _adminActionsFor(String section) {
  if (section.contains('Vehicle')) {
    return const ['상세 보기', '검증 승인', '비활성화'];
  }
  if (section.contains('Support')) {
    return const ['상세 보기', '답변 보내기', '처리 완료'];
  }
  if (section.contains('Privacy')) {
    return const ['상세 보기', '검토 시작', '완료 처리', '보류 처리'];
  }
  if (section.contains('Fraud') || section.contains('Report')) {
    return const ['상세 보기', '검토 완료', '사용자 알림'];
  }
  if (section.contains('App Settings')) {
    return const ['설정 수정', '변경 로그 보기'];
  }
  return const ['상세 보기', '상태 변경', '내보내기'];
}

List<String> _adminFiltersFor(String section) {
  if (section.contains('Privacy')) {
    return const ['전체', 'open', 'review', 'completed', 'rejected'];
  }
  if (section.contains('Support') || section.contains('Report')) {
    return const ['전체', 'open', 'review', 'resolved', 'rejected'];
  }
  return const ['전체', 'active', 'pending', 'review', 'blocked'];
}
