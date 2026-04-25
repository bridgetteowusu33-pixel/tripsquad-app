// ─────────────────────────────────────────────────────────────
//  TRIPSQUAD — Constants
// ─────────────────────────────────────────────────────────────

class TSEnv {
  TSEnv._();

  // Set these in your .env / --dart-define build args
  static const supabaseUrl    = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const revenueCatKey  = String.fromEnvironment('REVENUECAT_API_KEY');
  static const posthogKey     = String.fromEnvironment('POSTHOG_API_KEY');
  static const sentryDsn      = String.fromEnvironment('SENTRY_DSN');
  static const mapboxToken    = String.fromEnvironment('MAPBOX_TOKEN');
  static const branchKey      = String.fromEnvironment('BRANCH_KEY');
  static const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
}

class TSRoutes {
  TSRoutes._();
  static const splash        = '/';
  static const onboarding    = '/onboarding';
  static const auth          = '/auth';
  static const modeSelect    = '/mode';
  static const home          = '/home';
  static const tripCreate    = '/trip/create';
  static const tripDetail    = '/trip/:id';
  static const dashboard     = '/trip/:id/dashboard';
  static const voting        = '/trip/:id/voting';
  static const reveal        = '/trip/:id/reveal';
  static const tripBoard     = '/trip/:id/board';
  static const squadForm     = '/join/:token';  // PWA web form
  static const soloSetup     = '/solo/setup';
  static const soloBoard     = '/solo/:id/board';
  static const matchDiscover = '/match';
  static const passport      = '/passport';
  static const settings      = '/settings';
}

/// Free-tier ceilings. A free-tier host can plan 1 concurrent trip
/// with up to 6 squadmates and 3 AI generations. Squad members
/// participating on someone else's paid trip are NOT gated — only
/// the host needs an entitlement.
class TSFreeTier {
  TSFreeTier._();
  static const maxTrips        = 1;
  static const maxSquadSize    = 6;
  static const maxAiGens       = 3;
}

/// RevenueCat product identifiers. Must match the IAP product IDs
/// configured in App Store Connect and synced into RevenueCat.
class TSProducts {
  TSProducts._();
  static const tripPass        = 'tripsquad.trippass';
  static const explorerMonthly = 'tripsquad.explorer.monthly';
  static const explorerAnnual  = 'tripsquad.explorer.annual';
  static const teamMonthly     = 'tripsquad.team.monthly';

  /// RevenueCat entitlement identifiers (configure in RC dashboard).
  static const entExplorer     = 'explorer';
  static const entTeam         = 'team';
}

class TSVibes {
  TSVibes._();
  static const all = [
    (id: 'culture',    label: 'Culture',    emoji: '🏛️', desc: 'Art, history, food scenes'),
    (id: 'city',       label: 'City Break', emoji: '🌆', desc: 'Streets, cafés, energy'),
    (id: 'beach',      label: 'Beach',      emoji: '🏖️', desc: 'Sun, sea, zero plans'),
    (id: 'food',       label: 'Food & Drink',emoji: '🍜', desc: 'Markets, restaurants, wine'),
    (id: 'party',      label: 'Party',      emoji: '🎉', desc: 'Nightlife, music, chaos'),
    (id: 'adventure',  label: 'Adventure',  emoji: '🏔️', desc: 'Hikes, thrills, outdoors'),
    (id: 'nature',     label: 'Nature',     emoji: '🌿', desc: 'Forests, escape'),
    (id: 'wellness',   label: 'Wellness',   emoji: '🧘', desc: 'Spas, slow mornings'),
  ];
}

class TSQuickDestinations {
  TSQuickDestinations._();

