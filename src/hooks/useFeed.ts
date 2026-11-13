import { useCallback, useEffect, useRef, useState } from 'react';
import supabase from '../lib/supabase';
import { useFeedStore } from '../store/feedStore';
import { FEED_PAGE_SIZE } from '../constants/theme';
import { Comment, FeedMode, Post } from '../types';

// Which columns we ask the database for, including the joined user and location
const POST_COLUMNS =
  'id, created_at, user_id, location_id, photo_url, message, star_rating, difficulty_rating, like_count, comment_count, ' +
  'users(id, username, display_name, avatar_url), locations(id, name, type)';

const COMMENT_COLUMNS =
  'id, post_id, user_id, message, created_at, users(id, username, display_name, avatar_url)';

// Ids of everyone who is an accepted friend of `profileId`
async function fetchFriendIds(profileId: string): Promise<string[]> {
  const { data, error } = await supabase
    .from('friends')
    .select('requester_id, addressee_id')
    .eq('status', 'accepted')
    .or(`requester_id.eq.${profileId},addressee_id.eq.${profileId}`);
  if (error) throw error;
  return (data ?? []).map((row: any) =>
    row.requester_id === profileId ? row.addressee_id : row.requester_id
  );
}

// One page of posts, newest first. `cursor` is the created_at of the last post
// already on screen; we ask for posts older than that.
async function fetchPostsPage(
  profileId: string,
  mode: FeedMode,
  cursor: string | null
): Promise<Post[]> {
  let query = supabase
    .from('posts')
    .select(POST_COLUMNS)
    .eq('is_deleted', false)
    .order('created_at', { ascending: false })
    .limit(FEED_PAGE_SIZE);

  if (cursor) query = query.lt('created_at', cursor);

  if (mode === 'friends') {
    const friendIds = await fetchFriendIds(profileId);
    // Friends feed shows your friends' posts plus your own
    query = query.in('user_id', [...friendIds, profileId]);
  }

  const { data, error } = await query;
  if (error) throw error;
  const rows = (data ?? []) as any[];

  // Find which of these posts the signed-in person already liked
  let likedIds = new Set<string>();
  if (rows.length > 0) {
    const { data: likes, error: likesError } = await supabase
      .from('likes')
      .select('post_id')
      .eq('user_id', profileId)
      .in('post_id', rows.map((r) => r.id));
    if (likesError) throw likesError;
    likedIds = new Set((likes ?? []).map((l: any) => l.post_id));
  }

  return rows.map((r) => ({ ...r, liked_by_me: likedIds.has(r.id) })) as Post[];
}

