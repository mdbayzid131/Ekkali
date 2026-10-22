import 'dart:async';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/services/auth_service.dart';
import 'package:moeb_26/core/services/socket_service.dart';
import 'package:moeb_26/modules/auth/authentication/controllers/signin_controller.dart';
import 'package:moeb_26/modules/auth/authentication/views/signin_view.dart';
import 'package:moeb_26/modules/auth/authentication/views/reset_password_view.dart';
import 'package:moeb_26/modules/auth/authentication/controllers/forget_password_controller.dart';
import 'package:moeb_26/modules/auth/authentication/views/application_not_Approved_view.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class NavigationAuth extends AuthService {
  Completer<dio.Response>? pendingLogin;
  Completer<void>? pendingCleanup;
  Completer<dio.Response>? pendingForgot;
  // No network/storage startup for this fake.
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<dio.Response> login({
    required String email,
    required String password,
  }) => pendingLogin!.future;

  @override
  Future<void> clearLocalAuth() async {
    await pendingCleanup?.future;
  }

  @override
  Future<dio.Response> forgotPassword(String email) => pendingForgot!.future;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    Get.put<AuthService>(NavigationAuth());
  });
  tearDown(() => Get.reset());

  testWidgets(
    'forgot password link and back return to the existing sign in form repeatedly',
    (tester) async {
      tester.view.physicalSize = const Size(376, 856);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(376, 856),
          builder: (_, child) => GetMaterialApp(
            initialRoute: Routes.signinView,
            getPages: [
              GetPage(name: Routes.signinView, page: () => const SignInView()),
              GetPage(
                name: Routes.resetPasswordView,
                page: () => const ResetPasswordView(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final original = tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller;
      for (var i = 0; i < 4; i++) {
        await tester.ensureVisible(find.text('Forgot Password?'));
        await tester.tap(find.text('Forgot Password?'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField),
          'forgot$i@example.com',
        );
        if (i.isEven) {
          await tester.ensureVisible(find.text('Sign In'));
          await tester.tap(find.text('Sign In'));
        } else {
          await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
        }
        await tester.pumpAndSettle();
        expect(Get.currentRoute, Routes.signinView);
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).first)
              .controller,
          same(original),
        );
        await tester.enterText(
          find.byType(TextFormField).first,
          'login$i@example.com',
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('forgot password ignores an OTP response after its form closes', (
    tester,
  ) async {
    final auth = Get.find<AuthService>() as NavigationAuth;
    auth.pendingForgot = Completer<dio.Response>();
    final controller = ForgotPasswordController();
    controller.onStart();
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Form(key: controller.formKey, child: const SizedBox()),
        ),
      ),
    );
    controller.emailController.text = 'forgot@example.com';
    final request = controller.forgotPassword();
    controller.onDelete();
    auth.pendingForgot!.complete(
      dio.Response(
        requestOptions: dio.RequestOptions(path: '/forgot'),
        statusCode: 200,
        data: {'message': 'OTP sent'},
      ),
    );
    await request;
    await tester.pumpAndSettle();
    expect(Get.currentRoute, '/');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'overlapping sign in routes have independent live form controllers',
    (tester) async {
      tester.view.physicalSize = const Size(376, 856);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(376, 856),
          builder: (_, child) => GetMaterialApp(
            initialRoute: '/login',
            getPages: [
              GetPage(name: '/login', page: () => const SignInView()),
              GetPage(
                name: '/create',
                page: () => const Scaffold(body: Text('Create account')),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final original = tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!;
      for (var i = 0; i < 3; i++) {
        Get.toNamed('/create');
        await tester.pumpAndSettle();
        Get.back();
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'user$i@example.com',
        );
        expect(original.text, 'user$i@example.com');
        expect(tester.takeException(), isNull);
      }
      Get.to(() => const SignInView(), preventDuplicates: false);
      await tester.pumpAndSettle();
      final second = tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!;
      expect(identical(original, second), isFalse);
      Get.back();
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'still-live@example.com',
      );
      expect(original.text, 'still-live@example.com');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('disposed login ignores a late rejected response', (
    tester,
  ) async {
    final auth = Get.find<AuthService>() as NavigationAuth;
    auth.pendingLogin = Completer<dio.Response>();
    final controller = SigninController();
    controller.onStart();
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Form(key: controller.formKey, child: const SizedBox()),
        ),
      ),
    );
    await tester.pump();
    controller.emailController.text = 'user@example.com';
    controller.passwordController.text = 'password';
    final login = controller.login();
    controller.onDelete();
    auth.pendingLogin!.complete(
      dio.Response(
        requestOptions: dio.RequestOptions(path: '/login'),
        statusCode: 200,
        data: {
          'data': {'appState': 'REJECTED'},
        },
      ),
    );
    await login;
    await tester.pumpAndSettle();
    expect(controller.isClosed, isTrue);
    expect(Get.currentRoute, '/');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'return from rejection waits for auth cleanup before opening login',
    (tester) async {
      tester.view.physicalSize = const Size(376, 856);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = Get.find<AuthService>() as NavigationAuth;
      auth.pendingCleanup = Completer<void>();
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(376, 856),
          builder: (_, child) => GetMaterialApp(
            initialRoute: '/rejected',
            getPages: [
              GetPage(
                name: '/rejected',
                page: () => ApplicationNotApprovedView(),
              ),
              GetPage(name: Routes.signinView, page: () => const SignInView()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Back to Sign In'));
      await tester.tap(find.text('Back to Sign In'));
      await tester.pump();
      expect(Get.currentRoute, '/rejected');
      auth.pendingCleanup!.complete();
      await tester.pumpAndSettle();
      expect(Get.currentRoute, Routes.signinView);
      await tester.enterText(
        find.byType(TextFormField).first,
        'retry@example.com',
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'socket disconnect clears reconnect and previous account room state',
    () {
      final service = SocketService();
      service.socket = io.io('http://localhost', <String, dynamic>{
        'autoConnect': false,
        'forceNew': true,
      });
      service.isSocketInitialized = true;
      service.isConnected.value = true;
      service.activeChatId = 'old-chat';
      service.currentCommunityArea = 'old-area';
      service.isCommunityActive = true;
      service.disconnect();
      expect(service.isSocketInitialized, isFalse);
      expect(service.isConnected.value, isFalse);
      expect(service.activeChatId, isNull);
      expect(service.currentCommunityArea, isNull);
      expect(service.isCommunityActive, isFalse);
    },
  );
}
