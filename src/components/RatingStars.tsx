import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { colors } from '../constants/theme';

interface Props {
  label: string; // e.g. "Rating" or "Difficulty"
  value: number; // 1 to 5
}

// Five stars, filled up to `value`, with a small label in front
export function RatingStars({ label, value }: Props) {
  const filled = Math.max(0, Math.min(5, Math.round(value)));
  return (
    <View style={styles.row} accessibilityLabel={`${label} ${filled} out of 5`}>
      <Text style={styles.label}>{label}</Text>
      <Text style={styles.filled}>{'★'.repeat(filled)}</Text>
      <Text style={styles.empty}>{'★'.repeat(5 - filled)}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center' },
  label: { color: colors.textMuted, fontSize: 12, marginRight: 6 },
  filled: { color: colors.accent, fontSize: 14 },
  empty: { color: colors.border, fontSize: 14 },
});
