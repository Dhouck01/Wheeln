import React, { useCallback, useState } from 'react';
import {
  ActivityIndicator,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { format } from 'date-fns';
import { BadgeIcon } from '../components/BadgeIcon';
import { LadderCard } from '../components/LadderCard';
import { LadderSheet } from '../components/LadderSheet';
import { useBadges } from '../hooks/useBadges';
import {
  BADGE_COLORS,
  BADGE_GROUPS,
  DEFAULT_LADDER_META,
  LADDER_META,
  SPECIAL_BADGE_ICON,
} from '../constants/badges';
import { colors } from '../constants/theme';

export function BadgesScreen() {
  const { ladders, special, totalEarned, isLoading, isRefreshing, error, load } = useBadges();
  const [selectedSlug, setSelectedSlug] = useState<string | null>(null);

  // Reload every time the screen is opened, so new badges show up
  useFocusEffect(
    useCallback(() => {
      load(false);
    }, [load])
  );

  const selected = ladders.find((l) => l.ladder.slug === selectedSlug) ?? null;

  if (isLoading) {
    return (
      <View style={styles.screen}>
        <ActivityIndicator size="large" color={colors.accent} style={styles.spinner} />
      </View>
    );
  }

  return (
    <View style={styles.screen}>
      <ScrollView
        contentContainerStyle={styles.content}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => load(true)}
            tintColor={colors.accent}
            colors={[colors.accent]}
          />
        }
      >
        <Text style={styles.summary}>
          {totalEarned} {totalEarned === 1 ? 'badge' : 'badges'} earned
        </Text>

        {error !== '' && (
          <TouchableOpacity onPress={() => load(false)}>
            <Text style={styles.error}>{error} Tap to retry.</Text>
          </TouchableOpacity>
        )}

        {special.length > 0 && (
          <View>
            <Text style={styles.sectionTitle}>Special</Text>
            {special.map((badge) => (
              <View key={badge.id} style={styles.specialCard}>
                <BadgeIcon icon={SPECIAL_BADGE_ICON} color={BADGE_COLORS.gold} size={56} />
                <View style={styles.specialBody}>
                  <Text style={styles.specialName}>{badge.name}</Text>
                  <Text style={styles.specialDescription}>{badge.description}</Text>
                  <Text style={styles.specialDate}>
                    Earned {format(new Date(badge.earnedAt), 'MMM d, yyyy')}
                  </Text>
                </View>
              </View>
            ))}
          </View>
        )}

        {BADGE_GROUPS.map((group) => {
          const inGroup = ladders.filter(
            (l) => (LADDER_META[l.ladder.slug] ?? DEFAULT_LADDER_META).group === group.key
          );
          if (inGroup.length === 0) return null;
          return (
            <View key={group.key}>
              <Text style={styles.sectionTitle}>{group.title}</Text>
              {inGroup.map((status) => (
                <LadderCard
                  key={status.ladder.id}
                  status={status}
                  onPress={() => setSelectedSlug(status.ladder.slug)}
                />
              ))}
            </View>
          );
        })}
      </ScrollView>

      <LadderSheet status={selected} onClose={() => setSelectedSlug(null)} />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  spinner: { marginTop: 48 },
  content: { paddingTop: 8, paddingBottom: 32 },
  summary: { color: colors.textMuted, fontSize: 14, paddingHorizontal: 16, marginBottom: 4 },
  error: { color: colors.error, fontSize: 14, textAlign: 'center', paddingHorizontal: 16, paddingVertical: 8 },
  sectionTitle: {
    color: colors.text,
    fontSize: 13,
    fontWeight: '800',
    letterSpacing: 1,
    textTransform: 'uppercase',
    paddingHorizontal: 16,
    marginTop: 16,
    marginBottom: 8,
  },
  specialCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: 12,
    padding: 14,
    marginHorizontal: 12,
    marginBottom: 10,
  },
  specialBody: { flex: 1, marginLeft: 14 },
  specialName: { color: colors.text, fontSize: 16, fontWeight: '800' },
  specialDescription: { color: colors.textMuted, fontSize: 13, marginTop: 2 },
  specialDate: { color: BADGE_COLORS.gold, fontSize: 12, fontWeight: '700', marginTop: 4 },
});
