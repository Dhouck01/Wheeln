import { useEffect, useState } from 'react';
import * as ImagePicker from 'expo-image-picker';
import { manipulateAsync, SaveFormat } from 'expo-image-manipulator';
import supabase from '../lib/supabase';
import { useAuthStore } from '../store/authStore';
import { useFeedStore } from '../store/feedStore';
import { CHECKIN_PHOTO_WIDTH, MAX_POST_MESSAGE_LENGTH } from '../constants/theme';
import { LocationSummary } from '../types';

const PHOTO_BUCKET = 'post-photos';

// Search approved places by name. With an empty search, shows the busiest ones.
export function useLocationSearch(search: string) {
  const [results, setResults] = useState<LocationSummary[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    let cancelled = false;
    setIsLoading(true);
    setError('');
    // Wait a moment after typing stops so we do not ask the database on every key
    const timer = setTimeout(async () => {
      // Strip characters that have a special meaning in the search filter
      const cleaned = search.trim().replace(/[%_,()\\]/g, ' ');
      let query = supabase.from('locations').select('id, name, type').limit(20);
      if (cleaned !== '') query = query.ilike('name', `%${cleaned}%`);
      query = query.order('total_checkins', { ascending: false }).order('name', { ascending: true });
      const { data, error: dbError } = await query;
      if (cancelled) return;
      if (dbError) setError(dbError.message);
      else setResults((data ?? []) as LocationSummary[]);
      setIsLoading(false);
    }, 250);
    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [search]);

  return { results, isLoading, error };
}

export interface PickedPhoto {
  uri: string;
}

// Everything the Check In screen needs: choose a photo, then post
export function useCheckIn(profileId: string | undefined) {
  const authId = useAuthStore((s) => s.user?.id);
  const requestReload = useFeedStore((s) => s.requestReload);
  const [photo, setPhoto] = useState<PickedPhoto | null>(null);
  const [isPosting, setIsPosting] = useState(false);
  const [error, setError] = useState('');

  async function pickPhoto(source: 'camera' | 'library') {
    setError('');
    try {
      const permission =
        source === 'camera'
          ? await ImagePicker.requestCameraPermissionsAsync()
          : await ImagePicker.requestMediaLibraryPermissionsAsync();
      if (!permission.granted) {
        setError(
          source === 'camera'
            ? 'Camera access is off. Turn it on in your phone settings.'
            : 'Photo access is off. Turn it on in your phone settings.'
        );
        return;
      }
      const options: ImagePicker.ImagePickerOptions = {
        mediaTypes: ['images'],
        allowsEditing: true,
        aspect: [1, 1],
        quality: 1,
      };
      const result =
        source === 'camera'
          ? await ImagePicker.launchCameraAsync(options)
          : await ImagePicker.launchImageLibraryAsync(options);
      if (!result.canceled && result.assets.length > 0) {
        setPhoto({ uri: result.assets[0].uri });
      }
    } catch (e: any) {
      setError(e?.message ?? 'Could not get the photo.');
    }
  }

  function clearPhoto() {
    setPhoto(null);
  }

  // Returns true when the check-in was saved
  async function submit(input: {
    location: LocationSummary | null;
    message: string;
    stars: number;
    difficulty: number;
  }): Promise<boolean> {
    if (isPosting) return false;
    if (!profileId || !authId) {
      setError('Your profile has not loaded yet. Try again in a moment.');
      return false;
    }
    if (!input.location) {
      setError('Pick a place first.');
      return false;
    }
    if (!photo) {
      setError('Add a photo first.');
      return false;
    }
    if (input.stars < 1 || input.difficulty < 1) {
      setError('Rate both how much you liked it and how hard it was.');
      return false;
    }
    const message = input.message.trim();
    if (message.length > MAX_POST_MESSAGE_LENGTH) {
      setError(`Keep your message under ${MAX_POST_MESSAGE_LENGTH} characters.`);
      return false;
    }

    setIsPosting(true);
    setError('');
    try {
      // 1. Shrink the photo so it uploads fast and does not eat storage
      const small = await manipulateAsync(photo.uri, [{ resize: { width: CHECKIN_PHOTO_WIDTH } }], {
        compress: 0.8,
        format: SaveFormat.JPEG,
      });
      const response = await fetch(small.uri);
      const bytes = await response.arrayBuffer();

      // 2. Upload into a folder named with the login id (the storage rule requires it)
      const path = `${authId}/${Date.now()}.jpg`;
      const { error: uploadError } = await supabase.storage
        .from(PHOTO_BUCKET)
        .upload(path, bytes, { contentType: 'image/jpeg' });
      if (uploadError) throw uploadError;
      const { data: urlData } = supabase.storage.from(PHOTO_BUCKET).getPublicUrl(path);

      // 3. Save the post
      const { error: postError } = await supabase.from('posts').insert({
        user_id: profileId,
        location_id: input.location.id,
        photo_url: urlData.publicUrl,
        message: message === '' ? null : message,
        star_rating: input.stars,
        difficulty_rating: input.difficulty,
      });
      if (postError) throw postError;

      setPhoto(null);
      requestReload(); // the Feed reloads so the new post shows at the top
      return true;
    } catch (e: any) {
      setError(e?.message ?? 'Could not post your check-in. Try again.');
      return false;
    } finally {
      setIsPosting(false);
    }
  }

  return { photo, pickPhoto, clearPhoto, submit, isPosting, error, setError };
}