  /// Look up a flag emoji from a free-text destination name. Checks the
  /// quick list first, then a broader world cities + country map. Case
  /// insensitive, handles common aliases and "City, Country" input.
  /// Returns null if no match — caller should fall back to '🌍'.
  static String? flagFor(String destination) {
    String q = destination.toLowerCase().trim();
    if (q.isEmpty) return null;
    // Strip trailing country in "City, Country"
    final commaIdx = q.indexOf(',');
    final cityOnly = commaIdx > 0 ? q.substring(0, commaIdx).trim() : q;

    // 1. Exact match in quick list
    for (final d in all) {
      if (d.city.toLowerCase() == cityOnly) return d.flag;
    }
    // 2. Exact in world cities map
    if (_worldCities.containsKey(cityOnly)) return _worldCities[cityOnly];
    // 3. Country-level match ("Japan", "France")
    if (_countries.containsKey(cityOnly)) return _countries[cityOnly];
    // 4. Loose prefix match on quick list
    for (final d in all) {
      final c = d.city.toLowerCase();
      if (c.startsWith(cityOnly) || cityOnly.startsWith(c)) return d.flag;
    }
    // 5. Loose prefix on world cities
    for (final e in _worldCities.entries) {
      if (e.key.startsWith(cityOnly) || cityOnly.startsWith(e.key)) {
        return e.value;
      }
    }
    return null;
  }

  // ── World cities → flag (curated, not exhaustive). Add as needed. ──
  static const Map<String, String> _worldCities = {
    // Europe
    'london': '🇬🇧', 'paris': '🇫🇷', 'rome': '🇮🇹', 'milan': '🇮🇹',
    'florence': '🇮🇹', 'venice': '🇮🇹', 'naples': '🇮🇹',
    'madrid': '🇪🇸', 'seville': '🇪🇸', 'valencia': '🇪🇸',
    'amsterdam': '🇳🇱', 'berlin': '🇩🇪', 'munich': '🇩🇪', 'hamburg': '🇩🇪',
    'vienna': '🇦🇹', 'prague': '🇨🇿', 'budapest': '🇭🇺', 'warsaw': '🇵🇱',
    'krakow': '🇵🇱', 'copenhagen': '🇩🇰', 'stockholm': '🇸🇪', 'oslo': '🇳🇴',
    'helsinki': '🇫🇮', 'reykjavik': '🇮🇸', 'dublin': '🇮🇪', 'edinburgh': '🇬🇧',
    'brussels': '🇧🇪', 'zurich': '🇨🇭', 'geneva': '🇨🇭', 'athens': '🇬🇷',
    'istanbul': '🇹🇷', 'porto': '🇵🇹',
    // North America
    'new york': '🇺🇸', 'nyc': '🇺🇸', 'los angeles': '🇺🇸', 'la': '🇺🇸',
    'san francisco': '🇺🇸', 'sf': '🇺🇸', 'chicago': '🇺🇸', 'miami': '🇺🇸',
    'seattle': '🇺🇸', 'austin': '🇺🇸', 'nashville': '🇺🇸', 'new orleans': '🇺🇸',
    'boston': '🇺🇸', 'washington': '🇺🇸', 'washington dc': '🇺🇸',
    'las vegas': '🇺🇸', 'vegas': '🇺🇸', 'honolulu': '🇺🇸',
    'toronto': '🇨🇦', 'vancouver': '🇨🇦', 'montreal': '🇨🇦', 'quebec': '🇨🇦',
    'cancun': '🇲🇽', 'tulum': '🇲🇽', 'oaxaca': '🇲🇽', 'puerto vallarta': '🇲🇽',
    'havana': '🇨🇺', 'san juan': '🇵🇷',
    // South & Central America
    'buenos aires': '🇦🇷', 'rio': '🇧🇷', 'rio de janeiro': '🇧🇷',
    'sao paulo': '🇧🇷', 'são paulo': '🇧🇷', 'salvador': '🇧🇷',
    'santiago': '🇨🇱', 'lima': '🇵🇪', 'cusco': '🇵🇪', 'machu picchu': '🇵🇪',
    'bogota': '🇨🇴', 'bogotá': '🇨🇴', 'cartagena': '🇨🇴',
    'quito': '🇪🇨', 'galapagos': '🇪🇨', 'la paz': '🇧🇴',
    'san jose': '🇨🇷', 'costa rica': '🇨🇷', 'panama city': '🇵🇦',
    // Africa
    'accra': '🇬🇭', 'cape coast': '🇬🇭', 'kumasi': '🇬🇭',
    'lagos': '🇳🇬', 'abuja': '🇳🇬',
    'cairo': '🇪🇬', 'alexandria': '🇪🇬', 'luxor': '🇪🇬',
    'cape town': '🇿🇦', 'johannesburg': '🇿🇦', 'durban': '🇿🇦',
    'nairobi': '🇰🇪', 'mombasa': '🇰🇪', 'zanzibar': '🇹🇿',
    'dar es salaam': '🇹🇿', 'kigali': '🇷🇼',
    'casablanca': '🇲🇦', 'fez': '🇲🇦', 'rabat': '🇲🇦',
    'tunis': '🇹🇳', 'addis ababa': '🇪🇹',
    // Middle East
    'dubai': '🇦🇪', 'abu dhabi': '🇦🇪', 'doha': '🇶🇦', 'muscat': '🇴🇲',
    'riyadh': '🇸🇦', 'jeddah': '🇸🇦', 'beirut': '🇱🇧',
    'jerusalem': '🇮🇱', 'tel aviv': '🇮🇱', 'amman': '🇯🇴', 'petra': '🇯🇴',
    // Asia
    'tokyo': '🇯🇵', 'kyoto': '🇯🇵', 'osaka': '🇯🇵', 'hokkaido': '🇯🇵',
    'seoul': '🇰🇷', 'busan': '🇰🇷', 'jeju': '🇰🇷',
    'beijing': '🇨🇳', 'shanghai': '🇨🇳', 'hong kong': '🇭🇰',
    'taipei': '🇹🇼', 'singapore': '🇸🇬',
    'bangkok': '🇹🇭', 'phuket': '🇹🇭', 'chiang mai': '🇹🇭', 'krabi': '🇹🇭',
    'hanoi': '🇻🇳', 'ho chi minh': '🇻🇳', 'saigon': '🇻🇳', 'da nang': '🇻🇳',
    'siem reap': '🇰🇭', 'phnom penh': '🇰🇭', 'luang prabang': '🇱🇦',
    'vientiane': '🇱🇦', 'yangon': '🇲🇲',
    'kuala lumpur': '🇲🇾', 'penang': '🇲🇾',
    'jakarta': '🇮🇩', 'bali': '🇮🇩', 'ubud': '🇮🇩', 'lombok': '🇮🇩',
    'manila': '🇵🇭', 'cebu': '🇵🇭', 'palawan': '🇵🇭',
    'mumbai': '🇮🇳', 'delhi': '🇮🇳', 'new delhi': '🇮🇳', 'goa': '🇮🇳',
    'jaipur': '🇮🇳', 'agra': '🇮🇳', 'varanasi': '🇮🇳', 'kerala': '🇮🇳',
    'colombo': '🇱🇰', 'kathmandu': '🇳🇵', 'thimphu': '🇧🇹',
    // Oceania
    'sydney': '🇦🇺', 'melbourne': '🇦🇺', 'brisbane': '🇦🇺', 'perth': '🇦🇺',
    'gold coast': '🇦🇺', 'cairns': '🇦🇺',
    'auckland': '🇳🇿', 'queenstown': '🇳🇿', 'wellington': '🇳🇿',
    'fiji': '🇫🇯', 'tahiti': '🇵🇫', 'bora bora': '🇵🇫',
  };

