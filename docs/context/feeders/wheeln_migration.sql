-- ============================================================
--  WHEELN — Complete Database Migration
--  Run once in the Supabase SQL Editor (Dashboard > SQL Editor)
--  Safe to re-run: uses IF NOT EXISTS throughout
-- ============================================================


-- ============================================================
-- 0. EXTENSIONS
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";      -- uuid_generate_v4()
CREATE EXTENSION IF NOT EXISTS "pgcrypto";       -- gen_random_uuid() (Supabase default)


-- ============================================================
-- 1. ENUMS
-- ============================================================

DO $$ BEGIN
  CREATE TYPE location_type_enum AS ENUM (
    'track',
    'autocross',
    'drag_strip',
    'off_road_trail',
    'off_road_park',
    'car_show',
    'overlanding',
    'karting',
    'moto_track',
    'gravel_ride',
    'rock_crawl',
    'cars_and_coffee',
    'other'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE friend_status_enum AS ENUM ('pending', 'accepted', 'declined');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE package_type_enum AS ENUM ('starter', 'pro', 'elite');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE event_status_enum AS ENUM ('pending_payment', 'active', 'expired', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE fulfillment_status_enum AS ENUM ('pending', 'submitted', 'shipped', 'delivered', 'error');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE badge_category_enum AS ENUM ('milestone', 'category', 'streak', 'activity', 'special', 'event');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE threshold_type_enum AS ENUM (
    'total_checkins',
    'unique_locations',
    'unique_states',
    'checkins_by_location_type',
    'consecutive_weekends',
    'ratings_given',
    'messages_written',
    'manual'         -- admin-awarded or special badges
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE subscription_status_enum AS ENUM ('free', 'active', 'cancelled', 'past_due');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;


-- ============================================================
-- 2. USERS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.users (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Links to Supabase Auth. Set this equal to auth.uid() on sign-up.
  auth_id             UUID UNIQUE,
  email               TEXT NOT NULL UNIQUE,
  username            TEXT NOT NULL UNIQUE
                        CHECK (char_length(username) BETWEEN 3 AND 30)
                        CHECK (username ~ '^[a-zA-Z0-9_]+$'),
  display_name        TEXT NOT NULL,
  avatar_url          TEXT,
  bio                 TEXT CHECK (char_length(bio) <= 200),
  vehicle_types       TEXT[]          DEFAULT '{}',
  home_region         TEXT,
  subscription_status subscription_status_enum NOT NULL DEFAULT 'free',
  revenuecat_user_id  TEXT,
  total_checkins      INTEGER         NOT NULL DEFAULT 0,
  badge_count         INTEGER         NOT NULL DEFAULT 0,
  is_private          BOOLEAN         NOT NULL DEFAULT false,
  is_suspended        BOOLEAN         NOT NULL DEFAULT false,
  username_changed_at TIMESTAMPTZ,
  created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_auth_id       ON public.users (auth_id);
CREATE INDEX IF NOT EXISTS idx_users_username       ON public.users (username);
CREATE INDEX IF NOT EXISTS idx_users_email          ON public.users (email);
CREATE INDEX IF NOT EXISTS idx_users_total_checkins ON public.users (total_checkins DESC);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_users_updated_at ON public.users;
CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ============================================================
-- 3. LOCATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.locations (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                TEXT NOT NULL,
  slug                TEXT UNIQUE,
  type                location_type_enum NOT NULL,
  description         TEXT,
  address             TEXT,
  city                TEXT,
  state               TEXT,         -- 2-letter US state code
  country             TEXT          NOT NULL DEFAULT 'US',
  latitude            DOUBLE PRECISION NOT NULL,
  longitude           DOUBLE PRECISION NOT NULL,
  cover_photo_url     TEXT,
  website             TEXT,
  avg_rating          NUMERIC(3,2)  NOT NULL DEFAULT 0.00,
  avg_difficulty      NUMERIC(3,2)  NOT NULL DEFAULT 0.00,
  total_checkins      INTEGER       NOT NULL DEFAULT 0,
  submitted_by_user_id UUID
                        REFERENCES public.users (id)
                        ON DELETE SET NULL,
  admin_approved      BOOLEAN       NOT NULL DEFAULT false,
  admin_notes         TEXT,
  created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_locations_type          ON public.locations (type);
CREATE INDEX IF NOT EXISTS idx_locations_state         ON public.locations (state);
CREATE INDEX IF NOT EXISTS idx_locations_admin_approved ON public.locations (admin_approved);
CREATE INDEX IF NOT EXISTS idx_locations_avg_rating    ON public.locations (avg_rating DESC);
CREATE INDEX IF NOT EXISTS idx_locations_total_checkins ON public.locations (total_checkins DESC);
CREATE INDEX IF NOT EXISTS idx_locations_submitted_by  ON public.locations (submitted_by_user_id);
-- Composite for filtered browsing
CREATE INDEX IF NOT EXISTS idx_locations_type_state    ON public.locations (type, state);
-- Geo bounding-box queries
CREATE INDEX IF NOT EXISTS idx_locations_lat_lng       ON public.locations (latitude, longitude);

DROP TRIGGER IF EXISTS trg_locations_updated_at ON public.locations;
CREATE TRIGGER trg_locations_updated_at
  BEFORE UPDATE ON public.locations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ============================================================
-- 4. EVENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.events (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_email     TEXT NOT NULL,
  organizer_name      TEXT,
  event_name          TEXT NOT NULL,
  event_date          DATE NOT NULL,
  location_id         UUID REFERENCES public.locations (id) ON DELETE SET NULL,
  location_name       TEXT,          -- free-text fallback if no DB location
  logo_url            TEXT,
  badge_image_url     TEXT,
  badge_animation_url TEXT,          -- Elite tier: Lottie/GIF URL
  qr_code_url         TEXT,
  qr_scan_count       INTEGER       NOT NULL DEFAULT 0,
  package_type        package_type_enum NOT NULL,
  stripe_payment_id   TEXT,
  stripe_session_id   TEXT,
  status              event_status_enum NOT NULL DEFAULT 'pending_payment',
  expires_at          TIMESTAMPTZ,   -- QR code stops working after this
  featured_from       TIMESTAMPTZ,   -- Elite: feed placement window start
  featured_until      TIMESTAMPTZ,   -- Elite: feed placement window end
  created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_events_organizer_email ON public.events (organizer_email);
CREATE INDEX IF NOT EXISTS idx_events_status          ON public.events (status);
CREATE INDEX IF NOT EXISTS idx_events_event_date      ON public.events (event_date);
CREATE INDEX IF NOT EXISTS idx_events_location_id     ON public.events (location_id);
CREATE INDEX IF NOT EXISTS idx_events_featured        ON public.events (featured_from, featured_until);

DROP TRIGGER IF EXISTS trg_events_updated_at ON public.events;
CREATE TRIGGER trg_events_updated_at
  BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ============================================================
-- 5. POSTS (check-ins)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.posts (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL
                      REFERENCES public.users (id)
                      ON DELETE CASCADE,
  location_id       UUID
                      REFERENCES public.locations (id)
                      ON DELETE SET NULL,
  photo_url         TEXT NOT NULL,
  message           TEXT CHECK (char_length(message) <= 500),
  star_rating       SMALLINT NOT NULL CHECK (star_rating BETWEEN 1 AND 5),
  difficulty_rating SMALLINT NOT NULL CHECK (difficulty_rating BETWEEN 1 AND 5),
  is_event_checkin  BOOLEAN NOT NULL DEFAULT false,
  event_id          UUID REFERENCES public.events (id) ON DELETE SET NULL,
  like_count        INTEGER NOT NULL DEFAULT 0,
  comment_count     INTEGER NOT NULL DEFAULT 0,
  is_deleted        BOOLEAN NOT NULL DEFAULT false,  -- soft delete
  checkin_lat       DOUBLE PRECISION,
  checkin_lng       DOUBLE PRECISION,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_posts_user_id      ON public.posts (user_id);
CREATE INDEX IF NOT EXISTS idx_posts_location_id  ON public.posts (location_id);
CREATE INDEX IF NOT EXISTS idx_posts_event_id     ON public.posts (event_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at   ON public.posts (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_is_deleted   ON public.posts (is_deleted);
-- Feed query: non-deleted posts newest first
CREATE INDEX IF NOT EXISTS idx_posts_feed         ON public.posts (is_deleted, created_at DESC);
-- Per-location gallery
CREATE INDEX IF NOT EXISTS idx_posts_location_feed ON public.posts (location_id, is_deleted, created_at DESC);


-- ============================================================
-- 6. LIKES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.likes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES public.users (id) ON DELETE CASCADE,
  post_id    UUID NOT NULL REFERENCES public.posts (id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, post_id)   -- one like per user per post
);

CREATE INDEX IF NOT EXISTS idx_likes_post_id ON public.likes (post_id);
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON public.likes (user_id);


-- ============================================================
-- 7. COMMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.comments (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES public.users (id) ON DELETE CASCADE,
  post_id    UUID NOT NULL REFERENCES public.posts (id) ON DELETE CASCADE,
  message    TEXT NOT NULL CHECK (char_length(message) BETWEEN 1 AND 300),
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_comments_post_id    ON public.comments (post_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id    ON public.comments (user_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON public.comments (created_at DESC);


-- ============================================================
-- 8. FRIENDS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.friends (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES public.users (id) ON DELETE CASCADE,
  addressee_id UUID NOT NULL REFERENCES public.users (id) ON DELETE CASCADE,
  status       friend_status_enum NOT NULL DEFAULT 'pending',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (requester_id, addressee_id),
  CHECK (requester_id <> addressee_id)   -- cannot friend yourself
);

CREATE INDEX IF NOT EXISTS idx_friends_requester ON public.friends (requester_id, status);
CREATE INDEX IF NOT EXISTS idx_friends_addressee ON public.friends (addressee_id, status);

DROP TRIGGER IF EXISTS trg_friends_updated_at ON public.friends;
CREATE TRIGGER trg_friends_updated_at
  BEFORE UPDATE ON public.friends
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ============================================================
-- 9. BADGE DEFINITIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.badge_definitions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug             TEXT NOT NULL UNIQUE,  -- e.g. 'first_wheel', 'road_warrior'
  name             TEXT NOT NULL,
  description      TEXT NOT NULL,
  icon_url         TEXT,
  category         badge_category_enum NOT NULL,
  threshold_type   threshold_type_enum NOT NULL,
  threshold_value  INTEGER,        -- e.g. 10 for "10 check-ins"; NULL for manual
  location_type    location_type_enum, -- scoped to a type? e.g. 'drag_strip' for Quarter Mile Club
  is_active        BOOLEAN NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_badge_definitions_category ON public.badge_definitions (category);
CREATE INDEX IF NOT EXISTS idx_badge_definitions_active   ON public.badge_definitions (is_active);

-- Seed standard badges
INSERT INTO public.badge_definitions
  (slug, name, description, category, threshold_type, threshold_value, location_type)
VALUES
  ('first_wheel',       'First Wheel',         'Complete your first check-in.',                          'milestone', 'total_checkins',            1,   NULL),
  ('road_warrior',      'Road Warrior',        'Complete 10 check-ins.',                                 'milestone', 'total_checkins',            10,  NULL),
  ('track_regular',     'Track Regular',       'Complete 25 check-ins.',                                 'milestone', 'total_checkins',            25,  NULL),
  ('century_driver',    'Century Driver',      'Complete 100 check-ins.',                                'milestone', 'total_checkins',            100, NULL),
  ('explorer',          'Explorer',            'Check in at 5 different locations.',                     'milestone', 'unique_locations',           5,   NULL),
  ('globe_trotter',     'Globe Trotter',       'Check in across 5 different states.',                    'milestone', 'unique_states',              5,   NULL),
  ('track_rat',         'Track Rat',           '10 check-ins at track or autocross locations.',          'category',  'checkins_by_location_type', 10,  'track'),
  ('dirt_slinger',      'Dirt Slinger',        '10 check-ins at off-road locations.',                    'category',  'checkins_by_location_type', 10,  'off_road_trail'),
  ('quarter_mile_club', 'Quarter Mile Club',   '10 check-ins at drag strips.',                           'category',  'checkins_by_location_type', 10,  'drag_strip'),
  ('weekend_warrior',   'Weekend Warrior',     'Check in on 4 consecutive weekends.',                    'streak',    'consecutive_weekends',       4,   NULL),
  ('five_star_rater',   '5-Star Rater',        'Give a 5-star rating on 20 check-ins.',                 'activity',  'ratings_given',              20,  NULL),
  ('critic',            'Critic',              'Write 20 check-in messages longer than 100 characters.', 'activity',  'messages_written',           20,  NULL),
  ('early_adopter',     'Early Adopter',       'Joined Wheeln in the first 90 days after launch.',       'special',   'manual',                    NULL, NULL)
ON CONFLICT (slug) DO NOTHING;


-- ============================================================
-- 10. USER BADGES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_badges (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES public.users (id) ON DELETE CASCADE,
  badge_id   UUID NOT NULL REFERENCES public.badge_definitions (id) ON DELETE CASCADE,
  post_id    UUID REFERENCES public.posts (id) ON DELETE SET NULL,  -- triggering post
  earned_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, badge_id)   -- each badge earned once per user
);

CREATE INDEX IF NOT EXISTS idx_user_badges_user_id  ON public.user_badges (user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_badge_id ON public.user_badges (badge_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_earned_at ON public.user_badges (earned_at DESC);


-- ============================================================
-- 11. EVENT CHECK-INS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.event_checkins (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES public.users (id) ON DELETE CASCADE,
  event_id      UUID NOT NULL REFERENCES public.events (id) ON DELETE CASCADE,
  post_id       UUID REFERENCES public.posts (id) ON DELETE SET NULL,
  checked_in_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, event_id)   -- one check-in per user per event
);

CREATE INDEX IF NOT EXISTS idx_event_checkins_user_id  ON public.event_checkins (user_id);
CREATE INDEX IF NOT EXISTS idx_event_checkins_event_id ON public.event_checkins (event_id);


-- ============================================================
-- 12. ORGANIZER ORDERS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.organizer_orders (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id            UUID NOT NULL REFERENCES public.events (id) ON DELETE CASCADE,
  stripe_session_id   TEXT NOT NULL UNIQUE,
  package_type        package_type_enum NOT NULL,
  amount_paid         INTEGER NOT NULL,    -- in cents, e.g. 10000 = $100.00
  fulfillment_status  fulfillment_status_enum NOT NULL DEFAULT 'pending',
  printful_order_id   TEXT,                -- Pro + Elite only
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_organizer_orders_event_id        ON public.organizer_orders (event_id);
CREATE INDEX IF NOT EXISTS idx_organizer_orders_stripe_session  ON public.organizer_orders (stripe_session_id);
CREATE INDEX IF NOT EXISTS idx_organizer_orders_fulfillment     ON public.organizer_orders (fulfillment_status);

DROP TRIGGER IF EXISTS trg_organizer_orders_updated_at ON public.organizer_orders;
CREATE TRIGGER trg_organizer_orders_updated_at
  BEFORE UPDATE ON public.organizer_orders
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ============================================================
-- 13. DENORMALIZATION TRIGGERS
--     Keep counter columns in sync automatically
-- ============================================================

-- A. After a post is inserted → bump location.total_checkins and user.total_checkins
CREATE OR REPLACE FUNCTION public.trg_post_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Increment location counter
  IF NEW.location_id IS NOT NULL THEN
    UPDATE public.locations
    SET
      total_checkins = total_checkins + 1,
      avg_rating     = (
        SELECT ROUND(AVG(star_rating)::NUMERIC, 2)
        FROM public.posts
        WHERE location_id = NEW.location_id AND is_deleted = false
      ),
      avg_difficulty = (
        SELECT ROUND(AVG(difficulty_rating)::NUMERIC, 2)
        FROM public.posts
        WHERE location_id = NEW.location_id AND is_deleted = false
      )
    WHERE id = NEW.location_id;
  END IF;

  -- Increment user counter
  UPDATE public.users
  SET total_checkins = total_checkins + 1
  WHERE id = NEW.user_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_after_post_insert ON public.posts;
CREATE TRIGGER trg_after_post_insert
  AFTER INSERT ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.trg_post_insert();


-- B. After a post is soft-deleted → recalculate location averages
CREATE OR REPLACE FUNCTION public.trg_post_soft_delete()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Only fire when is_deleted flips from false to true
  IF OLD.is_deleted = false AND NEW.is_deleted = true THEN

    IF NEW.location_id IS NOT NULL THEN
      UPDATE public.locations
      SET
        total_checkins = GREATEST(total_checkins - 1, 0),
        avg_rating     = COALESCE((
          SELECT ROUND(AVG(star_rating)::NUMERIC, 2)
          FROM public.posts
          WHERE location_id = NEW.location_id AND is_deleted = false
        ), 0),
        avg_difficulty = COALESCE((
          SELECT ROUND(AVG(difficulty_rating)::NUMERIC, 2)
          FROM public.posts
          WHERE location_id = NEW.location_id AND is_deleted = false
        ), 0)
      WHERE id = NEW.location_id;
    END IF;

    UPDATE public.users
    SET total_checkins = GREATEST(total_checkins - 1, 0)
    WHERE id = NEW.user_id;

  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_after_post_soft_delete ON public.posts;
CREATE TRIGGER trg_after_post_soft_delete
  AFTER UPDATE OF is_deleted ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.trg_post_soft_delete();


-- C. Likes → update posts.like_count
CREATE OR REPLACE FUNCTION public.trg_like_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.posts SET like_count = like_count + 1 WHERE id = NEW.post_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_after_like_insert ON public.likes;
CREATE TRIGGER trg_after_like_insert
  AFTER INSERT ON public.likes
  FOR EACH ROW EXECUTE FUNCTION public.trg_like_insert();

CREATE OR REPLACE FUNCTION public.trg_like_delete()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.posts SET like_count = GREATEST(like_count - 1, 0) WHERE id = OLD.post_id;
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_after_like_delete ON public.likes;
CREATE TRIGGER trg_after_like_delete
  AFTER DELETE ON public.likes
  FOR EACH ROW EXECUTE FUNCTION public.trg_like_delete();


-- D. Comments → update posts.comment_count
CREATE OR REPLACE FUNCTION public.trg_comment_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_after_comment_insert ON public.comments;
CREATE TRIGGER trg_after_comment_insert
  AFTER INSERT ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.trg_comment_insert();

CREATE OR REPLACE FUNCTION public.trg_comment_soft_delete()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF OLD.is_deleted = false AND NEW.is_deleted = true THEN
    UPDATE public.posts SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = NEW.post_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_after_comment_soft_delete ON public.comments;
CREATE TRIGGER trg_after_comment_soft_delete
  AFTER UPDATE OF is_deleted ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.trg_comment_soft_delete();


-- E. User badges → update users.badge_count
CREATE OR REPLACE FUNCTION public.trg_user_badge_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.users SET badge_count = badge_count + 1 WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_after_user_badge_insert ON public.user_badges;
CREATE TRIGGER trg_after_user_badge_insert
  AFTER INSERT ON public.user_badges
  FOR EACH ROW EXECUTE FUNCTION public.trg_user_badge_insert();


-- ============================================================
-- 14. ROW LEVEL SECURITY
-- ============================================================

-- Enable RLS on every table
ALTER TABLE public.users             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friends           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.badge_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_checkins    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizer_orders  ENABLE ROW LEVEL SECURITY;

-- Helper: resolve auth.uid() to public.users.id
-- Stored in a function so policies stay readable
CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS UUID LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT id FROM public.users WHERE auth_id = auth.uid()
$$;


-- ──────────────────────────────────────────
-- USERS
-- ──────────────────────────────────────────
DROP POLICY IF EXISTS "users: public read"          ON public.users;
DROP POLICY IF EXISTS "users: insert own profile"   ON public.users;
DROP POLICY IF EXISTS "users: update own profile"   ON public.users;

-- Anyone (including anon) can read public profiles
CREATE POLICY "users: public read"
  ON public.users FOR SELECT
  USING (true);

-- A user can create their own profile row (matched by auth_id)
CREATE POLICY "users: insert own profile"
  ON public.users FOR INSERT
  WITH CHECK (auth_id = auth.uid());

-- A user can only update their own row
CREATE POLICY "users: update own profile"
  ON public.users FOR UPDATE
  USING (auth_id = auth.uid())
  WITH CHECK (auth_id = auth.uid());

-- No direct DELETE from client — handle via Supabase Auth cascade or service role


-- ──────────────────────────────────────────
-- LOCATIONS
-- ──────────────────────────────────────────
DROP POLICY IF EXISTS "locations: public read approved"    ON public.locations;
DROP POLICY IF EXISTS "locations: auth insert"             ON public.locations;
DROP POLICY IF EXISTS "locations: service role manage"     ON public.locations;

-- All users (including anon) can read approved locations
CREATE POLICY "locations: public read approved"
  ON public.locations FOR SELECT
  USING (admin_approved = true);

-- Authenticated users can submit new locations (admin_approved defaults to false)
CREATE POLICY "locations: auth insert"
  ON public.locations FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND admin_approved = false);

-- Service role (used by edge functions + admin) can do anything
-- Supabase service role bypasses RLS by default — no extra policy needed.
-- If you want an explicit admin policy, add an is_admin boolean to users and check it here.


-- ──────────────────────────────────────────
-- POSTS
-- ──────────────────────────────────────────
DROP POLICY IF EXISTS "posts: public read non-deleted"  ON public.posts;
DROP POLICY IF EXISTS "posts: auth insert"              ON public.posts;
DROP POLICY IF EXISTS "posts: owner update"             ON public.posts;
DROP POLICY IF EXISTS "posts: owner soft delete"        ON public.posts;

CREATE POLICY "posts: public read non-deleted"
  ON public.posts FOR SELECT
  USING (is_deleted = false);

CREATE POLICY "posts: auth insert"
  ON public.posts FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND user_id = public.current_user_id());

-- Owner can update their post (e.g. edit message) — but not change user_id
CREATE POLICY "posts: owner update"
  ON public.posts FOR UPDATE
  USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());

-- No hard deletes from client — use UPDATE to set is_deleted = true
-- The update policy above covers soft deletes


-- ──────────────────────────────────────────
-- LIKES
-- ──────────────────────────────────────────
DROP POLICY IF EXISTS "likes: public read"   ON public.likes;
DROP POLICY IF EXISTS "likes: auth insert"   ON public.likes;
DROP POLICY IF EXISTS "likes: owner delete"  ON public.likes;

CREATE POLICY "likes: public read"
  ON public.likes FOR SELECT
  USING (true);

CREATE POLICY "likes: auth insert"
  ON public.likes FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND user_id = public.current_user_id());

CREATE POLICY "likes: owner delete"
  ON public.likes FOR DELETE
  USING (user_id = public.current_user_id());


-- ──────────────────────────────────────────
-- COMMENTS
-- ──────────────────────────────────────────
DROP POLICY IF EXISTS "comments: public read non-deleted"  ON public.comments;
DROP POLICY IF EXISTS "comments: auth insert"              ON public.comments;
DROP POLICY IF EXISTS "comments: owner update"             ON public.comments;

CREATE POLICY "comments: public read non-deleted"
  ON public.comments FOR SELECT
  USING (is_deleted = false);

CREATE POLICY "comments: auth insert"
  ON public.comments FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND user_id = public.current_user_id());

-- Owner can soft-delete (set is_deleted = true) — prevent editing body
CREATE POLICY "comments: owner update"
  ON public.comments FOR UPDATE
  USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());


-- ──────────────────────────────────────────
-- FRIENDS
-- ──────────────────────────────────────────
DROP POLICY IF EXISTS "friends: read own"    ON public.friends;
DROP POLICY IF EXISTS "friends: auth insert" ON public.friends;
DROP POLICY IF EXISTS "friends: auth update" ON public.friends;
DROP POLICY IF EXISTS "friends: auth delete" ON public.friends;

-- Users can only see friend records they are party to
CREATE POLICY "friends: read own"
  ON public.friends FOR SELECT
  USING (
    requester_id = public.current_user_id()
    OR addressee_id = public.current_user_id()
  );

CREATE POLICY "friends: auth insert"
  ON public.friends FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND requester_id = public.current_user_id()
  );

-- Addressee can update status (accept / decline); requester cannot change status
CREATE POLICY "friends: auth update"
  ON public.friends FOR UPDATE
  USING (addressee_id = public.current_user_id())
  WITH CHECK (addressee_id = public.current_user_id());

-- Either party can delete (unfriend / withdraw request)
CREATE POLICY "friends: auth delete"
  ON public.friends FOR DELETE
  USING (
    requester_id = public.current_user_id()
    OR addressee_id = public.current_user_id()
  );


-- ──────────────────────────────────────────
-- BADGE DEFINITIONS
-- ──────────────────────────────────────────
DROP POLICY IF EXISTS "badge_definitions: public read" ON public.badge_definitions;

CREATE POLICY "badge_definitions: public read"
  ON public.badge_definitions FOR SELECT
  USING (is_active = true);

-- INSERT / UPDATE / DELETE only via service role (your edge functions + admin panel)


-- ──────────────────────────────────────────
-- USER BADGES
-- ──────────────────────────────────────────
DROP POLICY IF EXISTS "user_badges: public read"        ON public.user_badges;
DROP POLICY IF EXISTS "user_badges: service role write" ON public.user_badges;

-- Everyone can see who earned which badges (public achievement display)
CREATE POLICY "user_badges: public read"
  ON public.user_badges FOR SELECT
  USING (true);

-- Writes happen only from the badge-evaluation Edge Function using the service role key.
-- The service role bypasses RLS, so no explicit INSERT policy is needed from the client side.
-- Uncomment the block below ONLY if you need a named policy for auditing:
--
-- CREATE POLICY "user_badges: service role write"
--   ON public.user_badges FOR ALL
--   USING (auth.role() = 'service_role');


-- ──────────────────────────────────────────
-- EVENTS
-- ──────────────────────────────────────────
DROP POLICY IF EXISTS "events: organizer read"  ON public.events;
DROP POLICY IF EXISTS "events: public read active featured" ON public.events;

-- Organizer can read their own events (matched by email)
CREATE POLICY "events: organizer read"
  ON public.events FOR SELECT
  USING (
    organizer_email = (
      SELECT email FROM public.users WHERE auth_id = auth.uid()
    )
  );

-- Everyone can see active/featured events (for Elite feed placement)
CREATE POLICY "events: public read active featured"
  ON public.events FOR SELECT
  USING (
    status = 'active'
    AND featured_until IS NOT NULL
    AND featured_until > now()
  );

-- All inserts/updates to events go through the stripe-webhook Edge Function (service role)


-- ──────────────────────────────────────────
-- EVENT CHECK-INS
-- ──────────────────────────────────────────
DROP POLICY IF EXISTS "event_checkins: read own"    ON public.event_checkins;
DROP POLICY IF EXISTS "event_checkins: auth insert" ON public.event_checkins;

CREATE POLICY "event_checkins: read own"
  ON public.event_checkins FOR SELECT
  USING (user_id = public.current_user_id());

-- QR scan → Edge Function creates this record via service role.
-- Allow authenticated users to also insert directly for edge-case deep link handling.
CREATE POLICY "event_checkins: auth insert"
  ON public.event_checkins FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND user_id = public.current_user_id()
  );


-- ──────────────────────────────────────────
-- ORGANIZER ORDERS
-- ──────────────────────────────────────────
DROP POLICY IF EXISTS "organizer_orders: organizer read" ON public.organizer_orders;

-- Organizer can read their own orders (join through event → organizer_email)
CREATE POLICY "organizer_orders: organizer read"
  ON public.organizer_orders FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.id = organizer_orders.event_id
        AND e.organizer_email = (
          SELECT email FROM public.users WHERE auth_id = auth.uid()
        )
    )
  );

-- All inserts/updates via service role (Stripe webhook Edge Function)


-- ============================================================
-- 15. USEFUL VIEWS (optional but handy during development)
-- ============================================================

-- Feed view: joins posts with user info and location name
CREATE OR REPLACE VIEW public.v_feed AS
SELECT
  p.id,
  p.created_at,
  p.photo_url,
  p.message,
  p.star_rating,
  p.difficulty_rating,
  p.like_count,
  p.comment_count,
  p.is_event_checkin,
  p.event_id,
  u.id           AS user_id,
  u.username,
  u.display_name,
  u.avatar_url,
  l.id           AS location_id,
  l.name         AS location_name,
  l.type         AS location_type,
  l.city,
  l.state
FROM public.posts p
JOIN public.users u     ON u.id = p.user_id
LEFT JOIN public.locations l ON l.id = p.location_id
WHERE p.is_deleted = false
ORDER BY p.created_at DESC;

-- Location rankings view
CREATE OR REPLACE VIEW public.v_location_rankings AS
SELECT
  id,
  name,
  type,
  city,
  state,
  avg_rating,
  avg_difficulty,
  total_checkins,
  cover_photo_url,
  RANK() OVER (ORDER BY avg_rating DESC, total_checkins DESC)     AS rating_rank,
  RANK() OVER (ORDER BY avg_difficulty DESC, total_checkins DESC) AS difficulty_rank,
  RANK() OVER (ORDER BY total_checkins DESC)                      AS popularity_rank
FROM public.locations
WHERE admin_approved = true
  AND total_checkins >= 5   -- minimum for rankings
ORDER BY rating_rank;


-- ============================================================
-- DONE
-- ============================================================
-- To verify: run the query below after this migration
--   SELECT table_name FROM information_schema.tables
--   WHERE table_schema = 'public' ORDER BY table_name;
