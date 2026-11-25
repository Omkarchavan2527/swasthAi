import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'screens/landing/landing_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/shell/main_shell_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/family/family_screen.dart';
import 'screens/family/family_member_detail_screen.dart';
import 'screens/medical_records/medical_records_screen.dart';
import 'screens/medicines/medicines_screen.dart';
import 'screens/assistant/assistant_screen.dart';
import 'screens/health_trends/health_trends_screen.dart';
import 'screens/vaccinations/vaccinations_screen.dart';
import 'screens/blood_donors/blood_donors_screen.dart';
import 'screens/hospitals/hospitals_screen.dart';
import 'screens/emergency/emergency_screen.dart';
import 'screens/emergency/ice_medical_card_screen.dart';
import 'screens/doctor_access/doctor_access_screen.dart';
import 'screens/maternal_care/maternal_care_screen.dart';
import 'screens/nutrition/nutrition_screen.dart';
import 'screens/calculators/calculators_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/splash/splash_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/landing',
      builder: (context, state) => const LandingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/dashboard/home',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/dashboard/family',
          builder: (context, state) => const FamilyScreen(),
        ),
        GoRoute(
          path: '/dashboard/family/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return FamilyMemberDetailScreen(memberId: id);
          },
        ),
        GoRoute(
          path: '/dashboard/records',
          builder: (context, state) => const MedicalRecordsScreen(),
        ),
        GoRoute(
          path: '/dashboard/medicines',
          builder: (context, state) => const MedicinesScreen(),
        ),
        GoRoute(
          path: '/dashboard/assistant',
          builder: (context, state) => const AssistantScreen(),
        ),
        GoRoute(
          path: '/dashboard/trends',
          builder: (context, state) => const HealthTrendsScreen(),
        ),
        GoRoute(
          path: '/dashboard/vaccinations',
          builder: (context, state) => const VaccinationsScreen(),
        ),
        GoRoute(
          path: '/dashboard/blood',
          builder: (context, state) => const BloodDonorsScreen(),
        ),
        GoRoute(
          path: '/dashboard/hospitals',
          builder: (context, state) => const HospitalsScreen(),
        ),
        GoRoute(
          path: '/dashboard/emergency',
          builder: (context, state) => const EmergencyScreen(),
        ),
        GoRoute(
          path: '/dashboard/ice-card',
          builder: (context, state) => const IceMedicalCardScreen(),
        ),
        GoRoute(
          path: '/dashboard/doctor-access',
          builder: (context, state) => const DoctorAccessScreen(),
        ),
        GoRoute(
          path: '/dashboard/maternal',
          builder: (context, state) => const MaternalCareScreen(),
        ),
        GoRoute(
          path: '/dashboard/nutrition',
          builder: (context, state) => const NutritionScreen(),
        ),
        GoRoute(
          path: '/dashboard/calculators',
          builder: (context, state) => const CalculatorsScreen(),
        ),
        GoRoute(
          path: '/dashboard/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/dashboard/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

class SwasthAIApp extends ConsumerWidget {
  const SwasthAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isElderly = ref.watch(elderlyModeProvider);
    final lang = ref.watch(languageProvider);

    Locale locale;
    switch (lang) {
      case 'hi':
        locale = const Locale('hi', 'IN');
        break;
      case 'mr':
        locale = const Locale('mr', 'IN');
        break;
      default:
        locale = const Locale('en', 'US');
    }

    return MaterialApp.router(
      title: 'SwasthAI',
      locale: locale,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(isElderly ? 1.35 : 1.0),
          ),
          child: child!,
        );
      },
    );
  }
}
