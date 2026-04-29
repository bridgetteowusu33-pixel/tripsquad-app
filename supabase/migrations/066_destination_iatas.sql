-- v1.2 — Booking Layer (flights MVP)
-- Add airport_iata to destination_guides so Aviasales flight search
-- URLs can use 3-letter IATA codes (which the URL format requires).
-- For destinations without a guide row, the flight search falls back
-- to Google Flights with a city-name query.
--
-- Each destination gets the most-used international airport. Cities
-- with multiple major airports use the busiest IATA. (Tokyo: NRT or
-- HND — using NRT as the international default; Paris: CDG.)

ALTER TABLE public.destination_guides
  ADD COLUMN IF NOT EXISTS airport_iata text;

UPDATE public.destination_guides SET airport_iata = 'LIS' WHERE slug = 'lisbon';
UPDATE public.destination_guides SET airport_iata = 'NRT' WHERE slug = 'tokyo';
UPDATE public.destination_guides SET airport_iata = 'CDG' WHERE slug = 'paris';
UPDATE public.destination_guides SET airport_iata = 'RAK' WHERE slug = 'marrakech';
UPDATE public.destination_guides SET airport_iata = 'MEX' WHERE slug = 'mexico-city';
UPDATE public.destination_guides SET airport_iata = 'CPT' WHERE slug = 'cape-town';
UPDATE public.destination_guides SET airport_iata = 'MDE' WHERE slug = 'medellin';