  // ── Country → flag fallback ──
  static const Map<String, String> _countries = {
    'usa': '🇺🇸', 'united states': '🇺🇸', 'america': '🇺🇸',
    'uk': '🇬🇧', 'united kingdom': '🇬🇧', 'england': '🇬🇧', 'scotland': '🇬🇧',
    'canada': '🇨🇦', 'mexico': '🇲🇽',
    'france': '🇫🇷', 'spain': '🇪🇸', 'italy': '🇮🇹', 'portugal': '🇵🇹',
    'germany': '🇩🇪', 'netherlands': '🇳🇱', 'greece': '🇬🇷',
    'croatia': '🇭🇷', 'turkey': '🇹🇷', 'iceland': '🇮🇸', 'ireland': '🇮🇪',
    'switzerland': '🇨🇭', 'austria': '🇦🇹', 'czech republic': '🇨🇿',
    'hungary': '🇭🇺', 'poland': '🇵🇱',
    'japan': '🇯🇵', 'korea': '🇰🇷', 'south korea': '🇰🇷',
    'china': '🇨🇳', 'taiwan': '🇹🇼',
    'thailand': '🇹🇭', 'vietnam': '🇻🇳', 'cambodia': '🇰🇭',
    'laos': '🇱🇦', 'myanmar': '🇲🇲', 'burma': '🇲🇲',
    'malaysia': '🇲🇾', 'indonesia': '🇮🇩', 'philippines': '🇵🇭',
    'india': '🇮🇳', 'sri lanka': '🇱🇰', 'nepal': '🇳🇵', 'bhutan': '🇧🇹',
    'australia': '🇦🇺', 'new zealand': '🇳🇿',
    'brazil': '🇧🇷', 'argentina': '🇦🇷', 'chile': '🇨🇱',
    'peru': '🇵🇪', 'colombia': '🇨🇴', 'ecuador': '🇪🇨', 'bolivia': '🇧🇴',
    'costa rica': '🇨🇷', 'panama': '🇵🇦', 'cuba': '🇨🇺',
    'puerto rico': '🇵🇷', 'dominican republic': '🇩🇴',
    'egypt': '🇪🇬', 'morocco': '🇲🇦', 'tunisia': '🇹🇳',
    'south africa': '🇿🇦', 'kenya': '🇰🇪', 'tanzania': '🇹🇿',
    'ghana': '🇬🇭', 'nigeria': '🇳🇬', 'ethiopia': '🇪🇹', 'rwanda': '🇷🇼',
    'uae': '🇦🇪', 'united arab emirates': '🇦🇪', 'qatar': '🇶🇦',
    'oman': '🇴🇲', 'saudi arabia': '🇸🇦', 'jordan': '🇯🇴', 'israel': '🇮🇱',
    'lebanon': '🇱🇧',
    'singapore': '🇸🇬', 'hong kong': '🇭🇰',
  };

