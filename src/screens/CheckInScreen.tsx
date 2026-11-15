import React, { useState } from 'react';
import {
  ActivityIndicator,
  Image,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import { LocationPicker } from '../components/LocationPicker';
import { RatingInput } from '../components/RatingInput';
import { useCheckIn } from '../hooks/useCheckIn';
import { useProfile } from '../hooks/useProfile';
import { MAX_POST_MESSAGE_LENGTH, colors } from '../constants/theme';
import { LocationSummary } from '../types';

export function CheckInScreen() {
  const navigation = useNavigation<any>();
  const { profile, error: profileError } = useProfile();
  const { photo, pickPhoto, clearPhoto, submit, isPosting, error } = useCheckIn(profile?.id);

  const [location, setLocation] = useState<LocationSummary | null>(null);
  const [message, setMessage] = useState('');
  const [stars, setStars] = useState(0);
  const [difficulty, setDifficulty] = useState(0);

  async function handlePost() {
    const ok = await submit({ location, message, stars, difficulty });
    if (ok) {
      // Clear the form, then show the Feed with the new post at the top
      setLocation(null);
      setMessage('');
      setStars(0);
      setDifficulty(0);
      navigation.navigate('Feed');
    }
  }

  const shownError = profileError || error;

  return (
    <SafeAreaView style={styles.screen} edges={['top']}>
      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
          <Text style={styles.pageTitle}>Check In</Text>

          <Text style={styles.sectionTitle}>1. Where are you?</Text>
          <LocationPicker selected={location} onSelect={setLocation} />

          <Text style={styles.sectionTitle}>2. Add a photo</Text>
          {photo ? (
            <View>
              <Image source={{ uri: photo.uri }} style={styles.photo} />
              <TouchableOpacity onPress={clearPhoto} disabled={isPosting}>
                <Text style={styles.link}>Remove photo</Text>
              </TouchableOpacity>
            </View>
          ) : (
            <View style={styles.photoButtons}>
              <TouchableOpacity style={styles.photoButton} onPress={() => pickPhoto('camera')}>
                <Text style={styles.photoButtonText}>Take Photo</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.photoButton} onPress={() => pickPhoto('library')}>
                <Text style={styles.photoButtonText}>Choose Photo</Text>
              </TouchableOpacity>
            </View>
          )}

          <Text style={styles.sectionTitle}>3. Rate it</Text>
          <RatingInput
            label="How much did you like it?"
            hint="1 = not for me, 5 = loved it"
            value={stars}
            onChange={setStars}
          />
          <RatingInput
            label="How hard was it?"
            hint="1 = easy, 5 = extreme"
            value={difficulty}
            onChange={setDifficulty}
          />

          <Text style={styles.sectionTitle}>4. Say something (optional)</Text>
          <TextInput
            style={styles.messageInput}
            placeholder="How was it?"
            placeholderTextColor={colors.inactive}
            value={message}
            onChangeText={setMessage}
            maxLength={MAX_POST_MESSAGE_LENGTH}
            multiline
          />
          <Text style={styles.counter}>
            {message.length}/{MAX_POST_MESSAGE_LENGTH}
          </Text>

          {shownError !== '' && <Text style={styles.error}>{shownError}</Text>}

          <TouchableOpacity
            style={[styles.postButton, (isPosting || !profile) && styles.postButtonDisabled]}
            onPress={handlePost}
            disabled={isPosting || !profile}
          >
            {isPosting ? (
              <ActivityIndicator color={colors.text} />
            ) : (
              <Text style={styles.postButtonText}>Post Check-In</Text>
            )}
          </TouchableOpacity>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  flex: { flex: 1 },
  content: { padding: 16, paddingBottom: 40 },
  pageTitle: { color: colors.text, fontSize: 28, fontWeight: '900', marginBottom: 8 },
  sectionTitle: { color: colors.accent, fontSize: 14, fontWeight: '800', marginTop: 20, marginBottom: 8 },
  photo: { width: '100%', aspectRatio: 1, borderRadius: 12, backgroundColor: colors.card },
  link: { color: colors.accent, fontSize: 14, fontWeight: '700', textAlign: 'center', marginTop: 10 },
  photoButtons: { flexDirection: 'row' },
  photoButton: {
    flex: 1,
    backgroundColor: colors.card,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: 10,
    paddingVertical: 18,
    alignItems: 'center',
    marginRight: 8,
  },
  photoButtonText: { color: colors.text, fontSize: 15, fontWeight: '700' },
  messageInput: {
    backgroundColor: colors.card,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: 10,
    color: colors.text,
    fontSize: 16,
    minHeight: 90,
    padding: 12,
    textAlignVertical: 'top',
  },
  counter: { color: colors.textMuted, fontSize: 12, textAlign: 'right', marginTop: 4 },
  error: { color: colors.error, fontSize: 14, textAlign: 'center', marginTop: 12 },
  postButton: {
    backgroundColor: colors.accent,
    borderRadius: 10,
    paddingVertical: 16,
    alignItems: 'center',
    marginTop: 20,
  },
  postButtonDisabled: { opacity: 0.6 },
  postButtonText: { color: colors.text, fontSize: 17, fontWeight: '800' },
});
