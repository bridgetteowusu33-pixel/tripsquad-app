import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/widgets.dart';
import '../../widgets/tappable.dart';

/// Scout's Guide hub for a destination. Tabs: activities / hotels /
/// restaurants / recaps. Everything aggregated from real squad data.
class DestinationHubScreen extends ConsumerStatefulWidget {
  const DestinationHubScreen({super.key, required this.destination});
  final String destination;

  @override
  ConsumerState<DestinationHubScreen> createState() =>
      _DestinationHubScreenState();
}

class _DestinationHubScreenState extends ConsumerState<DestinationHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  DestinationHub? _hub;
  List<PlaceStats> _activities = [];
  List<PlaceStats> _hotels = [];
  List<PlaceStats> _restaurants = [];
  List<Map<String, dynamic>> _recaps = [];
  // Curated content from destination_guides for the 7 hand-picked
  // cities. Empty list means no guide exists for this destination —
  // the tabs fall back to community-only.
  List<Map<String, dynamic>> _curatedStays = [];
  List<Map<String, dynamic>> _curatedEats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final svc = ref.read(placesServiceProvider);
    try {
      final results = await Future.wait([
        svc.fetchDestination(widget.destination),
        svc.fetchPlacesForDestination(widget.destination, category: 'activity'),
        svc.fetchPlacesForDestination(widget.destination, category: 'hotel'),
        svc.fetchPlacesForDestination(widget.destination, category: 'restaurant'),
        svc.fetchDestinationRecapsFeed(widget.destination),
        svc.fetchDestinationGuide(widget.destination),
      ]);
      if (!mounted) return;
      setState(() {
        _hub = results[0] as DestinationHub?;
        _activities = results[1] as List<PlaceStats>;
        _hotels = results[2] as List<PlaceStats>;
        _restaurants = results[3] as List<PlaceStats>;
        _recaps = results[4] as List<Map<String, dynamic>>;
        final guide = results[5] as Map<String, dynamic>?;
        if (guide != null) {
          final stays = guide['stay_where'];
          if (stays is List) {
            _curatedStays =
                stays.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
          final eats = guide['curated_eats'];
          if (eats is List) {
            _curatedEats =
                eats.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TSColors.bg,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: TSColors.lime))
          : CustomScrollView(slivers: [
              _heroAppBar(),
              SliverToBoxAdapter(child: _statsRow()),
              SliverToBoxAdapter(child: _planCta()),
              SliverToBoxAdapter(child: _tabBar()),
              SliverFillRemaining(
                hasScrollBody: true,
                child: TabBarView(controller: _tabs, children: [
                  _placesList(_activities, 'activity'),
                  _hotelsTab(),
                  _restaurantsTab(),
                  _recapsList(),
                ]),
              ),
            ]),
    );
  }

  Widget _heroAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 72,
      toolbarHeight: 56,
      collapsedHeight: 56,
      backgroundColor: TSColors.bg,
      iconTheme: const IconThemeData(color: TSColors.text),
      titleSpacing: 0,
      title: Text(
        '${_hub?.flag ?? ''} ${widget.destination}',
        style: TSTextStyles.heading(size: 20),
      ),
    );
  }

  Widget _statsRow() {
    final hub = _hub;
    if (hub == null) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Wrap(spacing: 6, runSpacing: 6, children: [
        if (hub.avgStars != null && hub.recapCount > 0)
          TSPill('⭐ ${hub.avgStars!.toStringAsFixed(1)} · ${hub.recapCount} recaps',
              variant: TSPillVariant.lime, small: true),
        if (hub.placeCount > 0)
          TSPill('${hub.placeCount} places tracked',
              variant: TSPillVariant.muted, small: true),
      ]),
    );
  }

  Widget _planCta() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(children: [
        TSButton(
          label: '✈️ plan my trip to ${widget.destination}',
          onTap: () {
            TSHaptics.light();
            context.push('/trip/create', extra: {
              'destination': widget.destination,
            });
          },
        ),
        const SizedBox(height: 6),
        Text(
          'creates a brand new trip',
          style: TSTextStyles.caption(color: TSColors.muted),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  Widget _tabBar() {
    return Container(
      color: TSColors.bg,
      child: TabBar(
        controller: _tabs,
        isScrollable: true,
        indicatorColor: TSColors.lime,
        labelStyle: TSTextStyles.label(size: 11),
        unselectedLabelColor: TSColors.muted,
        labelColor: TSColors.lime,
        tabs: [
          Tab(text: 'activities · ${_activities.length}'),
          Tab(text:
              'hotels · ${_hotels.length + _curatedStays.length}'),
          Tab(text:
              'restaurants · ${_restaurants.length + _curatedEats.length}'),
          Tab(text: 'recaps · ${_recaps.length}'),
        ],
      ),
    );
  }

  /// Hotels tab: curated stay-areas from destination_guides on top
  /// (when available), then community-saved places below. Both can
  /// be empty — the empty-state copy now points users at trip space
  /// where Scout actually picks for them.
  Widget _hotelsTab() {
    if (_curatedStays.isEmpty && _hotels.isEmpty) {
      return _emptyHotelsRestaurants(category: 'hotel');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_curatedStays.isNotEmpty) ...[
          _curatedSectionHeader(
            'where to stay',
            "scout's editorial pick of areas",
          ),
          const SizedBox(height: 10),
          ...List.generate(_curatedStays.length, (i) {
            final s = _curatedStays[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CuratedAreaTile(
                area: (s['area'] as String?) ?? '',
                body: (s['body'] as String?) ?? '',
                destination: widget.destination,
              ).animate().fadeIn(delay: (i * 50).ms),
            );
          }),
          if (_hotels.isNotEmpty) const SizedBox(height: 12),
        ],
        if (_hotels.isNotEmpty) ...[
          _curatedSectionHeader(
            'community picks',
            'hotels saved by other squads',
          ),
          const SizedBox(height: 10),
          ...List.generate(_hotels.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PlaceTile(place: _hotels[i])
                  .animate()
                  .fadeIn(delay: (i * 50).ms),
            );
          }),
        ],
      ],
    );
  }

  /// Restaurants tab: curated eats from destination_guides on top,
  /// community below.
  Widget _restaurantsTab() {
    if (_curatedEats.isEmpty && _restaurants.isEmpty) {
      return _emptyHotelsRestaurants(category: 'restaurant');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_curatedEats.isNotEmpty) ...[
          _curatedSectionHeader(
            'where to eat',
            "scout's editorial pick",
          ),
          const SizedBox(height: 10),
          ...List.generate(_curatedEats.length, (i) {
            final e = _curatedEats[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CuratedEatsTile(
                name: (e['name'] as String?) ?? '',
                neighborhood: (e['neighborhood'] as String?),
                cuisine: (e['cuisine'] as String?),
                priceBand: (e['price_band'] as String?),
                note: (e['note'] as String?),
                destination: widget.destination,
              ).animate().fadeIn(delay: (i * 40).ms),
            );
          }),
          if (_restaurants.isNotEmpty) const SizedBox(height: 12),
        ],
        if (_restaurants.isNotEmpty) ...[
          _curatedSectionHeader(
            'community picks',
            'restaurants saved by other squads',
          ),
          const SizedBox(height: 10),
          ...List.generate(_restaurants.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PlaceTile(place: _restaurants[i])
                  .animate()
                  .fadeIn(delay: (i * 50).ms),
            );
          }),
        ],
      ],
    );
  }

  Widget _emptyHotelsRestaurants({required String category}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(category == 'hotel' ? '🛏️' : '🍽️',
                style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              category == 'hotel'
                  ? 'no community ${category}s here yet'
                  : 'no community $category picks yet',
              style: TSTextStyles.heading(size: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              "open a trip here and scout will pick stays + eats just for your squad",
              style: TSTextStyles.body(color: TSColors.text2),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _curatedSectionHeader(String label, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: TSTextStyles.heading(size: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '· $sub',
              style: TSTextStyles.caption(color: TSColors.muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placesList(List<PlaceStats> places, String category) {
    if (places.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('no $category data yet',
              style: TSTextStyles.body(color: TSColors.muted)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: places.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _PlaceTile(place: places[i])
          .animate()
          .fadeIn(delay: (i * 50).ms),
    );
  }

  Widget _recapsList() {
    if (_recaps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('no recaps yet — be the first ✦',
              style: TSTextStyles.body(color: TSColors.muted),
              textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _recaps.length,
      separatorBuilder: (_, __) => const Divider(color: TSColors.border),
      itemBuilder: (_, i) {
        final r = _recaps[i];
        final stars = (r['stars'] as int?) ?? 0;
        final nickname = (r['user_nickname'] as String?) ?? 'someone';
        final emoji = (r['user_emoji'] as String?) ?? '😎';
        final photoUrl = r['user_avatar_url'] as String?;
        final bestPart = r['best_part'] as String?;
        final wouldReturn = r['would_return'] as String?;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TSAvatar(emoji: emoji, photoUrl: photoUrl, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(nickname, style: TSTextStyles.body(weight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Text('⭐' * stars, style: const TextStyle(fontSize: 12)),
                  if (wouldReturn == 'yes') ...[
                    const SizedBox(width: 6),
                    Text('· would return ✨',
                        style: TSTextStyles.caption(color: TSColors.lime)),
                  ],
                ]),
                if (bestPart != null && bestPart.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('"$bestPart"',
                      style: TSTextStyles.body(
                          size: 13, color: TSColors.text2)),
                ],
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place});
  final PlaceStats place;

  @override
  Widget build(BuildContext context) {
    return TSTappable(
      onTap: () {
        TSHaptics.light();
        context.push('/place/${place.placeId}');
      },
      child: TSCard(
        padding: EdgeInsets.zero,
        child: Row(children: [
          if (place.displayPhoto != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: SizedBox(
                width: 84, height: 84,
                child: CachedNetworkImage(
                  imageUrl: place.displayPhoto!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: TSColors.s2),
                  errorWidget: (_, __, ___) => Container(color: TSColors.s2),
                ),
              ),
            )
          else
            Container(
              width: 84, height: 84,
              color: TSColors.s2,
              alignment: Alignment.center,
              child: Text(
                place.category == 'hotel' ? '🛏️'
                    : place.category == 'restaurant' ? '🍽️' : '📍',
                style: const TextStyle(fontSize: 32),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name,
                        style: TSTextStyles.heading(size: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      if (place.ratingCount >= 3)
                        Text('${place.approvalPct}% 👍',
                            style: TSTextStyles.caption(color: TSColors.lime))
                      else if (place.ratingCount > 0)
                        Text('${place.ratingCount} rating${place.ratingCount == 1 ? '' : 's'}',
                            style: TSTextStyles.caption(color: TSColors.muted))
                      else
                        Text('no ratings yet',
                            style: TSTextStyles.caption(color: TSColors.muted)),
                      const SizedBox(width: 8),
                      Text('· ${place.squadsCount} squad${place.squadsCount == 1 ? '' : 's'}',
                          style: TSTextStyles.caption(color: TSColors.muted)),
                    ]),
                  ]),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.arrow_forward_ios_rounded,
                color: TSColors.muted, size: 14),
          ),
        ]),
      ),
    );
  }
}

/// Curated stay-area tile — surfaces an entry from
/// `destination_guides.stay_where`. Tapping opens Google Maps to
/// search for the area within the destination, since we don't have
/// a place_id to route to.
class _CuratedAreaTile extends StatelessWidget {
  const _CuratedAreaTile({
    required this.area,
    required this.body,
    required this.destination,
  });
  final String area;
  final String body;
  final String destination;

  Future<void> _openMaps() async {
    TSHaptics.ctaTap();
    final q = '$area, $destination';
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(q)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TSTappable(
      onTap: _openMaps,
      child: TSCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TSColors.s2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🏘️', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(area, style: TSTextStyles.heading(size: 15)),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TSTextStyles.body(
                      size: 13, color: TSColors.text2,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.map_outlined,
                  color: TSColors.muted, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// Curated restaurant tile — surfaces an entry from
/// `destination_guides.curated_eats`. Tapping opens Google Maps so
/// the user can pull up directions / reviews / hours.
class _CuratedEatsTile extends StatelessWidget {
  const _CuratedEatsTile({
    required this.name,
    required this.neighborhood,
    required this.cuisine,
    required this.priceBand,
    required this.note,
    required this.destination,
  });
  final String name;
  final String? neighborhood;
  final String? cuisine;
  final String? priceBand;
  final String? note;
  final String destination;

  Future<void> _openMaps() async {
    TSHaptics.ctaTap();
    final q = '$name, $destination';
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(q)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subParts = <String>[];
    if (cuisine != null && cuisine!.isNotEmpty) subParts.add(cuisine!);
    if (neighborhood != null && neighborhood!.isNotEmpty) {
      subParts.add(neighborhood!);
    }

    return TSTappable(
      onTap: _openMaps,
      child: TSCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TSColors.s2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🍽️', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(name,
                            style: TSTextStyles.heading(size: 15)),
                      ),
                      if (priceBand != null && priceBand!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          priceBand!,
                          style: TSTextStyles.body(
                            size: 12,
                            color: TSColors.lime,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subParts.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subParts.join(' · '),
                      style: TSTextStyles.caption(color: TSColors.muted),
                    ),
                  ],
                  if (note != null && note!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '"$note"',
                      style: TSTextStyles.body(
                          size: 13, color: TSColors.text2),
                    ),
                  ],
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.map_outlined,
                  color: TSColors.muted, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
