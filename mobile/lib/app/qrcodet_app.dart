import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'modules/create/views/create_tab_view.dart';
import 'modules/gallery/views/gallery_tab_view.dart';
import 'modules/scan/views/scan_tab_view.dart';
import 'modules/settings/views/settings_tab_view.dart';
import 'providers/app_store.dart';
import 'providers/qrcodet_provider.dart';
import 'views/widgets/app_widgets.dart';

class QRCodetApp extends StatelessWidget {
  const QRCodetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStore>(create: (_) => AppStore()..initialize()),
        ChangeNotifierProxyProvider<AppStore, ShellProvider>(
          create: (_) => ShellProvider(),
          update: (_, store, provider) => provider!..attach(store),
        ),
        ChangeNotifierProxyProvider<AppStore, CreateProvider>(
          create: (_) => CreateProvider(),
          update: (_, store, provider) => provider!..attach(store),
        ),
        ChangeNotifierProxyProvider<AppStore, ScanProvider>(
          create: (_) => ScanProvider(),
          update: (_, store, provider) => provider!..attach(store),
        ),
        ChangeNotifierProxyProvider<AppStore, GalleryProvider>(
          create: (_) => GalleryProvider(),
          update: (_, store, provider) => provider!..attach(store),
        ),
        ChangeNotifierProxyProvider<AppStore, SettingsProvider>(
          create: (_) => SettingsProvider(),
          update: (_, store, provider) => provider!..attach(store),
        ),
      ],
      child: const _QRCodetRootView(),
    );
  }
}

class _QRCodetRootView extends StatelessWidget {
  const _QRCodetRootView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShellProvider>();
    if (vm.ui.loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'QRCodet',
        navigatorKey: vm.navigatorKey,
        scaffoldMessengerKey: vm.scaffoldMessengerKey,
        theme: ThemeData.dark(useMaterial3: true),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QRCodet',
      navigatorKey: vm.navigatorKey,
      scaffoldMessengerKey: vm.scaffoldMessengerKey,
      theme: vm.materialTheme,
      home: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                vm.appTheme.accent.withValues(alpha: 0.18),
                vm.materialTheme.scaffoldBackgroundColor,
                vm.appTheme.dark.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                  child: AppHeader(theme: vm.appTheme, runtimeMessage: vm.ui.runtimeMessage),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildCurrentTab(context, vm),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: vm.ui.tabIndex,
          onDestinationSelected: vm.setTabIndex,
          destinations: const <NavigationDestination>[
            NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Create'),
            NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
            NavigationDestination(icon: Icon(Icons.photo_library_outlined), label: 'Gallery'),
            NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab(BuildContext context, ShellProvider vm) {
    switch (vm.ui.tabIndex) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey<String>('tab-create'),
          child: CreateTabView(vm: context.watch<CreateProvider>()),
        );
      case 1:
        final scanVm = context.watch<ScanProvider>();
        return KeyedSubtree(
          key: const ValueKey<String>('tab-scan'),
          child: ScanTabView(
            controllerBuilder: scanVm.buildScannerController,
            onDetect: scanVm.handleScan,
            onAnalyzeImage: scanVm.analyzeImageFromGallery,
            hapticsEnabled: scanVm.hapticsEnabled,
            insight: scanVm.scanInsight,
            history: scanVm.history,
            dateFormat: scanVm.dateFormat,
            onRestoreHistory: scanVm.restoreHistory,
          ),
        );
      case 2:
        return KeyedSubtree(
          key: const ValueKey<String>('tab-gallery'),
          child: GalleryTabView(vm: context.watch<GalleryProvider>()),
        );
      default:
        return KeyedSubtree(
          key: const ValueKey<String>('tab-settings'),
          child: SettingsTabView(vm: context.watch<SettingsProvider>()),
        );
    }
  }
}
