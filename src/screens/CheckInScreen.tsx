import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import Ionicons from '@expo/vector-icons/Ionicons';
import { SafeAreaView } from 'react-native-safe-area-context';
import { colors } from '../constants/theme';

// Temporary screen until check-in is built (build order step 2, slice 2)
export function CheckInScreen() {
  return (
    <SafeAreaView style={styles.screen} edges={['top']}>
      <View style={styles.box}>
        <Ionicons name="add-circle" size={64} color={colors.accent} />
        <Text style={styles.title}>Check-in coming soon</Text>
        <Text style={styles.text}>Soon you can check in at tracks, strips and trails here.</Text>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  box: { flex: 1, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 32 },
  title: { color: colors.text, fontSize: 20, fontWeight: '800', marginTop: 16, marginBottom: 6 },
  text: { color: colors.textMuted, fontSize: 15, textAlign: 'center' },
});
