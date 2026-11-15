import { useCallback, useEffect, useRef, useState } from 'react';
import supabase from '../lib/supabase';
import { RANKINGS_LIMIT, RANKINGS_MIN_CHECKINS } from '../constants/theme';
import { RankedLocation, RankingKind } from '../types';

const COLUMNS =
  'id, name, type, city, state, avg_rating, avg_difficulty, total_checkins, cover_photo_url';

// Which column each sub-tab sorts by. Ties are broken by check-in count.
const SORT_COLUMN: Record<RankingKind, string> = {
  rating: 'avg_rating',
  difficulty: 'avg_difficulty',
  popularity: 'total_checkins',
};

// Ranked places for one sub-tab. Only approved places are returned (database rule).
export function useRankings(kind: RankingKind) {
  const [locations, setLocations] = useState<RankedLocation[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState('');
  // If the sub-tab changes mid-load, ignore the older answer
  const requestId = useRef(0);

  const load = useCallback(
    async (isPullRefresh: boolean) => {
      const myRequest = ++requestId.current;
      setError('');
      if (isPullRefresh) setIsRefreshing(true);
      else setIsLoading(true);

      let query = supabase
        .from('locations')
        .select(COLUMNS)
        .gte('total_checkins', RANKINGS_MIN_CHECKINS)
        .order(SORT_COLUMN[kind], { ascending: false });
      if (kind !== 'popularity') query = query.order('total_checkins', { ascending: false });
      const { data, error: dbError } = await query.limit(RANKINGS_LIMIT);

      if (myRequest !== requestId.current) return;
      if (dbError) setError(dbError.message);
      else setLocations((data ?? []) as unknown as RankedLocation[]);
      setIsLoading(false);
      setIsRefreshing(false);
    },
    [kind]
  );

  useEffect(() => {
    setLocations([]);
    load(false);
  }, [load]);

  const refresh = useCallback(() => load(true), [load]);

  return { locations, isLoading, isRefreshing, error, refresh };
}
