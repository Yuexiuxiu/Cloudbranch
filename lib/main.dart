import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/platform_config.dart';
import 'providers/app_state.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';
import 'pages/windows_home_page.dart';
import 'services/log_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (PlatformConfig.isAndroid) {
    // [Android Liquid Glass] 沉浸式布局：透明状态栏/导航栏，内容延伸到刘海区
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  final appState = AppState();
  await appState.initialize();

  // 根据设置初始化日志
  if (appState.settings.enableLogging) {
    await LogService.enableLogging();
  }

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(CloudbranchApp(appState: appState, themeProvider: themeProvider));
}

class CloudbranchApp extends StatelessWidget {
  final AppState appState;
  final ThemeProvider themeProvider;

  const CloudbranchApp({super.key, required this.appState, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: ChangeNotifierProvider.value(
        value: themeProvider,
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            // [Android Liquid Glass] 动态更新系统栏样式，适配主题切换
            if (PlatformConfig.isAndroid) {
              final isDark = themeProvider.isDark;
              SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                systemNavigationBarDividerColor: Colors.transparent,
              ));
            }
            return MaterialApp(
              title: '云栖枝',
              debugShowCheckedModeBanner: false,
              themeMode: themeProvider.themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              home: PlatformConfig.isAndroid
                  ? const HomePage()
                  : const WindowsHomePage(),
            );
          },
        ),
      ),
    );
  }
}