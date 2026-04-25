import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'haptics.dart';
import 'theme.dart';
import 'transitions.dart';
import '../providers/providers.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/mode_select/mode_select_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/trip_creation/trip_creation_wizard.dart';
import '../screens/trip_creation/invite_ceremony_screen.dart';
import '../screens/dashboard/live_dashboard_screen.dart';
import '../screens/voting/voting_screen.dart';
import '../screens/reveal/trip_reveal_screen.dart';
import '../screens/trip_board/trip_board_screen.dart';
import '../screens/profile/profile_tab_screen.dart';
import '../screens/trips/trips_tab_screen.dart';
import '../screens/scout/scout_tab_screen.dart';
import '../screens/profile_setup/profile_setup_screen.dart';
import '../screens/trip_space/trip_space_screen.dart';
import '../screens/fill_preferences/fill_preferences_screen.dart';
import '../screens/messages/dm_inbox_screen.dart';
import '../screens/messages/dm_thread_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/profile/public_profile_screen.dart';
import '../screens/places/destination_hub_screen.dart';
import '../screens/places/place_detail_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/blocked_users_screen.dart';
import '../screens/settings/edit_profile_screen.dart';
import 'constants.dart';

part 'router.g.dart';

/// Exposed so non-UI code (e.g. PushService) can deep-link into
/// routes when the app is backgrounded or resumed from a push tap.
final rootNavigatorKey = GlobalKey<NavigatorState>();

