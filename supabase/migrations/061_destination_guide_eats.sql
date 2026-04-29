-- v1.1 — Destination Hub: backfill empty hotel/restaurant tabs with
-- curated content from destination_guides.
--
-- The hotels tab already has good data via the existing `stay_where`
-- column (areas to stay). We surface those in DestinationHubScreen.
-- For restaurants, we add `curated_eats` — a hand-curated list of
-- well-known restaurants per destination, drawn from the same
-- editorial knowledge that powers the web destination pages.

ALTER TABLE public.destination_guides
  ADD COLUMN IF NOT EXISTS curated_eats jsonb DEFAULT '[]'::jsonb;
  -- shape: [{ "name": "...", "neighborhood": "...", "cuisine": "...",
  --          "price_band": "$$" | "$$$", "note": "..." }]

UPDATE public.destination_guides
SET curated_eats = $eats$[
  {"name":"Taberna da Rua das Flores","neighborhood":"Chiado","cuisine":"Portuguese","price_band":"$$","note":"book ahead — the squad will want this one twice"},
  {"name":"Time Out Market","neighborhood":"Cais do Sodré","cuisine":"food hall","price_band":"$$","note":"start at Sea Me, end at Manteigaria"},
  {"name":"Manteigaria","neighborhood":"Chiado","cuisine":"pastéis de nata","price_band":"$","note":"the warm-out-of-the-oven moment is the point"},
  {"name":"Clube de Fado","neighborhood":"Alfama","cuisine":"Portuguese · fado","price_band":"$$$","note":"dinner + live fado, atmospheric"},
  {"name":"Fábrica Coffee Roasters","neighborhood":"various","cuisine":"specialty coffee","price_band":"$","note":"lisbon's best espresso, pick the closest location"}
]$eats$::jsonb
WHERE slug = 'lisbon';

UPDATE public.destination_guides
SET curated_eats = $eats$[
  {"name":"Ichiran Ramen","neighborhood":"Shibuya / various","cuisine":"tonkotsu ramen","price_band":"$$","note":"the focus-booth experience is half the meal"},
  {"name":"Tsukiji Outer Market","neighborhood":"Tsukiji","cuisine":"sushi · street food","price_band":"$$","note":"breakfast move — tamago, sushi, mochi as you walk"},
  {"name":"Omoide Yokocho","neighborhood":"Shinjuku","cuisine":"yakitori","price_band":"$$","note":"smoky alley of skewers — the squad shot of tokyo"},
  {"name":"Golden Gai","neighborhood":"Shinjuku","cuisine":"tiny bars","price_band":"$$","note":"6-seat bars, some refuse tourists, that's part of the deal"},
  {"name":"Nonbei Yokocho","neighborhood":"Shibuya","cuisine":"yakitori · drinks","price_band":"$$","note":"more relaxed than golden gai, easier first night"}
]$eats$::jsonb
WHERE slug = 'tokyo';

UPDATE public.destination_guides
SET curated_eats = $eats$[
  {"name":"Le Mary Celeste","neighborhood":"Le Marais","cuisine":"natural wine · small plates","price_band":"$$","note":"easy first-day lunch, cocktails after"},
  {"name":"Chez Janou","neighborhood":"Le Marais","cuisine":"Provençal","price_band":"$$","note":"the chocolate mousse is the squad's group photo"},
  {"name":"Café de Flore","neighborhood":"Saint-Germain","cuisine":"café classics","price_band":"$$","note":"yes, touristy. yes, do it once. coffee at the bar is half price."},
  {"name":"Clamato","neighborhood":"11th","cuisine":"seafood","price_band":"$$$","note":"no reservations — go early or go late"},
  {"name":"Le Servan","neighborhood":"11th","cuisine":"modern bistro","price_band":"$$$","note":"the dish to order: whatever the chalkboard says"},
  {"name":"L'As du Fallafel","neighborhood":"Le Marais","cuisine":"falafel","price_band":"$","note":"long line moves fast, takeout works, eat walking"}
]$eats$::jsonb
WHERE slug = 'paris';

