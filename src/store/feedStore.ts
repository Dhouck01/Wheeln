import { create } from 'zustand';
import { FeedMode, Post } from '../types';

interface FeedState {
  posts: Post[];
  mode: FeedMode;
  setPosts: (posts: Post[]) => void;
  appendPosts: (posts: Post[]) => void;
  updatePost: (postId: string, changes: Partial<Post>) => void;
  setMode: (mode: FeedMode) => void;
  clearFeed: () => void;
}

export const useFeedStore = create<FeedState>()((set) => ({
  posts: [],
  mode: 'community',
  setPosts: (posts) => set({ posts }),
  appendPosts: (more) =>
    set((state) => {
      // Skip anything already in the list (protects against duplicates)
      const seen = new Set(state.posts.map((p) => p.id));
      return { posts: [...state.posts, ...more.filter((p) => !seen.has(p.id))] };
    }),
  updatePost: (postId, changes) =>
    set((state) => ({
      posts: state.posts.map((p) => (p.id === postId ? { ...p, ...changes } : p)),
    })),
  setMode: (mode) => set({ mode }),
  clearFeed: () => set({ posts: [] }),
}));
