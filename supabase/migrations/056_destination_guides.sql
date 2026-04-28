-- v1.1 — Stays + Eats, step 1 of 3
-- destination_guides: curated ground-truth content for top destinations.
-- Used as seed context by generate_recommendations so Scout doesn't
-- hallucinate hotels in cities we have first-hand opinions on.
--
-- Source: web/src/data/destinations.ts (the public site's destination
-- pages). Keep these in lockstep — when we add a new destination on the
-- web, copy the row in here too. (Future: a build step that diffs
-- web/src/data/destinations.ts against this table.)

CREATE TABLE IF NOT EXISTS public.destination_guides (
  slug          text PRIMARY KEY,
  name          text NOT NULL,
  country       text NOT NULL,
  flag          text,
  vibe          text,
  best_time     text,
  ideal_length  text,
  hero          text,
  scout_take    text,
  things_to_do  jsonb DEFAULT '[]'::jsonb,    -- [{ title, body }]
  itinerary_seed jsonb DEFAULT '[]'::jsonb,   -- [{ day, title, items[] }]
  stay_where    jsonb DEFAULT '[]'::jsonb,    -- [{ area, body }] — area picks
  flight_hint   text,
  aliases       text[] DEFAULT '{}',          -- ['lisbon, portugal', 'lisboa', ...] for fuzzy lookup
  updated_at    timestamptz DEFAULT now()
);

ALTER TABLE public.destination_guides ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can read. Writes only via service_role
-- (no policy = denied for anon/authenticated).
CREATE POLICY "destination_guides readable by authenticated"
  ON public.destination_guides FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- ─── Seed data ─────────────────────────────────────────────────
-- Mirrors web/src/data/destinations.ts. Keep updated.

INSERT INTO public.destination_guides
  (slug, name, country, flag, vibe, best_time, ideal_length, hero, scout_take, things_to_do, itinerary_seed, stay_where, flight_hint, aliases)
