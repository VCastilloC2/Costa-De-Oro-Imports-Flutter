import 'package:costa_de_oro_imports/features/dashboard/presentation/widgets/statistics/statistics_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('statistics skeleton lays out with the shared shimmer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatisticsSkeleton(s: 1))),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });
}
