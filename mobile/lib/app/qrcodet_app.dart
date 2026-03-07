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
        ChangeNotifierProvider<AppStore>(
          create: (_) => AppStore()..initialize(),
        ),
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
    if (vm.loading) {
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
                  child: AppHeader(
                    theme: vm.appTheme,
                    runtimeMessage: vm.runtimeMessage,
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: vm.tabIndex,
                    children: <Widget>[
                      const _CreateTabSlot(),
                      _ScanTabSlot(isActiveTab: vm.tabIndex == 1),
                      const _GalleryTabSlot(),
                      const _SettingsTabSlot(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: vm.tabIndex,
          onDestinationSelected: vm.setTabIndex,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.auto_awesome),
              label: 'Create',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner),
              label: 'Scan',
            ),
            NavigationDestination(
              icon: Icon(Icons.photo_library_outlined),
              label: 'Gallery',
            ),
            NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

class _CreateTabSlot extends StatelessWidget {
  const _CreateTabSlot();

  @override
  Widget build(BuildContext context) {
    return Consumer<CreateProvider>(
      builder: (context, vm, child) => CreateTabView(vm: vm),
    );
  }
}

class _ScanTabSlot extends StatelessWidget {
  const _ScanTabSlot({required this.isActiveTab});

  final bool isActiveTab;

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, vm, child) => ScanTabView(
        isActiveTab: isActiveTab,
        controllerBuilder: vm.buildScannerController,
        onDetect: vm.handleScan,
        onAnalyzeImage: vm.analyzeImageFromGallery,
        hapticsEnabled: vm.hapticsEnabled,
        insight: vm.scanInsight,
        history: vm.history,
        dateFormat: vm.dateFormat,
        onRestoreHistory: vm.restoreHistory,
      ),
    );
  }
}

class _GalleryTabSlot extends StatelessWidget {
  const _GalleryTabSlot();

  @override
  Widget build(BuildContext context) {
    return Consumer<GalleryProvider>(
      builder: (context, vm, child) => GalleryTabView(vm: vm),
    );
  }
}

class _SettingsTabSlot extends StatelessWidget {
  const _SettingsTabSlot();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, vm, child) => SettingsTabView(vm: vm),
    );
  }
}
