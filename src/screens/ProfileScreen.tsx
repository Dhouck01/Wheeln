import React, { useState } from 'react';
import { View, Text, TouchableOpacity, ActivityIndicator, StyleSheet } from 'react-native';
import { useAuth } from '../hooks/useAuth';

export function ProfileScreen() {
  const { user, signOut } = useAuth();
  const [isSigningOut, setIsSigningOut] = useState(false);
  const [error, setError] = useState('');

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
