import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_typography.dart';
import '../../../shared/widgets/widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  var _index = 0;

  static const _pages = [
    _OnboardingPageData(
      title: '연비를 관리하지 말고\n경쟁하세요',
      body: '매일의 주행을 점수와 순위로 바꿔보세요. 좋은 운전이 승리로 이어집니다.',
      icon: Icons.speed_rounded,
    ),
    _OnboardingPageData(
      title: '친구뿐 아니라\n모든 운전자와 겨루세요',
      body: '동급 차량, 지역, 연료 타입별 리더보드에서 라이벌을 추월하세요.',
      icon: Icons.sports_mma_rounded,
    ),
    _OnboardingPageData(
      title: '주행할수록 티어와\n보상이 쌓입니다',
      body: '시즌 미션과 배틀패스로 승급하고 한정 보상을 획득하세요.',
      icon: Icons.emoji_events_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _pages.length - 1) {
      context.go('/auth/login');
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/auth/login'),
              child: const Text('Skip'),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) => _OnboardingPage(data: _pages[index]),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (index) {
              final selected = index == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: selected ? 32 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: selected ? AppColors.neonGreen : AppColors.surfaceHighest,
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: _index == _pages.length - 1 ? '시작하기' : 'Next',
            icon: Icons.arrow_forward_rounded,
            onPressed: _next,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppCard(
          glowColor: AppColors.neonGreen,
          child: SizedBox(
            height: 260,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonGreen.withOpacity(0.08),
                      border: Border.all(color: AppColors.neonGreen.withOpacity(0.22)),
                    ),
                  ),
                  Icon(data.icon, size: 82, color: AppColors.neonGreen),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: AppTypography.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          data.body,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceMuted),
        ),
      ],
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}
