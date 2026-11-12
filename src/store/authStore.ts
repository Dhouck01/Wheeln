import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Session, User } from '@supabase/supabase-js';

interface AuthState {
  user: User | null;
  session: Session | null;
  isLoading: boolean;
  isPremium: boolean;
  setUser: (user: User | null) => void;
  setSession: (session: Session | null) => void;
  setLoading: (isLoading: boolean) => void;
  setIsPremium: (isPremium: boolean) => void;
  clearAuth: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      session: null,
      isLoading: true,
      isPremium: false,
      setUser: (user) => set({ user }),
      setSession: (session) => set({ session }),
      setLoading: (isLoading) => set({ isLoading }),
      setIsPremium: (isPremium) => set({ isPremium }),
      clearAuth: () => set({ user: null, session: null, isPremium: false }),
    }),
    {
      name: 'wheeln-auth',
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (state) => ({ session: state.session, user: state.user, isPremium: state.isPremium }),
    }
  )
);
