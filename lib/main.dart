/// 记账本 · 本地记账 App
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/app_state.dart';
import 'pages/add_transaction_page.dart';
import 'pages/home_page.dart';
import 'pages/ledger_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/profile_page.dart';
import 'pages/stats_page.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  unawaited(NotificationService.instance.init());
  runApp(MoneyApp(state: state));
}

class MoneyApp extends StatelessWidget {
  const MoneyApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        title: '记账本',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: state.onboarded ? const HomeShell() : const OnboardingPage(),
      ),
    );
  }
}

/// 一级页面外壳：四个页面 + 固定底部导航
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (int i = 0; i < 4; i++)
            ExcludeSemantics(
              // 只暴露当前页的语义，避免 offstage 页面干扰读屏
              excluding: i != _index,
              child: switch (i) {
                0 => HomePage(
                      onAdd: _openAdd,
                      onGoLedger: () => setState(() => _index = 1),
                      onGoStats: () => setState(() => _index = 2),
                      onGoProfile: () => setState(() => _index = 3),
                    ),
                1 => const LedgerPage(),
                2 => const StatsPage(),
                _ => const ProfilePage(),
              },
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onSelect: (i) => setState(() => _index = i),
      ),
    );
  }

  Future<void> _openAdd() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddTransactionPage()),
    );
  }
}

