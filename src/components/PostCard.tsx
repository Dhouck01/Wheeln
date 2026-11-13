import React from 'react';
import { View, Text, Image, TouchableOpacity, StyleSheet } from 'react-native';
import { formatDistanceToNowStrict } from 'date-fns';
import { RatingStars } from './RatingStars';
import { colors } from '../constants/theme';
import { LOCATION_TYPE_LABELS } from '../constants/locationTypes';
import { Post } from '../types';

interface Props {
  post: Post;
  onToggleLike: (postId: string) => void;
  onOpenComments: (postId: string) => void;
}

export function PostCard({ post, onToggleLike, onOpenComments }: Props) {
  const name = post.users?.username ?? 'unknown';
  const initial = name.charAt(0).toUpperCase();

  return (
    <View style={styles.card}>
      <View style={styles.header}>
        {post.users?.avatar_url ? (
          <Image source={{ uri: post.users.avatar_url }} style={styles.avatar} />
        ) : (
          <View style={[styles.avatar, styles.avatarFallback]}>
            <Text style={styles.avatarInitial}>{initial}</Text>
          </View>
        )}
        <View style={styles.headerText}>
          <Text style={styles.username}>@{name}</Text>
          {/* Location name is not tappable yet: the location screen comes later */}
          <Text style={styles.location} numberOfLines={1}>
            {post.locations?.name ?? 'Unknown location'}
          </Text>
        </View>
        {post.locations && (
          <View style={styles.typeBadge}>
            <Text style={styles.typeBadgeText}>{LOCATION_TYPE_LABELS[post.locations.type]}</Text>
          </View>
        )}
      </View>

      <Image source={{ uri: post.photo_url }} style={styles.photo} resizeMode="cover" />

      <View style={styles.body}>
        <View style={styles.ratings}>
          <RatingStars label="Rating" value={post.star_rating} />
          <RatingStars label="Difficulty" value={post.difficulty_rating} />
        </View>

        {!!post.message && <Text style={styles.message}>{post.message}</Text>}

        <View style={styles.actions}>
          <TouchableOpacity
            style={styles.action}
            onPress={() => onToggleLike(post.id)}
            accessibilityLabel={post.liked_by_me ? 'Unlike' : 'Like'}
          >
            <Text style={[styles.actionIcon, post.liked_by_me && styles.liked]}>
              {post.liked_by_me ? '♥' : '♡'}
            </Text>
            <Text style={styles.actionCount}>{post.like_count}</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.action}
            onPress={() => onOpenComments(post.id)}
            accessibilityLabel="Open comments"
          >
            <Text style={styles.actionIcon}>💬</Text>
            <Text style={styles.actionCount}>{post.comment_count}</Text>
          </TouchableOpacity>

          <Text style={styles.time}>
            {formatDistanceToNowStrict(new Date(post.created_at), { addSuffix: true })}
          </Text>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.card,
    borderRadius: 12,
    marginHorizontal: 12,
    marginBottom: 16,
    overflow: 'hidden',
  },
  header: { flexDirection: 'row', alignItems: 'center', padding: 12 },
  avatar: { width: 40, height: 40, borderRadius: 20 },
  avatarFallback: { backgroundColor: colors.accent, alignItems: 'center', justifyContent: 'center' },
  avatarInitial: { color: colors.text, fontSize: 18, fontWeight: '800' },
  headerText: { flex: 1, marginLeft: 10, marginRight: 8 },
  username: { color: colors.text, fontSize: 15, fontWeight: '700' },
  location: { color: colors.textMuted, fontSize: 13, marginTop: 1 },
  typeBadge: {
    borderColor: colors.accent,
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  typeBadgeText: { color: colors.accent, fontSize: 11, fontWeight: '700' },
  photo: { width: '100%', aspectRatio: 1, backgroundColor: colors.border },
  body: { padding: 12 },
  ratings: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 8 },
  message: { color: colors.text, fontSize: 15, lineHeight: 21, marginBottom: 10 },
  actions: { flexDirection: 'row', alignItems: 'center' },
  action: { flexDirection: 'row', alignItems: 'center', marginRight: 20, paddingVertical: 4 },
  actionIcon: { color: colors.textMuted, fontSize: 22, marginRight: 6 },
  liked: { color: colors.accent },
  actionCount: { color: colors.text, fontSize: 14, fontWeight: '600' },
  time: { color: colors.inactive, fontSize: 12, marginLeft: 'auto' },
});
