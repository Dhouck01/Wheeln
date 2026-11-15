import React from 'react';
import { Image, StyleSheet, Text, View } from 'react-native';
import { LOCATION_TYPE_LABELS } from '../constants/locationTypes';
import { colors } from '../constants/theme';
import { RankedLocation } from '../types';

interface Props {
  location: RankedLocation;
  rank: number; // 1 = first place
}

// One row in the rankings list
export function LocationCard({ location, rank }: Props) {
  const place = [location.city, location.state].filter(Boolean).join(', ');
  const count = location.total_checkins;

  return (
    <View style={styles.card}>
      <Text style={[styles.rank, rank <= 3 && styles.rankTop]}>{rank}</Text>

      {location.cover_photo_url ? (
        <Image source={{ uri: location.cover_photo_url }} style={styles.photo} />
      ) : (
        <View style={[styles.photo, styles.photoEmpty]}>
          <Text style={styles.photoEmptyText}>🏁</Text>
        </View>
      )}

      <View style={styles.info}>
        <Text style={styles.name} numberOfLines={1}>
          {location.name}
        </Text>
        <View style={styles.typeRow}>
          <View style={styles.typeBadge}>
            <Text style={styles.typeText}>{LOCATION_TYPE_LABELS[location.type]}</Text>
          </View>
          {place !== '' && (
            <Text style={styles.place} numberOfLines={1}>
              {place}
            </Text>
          )}
        </View>
        <Text style={styles.stats}>
          <Text style={styles.star}>★ </Text>
          {Number(location.avg_rating).toFixed(1)}
          {'   '}
          <Text style={styles.star}>⚑ </Text>
          {Number(location.avg_difficulty).toFixed(1)}
          {'   '}
          {count} check-in{count === 1 ? '' : 's'}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: 12,
    marginHorizontal: 12,
    marginBottom: 10,
    padding: 10,
  },
  rank: { width: 30, color: colors.textMuted, fontSize: 20, fontWeight: '800', textAlign: 'center' },
  rankTop: { color: colors.accent },
  photo: { width: 64, height: 64, borderRadius: 8, marginHorizontal: 10, backgroundColor: colors.border },
  photoEmpty: { alignItems: 'center', justifyContent: 'center' },
  photoEmptyText: { fontSize: 26 },
  info: { flex: 1 },
  name: { color: colors.text, fontSize: 16, fontWeight: '800', marginBottom: 4 },
  typeRow: { flexDirection: 'row', alignItems: 'center', marginBottom: 4 },
  typeBadge: {
    backgroundColor: colors.background,
    borderColor: colors.accent,
    borderWidth: 1,
    borderRadius: 6,
    paddingHorizontal: 6,
    paddingVertical: 2,
    marginRight: 8,
  },
  typeText: { color: colors.accent, fontSize: 11, fontWeight: '700' },
  place: { flex: 1, color: colors.textMuted, fontSize: 12 },
  stats: { color: colors.text, fontSize: 13, fontWeight: '600' },
  star: { color: colors.accent },
});
