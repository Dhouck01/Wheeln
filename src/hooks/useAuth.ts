import { useEffect } from 'react';
import supabase from '../lib/supabase';
import { useAuthStore } from '../store/authStore';

export function useAuth() {
  const { user, session, isLoading, setUser, setSession, setLoading, clearAuth } = useAuthStore();

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      setLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      setUser(session?.user ?? null);
    });

    return () => subscription.unsubscribe();
  }, []);

  // signIn and signUp do not touch the shared isLoading flag. That flag means
  // "checking for a saved session at app start" and swaps the whole screen for a
  // spinner, which would wipe the form and any error message.
  async function signIn(email: string, password: string) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
    setSession(data.session);
    setUser(data.user);
  }

  async function signUp(email: string, password: string, username: string) {
    const { data, error } = await supabase.auth.signUp({ email, password });
    if (error) throw error;

    if (data.user) {
      const { error: insertError } = await supabase.from('users').insert({
        auth_id: data.user.id,
        email,
        username,
        display_name: username,
      });
      if (insertError) throw insertError;
      setSession(data.session);
      setUser(data.user);
    }
  }

  async function signOut() {
    setLoading(true);
    try {
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
      clearAuth();
    } finally {
      setLoading(false);
    }
  }

  return { user, session, isLoading, signIn, signUp, signOut };
}
