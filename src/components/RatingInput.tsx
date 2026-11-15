import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { colors } from '../constants/theme';

interface Props {
  label: string; // e.g. "How much did you like it?"
  hint: string; // e.g. "1 = meh, 5 = loved it"
  value: number; // 0 = not chosen yet, otherwise 1 to 5
  onChange: (value: number) => void;
}

// Five tappable stars. Tap the same star again to clear it.
export function RatingInput({ label, hint, value, onChange }: Props) {
  return (
    <View style={styles.wrap}>
      <Text style={styles.label}>{label}</Text>
      <Text style={styles.hint}>{hint}</Text>
      <View style={styles.row}>
        {[1, 2, 3, 4, 5].map((n) => (
          <TouchableOpacity
            key={n}
            onPress={() => onChange(n === value ? 0 : n)}
            hitSlop={{ top: 6, bottom: 6, left: 4, right: 4 }}
            accessibilityLabel={`${n} out of 5`}
          >
            <Text style={[styles.star, n <= value && styles.starOn]}>★</Text>
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { marginBottom: 16 },
  label: { color: colors.text, fontSize: 15, fontWeight: '700' },
  hint: { color: colors.textMuted, fontSize: 12, marginTop: 2, marginBottom: 6 },
  row: { flexDirection: 'row' },
  star: { color: colors.border, fontSize: 40, marginRight: 8 },
  starOn: { color: colors.accent },
});
