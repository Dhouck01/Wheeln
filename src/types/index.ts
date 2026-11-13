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
