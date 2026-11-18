import { useCallback, useRef, useState } from 'react';
import supabase from '../lib/supabase';
import { useProfile } from './useProfile';
import {
  BadgeDefinition,
  BadgeLadder,
  EarnedBadge,
  LadderStatus,
  LadderStep,
  SpecialBadge,
} from '../types';

interface ProgressRow {
  ladder_slug: string;
  metric_value: number;
}

// Everything the Badges screen shows: each ladder with the signed-in person's
// progress, plus one-off badges (like Early Adopter) if earned.
// Badges are awarded by the database. This hook only reads them.
export function useBadges() {
  const { profile, error: profileError } = useProfile();
  const profileId = profile?.id;
  const [ladders, setLadders] = useState<LadderStatus[]>([]);
  const [special, setSpecial] = useState<SpecialBadge[]>([]);
  const [totalEarned, setTotalEarned] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState('');
  const requestId = useRef(0);
  const loadedOnce = useRef(false);

  // The spinner only shows on the very first load; later reloads happen quietly
  const load = useCallback(
    async (isPullRefresh: boolean) => {
      if (!profileId) return;
      const myRequest = ++requestId.current;
      setError('');
      if (isPullRefresh) setIsRefreshing(true);
      else if (!loadedOnce.current) setIsLoading(true);

      const [ladderRes, defRes, earnedRes, progressRes] = await Promise.all([
        supabase.from('badge_ladders').select('id, slug, name, sort_order').order('sort_order'),
        supabase
          .from('badge_definitions')
          .select('id, slug, name, description, tier, threshold_value, ladder_id')
          .order('tier'),
        supabase.from('user_badges').select('badge_id, earned_at').eq('user_id', profileId),
        supabase.rpc('my_badge_progress'),
      ]);

      if (myRequest !== requestId.current) return;

      const failure = ladderRes.error ?? defRes.error ?? earnedRes.error ?? progressRes.error;
      if (failure) {
        setError(failure.message);
        setIsLoading(false);
        setIsRefreshing(false);
        return;
      }

      const ladderRows = (ladderRes.data ?? []) as BadgeLadder[];
      const defs = (defRes.data ?? []) as BadgeDefinition[];
      const earned = (earnedRes.data ?? []) as EarnedBadge[];
      const progress = (progressRes.data ?? []) as ProgressRow[];

      const earnedAt = new Map(earned.map((e) => [e.badge_id, e.earned_at]));
      const valueBySlug = new Map(progress.map((p) => [p.ladder_slug, p.metric_value]));

      const built: LadderStatus[] = ladderRows.map((ladder) => {
        const steps: LadderStep[] = defs
          .filter((d) => d.ladder_id === ladder.id && d.tier !== null && d.threshold_value !== null)
          .sort((a, b) => (a.tier as number) - (b.tier as number))
          .map((d) => ({
            id: d.id,
            name: d.name,
            description: d.description,
            tier: d.tier as number,
            threshold: d.threshold_value as number,
            earnedAt: earnedAt.get(d.id) ?? null,
          }));
        const earnedSteps = steps.filter((s) => s.earnedAt !== null);
        const current = earnedSteps.length > 0 ? earnedSteps[earnedSteps.length - 1] : null;
        const next = steps.find((s) => current === null || s.tier > current.tier) ?? null;
        return { ladder, steps, value: valueBySlug.get(ladder.slug) ?? 0, current, next };
      });

      const specialBadges: SpecialBadge[] = defs
        .filter((d) => d.ladder_id === null && earnedAt.has(d.id))
        .map((d) => ({
          id: d.id,
          name: d.name,
          description: d.description,
          earnedAt: earnedAt.get(d.id) as string,
        }));

      setLadders(built);
      setSpecial(specialBadges);
      setTotalEarned(earned.length);
      loadedOnce.current = true;
      setIsLoading(false);
      setIsRefreshing(false);
    },
    [profileId]
  );

  return {
    ladders,
    special,
    totalEarned,
    isLoading: isLoading && !profileError,
    isRefreshing,
    error: error || profileError,
    load,
  };
}

// Just the number of badges earned, for the Profile screen
export function useBadgeCount() {
  const { profile } = useProfile();
  const profileId = profile?.id;
  const [count, setCount] = useState<number | null>(null);

  const reload = useCallback(async () => {
    if (!profileId) return;
    const { count: total, error } = await supabase
      .from('user_badges')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', profileId);
    if (!error) setCount(total ?? 0);
  }, [profileId]);

  return { count, reload };
}
