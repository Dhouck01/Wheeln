import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
  ScrollView,
} from 'react-native';
import { useAuth } from '../hooks/useAuth';

type Mode = 'signIn' | 'signUp';

export function AuthScreen() {
  const { signIn, signUp } = useAuth();
  const [isLoading, setIsLoading] = useState(false);
  const [mode, setMode] = useState<Mode>('signIn');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [username, setUsername] = useState('');
  const [error, setError] = useState('');

  async function handleSubmit() {
    setError('');
    if (!email || !password) {
      setError('Please fill in all fields.');
      return;
    }
    if (mode === 'signUp' && !username) {
      setError('Please enter a username.');
      return;
    }
    setIsLoading(true);
    try {
      if (mode === 'signIn') {
        await signIn(email, password);
      } else {
        await signUp(email, password, username);
      }
    } catch (e: any) {
      setError(e?.message ?? 'Something went wrong.');
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView
        contentContainerStyle={styles.scroll}
        keyboardShouldPersistTaps="handled"
      >
        <Text style={styles.logo}>WHEELN</Text>
        <Text style={styles.tagline}>The motorsport community</Text>

        {/* Tab switcher */}
        <View style={styles.tabRow}>
          <TouchableOpacity
            style={[styles.tab, mode === 'signIn' && styles.tabActive]}
            onPress={() => { setMode('signIn'); setError(''); }}
          >
            <Text style={[styles.tabText, mode === 'signIn' && styles.tabTextActive]}>
              Sign In
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.tab, mode === 'signUp' && styles.tabActive]}
            onPress={() => { setMode('signUp'); setError(''); }}
          >
            <Text style={[styles.tabText, mode === 'signUp' && styles.tabTextActive]}>
              Sign Up
            </Text>
          </TouchableOpacity>
        </View>

        {/* Form */}
        <View style={styles.form}>
          {mode === 'signUp' && (
            <TextInput
              style={styles.input}
              placeholder="Username"
              placeholderTextColor="#555"
              autoCapitalize="none"
              value={username}
              onChangeText={setUsername}
            />
          )}
          <TextInput
            style={styles.input}
            placeholder="Email"
            placeholderTextColor="#555"
            autoCapitalize="none"
            keyboardType="email-address"
            value={email}
            onChangeText={setEmail}
          />
          <TextInput
            style={styles.input}
            placeholder="Password"
            placeholderTextColor="#555"
            secureTextEntry
            value={password}
            onChangeText={setPassword}
          />

          {error !== '' && <Text style={styles.error}>{error}</Text>}

          <TouchableOpacity
            style={styles.button}
            onPress={handleSubmit}
            disabled={isLoading}
          >
            {isLoading ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.buttonText}>
                {mode === 'signIn' ? 'Sign In' : 'Create Account'}
              </Text>
            )}
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0D0D0D',
  },
  scroll: {
    flexGrow: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 24,
    paddingVertical: 48,
  },
  logo: {
    fontSize: 48,
    fontWeight: '900',
    color: '#FF5A00',
    letterSpacing: 4,
    marginBottom: 8,
  },
  tagline: {
    fontSize: 14,
    color: '#888',
    letterSpacing: 1,
    marginBottom: 48,
  },
  tabRow: {
    flexDirection: 'row',
    backgroundColor: '#1A1A1A',
    borderRadius: 12,
    padding: 4,
    marginBottom: 32,
    width: '100%',
  },
  tab: {
    flex: 1,
    paddingVertical: 10,
    alignItems: 'center',
    borderRadius: 9,
  },
  tabActive: {
    backgroundColor: '#FF5A00',
  },
  tabText: {
    color: '#666',
    fontWeight: '600',
    fontSize: 15,
  },
  tabTextActive: {
    color: '#fff',
  },
  form: {
    width: '100%',
    gap: 14,
  },
  input: {
    backgroundColor: '#1A1A1A',
    borderWidth: 1,
    borderColor: '#2A2A2A',
    borderRadius: 10,
    padding: 14,
    color: '#fff',
    fontSize: 16,
  },
  error: {
    color: '#FF4444',
    fontSize: 13,
    textAlign: 'center',
  },
  button: {
    backgroundColor: '#FF5A00',
    borderRadius: 10,
    paddingVertical: 15,
    alignItems: 'center',
    marginTop: 6,
  },
  buttonText: {
    color: '#fff',
    fontWeight: '700',
    fontSize: 16,
  },
});
