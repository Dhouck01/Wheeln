import React from 'react';
import { StyleSheet, View } from 'react-native';
import Ionicons from '@expo/vector-icons/Ionicons';
import { BADGE_COLORS, IconName } from '../constants/badges';

interface Props {
  icon: IconName;
  color: string; // ring and icon color when earned
  size?: number; // width of the hexagon
  locked?: boolean; // gray and dim when nothing on this ladder is earned yet
}

// A pointy-top hexagon built from a rectangle plus a triangle above and below.
// (React Native has no polygon shape, and this avoids installing a drawing package.)
function Hexagon({ width, color }: { width: number; color: string }) {
  const side = width / Math.sqrt(3); // length of each hexagon side
  const triangle = side / 2;
  return (
    <View style={styles.center} pointerEvents="none">
      <View
        style={{
          width: 0,
          height: 0,
          borderLeftWidth: width / 2,
          borderRightWidth: width / 2,
          borderBottomWidth: triangle,
          borderLeftColor: 'transparent',
          borderRightColor: 'transparent',
          borderBottomColor: color,
        }}
      />
      {/* A hair taller than the sides so no thin line shows between the pieces */}
      <View style={{ width, height: side + 1, marginVertical: -0.5, backgroundColor: color }} />
      <View
        style={{
          width: 0,
          height: 0,
          borderLeftWidth: width / 2,
          borderRightWidth: width / 2,
          borderTopWidth: triangle,
          borderLeftColor: 'transparent',
          borderRightColor: 'transparent',
          borderTopColor: color,
        }}
      />
    </View>
  );
}

// The hexagon badge: colored ring, dark middle, icon on top
export function BadgeIcon({ icon, color, size = 56, locked = false }: Props) {
  const ring = locked ? BADGE_COLORS.lockedRing : color;
  const iconColor = locked ? BADGE_COLORS.lockedIcon : color;
  const border = Math.max(2, Math.round(size / 18));
  const height = (2 / Math.sqrt(3)) * size;

  return (
    <View style={{ width: size, height }}>
      <Hexagon width={size} color={ring} />
      <Hexagon width={size - border * 2} color={BADGE_COLORS.fill} />
      <View style={styles.center} pointerEvents="none">
        <Ionicons name={icon} size={Math.round(size * 0.42)} color={iconColor} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  center: { ...StyleSheet.absoluteFill, alignItems: 'center', justifyContent: 'center' },
});
