import { useEffect, useState } from 'react';
import supabase from '../lib/supabase';
import { useAuthStore } from '../store/authStore';
import { UserProfile } from '../types';

// Finds the signed-in person's row in the `users` table.
// Posts, likes and comments point at that row's id, NOT at the login id.
export function useProfile() {
  const authId = useAuthStore((s) => s.user?.id);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!authId) {
      setProfile(null);
      return;
    }
    let cancelled = false;
    setError('');
    supabase
      .from('users')
      .select('id, auth_id, username, display_name, avatar_url')
      .eq('auth_id', authId)
      .maybeSingle()
      .then(({ data, error: dbError }) => {
        if (cancelled) return;
        if (dbError) setError(dbError.message);
        else if (!data) setError('Your profile was not found.');
        else setProfile(data as UserProfile);
      });
    return () => {
      cancelled = true;
    };
  }, [authId]);

  return { profile, error };
}