  static const all = [
    (flag: '🇵🇹', city: 'Lisbon',       country: 'Portugal'),
    (flag: '🇪🇸', city: 'Barcelona',     country: 'Spain'),
    (flag: '🇭🇷', city: 'Dubrovnik',     country: 'Croatia'),
    (flag: '🇯🇵', city: 'Tokyo',         country: 'Japan'),
    (flag: '🇲🇦', city: 'Marrakech',     country: 'Morocco'),
    (flag: '🇬🇷', city: 'Santorini',     country: 'Greece'),
    (flag: '🇮🇩', city: 'Bali',          country: 'Indonesia'),
    (flag: '🇹🇭', city: 'Bangkok',       country: 'Thailand'),
    (flag: '🇨🇴', city: 'Medellín',      country: 'Colombia'),
    (flag: '🇦🇪', city: 'Dubai',         country: 'UAE'),
    (flag: '🇲🇽', city: 'Mexico City',   country: 'Mexico'),
    (flag: '🇮🇹', city: 'Amalfi Coast',  country: 'Italy'),
    (flag: '🇬🇭', city: 'Accra',         country: 'Ghana'),
  ];

  // ── Curated city shortlists per country/region ───────────────
  // Lower-case keys. When the trip name contains any of these tokens
  // (or their aliases in [_countries] / region aliases below), the
  // wizard surfaces these cities instead of the generic [all] list.
  // Aim for 3–6 destinations per country — the ones the squad is
  // most likely to pick.
  static const _citiesByCountry = <String, List<({String flag, String city, String country})>>{
    'japan': [
      (flag: '🇯🇵', city: 'Tokyo',   country: 'Japan'),
      (flag: '🇯🇵', city: 'Kyoto',   country: 'Japan'),
      (flag: '🇯🇵', city: 'Osaka',   country: 'Japan'),
      (flag: '🇯🇵', city: 'Hakone',  country: 'Japan'),
      (flag: '🇯🇵', city: 'Sapporo', country: 'Japan'),
    ],
    'italy': [
      (flag: '🇮🇹', city: 'Rome',         country: 'Italy'),
      (flag: '🇮🇹', city: 'Florence',     country: 'Italy'),
      (flag: '🇮🇹', city: 'Amalfi Coast', country: 'Italy'),
      (flag: '🇮🇹', city: 'Milan',        country: 'Italy'),
      (flag: '🇮🇹', city: 'Venice',       country: 'Italy'),
      (flag: '🇮🇹', city: 'Sicily',       country: 'Italy'),
    ],
    'france': [
      (flag: '🇫🇷', city: 'Paris',    country: 'France'),
      (flag: '🇫🇷', city: 'Nice',     country: 'France'),
      (flag: '🇫🇷', city: 'Marseille',country: 'France'),
      (flag: '🇫🇷', city: 'Lyon',     country: 'France'),
      (flag: '🇫🇷', city: 'Bordeaux', country: 'France'),
    ],
    'spain': [
      (flag: '🇪🇸', city: 'Barcelona', country: 'Spain'),
      (flag: '🇪🇸', city: 'Madrid',    country: 'Spain'),
      (flag: '🇪🇸', city: 'Seville',   country: 'Spain'),
      (flag: '🇪🇸', city: 'Ibiza',     country: 'Spain'),
      (flag: '🇪🇸', city: 'Valencia',  country: 'Spain'),
    ],
    'ghana': [
      (flag: '🇬🇭', city: 'Accra',       country: 'Ghana'),
      (flag: '🇬🇭', city: 'Kumasi',      country: 'Ghana'),
      (flag: '🇬🇭', city: 'Cape Coast',  country: 'Ghana'),
      (flag: '🇬🇭', city: 'Takoradi',    country: 'Ghana'),
    ],
    'morocco': [
      (flag: '🇲🇦', city: 'Marrakech', country: 'Morocco'),
      (flag: '🇲🇦', city: 'Fes',       country: 'Morocco'),
      (flag: '🇲🇦', city: 'Casablanca',country: 'Morocco'),
      (flag: '🇲🇦', city: 'Chefchaouen', country: 'Morocco'),
      (flag: '🇲🇦', city: 'Essaouira', country: 'Morocco'),
    ],
    'mexico': [
      (flag: '🇲🇽', city: 'Mexico City', country: 'Mexico'),
      (flag: '🇲🇽', city: 'Tulum',       country: 'Mexico'),
      (flag: '🇲🇽', city: 'Oaxaca',      country: 'Mexico'),
      (flag: '🇲🇽', city: 'Cancún',      country: 'Mexico'),
      (flag: '🇲🇽', city: 'Puerto Vallarta', country: 'Mexico'),
    ],
    'thailand': [
      (flag: '🇹🇭', city: 'Bangkok',     country: 'Thailand'),
      (flag: '🇹🇭', city: 'Chiang Mai',  country: 'Thailand'),
      (flag: '🇹🇭', city: 'Phuket',      country: 'Thailand'),
      (flag: '🇹🇭', city: 'Koh Samui',   country: 'Thailand'),
      (flag: '🇹🇭', city: 'Krabi',       country: 'Thailand'),
    ],
    'indonesia': [
      (flag: '🇮🇩', city: 'Bali',     country: 'Indonesia'),
      (flag: '🇮🇩', city: 'Ubud',     country: 'Indonesia'),
      (flag: '🇮🇩', city: 'Jakarta',  country: 'Indonesia'),
      (flag: '🇮🇩', city: 'Lombok',   country: 'Indonesia'),
    ],
    'usa': [
      (flag: '🇺🇸', city: 'New York',      country: 'USA'),
      (flag: '🇺🇸', city: 'Los Angeles',   country: 'USA'),
      (flag: '🇺🇸', city: 'Miami',         country: 'USA'),
      (flag: '🇺🇸', city: 'Nashville',     country: 'USA'),
      (flag: '🇺🇸', city: 'New Orleans',   country: 'USA'),
      (flag: '🇺🇸', city: 'San Francisco', country: 'USA'),
    ],
    'uk': [
      (flag: '🇬🇧', city: 'London',    country: 'UK'),
      (flag: '🇬🇧', city: 'Edinburgh', country: 'UK'),
      (flag: '🇬🇧', city: 'Manchester',country: 'UK'),
      (flag: '🇬🇧', city: 'Bath',      country: 'UK'),
    ],
    'greece': [
      (flag: '🇬🇷', city: 'Athens',    country: 'Greece'),
      (flag: '🇬🇷', city: 'Santorini', country: 'Greece'),
      (flag: '🇬🇷', city: 'Mykonos',   country: 'Greece'),
      (flag: '🇬🇷', city: 'Crete',     country: 'Greece'),
    ],
    'portugal': [
      (flag: '🇵🇹', city: 'Lisbon',   country: 'Portugal'),
      (flag: '🇵🇹', city: 'Porto',    country: 'Portugal'),
      (flag: '🇵🇹', city: 'Algarve',  country: 'Portugal'),
      (flag: '🇵🇹', city: 'Madeira',  country: 'Portugal'),
    ],
    'croatia': [
      (flag: '🇭🇷', city: 'Dubrovnik', country: 'Croatia'),
      (flag: '🇭🇷', city: 'Split',     country: 'Croatia'),
      (flag: '🇭🇷', city: 'Hvar',      country: 'Croatia'),
      (flag: '🇭🇷', city: 'Zagreb',    country: 'Croatia'),
    ],
    'colombia': [
      (flag: '🇨🇴', city: 'Medellín',    country: 'Colombia'),
      (flag: '🇨🇴', city: 'Cartagena',   country: 'Colombia'),
      (flag: '🇨🇴', city: 'Bogotá',      country: 'Colombia'),
      (flag: '🇨🇴', city: 'Santa Marta', country: 'Colombia'),
    ],
    'uae': [
      (flag: '🇦🇪', city: 'Dubai',    country: 'UAE'),
      (flag: '🇦🇪', city: 'Abu Dhabi',country: 'UAE'),
    ],
    'turkey': [
      (flag: '🇹🇷', city: 'Istanbul',   country: 'Turkey'),
      (flag: '🇹🇷', city: 'Cappadocia', country: 'Turkey'),
      (flag: '🇹🇷', city: 'Antalya',    country: 'Turkey'),
      (flag: '🇹🇷', city: 'Bodrum',     country: 'Turkey'),
    ],
    'egypt': [
      (flag: '🇪🇬', city: 'Cairo',    country: 'Egypt'),
      (flag: '🇪🇬', city: 'Luxor',    country: 'Egypt'),
      (flag: '🇪🇬', city: 'Hurghada', country: 'Egypt'),
      (flag: '🇪🇬', city: 'Aswan',    country: 'Egypt'),
    ],
    'brazil': [
      (flag: '🇧🇷', city: 'Rio de Janeiro', country: 'Brazil'),
      (flag: '🇧🇷', city: 'São Paulo',      country: 'Brazil'),
      (flag: '🇧🇷', city: 'Salvador',       country: 'Brazil'),
      (flag: '🇧🇷', city: 'Florianópolis',  country: 'Brazil'),
    ],
    'peru': [
      (flag: '🇵🇪', city: 'Cusco',     country: 'Peru'),
      (flag: '🇵🇪', city: 'Lima',      country: 'Peru'),
      (flag: '🇵🇪', city: 'Arequipa',  country: 'Peru'),
    ],
  };

