import React, { useState } from 'react';
import { ActivityIndicator, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import { LOCATION_TYPE_LABELS } from '../constants/locationTypes';
import { colors } from '../constants/theme';
import { useLocationSearch } from '../hooks/useCheckIn';
import { LocationSummary } from '../types';

interface Props {
  selected: LocationSummary | null;
  onSelect: (location: LocationSummary | null) => void;
}

// Search box plus a short list of matching places. Once one is chosen it shows as a card.
export function LocationPicker({ selected, onSelect }: Props) {
  const [search, setSearch] = useState('');
  const { results, isLoading, error } = useLocationSearch(selected ? '' : search);

  if (selected) {
    return (
      <View style={styles.selected}>
        <View style={styles.selectedInfo}>
          <Text style={styles.name} numberOfLines={1}>
            {selected.name}
          </Text>
          <Text style={styles.type}>{LOCATION_TYPE_LABELS[selected.type]}</Text>
        </View>
        <TouchableOpacity onPress={() => onSelect(null)}>
          <Text style={styles.change}>Change</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View>
      <TextInput
        style={styles.input}
        placeholder="Search tracks, strips, trails..."
        placeholderTextColor={colors.inactive}
        value={search}
        onChangeText={setSearch}
        autoCorrect={false}
        autoCapitalize="none"
      />
      {error !== '' && <Text style={styles.error}>{error}</Text>}
      {isLoading && results.length === 0 ? (
        <ActivityIndicator color={colors.accent} style={styles.spinner} />
      ) : results.length === 0 && error === '' ? (
        <Text style={styles.empty}>No places match "{search.trim()}".</Text>
      ) : (
        results.map((loc) => (
          <TouchableOpacity key={loc.id} style={styles.row} onPress={() => onSelect(loc)}>
            <Text style={styles.name} numberOfLines={1}>
              {loc.name}
            </Text>
            <Text style={styles.type}>{LOCATION_TYPE_LABELS[loc.type]}</Text>
          </TouchableOpacity>
        ))
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  input: {
    backgroundColor: colors.card,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: 10,
    color: colors.text,
    fontSize: 16,
    paddingHorizontal: 14,
    paddingVertical: 12,
    marginBottom: 8,
  },
  row: {
    backgroundColor: colors.card,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 12,
    marginBottom: 6,
  },
  selected: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderColor: colors.accent,
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  selectedInfo: { flex: 1, marginRight: 12 },
  name: { color: colors.text, fontSize: 16, fontWeight: '700' },
  type: { color: colors.accent, fontSize: 12, fontWeight: '700', marginTop: 2 },
  change: { color: colors.accent, fontSize: 14, fontWeight: '700' },
  empty: { color: colors.textMuted, fontSize: 14, textAlign: 'center', marginTop: 12 },
  error: { color: colors.error, fontSize: 14, marginBottom: 8 },
  spinner: { marginTop: 16 },
});