UPDATE public.destination_guides
SET curated_eats = $eats$[
  {"name":"Nomad","neighborhood":"Medina","cuisine":"modern Moroccan","price_band":"$$","note":"rooftop with a view of the spice market — first-night easy"},
  {"name":"Le Jardin","neighborhood":"Medina","cuisine":"Moroccan · garden","price_band":"$$","note":"open courtyard, slow dinner, the squad will linger"},
  {"name":"Dar Yacout","neighborhood":"Medina","cuisine":"set-menu Moroccan","price_band":"$$$","note":"the full ceremony — multi-course, music, the works"},
  {"name":"Café Clock","neighborhood":"Kasbah","cuisine":"camel burger · café","price_band":"$","note":"ironic squad-meal, but the storytelling night is unironically great"},
  {"name":"Mint","neighborhood":"Medina","cuisine":"rooftop tea","price_band":"$","note":"late-afternoon mint tea + sunset over the koutoubia"}
]$eats$::jsonb
WHERE slug = 'marrakech';

UPDATE public.destination_guides
SET curated_eats = $eats$[
  {"name":"Contramar","neighborhood":"Roma Norte","cuisine":"seafood","price_band":"$$$","note":"book weeks ahead — tuna tostadas live up to the hype"},
  {"name":"Pujol","neighborhood":"Polanco","cuisine":"modern Mexican","price_band":"$$$$","note":"taco omakase tasting — the special-occasion squad meal"},
  {"name":"Panadería Rosetta","neighborhood":"Roma Norte","cuisine":"bakery · café","price_band":"$","note":"morning move — the guava roll is the order"},
  {"name":"Taquería el Califa de León","neighborhood":"San Rafael","cuisine":"tacos","price_band":"$","note":"the michelin-starred taco stand, line moves fast, do it"},
  {"name":"Azul Histórico","neighborhood":"Centro","cuisine":"regional Mexican","price_band":"$$","note":"courtyard inside a colonial building, slow lunch energy"},
  {"name":"Corazón de Maguey","neighborhood":"Coyoacán","cuisine":"mezcal · regional","price_band":"$$","note":"after casa azul, pre-frida-museum lunch ritual"},
  {"name":"Máximo Bistrot","neighborhood":"Roma Norte","cuisine":"contemporary","price_band":"$$$","note":"squad-dinner spot when you want something quieter than contramar"}
]$eats$::jsonb
WHERE slug = 'mexico-city';

UPDATE public.destination_guides
SET curated_eats = $eats$[
  {"name":"The Test Kitchen Fledglings","neighborhood":"Woodstock","cuisine":"contemporary tasting","price_band":"$$$$","note":"hard to book, worth the planning. arrival-night statement meal."},
  {"name":"Kloof Street House","neighborhood":"Gardens","cuisine":"South African contemporary","price_band":"$$$","note":"after table mountain — the porch and the ribeye"},
  {"name":"Chefs Warehouse","neighborhood":"Bree Street","cuisine":"tapas","price_band":"$$$","note":"no reservations. arrive early or be the squad that drinks first."},
  {"name":"V&A Food Market","neighborhood":"V&A Waterfront","cuisine":"food hall","price_band":"$$","note":"easy first-night when nobody wants to commit. samples + sundowners."},
  {"name":"Mzansi Restaurant","neighborhood":"Langa","cuisine":"township Xhosa","price_band":"$$","note":"book the dinner show — the trip you'll actually talk about back home"}
]$eats$::jsonb
WHERE slug = 'cape-town';

UPDATE public.destination_guides
SET curated_eats = $eats$[
  {"name":"Carmen","neighborhood":"El Poblado","cuisine":"modern Colombian","price_band":"$$$","note":"first-night squad dinner — design-forward, photogenic, the bandeja paisa upgraded"},
  {"name":"Pergamino","neighborhood":"El Poblado","cuisine":"specialty coffee","price_band":"$","note":"the morning ritual — try the cold brew tonic"},
  {"name":"Mondongo","neighborhood":"El Poblado / Laureles","cuisine":"traditional Colombian","price_band":"$$","note":"order the mondongo soup. yes really. do it."},
  {"name":"Oci.mde","neighborhood":"El Poblado","cuisine":"contemporary","price_band":"$$$","note":"chef-driven tasting moments without the pretense"},
  {"name":"Cuartocrudo","neighborhood":"El Poblado","cuisine":"sushi · ceviche","price_band":"$$","note":"surprise hit — colombian seafood meets japan"}
]$eats$::jsonb
WHERE slug = 'medellin';
