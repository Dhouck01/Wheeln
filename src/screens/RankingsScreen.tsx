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
import { LocationCard } from '../components/LocationCard';
import { useRankings } from '../hooks/useRankings';
import { RANKINGS_MIN_CHECKINS, colors } from '../constants/theme';
import { RankingKind } from '../types';

const TABS: { kind: RankingKind; label: string }[] = [
  { kind: 'rating', label: 'Top Rated' },
  { kind: 'difficulty', label: 'Most Challenging' },
  { kind: 'popularity', label: 'Most Popular' },
];

export function RankingsScreen() {
  const [kind, setKind] = useState<RankingKind>('rating');
  const { locations, isLoading, isRefreshing, error, refresh } = useRankings(kind);

  return (
    <SafeAreaView style={styles.screen} edges={['top']}>
      <Text style={styles.pageTitle}>Rankings</Text>
      <Text style={styles.pageSubtitle}>
        Places with {RANKINGS_MIN_CHECKINS}+ check-ins, ranked by the community
      </Text>
      <View style={styles.toggle}>
        {TABS.map((tab) => {
          const active = tab.kind === kind;
          return (
            <TouchableOpacity
              key={tab.kind}
              style={[styles.toggleButton, active && styles.toggleActive]}
              onPress={() => setKind(tab.kind)}
            >
              <Text style={[styles.toggleText, active && styles.toggleTextActive]} numberOfLines={1}>
                {tab.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>

      {error !== '' && (
        <TouchableOpacity onPress={refresh}>
          <Text style={styles.error}>{error} Tap to retry.</Text>
        </TouchableOpacity>
      )}

      {isLoading ? (
        <ActivityIndicator size="large" color={colors.accent} style={styles.spinner} />
      ) : (
        <FlatList
          data={locations}
          keyExtractor={(l) => l.id}
          renderItem={({ item, index }) => <LocationCard location={item} rank={index + 1} />}
          contentContainerStyle={styles.list}
          refreshControl={
            <RefreshControl
              refreshing={isRefreshing}
              onRefresh={refresh}
              tintColor={colors.accent}
              colors={[colors.accent]}
            />
          }
          ListEmptyComponent={
            error === '' ? (
              <View style={styles.centerBox}>
                <Text style={styles.emptyTitle}>Not enough check-ins yet</Text>
                <Text style={styles.emptyText}>
                  A place shows up here after {RANKINGS_MIN_CHECKINS} check-ins.
                </Text>
              </View>
            ) : undefined
          }
        />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  pageTitle: { color: colors.text, fontSize: 28, fontWeight: '900', paddingHorizontal: 16, paddingTop: 8 },
  pageSubtitle: { color: colors.textMuted, fontSize: 13, paddingHorizontal: 16, marginTop: 2 },
  toggle: {
    flexDirection: 'row',
    backgroundColor: colors.card,
    borderRadius: 10,
    margin: 12,
    padding: 4,
  },
  toggleButton: { flex: 1, paddingVertical: 10, borderRadius: 8, alignItems: 'center' },
  toggleActive: { backgroundColor: colors.accent },
  toggleText: { color: colors.textMuted, fontSize: 13, fontWeight: '700' },
  toggleTextActive: { color: colors.text },
  error: { color: colors.error, fontSize: 14, textAlign: 'center', paddingHorizontal: 16, paddingBottom: 8 },
  spinner: { marginTop: 48 },
  list: { paddingTop: 4, paddingBottom: 24, flexGrow: 1 },
  centerBox: { alignItems: 'center', paddingHorizontal: 32, marginTop: 64 },
  emptyTitle: { color: colors.text, fontSize: 18, fontWeight: '800', marginBottom: 6 },
  emptyText: { color: colors.textMuted, fontSize: 15, textAlign: 'center' },
});
