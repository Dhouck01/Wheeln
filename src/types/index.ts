// Shared types. These match the columns in the Supabase database.

export type LocationType =
  | 'track'
  | 'autocross'
  | 'drag_strip'
  | 'off_road_trail'
  | 'off_road_park'
  | 'car_show'
  | 'overlanding'
  | 'karting'
  | 'moto_track'
  | 'gravel_ride'
  | 'rock_crawl'
  | 'cars_and_coffee'
  | 'other';

// A row of the `users` table (only the columns the app reads so far)
export interface UserProfile {
  id: string;
  auth_id: string | null;
  username: string;
  display_name: string;
  avatar_url: string | null;
}

// The small slice of a user shown on a post or comment
export interface UserSummary {
  id: string;
  username: string;
  display_name: string;
  avatar_url: string | null;
}

// The small slice of a location shown on a post
export interface LocationSummary {
  id: string;
  name: string;
  type: LocationType;
}

// A row of the `posts` table, joined with its user and location
export interface Post {
  id: string;
  created_at: string;
  user_id: string;
  location_id: string | null;
  photo_url: string;
  message: string | null;
  star_rating: number;
  difficulty_rating: number;
  like_count: number;
  comment_count: number;
  users: UserSummary | null;
  // null if the location is missing or not approved (hidden by database rules)
  locations: LocationSummary | null;
  // Not a database column: filled in by the app for the signed-in user
  liked_by_me: boolean;
}

// A location as shown on the Rankings screen (columns of the `locations` table)
export interface RankedLocation {
  id: string;
  name: string;
  type: LocationType;
  city: string | null;
  state: string | null;
  avg_rating: number;
  avg_difficulty: number;
  total_checkins: number;
  cover_photo_url: string | null;
}

export type RankingKind = 'rating' | 'difficulty' | 'popularity';

// A row of the `comments` table, joined with its user
export interface Comment {
  id: string;
  post_id: string;
  user_id: string;
  message: string;
  created_at: string;
  users: UserSummary | null;
}

export type FeedMode = 'community' | 'friends';

// A row of the `badge_ladders` table
export interface BadgeLadder {
  id: string;
  slug: string;
  name: string;
  sort_order: number;
}

// A row of the `badge_definitions` table (only the columns the app reads)
export interface BadgeDefinition {
  id: string;
  slug: string;
  name: string;
  description: string;
  tier: number | null; // step number on its ladder; null for one-off badges
  threshold_value: number | null; // the number needed to earn it
  ladder_id: string | null; // null for one-off badges like Early Adopter
}

// A row of the `user_badges` table
export interface EarnedBadge {
  badge_id: string;
  earned_at: string;
}

// One step of a ladder, with the date it was earned (null = still locked)
export interface LadderStep {
  id: string;
  name: string;
  description: string;
  tier: number;
  threshold: number;
  earnedAt: string | null;
}

// A ladder with the signed-in person's progress on it
export interface LadderStatus {
  ladder: BadgeLadder;
  steps: LadderStep[]; // every step, lowest first
  value: number; // the person's current number (visits, places, likes, ...)
  current: LadderStep | null; // highest step earned, or null if not started
  next: LadderStep | null; // the next step to earn, or null at the top
}

// A one-off badge that is not on a ladder
export interface SpecialBadge {
  id: string;
  name: string;
  description: string;
  earnedAt: string;
}

// The screens that sit on top of the tabs
export type RootStackParamList = {
  Tabs: undefined;
  Badges: undefined;
};
