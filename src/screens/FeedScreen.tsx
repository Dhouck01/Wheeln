import React, { useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  RefreshControl,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { PostCard } from '../components/PostCard';
import { CommentSheet } from '../components/CommentSheet';
import { useFeed } from '../hooks/useFeed';
import { useProfile } from '../hooks/useProfile';
import { colors } from '../constants/theme';
import { FeedMode } from '../types';

const TABS: { mode: FeedMode; label: string }[] = [
  { mode: 'friends', label: 'Friends' },
  { mode: 'community', label: 'Community' },
];

export function FeedScreen() {
  const { profile, error: profileError } = useProfile();
  const {
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
  } = useFeed(profile?.id);
  const [commentPostId, setCommentPostId] = useState<string | null>(null);

  const shownError = profileError || error;

  function renderEmpty() {
    if (isLoading || !profile) return undefined;
    return (
      <View style={styles.centerBox}>
        <Text style={styles.emptyTitle}>No posts yet</Text>
        <Text style={styles.emptyText}>
          {mode === 'friends'
            ? 'Posts from you and your friends show up here.'
            : 'Be the first to check in somewhere.'}
        </Text>
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.screen} edges={['top']}>
      <View style={styles.toggle}>
        {TABS.map((tab) => {
          const active = tab.mode === mode;
          return (
            <TouchableOpacity
              key={tab.mode}
              style={[styles.toggleButton, active && styles.toggleActive]}
              onPress={() => setMode(tab.mode)}
            >
              <Text style={[styles.toggleText, active && styles.toggleTextActive]}>
                {tab.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>

      {shownError !== '' && (
        <TouchableOpacity onPress={refresh}>
          <Text style={styles.error}>{shownError} Tap to retry.</Text>
        </TouchableOpacity>
      )}

      {isLoading || !profile ? (
        shownError === '' ? (
          <ActivityIndicator size="large" color={colors.accent} style={styles.spinner} />
        ) : null
      ) : (
        <FlatList
          data={posts}
          keyExtractor={(p) => p.id}
          renderItem={({ item }) => (
            <PostCard post={item} onToggleLike={toggleLike} onOpenComments={setCommentPostId} />
          )}
          contentContainerStyle={styles.list}
          onEndReached={loadMore}
          onEndReachedThreshold={0.5}
          refreshControl={
            <RefreshControl
              refreshing={isRefreshing}
              onRefresh={refresh}
              tintColor={colors.accent}
              colors={[colors.accent]}
            />
          }
          ListEmptyComponent={renderEmpty()}
          ListFooterComponent={
            isLoadingMore ? <ActivityIndicator color={colors.accent} style={styles.footer} /> : undefined
          }
        />
      )}

      <CommentSheet
        postId={commentPostId}
        profileId={profile?.id}
        onClose={() => setCommentPostId(null)}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  toggle: {
    flexDirection: 'row',
    backgroundColor: colors.card,
    borderRadius: 10,
    margin: 12,
    padding: 4,
  },
  toggleButton: { flex: 1, paddingVertical: 10, borderRadius: 8, alignItems: 'center' },
  toggleActive: { backgroundColor: colors.accent },
  toggleText: { color: colors.textMuted, fontSize: 15, fontWeight: '700' },
  toggleTextActive: { color: colors.text },
  error: { color: colors.error, fontSize: 14, textAlign: 'center', paddingHorizontal: 16, paddingBottom: 8 },
  spinner: { marginTop: 48 },
  list: { paddingTop: 4, paddingBottom: 24, flexGrow: 1 },
  footer: { marginVertical: 16 },
  centerBox: { alignItems: 'center', paddingHorizontal: 32, marginTop: 64 },
  emptyTitle: { color: colors.text, fontSize: 18, fontWeight: '800', marginBottom: 6 },
  emptyText: { color: colors.textMuted, fontSize: 15, textAlign: 'center' },
});