  // ── Region / continent suggestions ───────────────────────────
  // When the name references a region rather than a country, surface a
  // mix of popular cities across that region.
  static const _citiesByRegion = <String, List<({String flag, String city, String country})>>{
    'asia': [
      (flag: '🇯🇵', city: 'Tokyo',      country: 'Japan'),
      (flag: '🇹🇭', city: 'Bangkok',    country: 'Thailand'),
      (flag: '🇮🇩', city: 'Bali',       country: 'Indonesia'),
      (flag: '🇻🇳', city: 'Hanoi',      country: 'Vietnam'),
      (flag: '🇰🇷', city: 'Seoul',      country: 'South Korea'),
      (flag: '🇸🇬', city: 'Singapore',  country: 'Singapore'),
    ],
    'europe': [
      (flag: '🇵🇹', city: 'Lisbon',     country: 'Portugal'),
      (flag: '🇮🇹', city: 'Rome',       country: 'Italy'),
      (flag: '🇫🇷', city: 'Paris',      country: 'France'),
      (flag: '🇪🇸', city: 'Barcelona',  country: 'Spain'),
      (flag: '🇭🇷', city: 'Dubrovnik',  country: 'Croatia'),
      (flag: '🇬🇷', city: 'Santorini',  country: 'Greece'),
    ],
    'africa': [
      (flag: '🇲🇦', city: 'Marrakech',  country: 'Morocco'),
      (flag: '🇬🇭', city: 'Accra',      country: 'Ghana'),
      (flag: '🇰🇪', city: 'Nairobi',    country: 'Kenya'),
      (flag: '🇿🇦', city: 'Cape Town',  country: 'South Africa'),
      (flag: '🇪🇬', city: 'Cairo',      country: 'Egypt'),
    ],
    'caribbean': [
      (flag: '🇯🇲', city: 'Kingston',   country: 'Jamaica'),
      (flag: '🇧🇸', city: 'Nassau',     country: 'Bahamas'),
      (flag: '🇩🇴', city: 'Punta Cana', country: 'Dominican Republic'),
      (flag: '🇵🇷', city: 'San Juan',   country: 'Puerto Rico'),
    ],
    'south america': [
      (flag: '🇨🇴', city: 'Medellín',       country: 'Colombia'),
      (flag: '🇧🇷', city: 'Rio de Janeiro', country: 'Brazil'),
      (flag: '🇦🇷', city: 'Buenos Aires',   country: 'Argentina'),
      (flag: '🇵🇪', city: 'Cusco',          country: 'Peru'),
    ],
  };