export function useFeed(profileId: string | undefined) {
  const { posts, mode, setPosts, appendPosts, updatePost, setMode, clearFeed } = useFeedStore();
  const [isLoading, setIsLoading] = useState(false); // first load of a feed
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [error, setError] = useState('');

  // Each load gets a number; if a newer load starts, older answers are ignored.
  const requestId = useRef(0);
  const likesInFlight = useRef(new Set<string>());

  const loadFirstPage = useCallback(
    async (kind: 'initial' | 'refresh') => {
      if (!profileId) return;
      const myRequest = ++requestId.current;
      setError('');
      if (kind === 'initial') setIsLoading(true);
      else setIsRefreshing(true);
      try {
        const rows = await fetchPostsPage(profileId, mode, null);
        if (myRequest !== requestId.current) return;
        setPosts(rows);
        setHasMore(rows.length === FEED_PAGE_SIZE);
      } catch (e: any) {
        if (myRequest !== requestId.current) return;
        setError(e?.message ?? 'Could not load the feed.');
      } finally {
        if (myRequest === requestId.current) {
          setIsLoading(false);
          setIsRefreshing(false);
        }
      }
    },
    [profileId, mode, setPosts]
  );

  // Start over whenever the person or the Friends/Community toggle changes
  useEffect(() => {
    clearFeed();
    setHasMore(true);
    loadFirstPage('initial');
  }, [profileId, mode]);

  const loadMore = useCallback(async () => {
    if (!profileId || isLoading || isRefreshing || isLoadingMore || !hasMore) return;
    const current = useFeedStore.getState().posts;
    if (current.length === 0) return;
    const myRequest = requestId.current;
    setIsLoadingMore(true);
    try {
      const rows = await fetchPostsPage(profileId, mode, current[current.length - 1].created_at);
      if (myRequest !== requestId.current) return;
      appendPosts(rows);
      setHasMore(rows.length === FEED_PAGE_SIZE);
    } catch (e: any) {
      if (myRequest !== requestId.current) return;
      setError(e?.message ?? 'Could not load more posts.');
    } finally {
      setIsLoadingMore(false);
    }
  }, [profileId, mode, isLoading, isRefreshing, isLoadingMore, hasMore, appendPosts]);

  const refresh = useCallback(() => loadFirstPage('refresh'), [loadFirstPage]);

  // Like or unlike. The screen updates instantly; if the database says no, we undo it.
  const toggleLike = useCallback(
    async (postId: string) => {
      if (!profileId || likesInFlight.current.has(postId)) return;
      const post = useFeedStore.getState().posts.find((p) => p.id === postId);
      if (!post) return;

      likesInFlight.current.add(postId);
      const wasLiked = post.liked_by_me;
      updatePost(postId, {
        liked_by_me: !wasLiked,
        like_count: Math.max(post.like_count + (wasLiked ? -1 : 1), 0),
      });

      try {
        if (wasLiked) {
          const { error: dbError } = await supabase
            .from('likes')
            .delete()
            .eq('user_id', profileId)
            .eq('post_id', postId);
          if (dbError) throw dbError;
        } else {
          const { error: dbError } = await supabase
            .from('likes')
            .insert({ user_id: profileId, post_id: postId });
          // 23505 = "already liked" — the screen is already right, so ignore it
          if (dbError && dbError.code !== '23505') throw dbError;
        }
      } catch {
        const latest = useFeedStore.getState().posts.find((p) => p.id === postId);
        if (latest) {
          updatePost(postId, {
            liked_by_me: wasLiked,
            like_count: Math.max(latest.like_count + (wasLiked ? 1 : -1), 0),
          });
        }
        setError('Could not update your like. Try again.');
      } finally {
        likesInFlight.current.delete(postId);
      }
    },
    [profileId, updatePost]
  );

  return {
    posts,
    mode,
    setMode,
    isLoading,
    isRefreshing,
    isLoadingMore,
    error,
    refresh,
    loadMore,
    toggleLike,
  };
}

// Comments for one post. Pass null when no post is open.
export function useComments(postId: string | null, profileId: string | undefined) {
  const updatePost = useFeedStore((s) => s.updatePost);
  const [comments, setComments] = useState<Comment[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isSending, setIsSending] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    setComments([]);
    setError('');
    if (!postId) return;
    let cancelled = false;
    setIsLoading(true);
    supabase
      .from('comments')
      .select(COMMENT_COLUMNS)
      .eq('post_id', postId)
      .eq('is_deleted', false)
      .order('created_at', { ascending: true })
      .then(({ data, error: dbError }) => {
        if (cancelled) return;
        if (dbError) setError(dbError.message);
        else setComments((data ?? []) as unknown as Comment[]);
        setIsLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [postId]);

  // Returns true if the comment was saved (so the screen can clear the text box)
  async function addComment(message: string): Promise<boolean> {
    const text = message.trim();
    if (!postId || !profileId || text === '' || isSending) return false;
    setIsSending(true);
    setError('');
    try {
      const { data, error: dbError } = await supabase
        .from('comments')
        .insert({ post_id: postId, user_id: profileId, message: text })
        .select(COMMENT_COLUMNS)
        .single();
      if (dbError) throw dbError;
      setComments((prev) => [...prev, data as unknown as Comment]);
      const post = useFeedStore.getState().posts.find((p) => p.id === postId);
      if (post) updatePost(postId, { comment_count: post.comment_count + 1 });
      return true;
    } catch (e: any) {
      setError(e?.message ?? 'Could not post your comment.');
      return false;
    } finally {
      setIsSending(false);
    }
  }

  return { comments, isLoading, isSending, error, addComment };
}
