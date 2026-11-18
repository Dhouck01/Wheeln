import React from 'react';
import { FlatList, Modal, Pressable, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import Ionicons from '@expo/vector-icons/Ionicons';
import { format } from 'date-fns';
import { BadgeIcon } from './BadgeIcon';
import { DEFAULT_LADDER_META, LADDER_META, rankColor } from '../constants/badges';
import { colors } from '../constants/theme';
import { LadderStatus } from '../types';

interface Props {
  status: LadderStatus | null; // null = sheet closed
  onClose: () => void;
}

// A panel that slides up listing every step of one ladder
export function LadderSheet({ status, onClose }: Props) {
  const meta = status ? LADDER_META[status.ladder.slug] ?? DEFAULT_LADDER_META : DEFAULT_LADDER_META;
  const total = status?.steps.length ?? 0;

  return (
    <Modal visible={status !== null} transparent animationType="slide" onRequestClose={onClose}>
      <View style={styles.overlay}>
        <Pressable style={styles.backdrop} onPress={onClose} />
        <View style={styles.sheet}>
          <View style={styles.titleRow}>
            <Text style={styles.title}>{status?.ladder.name}</Text>
            <TouchableOpacity onPress={onClose} accessibilityLabel="Close">
              <Text style={styles.close}>✕</Text>
            </TouchableOpacity>
          </View>

          <FlatList
            data={status?.steps ?? []}
            keyExtractor={(s) => s.id}
            contentContainerStyle={styles.list}
            renderItem={({ item }) => {
              const earned = item.earnedAt !== null;
              const isCurrent = status?.current?.id === item.id;
              return (
                <View style={[styles.row, isCurrent && styles.rowCurrent]}>
                  <BadgeIcon
                    icon={meta.icon}
                    color={rankColor(item.tier, total)}
                    size={40}
                    locked={!earned}
                  />
                  <View style={styles.rowBody}>
                    <Text style={[styles.rowName, !earned && styles.dim]}>
                      Level {item.tier} · {item.name}
                    </Text>
                    <Text style={styles.rowDescription}>{item.description}</Text>
                  </View>
                  {earned ? (
                    <Text style={styles.date}>{format(new Date(item.earnedAt as string), 'MMM d, yyyy')}</Text>
                  ) : (
                    <Ionicons name="lock-closed" size={16} color={colors.inactive} />
                  )}
                </View>
              );
            }}
          />
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: { flex: 1, justifyContent: 'flex-end' },
  backdrop: { ...StyleSheet.absoluteFill, backgroundColor: 'rgba(0,0,0,0.6)' },
  sheet: {
    backgroundColor: colors.card,
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    maxHeight: '80%',
    minHeight: '45%',
  },
  titleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    borderBottomColor: colors.border,
    borderBottomWidth: 1,
  },
  title: { color: colors.text, fontSize: 17, fontWeight: '800' },
  close: { color: colors.textMuted, fontSize: 20 },
  list: { paddingHorizontal: 12, paddingVertical: 8, paddingBottom: 32 },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
    paddingHorizontal: 8,
    borderRadius: 10,
    borderLeftWidth: 3,
    borderLeftColor: 'transparent',
  },
  rowCurrent: { backgroundColor: colors.background, borderLeftColor: colors.accent },
  rowBody: { flex: 1, marginLeft: 12, marginRight: 8 },
  rowName: { color: colors.text, fontSize: 15, fontWeight: '700' },
  dim: { color: colors.textMuted },
  rowDescription: { color: colors.textMuted, fontSize: 12, marginTop: 2 },
  date: { color: colors.textMuted, fontSize: 12 },
});