@Riverpod(keepAlive: true)
GoRouter router(RouterRef ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: TSRoutes.splash,
    debugLogDiagnostics: true,
    // No global redirect — splash handles initial routing,
    // auth screen navigates to /home on successful sign-in.
    routes: [
      GoRoute(
        path: TSRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: TSRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: TSRoutes.auth,
        builder: (_, __) => const AuthScreen(),
      ),
      GoRoute(
        path: TSRoutes.modeSelect,
        builder: (_, __) => const ModeSelectScreen(),
      ),
      // ── Main shell with bottom nav ──────────────────────
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: TSRoutes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/scout',
            builder: (_, __) => const ScoutTabScreen(),
          ),
          GoRoute(
            path: '/trips',
            builder: (_, __) => const TripsTabScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileTabScreen(),
          ),
        ],
      ),
      // ── Profile setup ──────────────────────────────────────
      GoRoute(
        path: '/profile-setup',
        pageBuilder: (context, state) => tsSlideTransition(
          key: state.pageKey,
          child: const ProfileSetupScreen(),
        ),
      ),
      // ── Trip flows ────────────────────────────────────────
      GoRoute(
        path: TSRoutes.tripCreate,
        pageBuilder: (context, state) {
          final extra = state.extra;
          String? pre;
          if (extra is Map && extra['destination'] is String) {
            pre = extra['destination'] as String;
          }
          return tsSlideTransition(
            key: state.pageKey,
            child: TripCreationWizard(preselectedDestination: pre),
          );
        },
      ),
      GoRoute(
        path: '/trip/:id/invite',
        pageBuilder: (context, state) => tsSlideTransition(
          key: state.pageKey,
          child: InviteCeremonyScreen(
            tripId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/trip/:id/dashboard',
        pageBuilder: (context, state) => tsSlideTransition(
          key: state.pageKey,
          child: LiveDashboardScreen(
            tripId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/trip/:id/voting',
        pageBuilder: (context, state) => tsSlideTransition(
          key: state.pageKey,
          child: VotingScreen(
            tripId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/trip/:id/reveal',
        pageBuilder: (context, state) => tsSlideTransition(
          key: state.pageKey,
          child: TripRevealScreen(
            tripId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/trip/:id/board',
        pageBuilder: (context, state) => tsSlideTransition(
          key: state.pageKey,
          child: TripBoardScreen(
            tripId: state.pathParameters['id']!,
          ),
        ),
      ),
      // ── Trip Space (phase-aware unified container) ──────────
      GoRoute(
        path: '/trip/:id/space',
        pageBuilder: (context, state) => tsSlideTransition(
          key: state.pageKey,
          child: TripSpaceScreen(
            tripId: state.pathParameters['id']!,
            preferredTab: state.uri.queryParameters['tab'],
          ),
        ),
      ),
      GoRoute(
        path: '/trip/:id/fill',
        pageBuilder: (context, state) => tsSlideTransition(
          key: state.pageKey,
          child: FillPreferencesScreen(
            tripId: state.pathParameters['id']!,
          ),
        ),
      ),
      // ── Messages / DMs ─────────────────────────────────────
      GoRoute(
        path: '/messages',
        pageBuilder: (context, state) => tsSlideTransition(
          key: state.pageKey,
          child: const DmInboxScreen(),
        ),
      ),
      GoRoute(
        path: '/messages/:userId',
        pageBuilder: (context, state) => tsSlideTransition(
          key: state.pageKey,
          child: DmThreadScreen(
            otherUserId: state.pathParameters['userId']!,
          ),
        ),
      ),
      // ── Universal search + public profile ──────────────────
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => tsSlideTransition(
          key: state.pageKey,
          child: const SearchScreen(),
        ),
      ),
      GoRoute(
        path: '/user/:id',
        pageBuilder: (context, state) => tsSlideTransition(
          key: state.pageKey,
          child: PublicProfileScreen(
            userId: state.pathParameters['id']!,
          ),
        ),
      ),
      // ── Scout's Guide: destinations + places ──────────────
      GoRoute(
        path: '/destination/:name',
        pageBuilder: (context, state) => tsSlideTransition(
          key: state.pageKey,
          child: DestinationHubScreen(
            destination: Uri.decodeComponent(state.pathParameters['name']!),
          ),
        ),
      ),
      GoRoute(
        path: '/place/:id',
        pageBuilder: (context, state) => tsSlideTransition(
          key: state.pageKey,
          child: PlaceDetailScreen(
            placeId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => tsSlideTransition(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/blocked',
        pageBuilder: (context, state) => tsSlideTransition(
          key: state.pageKey,
          child: const BlockedUsersScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/edit-profile',
        pageBuilder: (context, state) => tsSlideTransition(
          key: state.pageKey,
          child: const EditProfileScreen(),
        ),
      ),
      // Solo / Match flows removed from v1.0 — to be rebuilt per v1.1 redesign spec.
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: TSColors.bg,
      body: Center(
        child: Text('Page not found', style: TSTextStyles.body()),
      ),
    ),
  );
}

// ── Main shell: wraps screens that have bottom navigation ──
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Any of these mean the user has something actionable on the
    // Trips tab — pending vote, unread trip activity, etc. One red
    // dot covers all signals so we don't stack badges.
    final pendingVotes = ref.watch(pendingVotesProvider);
    final unreadTrips = ref.watch(unreadTripIdsProvider);
    final hasTripsBadge =
        pendingVotes.isNotEmpty || unreadTrips.isNotEmpty;
    return Scaffold(
      backgroundColor: TSColors.bg,
      body: child,
      bottomNavigationBar: TSBottomNav(
        currentIndex: _currentIndex(GoRouterState.of(context).matchedLocation),
        onTap: (i) => _navigate(context, i),
        tripsBadge: hasTripsBadge,
      ),
    );
  }

  int _currentIndex(String location) {
    if (location.startsWith('/scout')) return 1;
    if (location.startsWith('/trips')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _navigate(BuildContext context, int i) {
    switch (i) {
      case 0: context.go('/home');
      case 1: context.go('/scout');
      case 2: context.go('/trips');
      case 3: context.go('/profile');
    }
  }
}

/// Four-tab bottom nav: Home · Scout · Trips · Profile.
/// Icons are custom-drawn strokes (not emoji) for a premium feel.
class TSBottomNav extends StatelessWidget {
  const TSBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.tripsBadge = false,
  });
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool tripsBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TSColors.s1,
        border: Border(top: BorderSide(color: TSColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _item(0, _NavIcon.home,    'home',    showBadge: false),
              _item(1, _NavIcon.scout,   'scout',   showBadge: false),
              _item(2, _NavIcon.trips,   'trips',   showBadge: tripsBadge),
              _item(3, _NavIcon.profile, 'profile', showBadge: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int index, _NavIcon icon, String label,
      {required bool showBadge}) {
    final active = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          TSHaptics.tabSwitch();
          onTap(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(clipBehavior: Clip.none, children: [
              CustomPaint(
                size: const Size(22, 22),
                painter: _NavIconPainter(
                  icon: icon,
                  color: active ? TSColors.lime : TSColors.muted,
                ),
              ),
              if (showBadge)
                Positioned(
                  right: -3,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: TSColors.lime,
                      shape: BoxShape.circle,
                      border: Border.all(color: TSColors.s1, width: 1.5),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TSTextStyles.label(
                color: active ? TSColors.lime : TSColors.muted,
                size: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _NavIcon { home, scout, trips, profile }

class _NavIconPainter extends CustomPainter {
  _NavIconPainter({required this.icon, required this.color});
  final _NavIcon icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final c = size.center(Offset.zero);
    final r = size.width * 0.42;

    switch (icon) {
      case _NavIcon.home:
        // Simplified signal: a pulse with a ground line (home = your base).
        canvas.drawCircle(c, r * 0.35, paint);
        canvas.drawCircle(c, r * 0.72, paint..color = color.withOpacity(0.55));
        break;
      case _NavIcon.scout:
        // Compass rose: a diamond inscribed in a circle.
        paint.color = color;
        canvas.drawCircle(c, r, paint);
        final path = Path()
          ..moveTo(c.dx, c.dy - r * 0.7)
          ..lineTo(c.dx + r * 0.45, c.dy)
          ..lineTo(c.dx, c.dy + r * 0.7)
          ..lineTo(c.dx - r * 0.45, c.dy)
          ..close();
        canvas.drawPath(path, paint..style = PaintingStyle.fill);
        break;
      case _NavIcon.trips:
        // Three stacked horizontal lines — archive / collection.
        paint.color = color;
        for (var i = 0; i < 3; i++) {
          final y = c.dy - r * 0.5 + r * 0.5 * i;
          canvas.drawLine(
            Offset(c.dx - r, y),
            Offset(c.dx + r, y),
            paint,
          );
        }
        break;
      case _NavIcon.profile:
        // Minimal head-and-shoulders silhouette, stroke only.
        paint.color = color;
        canvas.drawCircle(Offset(c.dx, c.dy - r * 0.35), r * 0.38, paint);
        final path = Path()
          ..moveTo(c.dx - r * 0.72, c.dy + r * 0.78)
          ..quadraticBezierTo(
              c.dx, c.dy + r * 0.15, c.dx + r * 0.72, c.dy + r * 0.78);
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _NavIconPainter old) =>
      old.icon != icon || old.color != color;
}
