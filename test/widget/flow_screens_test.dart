import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_arena/features/onboarding/presentation/onboarding_screen.dart';
import 'package:fuel_arena/features/vehicle/presentation/vehicle_register_screen.dart';
import 'package:fuel_arena/features/home/presentation/home_screen.dart';
import 'package:fuel_arena/features/drive/presentation/drive_result_screen.dart';
import 'package:fuel_arena/features/ranking/presentation/ranking_screen.dart';
import 'package:fuel_arena/features/battle/presentation/battle_screen.dart';
import 'package:fuel_arena/features/season/presentation/season_screen.dart';
import 'package:fuel_arena/features/premium/presentation/premium_screen.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: child,
    ),
  );
}

void main() {
  testWidgets('Onboarding CTA 렌더링', (tester) async {
    await tester.pumpWidget(_wrap(const OnboardingScreen()));
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('VehicleRegister form 렌더링', (tester) async {
    await tester.pumpWidget(_wrap(const VehicleRegisterScreen()));
    expect(find.text('차량 등록 완료'), findsOneWidget);
    expect(find.text('연료 타입'), findsOneWidget);
  });

  testWidgets('HomeScreen mock data 렌더링', (tester) async {
    await tester.pumpWidget(_wrap(const HomeScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('ApexDriver'), findsWidgets);
  });

  testWidgets('DriveResultScreen score display 렌더링', (tester) async {
    await tester.pumpWidget(_wrap(const DriveResultScreen()));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('랭킹 확인'), findsOneWidget);
  });

  testWidgets('RankingScreen list 렌더링', (tester) async {
    await tester.pumpWidget(_wrap(const RankingScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('랭킹'), findsOneWidget);
    expect(find.textContaining('EcoBlade'), findsWidgets);
  });

  testWidgets('BattleScreen list 렌더링', (tester) async {
    await tester.pumpWidget(_wrap(const BattleScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('새 배틀 만들기'), findsOneWidget);
  });

  testWidgets('SeasonScreen mission display 렌더링', (tester) async {
    await tester.pumpWidget(_wrap(const SeasonScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('시즌패스 보상 트랙'), findsOneWidget);
  });

  testWidgets('PremiumScreen benefit display 렌더링', (tester) async {
    await tester.pumpWidget(_wrap(const PremiumScreen()));
    await tester.pump();
    expect(find.text('프리미엄 시작하기'), findsOneWidget);
  });
}

