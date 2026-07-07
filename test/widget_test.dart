import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:on_the_go/main.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('boots to Google sign-in', (tester) async {
    await tester.pumpWidget(const OnTheGoApp());
    await tester.pumpAndSettle();

    expect(find.text('On the Go'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
