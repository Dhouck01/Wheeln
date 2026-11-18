import React, { useCallback, useState } from 'react';
import { View, Text, TouchableOpacity, ActivityIndicator, StyleSheet } from 'react-native';
import { useFocusEffect, useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import Ionicons from '@expo/vector-icons/Ionicons';
import { useAuth } from '../hooks/useAuth';
import { useBadgeCount } from '../hooks/useBadges';
import { colors } from '../constants/theme';
import { RootStackParamList } from '../types';

export function ProfileScreen() {
  const { user, signOut } = useAuth();
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const { count, reload } = useBadgeCount();
  const [isSigningOut, setIsSigningOut] = useState(false);
  const [error, setError] = useState('');

  // Refresh the count whenever this tab is shown (after a check-in, or coming back from Badges)
  useFocusEffect(
    useCallback(() => {
      reload();
    }, [reload])
  );

  async function handleSignOut() {
    setError('');
    setIsSigningOut(true);
    try {
      await signOut();
    } catch (e: any) {
      setError(e?.message ?? 'Could not sign out.');
      setIsSigningOut(false);
    }
  }

  return (
    <View style={styles.screen}>
      <Text style={styles.title}>Profile</Text>
      <Text style={styles.label}>Signed in as</Text>
      <Text style={styles.email}>{user?.email}</Text>

      <TouchableOpacity
        style={styles.badgesRow}
        onPress={() => navigation.navigate('Badges')}
        accessibilityLabel="Open badges"
      >
        <Ionicons name="ribbon" size={22} color={colors.accent} />
        <Text style={styles.badgesLabel}>Badges</Text>
        <Text style={styles.badgesCount}>{count === null ? '' : `${count} earned`}</Text>
        <Text style={styles.badgesChevron}>›</Text>
      </TouchableOpacity>

      {error !== '' && <Text style={styles.error}>{error}</Text>}

      <TouchableOpacity
        style={styles.button}
        onPress={handleSignOut}
        disabled={isSigningOut}
      >
        {isSigningOut ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.buttonText}>Sign Out</Text>
        )}
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: '#0D0D0D',
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 24,
  },
  title: { color: '#fff', fontSize: 24, fontWeight: '800', marginBottom: 24 },
  label: { color: '#666666', fontSize: 14, marginBottom: 4 },
  email: { color: '#fff', fontSize: 16, marginBottom: 32 },
  badgesRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: 12,
    paddingVertical: 14,
    paddingHorizontal: 16,
    alignSelf: 'stretch',
    marginBottom: 24,
  },
  badgesLabel: { color: colors.text, fontSize: 16, fontWeight: '700', marginLeft: 12, flex: 1 },
  badgesCount: { color: colors.textMuted, fontSize: 14 },
  badgesChevron: { color: colors.inactive, fontSize: 24, marginLeft: 8 },
  error: { color: '#FF4D4D', fontSize: 14, marginBottom: 16, textAlign: 'center' },
  button: {
    backgroundColor: '#FF5A00',
    borderRadius: 8,
    paddingVertical: 14,
    paddingHorizontal: 40,
    minWidth: 180,
    alignItems: 'center',
  },
  buttonText: { color: '#fff', fontSize: 16, fontWeight: '700' },
});
