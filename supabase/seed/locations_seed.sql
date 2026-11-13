-- ============================================================
--  WHEELN — Starter locations (admin-curated)
--  Paste into the Supabase SQL editor and run once. Safe to re-run
--  (rows with the same slug are skipped).
--
--  NOTE: coordinates are approximate (good enough for a map pin, not for
--  navigation). Check names and positions before public launch.
--  These rows are inserted with admin_approved = true so they show in the app.
-- ============================================================

INSERT INTO public.locations
  (name, slug, type, description, city, state, latitude, longitude, admin_approved)
VALUES
  -- On-road tracks
  ('WeatherTech Raceway Laguna Seca', 'laguna-seca',       'track', 'Legendary road course with the Corkscrew.',         'Salinas',      'CA', 36.5842, -121.7536, true),
  ('Road America',                    'road-america',      'track', '4-mile road course in the Wisconsin countryside.',  'Elkhart Lake', 'WI', 43.7978,  -87.9894, true),
  ('Circuit of the Americas',         'circuit-of-americas','track','Grand-prix-level circuit outside Austin.',          'Austin',       'TX', 30.1328,  -97.6411, true),
  ('Virginia International Raceway',  'virginia-international','track','Fast, flowing road course in southern Virginia.','Alton',        'VA', 36.5686,  -79.2064, true),
  ('Watkins Glen International',      'watkins-glen',      'track', 'Historic road course in the Finger Lakes.',         'Watkins Glen', 'NY', 42.3369,  -76.9272, true),
  ('Road Atlanta',                    'road-atlanta',      'track', 'Hilly 2.5-mile road course north of Atlanta.',      'Braselton',    'GA', 34.1488,  -83.8187, true),

  -- Autocross
  ('Lincoln Airpark (Solo Nationals)', 'lincoln-airpark',  'autocross', 'Long-time home of the SCCA Solo Nationals autocross.', 'Lincoln', 'NE', 40.8500, -96.7600, true),

  -- Drag strips
  ('Bandimere Speedway',              'bandimere-speedway','drag_strip', 'Mile-high drag strip at the foot of the Rockies.', 'Morrison',   'CO', 39.6677, -105.2010, true),
  ('zMAX Dragway',                    'zmax-dragway',      'drag_strip', 'Four-lane dragway at Charlotte Motor Speedway.',      'Concord',    'NC', 35.3567,  -80.6847, true),
  ('Texas Motorplex',                 'texas-motorplex',   'drag_strip', 'Fast, well-known strip south of Dallas.',             'Ennis',      'TX', 32.3270,  -96.6540, true),
  ('Atlanta Dragway',                 'atlanta-dragway',   'drag_strip', 'Drag strip northeast of Atlanta.',                    'Commerce',   'GA', 34.1890,  -83.5670, true),
  ('Maple Grove Raceway',             'maple-grove-raceway','drag_strip','Eastern Pennsylvania drag strip.',                   'Mohnton',    'PA', 40.2750,  -76.0610, true),

  -- Off-road trails
  ('Hell''s Revenge',                 'hells-revenge',     'off_road_trail', 'Slickrock trail above Moab.',                     'Moab',       'UT', 38.5700, -109.5200, true),
  ('Rubicon Trail',                   'rubicon-trail',     'off_road_trail', 'The classic Sierra Nevada rock crawl.',           'Georgetown', 'CA', 38.9200, -120.3500, true),

  -- Off-road parks
  ('Johnson Valley OHV Area',         'johnson-valley',    'off_road_park', 'Huge open desert park, home of King of the Hammers.','Johnson Valley','CA', 34.4000, -116.5000, true),
  ('Hatfield-McCoy Trails',           'hatfield-mccoy',    'off_road_park', 'Large trail system across southern West Virginia.','Man',        'WV', 37.7000,  -81.8700, true),
  ('Rausch Creek Off-Road Park',      'rausch-creek',      'off_road_park', 'Coal-region trail park in Pennsylvania.',          'Pine Grove', 'PA', 40.5900,  -76.5500, true),
  ('Windrock Park',                   'windrock-park',     'off_road_park', 'Mountain trail park in the Tennessee hills.',      'Oliver Springs','TN', 36.0600, -84.3500, true)
ON CONFLICT (slug) DO NOTHING;

-- To check: SELECT name, type, state FROM public.locations ORDER BY type, name;