VALUES
  (
    'lisbon', 'Lisbon', 'Portugal', '🇵🇹',
    'food, culture, golden hour',
    'May, September–October',
    '4–6 days',
    'shoulder-season warmth, world-class food, beach 30 min away. the squad''s first trip, basically.',
    'lisbon is the trip you can pitch to anyone. the food crowd gets time out market and alfama tascas. the museum crowd gets the gulbenkian and the tile museum. the beach crowd gets cascais. the slow crowd gets a miradouro at sunset. nobody loses. october is the sweet spot — warm enough, no crowds, prices haven''t spiked.',
    $$[
      {"title":"time out market","body":"the food court that legitimized food courts. start at sea me, end at manteigaria."},
      {"title":"alfama wander","body":"the oldest neighborhood. tiles, fado bars, a tram that climbs the hill. tascas the squad can split."},
      {"title":"miradouro da senhora do monte","body":"sunset spot the locals haven't given up on yet. bring a beer."},
      {"title":"tile museum","body":"national tile museum. one room is a 25-meter view of pre-earthquake lisbon, all in azulejo."},
      {"title":"cascais day trip","body":"30 min on the train. proper beach, proper seafood. easy half-day."},
      {"title":"sintra","body":"palaces and forest. closer to a fairytale than you'd expect. plan a full day, ride-share recommended."}
    ]$$::jsonb,
    $$[
      {"day":"day 1","title":"arrival + alfama","items":["15:00 — settle in, snack at fábrica","17:30 — alfama wander (downhill from castelo)","20:00 — taberna da rua das flores (book ahead)","22:00 — fado at clube de fado"]},
      {"day":"day 2","title":"food crawl","items":["10:30 — coffee at fábrica","12:30 — time out market","15:00 — national tile museum","17:30 — sunset at miradouro da senhora do monte","20:00 — dinner, taberna da rua das flores"]},
      {"day":"day 3","title":"sintra","items":["09:00 — uber to sintra","10:30 — pena palace","13:00 — lunch in sintra centro","15:00 — quinta da regaleira (the gardens)","18:00 — back to lisbon, easy dinner"]}
    ]$$::jsonb,
    $$[
      {"area":"alfama","body":"oldest, most atmospheric. cobblestones and hills — pack good shoes. closest to the sights."},
      {"area":"chiado","body":"central, walkable, great for first-timers. food and shopping."},
      {"area":"príncipe real","body":"quieter, residential, design-y. cafés and the squad will love the slower pace."}
    ]$$::jsonb,
    'most us east coast cities have a direct on tap portugal or united.',
    ARRAY['lisbon', 'lisbon, portugal', 'lisboa']
  ),
  (
    'tokyo', 'Tokyo', 'Japan', '🇯🇵',
    'city energy, food precision, late nights',
    'late March (cherry blossom), October–November',
    '6–8 days',
    'the most rewarded city for being curious. the squad will eat better than they ever have.',
    'tokyo rewards walking and noticing. the city doesn''t perform for tourists — it just lets you in if you pay attention. budget more days than you think (six minimum). pair tokyo with a few days in kyoto and one in osaka if the squad can swing it. fall is the underrated season; spring is the crowded one.',
    $$[
      {"title":"shimokitazawa wander","body":"thrift shops, vinyl, coffee, no rush. saturday afternoon material."},
      {"title":"tsukiji outer market","body":"breakfast on the move. tamago, sushi, mochi. arrive hungry."},
      {"title":"meiji shrine + harajuku","body":"the calmest forest in tokyo, then the loudest street. one block apart."},
      {"title":"shinjuku at night","body":"omoide yokocho for skewers, golden gai for tiny bars (some refuse tourists, that's okay)."},
      {"title":"team lab planets","body":"an art experience, not an exhibit. book ahead. wear shorts you can roll up."},
      {"title":"day trip: kamakura or hakone","body":"1 hr by train. great escape day if the city is too much."}
    ]$$::jsonb,
    $$[
      {"day":"day 1","title":"arrival + shibuya","items":["15:00 — drop bags, lunch at ichiran","17:30 — shibuya scramble + golden hour","20:00 — yakitori in nonbei yokocho"]},
      {"day":"day 2","title":"old tokyo","items":["09:00 — tsukiji outer market breakfast","11:00 — senso-ji + asakusa wander","14:00 — boat to hamarikyu gardens","18:00 — dinner in ginza"]},
      {"day":"day 3","title":"harajuku → shinjuku","items":["10:00 — meiji shrine","12:00 — harajuku takeshita street","14:00 — omotesando (calmer, design-y)","19:00 — golden gai for the squad's nightcap"]}
    ]$$::jsonb,
    $$[
      {"area":"shibuya / shinjuku","body":"central, energetic, easy transit. most squad-friendly first-timer pick."},
      {"area":"ebisu / nakameguro","body":"quieter, design-forward, great food. for slower-paced trips."},
      {"area":"asakusa","body":"old tokyo, cheaper, more atmospheric. transit takes a beat longer."}
    ]$$::jsonb,
    'jal and ana are the gold standard. nrt → city center, 60–90 min via narita express or skyliner.',
    ARRAY['tokyo', 'tokyo, japan']
  ),
  (
    'paris', 'Paris', 'France', '🇫🇷',
    'classic, romantic, café culture',
    'May–June, September',
    '4–5 days',
    'yes, the cliché. and yes, it earns it — if you treat it like a city, not a checklist.',
    'paris is best when the squad doesn''t try to do paris. skip the eiffel-louvre-arc march and just live in a neighborhood. the marais for one trip, saint-germain for another. eat lunch at the same café twice. the city opens up when you stop performing tourism.',
    $$[
      {"title":"breakfast at a corner café","body":"pick one, return daily. the squad will notice the difference."},
      {"title":"musée d'orsay","body":"better than the louvre for a first visit. impressionists, perfect size, no overwhelm."},
      {"title":"canal saint-martin picnic","body":"wine, bread, cheese from monoprix. sit by the water. that's the day."},
      {"title":"le marais wander","body":"falafel at l'as du fallafel, then no plan. let the squad discover shops."},
      {"title":"shakespeare and company","body":"the bookstore, yes. but also the upstairs is free, and the typewriters are real."},
      {"title":"sunset at sacré-cœur","body":"climb the steps. the view is the point. bring a sweater."}
    ]$$::jsonb,
    $$[
      {"day":"day 1","title":"arrival + marais","items":["14:00 — drop bags, lunch at le mary celeste","16:30 — marais wander","20:00 — dinner at chez janou"]},
      {"day":"day 2","title":"left bank","items":["10:00 — coffee at café de flore (yes, touristy, do it once)","11:30 — musée d'orsay","14:30 — lunch at le bon saint pourçain","16:30 — luxembourg gardens","20:00 — dinner at clamato"]},
      {"day":"day 3","title":"montmartre + canal","items":["11:00 — sacré-cœur (early, before crowds)","13:00 — lunch at le coq rico","16:00 — canal saint-martin picnic","20:00 — dinner at le servan"]}
    ]$$::jsonb,
    $$[
      {"area":"le marais (3rd / 4th)","body":"central, walkable, great food. squad-friendly, lots to do without metro-ing."},
      {"area":"saint-germain (6th)","body":"classic paris, cafés on every corner, slightly pricier."},
      {"area":"canal saint-martin (10th)","body":"younger crowd, cheaper, more local. less central but better priced."}
    ]$$::jsonb,
    'cdg or orly. cdg is bigger but easier if you have lots of bags. rer b train into the city, ~45 min.',
    ARRAY['paris', 'paris, france']
  ),
  (
    'marrakech', 'Marrakech', 'Morocco', '🇲🇦',
    'souks, riads, atlas mountains',
    'October–April (avoid July–August)',
    '4–6 days',
    'the medina at night feels like another century. mint tea on a rooftop, dye-vats and spice piles, atlas turning pink at sunset.',
    'marrakech rewards a squad that wants both energy and stillness. spend mornings getting lost in the souks, afternoons by a riad pool, evenings on a rooftop with a view of the koutoubia. one night in the agafay desert (it''s the moon, an hour out) makes the trip. october and april are the sweet spots — warm but not blistering. don''t try to see everything; the magic is in slowing down.',
    $$[
      {"title":"jemaa el-fna at dusk","body":"the main square transforms at sunset — food stalls, snake charmers, music. order tagine + mint tea, watch."},
      {"title":"souks of the medina","body":"spices, leather, lanterns. haggle politely (start at half their price). get lost on purpose."},
      {"title":"jardin majorelle","body":"ysl bought it. cobalt-blue walls, cactus garden. book ahead — fills up."},
      {"title":"cooking class at dar les cigognes","body":"morning at the spice market, afternoon making tagine. group activity that actually delivers."},
      {"title":"overnight in agafay desert","body":"an hour from the city. camel ride at sunset, dinner under the stars in a luxury camp. one night is enough."},
      {"title":"hammam","body":"the squad will not stop talking about it. les bains de marrakech for first-timers."}
    ]$$::jsonb,
    $$[
      {"day":"day 1","title":"arrival + medina","items":["15:00 — settle into the riad, mint tea on the roof","17:30 — slow walk into the medina, get lost intentionally","20:00 — dinner at nomad (rooftop, modern moroccan)","22:00 — jemaa el-fna at full chaos"]},
      {"day":"day 2","title":"cooking class + souks","items":["09:00 — spice market visit + cooking class","14:00 — lunch (what you cooked)","16:00 — souks for shopping, riads break","20:00 — dinner at le jardin (open courtyard)"]},
      {"day":"day 3","title":"agafay desert","items":["14:00 — depart for agafay (~1 hr drive)","16:00 — camel ride at golden hour","19:00 — dinner under the stars","overnight in luxury desert camp"]},
      {"day":"day 4","title":"jardin majorelle + hammam","items":["09:00 — back to marrakech","11:00 — jardin majorelle + ysl museum","15:00 — group hammam (book ahead)","20:00 — dinner at dar yacout (set menu, full ceremony)"]}
    ]$$::jsonb,
    $$[
      {"area":"medina (riads)","body":"old city, a riad is non-negotiable. dar les cigognes and riad kniza are squad-sized and stunning."},
      {"area":"gueliz","body":"newer, more 'european.' cafés, art galleries. easier if you want a hotel rather than a riad."},
      {"area":"palmeraie (outside the city)","body":"resort vibe, palm groves, big pools. for a squad who wants to lounge."}
    ]$$::jsonb,
    'most us east coast routes are one-stop via paris, london, or madrid. ras nas (rak) airport is small but easy.',
    ARRAY['marrakech', 'marrakech, morocco', 'marrakesh']
  ),
  (
    'mexico-city', 'Mexico City', 'Mexico', '🇲🇽',
    'food, art, neighborhoods that feel like cities of their own',
    'March–May, October–November',
    '4–7 days',
    'the food capital of the americas. roma norte for cafés, condesa for parks, centro for history. cheap, beautiful, alive.',
    'cdmx might be the best food city in the world right now. don''t waste meals on tourist places — every neighborhood has a contramar-or-pujol-tier spot. budget the squad ~$60/day for great eating, less if you stick to taquerías and street food (which you should). october–november is the sweet spot weather-wise. one trip is not enough; go knowing you''ll come back.',
    $$[
      {"title":"taquería el califa de león","body":"first taco stand to get a michelin star. one taco. line moves fast. do it."},
      {"title":"museo nacional de antropología","body":"world-class. budget 3 hours. the aztec sun stone alone is worth the trip."},
      {"title":"frida kahlo museum (casa azul)","body":"her house in coyoacán. small but transporting. book online ahead."},
      {"title":"sunday in chapultepec","body":"the city park is enormous. families everywhere. food carts. rent boats on the lake. nothing planned is the plan."},
      {"title":"lucha libre at arena méxico","body":"fri or sun nights. mask sellers outside, beer inside, the whole crowd shouting. the squad will love it."},
      {"title":"xochimilco trajineras","body":"colorful boats on the canals. mariachi for hire. byob and snacks. sunday afternoon, all-day plans."}
    ]$$::jsonb,
    $$[
      {"day":"day 1","title":"roma norte arrival","items":["14:00 — settle in roma norte airbnb","16:00 — coffee at panadería rosetta","18:00 — neighborhood walk, plaza río de janeiro","20:30 — dinner at contramar (book weeks ahead)"]},
      {"day":"day 2","title":"centro + taco crawl","items":["10:00 — zócalo + metropolitan cathedral","12:00 — palacio de bellas artes","14:00 — taquería el califa de león (the michelin one)","17:00 — torre latinoamericana for sunset views","20:00 — dinner at azul histórico"]},
      {"day":"day 3","title":"coyoacán + frida","items":["10:00 — uber to coyoacán","11:00 — casa azul (book online)","13:00 — lunch at corazón de maguey","15:00 — wander the coyoacán market","19:00 — back to roma, dinner at máximo bistrot"]},
      {"day":"day 4","title":"xochimilco","items":["11:00 — uber to xochimilco (~45 min)","12:00 — board a trajinera (4-6 hrs, byob)","17:00 — back to the city, easy taqueria dinner"]}
    ]$$::jsonb,
    $$[
      {"area":"roma norte","body":"the squad pick. cafés, restaurants, parks, walkable. mid-range airbnbs are great."},
      {"area":"condesa","body":"next to roma, leafier, more residential. parque méxico is gorgeous."},
      {"area":"polanco","body":"fancier, more hotel-style. great for a high-end stay or a business-y mood."}
    ]$$::jsonb,
    'mex airport is huge. uber works smoothly from there. ~45 min into roma norte (no traffic). 5–6 hr direct from us east coast.',
    ARRAY['mexico city', 'mexico city, mexico', 'cdmx', 'ciudad de méxico', 'mexico']
  ),
  (
    'cape-town', 'Cape Town', 'South Africa', '🇿🇦',
    'mountain + ocean + wine country, all in 30 min',
    'November–March (their summer)',
    '6–10 days',
    'table mountain on one side, atlantic on the other, wine country an hour out. one of the most photogenic cities on earth.',
    'cape town is unreasonable in how much it has. you can hike a mountain in the morning, swim in the ocean by lunch, drink syrah in stellenbosch by sunset. budget extra days for the cape peninsula drive — chapman''s peak, boulders beach (penguins), cape point. add 2 days for safari nearby (kruger if you have time, sanbona is closer). dollars go far here. november–march is summer; april and october are also great.',
    $$[
      {"title":"table mountain","body":"cable car up, hike down (or the reverse). go early, weather can shut the cable car. allow 4 hours."},
      {"title":"cape peninsula drive","body":"full-day loop: chapman's peak drive, boulders beach (penguins!), cape point lighthouse. rent a car."},
      {"title":"stellenbosch + franschhoek","body":"wine country. franschhoek wine tram is the squad-friendly way (hop-on hop-off through estates)."},
      {"title":"bo-kaap walking tour","body":"pastel houses, malay-cape culture, food. the colorful streets are a real neighborhood, not a set."},
      {"title":"v&a waterfront","body":"touristy but well-done. food market, harbor, sunset cocktails. easy first-night dinner spot."},
      {"title":"two oceans aquarium","body":"small but well-curated. great rainy-day backup. the squad will linger at the predator tank."}
    ]$$::jsonb,
    $$[
      {"day":"day 1","title":"arrival + waterfront","items":["15:00 — settle in (sea point or v&a area)","17:30 — sunset at signal hill (uber up)","20:00 — dinner at the test kitchen fledglings"]},
      {"day":"day 2","title":"table mountain","items":["08:00 — early breakfast (weather is best in the morning)","09:00 — cable car up table mountain","13:00 — lunch at kloof street house","16:00 — bo-kaap walking tour","20:00 — dinner at chefs warehouse"]},
      {"day":"day 3","title":"cape peninsula","items":["09:00 — pick up rental car","10:00 — chapman's peak drive","12:00 — boulders beach for the penguins","14:00 — cape point + lunch","17:00 — back via simon's town for sunset"]},
      {"day":"day 4","title":"wine country","items":["10:00 — drive to franschhoek (~1 hr)","11:00 — board the wine tram (full day)","17:00 — dinner at one of the estate restaurants","21:00 — driver back to the city (don't drive after wine)"]}
    ]$$::jsonb,
    $$[
      {"area":"sea point","body":"beachfront promenade, walkable, less touristy than v&a. the squad will love the morning runs."},
      {"area":"de waterkant / bo-kaap edge","body":"central, charming, walking distance to the v&a and city center."},
      {"area":"camps bay","body":"iconic beach. fancier hotels. uber to everything else but the beach is right there."}
    ]$$::jsonb,
    'no direct from us. one-stop via doha (qatar), addis (ethiopian), or london. ~18-22 hours total. worth it.',
    ARRAY['cape town', 'cape town, south africa', 'capetown']
  ),
  (
    'medellin', 'Medellín', 'Colombia', '🇨🇴',
    'city of eternal spring, design-forward, easy to love',
    'December–March, June–August',
    '4–6 days',
    'perfect weather year-round, killer coffee, comuna 13 street art, and your dollar goes way further than you''d expect.',
    'medellín is the easy-mode latin america trip. weather is ~75°F every single day. the metro is clean and the cable cars give you mountain views for $1. comuna 13 is mandatory (book a guided walking tour — the history matters). el poblado is where the squad will stay; laureles is where you''ll wish you stayed. coffee farms an hour out are a perfect day trip. december–march for the driest weather.',
    $$[
      {"title":"comuna 13 walking tour","body":"colorful murals on what was once one of the most dangerous neighborhoods. take a guide — the story makes it."},
      {"title":"plaza botero","body":"23 botero sculptures in one downtown plaza. free, weird, photogenic."},
      {"title":"cable car to parque arví","body":"metro + cable car combo. 30 min ride over the city, ends in a forest park. ~$1.50."},
      {"title":"guatapé day trip","body":"colorful village + el peñol rock (740 steps to the top, worth it). ~2 hrs out."},
      {"title":"coffee farm tour","body":"jardín or salento area. learn the bean-to-cup. one of the most underrated colombia experiences."},
      {"title":"salsa lessons in zona rosa","body":"el poblado nightlife. son havana for the real-deal salsa night."}
    ]$$::jsonb,
    $$[
      {"day":"day 1","title":"arrival + el poblado","items":["15:00 — settle in el poblado","17:00 — coffee at pergamino","19:00 — dinner at carmen (modern colombian)","21:00 — drinks in parque lleras"]},
      {"day":"day 2","title":"comuna 13 + downtown","items":["09:00 — comuna 13 guided walking tour","13:00 — lunch at mondongo (try the soup)","15:00 — plaza botero + museo de antioquia","17:00 — metro back, sunset at envigado"]},
      {"day":"day 3","title":"guatapé","items":["08:00 — depart for guatapé (~2 hr drive or tour)","11:00 — climb el peñol rock (740 steps)","13:00 — lunch in guatapé village","15:00 — boat ride on the reservoir","19:00 — back to medellín for dinner"]},
      {"day":"day 4","title":"coffee + arví","items":["09:00 — half-day coffee farm tour (book ahead)","14:00 — back to the city, lunch","15:00 — metro + cable car to parque arví","20:00 — dinner at oci.mde"]}
    ]$$::jsonb,
    $$[
      {"area":"el poblado","body":"where most travelers stay. cafés, restaurants, nightlife. safest, most polished."},
      {"area":"laureles","body":"more local, leafier, slightly cheaper. squad-friendly if you want neighborhood vibes over tourist polish."},
      {"area":"envigado","body":"south of el poblado. residential, quiet, great food. uber to everything."}
    ]$$::jsonb,
    'mde airport, ~45 min from el poblado. 4–6 hr direct from miami, jfk, lax. avianca and copa fly frequently.',
    ARRAY['medellin', 'medellín', 'medellin, colombia', 'medellín, colombia']
  )
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name, country = EXCLUDED.country, flag = EXCLUDED.flag,
  vibe = EXCLUDED.vibe, best_time = EXCLUDED.best_time,
  ideal_length = EXCLUDED.ideal_length, hero = EXCLUDED.hero,
  scout_take = EXCLUDED.scout_take, things_to_do = EXCLUDED.things_to_do,
  itinerary_seed = EXCLUDED.itinerary_seed, stay_where = EXCLUDED.stay_where,
  flight_hint = EXCLUDED.flight_hint, aliases = EXCLUDED.aliases,
  updated_at = now();
