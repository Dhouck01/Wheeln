import React, { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { formatDistanceToNowStrict } from 'date-fns';
import { useComments } from '../hooks/useFeed';
import { colors, MAX_COMMENT_LENGTH } from '../constants/theme';

interface Props {
  postId: string | null; // null = sheet closed
  profileId: string | undefined;
  onClose: () => void;
}

// A panel that slides up showing a post's comments and a box to add one
export function CommentSheet({ postId, profileId, onClose }: Props) {
  const { comments, isLoading, isSending, error, addComment } = useComments(postId, profileId);
  const [text, setText] = useState('');

  // Start with an empty text box each time a different post is opened
  useEffect(() => {
    setText('');
  }, [postId]);

  async function handleSend() {
    const saved = await addComment(text);
    if (saved) setText('');
  }

  return (
    <Modal visible={postId !== null} transparent animationType="slide" onRequestClose={onClose}>
      <KeyboardAvoidingView
        style={styles.overlay}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <Pressable style={styles.backdrop} onPress={onClose} />
        <View style={styles.sheet}>
          <View style={styles.titleRow}>
            <Text style={styles.title}>Comments</Text>
            <TouchableOpacity onPress={onClose} accessibilityLabel="Close comments">
              <Text style={styles.close}>✕</Text>
            </TouchableOpacity>
          </View>

          {isLoading ? (
            <ActivityIndicator color={colors.accent} style={styles.loading} />
          ) : (
            <FlatList
              data={comments}
              keyExtractor={(c) => c.id}
              style={styles.list}
              ListEmptyComponent={<Text style={styles.empty}>No comments yet. Be the first.</Text>}
              renderItem={({ item }) => (
                <View style={styles.comment}>
                  <Text style={styles.commentName}>
                    @{item.users?.username ?? 'unknown'}{' '}
                    <Text style={styles.commentTime}>
                      {formatDistanceToNowStrict(new Date(item.created_at), { addSuffix: true })}
                    </Text>
                  </Text>
                  <Text style={styles.commentText}>{item.message}</Text>
                </View>
              )}
            />
          )}

          {error !== '' && <Text style={styles.error}>{error}</Text>}

          <View style={styles.inputRow}>
            <TextInput
              style={styles.input}
              value={text}
              onChangeText={setText}
              placeholder="Add a comment…"
              placeholderTextColor={colors.inactive}
              maxLength={MAX_COMMENT_LENGTH}
              multiline
            />
            <TouchableOpacity
              style={[styles.send, (text.trim() === '' || isSending) && styles.sendDisabled]}
              onPress={handleSend}
              disabled={text.trim() === '' || isSending}
            >
              {isSending ? (
                <ActivityIndicator color={colors.text} />
              ) : (
                <Text style={styles.sendText}>Post</Text>
              )}
            </TouchableOpacity>
          </View>
        </View>
      </KeyboardAvoidingView>
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
    maxHeight: '75%',
    minHeight: '45%',
    paddingBottom: 24,
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
  loading: { marginVertical: 32 },
  list: { paddingHorizontal: 16 },
  empty: { color: colors.textMuted, textAlign: 'center', marginVertical: 32 },
  comment: { paddingVertical: 10 },
  commentName: { color: colors.text, fontSize: 14, fontWeight: '700' },
  commentTime: { color: colors.inactive, fontSize: 12, fontWeight: '400' },
  commentText: { color: colors.text, fontSize: 15, marginTop: 2, lineHeight: 20 },
  error: { color: colors.error, fontSize: 13, paddingHorizontal: 16, paddingTop: 8 },
  inputRow: { flexDirection: 'row', alignItems: 'flex-end', paddingHorizontal: 16, paddingTop: 10 },
  input: {
    flex: 1,
    backgroundColor: colors.background,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: 10,
    color: colors.text,
    fontSize: 15,
    paddingHorizontal: 12,
    paddingVertical: 10,
    maxHeight: 100,
  },
  send: {
    backgroundColor: colors.accent,
    borderRadius: 10,
    paddingHorizontal: 16,
    paddingVertical: 11,
    marginLeft: 8,
    minWidth: 60,
    alignItems: 'center',
  },
  sendDisabled: { opacity: 0.4 },
  sendText: { color: colors.text, fontWeight: '700', fontSize: 15 },
});
