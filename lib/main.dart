import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'services/billing_service.dart';
import 'screens/calendar_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/next_shift_widget.dart';
import 'widgets/promo_countdown_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  Intl.defaultLocale = 'ru';

  final app = AppProvider();
  final billing = BillingService();
  await app.init();
  await billing.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: app),
        ChangeNotifierProvider.value(value: billing),
      ],
      child: const KalendarApp(),
    ),
  );
}

class KalendarApp extends StatelessWidget {
  const KalendarApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return MaterialApp(
      title: 'График Смен 2х2',
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF455A64),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
          titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF607D8B),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: const Color(0xFF37474F),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return const IconThemeData(color: Colors.white);
            return const IconThemeData(color: Colors.grey);
          }),
        ),
      ),
      themeMode: app.themeMode,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;
  final _pageCtrl = PageController();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageCtrl,
          onPageChanged: (i) => setState(() => _tab = i),
          children: const [
            CalendarScreen(),
            AnalyticsScreen(),
            SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.08),
            blurRadius: 10, offset: const Offset(0, -2),
          )],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PromoCountdownWidget(),
            NextShiftWidget(shifts: app.shifts),
            NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) {
                setState(() => _tab = i);
                _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              },
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Theme.of(context).colorScheme.surface,
              elevation: 0,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'График'),
                NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Аналитика'),
                NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Настройки'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
