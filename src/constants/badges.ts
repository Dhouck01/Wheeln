// Look and grouping of the badge ladders. The rules for earning badges live in
// the database; this file only decides how they are shown.

import type { ComponentProps } from 'react';
import type Ionicons from '@expo/vector-icons/Ionicons';

export type IconName = ComponentProps<typeof Ionicons>['name'];

export type BadgeGroup = 'overall' | 'road' | 'offroad' | 'drag' | 'social';

// The sections on the Badges screen, in order
export const BADGE_GROUPS: { key: BadgeGroup; title: string }[] = [
  { key: 'overall', title: 'Overall' },
  { key: 'road', title: 'Road' },
  { key: 'offroad', title: 'Off-road' },
  { key: 'drag', title: 'Drag' },
  { key: 'social', title: 'Social' },
];

// One entry per ladder slug (matches `badge_ladders.slug`)
export const LADDER_META: Record<string, { group: BadgeGroup; icon: IconName; unit: string }> = {
  all_visits: { group: 'overall', icon: 'flag', unit: 'visits' },
  all_venues: { group: 'overall', icon: 'earth', unit: 'places' },
  courses: { group: 'overall', icon: 'git-branch', unit: 'trails' },
  states: { group: 'overall', icon: 'location', unit: 'states' },
  road_visits: { group: 'road', icon: 'speedometer', unit: 'visits' },
  road_venues: { group: 'road', icon: 'map', unit: 'venues' },
  offroad_visits: { group: 'offroad', icon: 'trail-sign', unit: 'visits' },
  offroad_venues: { group: 'offroad', icon: 'compass', unit: 'venues' },
  drag_visits: { group: 'drag', icon: 'flash', unit: 'visits' },
  drag_venues: { group: 'drag', icon: 'navigate', unit: 'venues' },
  likes: { group: 'social', icon: 'heart', unit: 'likes' },
  friends: { group: 'social', icon: 'people', unit: 'friends' },
};

// Used if the database ever has a ladder this file does not know yet
export const DEFAULT_LADDER_META = { group: 'overall' as BadgeGroup, icon: 'ribbon' as IconName, unit: '' };

export const SPECIAL_BADGE_ICON: IconName = 'star';

export const BADGE_COLORS = {
  bronze: '#CD7F32',
  silver: '#C0C0C0',
  gold: '#F5C518',
  platinum: '#8FE3FF',
  lockedRing: '#3A3A3A',
  lockedIcon: '#555555',
  fill: '#111111', // the dark middle of the hexagon
} as const;

// Each ladder is split into four equal parts: bronze, silver, gold, platinum
export function rankColor(tier: number, totalSteps: number): string {
  const quarter = Math.min(4, Math.max(1, Math.ceil((tier / totalSteps) * 4)));
  return [BADGE_COLORS.bronze, BADGE_COLORS.silver, BADGE_COLORS.gold, BADGE_COLORS.platinum][quarter - 1];
}
