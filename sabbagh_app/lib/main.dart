import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/config/app_config.dart';
import 'package:sabbagh_app/core/constants/app_routes.dart';
import 'package:sabbagh_app/core/constants/app_strings.dart';
import 'package:sabbagh_app/core/constants/app_themes.dart';
import 'package:sabbagh_app/core/services/dio_client.dart';
import 'package:sabbagh_app/core/services/storage_service.dart';
import 'package:sabbagh_app/core/services/fcm_service.dart';
import 'package:sabbagh_app/firebase_options.dart';
import 'package:sabbagh_app/localization/localization_service.dart';
import 'package:sabbagh_app/localization/app_translations.dart';
import 'package:sabbagh_app/presentation/bindings/initial_binding.dart';
import 'package:window_manager/window_manager.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await startBackgroundInitializations();

  // Configure window for desktop
  if (GetPlatform.isDesktop) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: AppStrings.appName,
      minimumSize: Size(800, 600),
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Ensure InitialBinding registers FCMService, then initialize FCM
  InitialBinding().dependencies();
  await Get.find<FCMService>().initialize();

  runApp(const SabbaghApp());
}

Future<void> startBackgroundInitializations() async {
  // Storage and localization can be initialized asynchronously but not awaited here
  final storageService = StorageService();
  await storageService.init();
  Get.put(storageService, permanent: true);

  final localizationService = LocalizationService();
  await localizationService.init();
  Get.put(localizationService, permanent: true);
  Get.put(DioClient(), permanent: true);

  // Initialize critical services lazily or on-demand
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class SabbaghApp extends StatelessWidget {
  const SabbaghApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationService = Get.find<LocalizationService>();

    return Obx(
      () => GetMaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppThemes.lightTheme,
        themeMode: ThemeMode.light,
        locale: Locale(localizationService.currentLanguage.value),
        fallbackLocale: const Locale('en'),
        translations: AppTranslations(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales:
            AppConfig.supportedLanguages.map((lang) => Locale(lang)).toList(),
        initialBinding: InitialBinding(),
        initialRoute: AppRoutes.splash,
        getPages: AppPages.pages,
        defaultTransition: Transition.fade,
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}