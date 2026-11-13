// Brand colors and fixed values. Use these instead of typing colors inline.

export const colors = {
  background: '#0D0D0D',
  card: '#1A1A1A',
  accent: '#FF5A00',
  text: '#FFFFFF',
  textMuted: '#999999',
  inactive: '#666666',
  border: '#2A2A2A',
  error: '#FF4D4D',
} as const;

export const FEED_PAGE_SIZE = 20;
export const MAX_COMMENT_LENGTH = 300; // matches the database limit
