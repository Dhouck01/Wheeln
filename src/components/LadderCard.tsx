import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { BadgeIcon } from './BadgeIcon';
import { DEFAULT_LADDER_META, LADDER_META, rankColor } from '../constants/badges';
import { colors } from '../constants/theme';
import { LadderStatus } from '../types';

interface Props {
  status: LadderStatus;
  onPress: () => void;
}

// One row on the Badges screen: hexagon, ladder name, current step, progress bar
export function LadderCard({ status, onPress }: Props) {
  const { ladder, steps, value, current, next } = status;
  const meta = LADDER_META[ladder.slug] ?? DEFAULT_LADDER_META;
  const total = steps.length;
  const accent = current ? rankColor(current.tier, total) : colors.inactive;

  // The bar fills from the step you hold to the next one
  const from = current ? current.threshold : 0;
  const fraction = next
    ? Math.min(1, Math.max(0, (value - from) / Math.max(1, next.threshold - from)))
    : 1;

  // Titled steps read "Hot Lap · Level 10 of 20"; plain ones are already "Dirt Level 3"
  let currentLine = 'Not started';
  if (current) {
    const plain = current.name.startsWith(`${ladder.name} Level`);
    currentLine = plain
      ? `Level ${current.tier} of ${total}`
      : `${current.name} · Level ${current.tier} of ${total}`;
  }

  const progressLine = next
    ? `${value} / ${next.threshold} ${meta.unit}`.trim()
    : 'Top of the ladder';

  return (
    <TouchableOpacity
      style={styles.card}
      onPress={onPress}
      accessibilityLabel={`${ladder.name}. ${currentLine}. ${progressLine}`}
    >
      <BadgeIcon icon={meta.icon} color={accent} size={56} locked={current === null} />
      <View style={styles.body}>
        <Text style={styles.name}>{ladder.name}</Text>
        <Text style={[styles.current, { color: accent }]} numberOfLines={1}>
          {currentLine}
        </Text>
        <View style={styles.barTrack}>
          <View style={[styles.barFill, { width: `${Math.round(fraction * 100)}%` }]} />
        </View>
        <Text style={styles.progress}>{progressLine}</Text>
      </View>
      <Text style={styles.chevron}>›</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: 12,
    padding: 14,
    marginHorizontal: 12,
    marginBottom: 10,
  },
  body: { flex: 1, marginLeft: 14 },
  name: { color: colors.text, fontSize: 16, fontWeight: '800' },
  current: { fontSize: 13, fontWeight: '700', marginTop: 1 },
  barTrack: {
    height: 6,
    borderRadius: 3,
    backgroundColor: colors.border,
    marginTop: 8,
    overflow: 'hidden',
  },
  barFill: { height: 6, borderRadius: 3, backgroundColor: colors.accent },
  progress: { color: colors.textMuted, fontSize: 12, marginTop: 4 },
  chevron: { color: colors.inactive, fontSize: 26, marginLeft: 8 },
});