  // Country-name aliases → canonical key in [_citiesByCountry].
  // Extends the aliases already in [_countries] with a few extras we
  // hear frequently in trip names.
  static const _countryAliases = <String, String>{
    'united states': 'usa',
    'united states of america': 'usa',
    'america': 'usa',
    'united kingdom': 'uk',
    'britain': 'uk',
    'england': 'uk',
    'scotland': 'uk',
    'wales': 'uk',
    'united arab emirates': 'uae',
    'emirates': 'uae',
  };

  /// Matched country/region for a trip name, plus the suggested cities.
  /// Returns `null` label when there's no match and the caller should
  /// fall back to [all].
  static ({String? matched, List<({String flag, String city, String country})> cities}) suggestFor(String tripName) {
    final q = tripName.toLowerCase();
    if (q.isEmpty) {
      return (matched: null, cities: all);
    }

    // 1. Check country matches first — more specific than regions.
    for (final key in _citiesByCountry.keys) {
      if (_hasToken(q, key)) {
        return (matched: _titleCase(key), cities: _citiesByCountry[key]!);
      }
    }

    // 2. Check aliases ("america" → usa).
    for (final alias in _countryAliases.keys) {
      if (_hasToken(q, alias)) {
        final canonical = _countryAliases[alias]!;
        final list = _citiesByCountry[canonical];
        if (list != null) {
          return (matched: _titleCase(canonical), cities: list);
        }
      }
    }

    // 3. Region / continent match.
    for (final key in _citiesByRegion.keys) {
      if (_hasToken(q, key)) {
        return (matched: _titleCase(key), cities: _citiesByRegion[key]!);
      }
    }

    return (matched: null, cities: all);
  }

  // Tokenises [haystack] on non-word characters and checks whether
  // [needle] appears as a whole token — so "japan" matches "japan 2026"
  // but not "japanesesushi".
  static bool _hasToken(String haystack, String needle) {
    final tokens = haystack.split(RegExp(r'[^a-z]+'))
        .where((t) => t.isNotEmpty).toList();
    // Handle multi-word needles ("south america", "united states").
    if (needle.contains(' ')) return haystack.contains(needle);
    return tokens.contains(needle);
  }

  static String _titleCase(String s) {
    return s.split(' ').map((w) =>
        w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}

class TSEmojis {
  TSEmojis._();
  static const avatars = ['😎','🌸','🔥','🌊','✨','⚡','🦋','🎯','🌙','🎨','🦊','🐬'];
}
