import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { View, Text, StyleSheet } from 'react-native';
import { ProfileScreen } from '../screens/ProfileScreen';
import { FeedScreen } from '../screens/FeedScreen';

// Placeholder screens — replace these with real screen components as you build them
function CheckInScreen() {
  return <View style={s.screen}><Text style={s.text}>Check In</Text></View>;
}
function RankingsScreen() {
  return <View style={s.screen}><Text style={s.text}>Rankings</Text></View>;
}

const s = StyleSheet.create({
  screen: { flex: 1, backgroundColor: '#0D0D0D', alignItems: 'center', justifyContent: 'center' },
  text: { color: '#fff', fontSize: 20 },
});

// Simple SVG-free icon text — swap for @expo/vector-icons once installed
function Icon({ name, color }: { name: string; color: string }) {
  const icons: Record<string, string> = {
    home: '⌂',
    plus: '＋',
    trophy: '🏆',
    person: '◉',
  };
  return <Text style={{ fontSize: 22, color }}>{icons[name]}</Text>;
}

const Tab = createBottomTabNavigator();

export function TabNavigator() {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarShowLabel: false,
        tabBarStyle: {
          backgroundColor: '#1A1A1A',
          borderTopColor: '#2A2A2A',
          height: 60,
        },
        tabBarActiveTintColor: '#FF5A00',
        tabBarInactiveTintColor: '#666666',
      }}
    >
      <Tab.Screen
        name="Feed"
        component={FeedScreen}
        options={{ tabBarIcon: ({ color }) => <Icon name="home" color={color} /> }}
      />
      <Tab.Screen
        name="CheckIn"
        component={CheckInScreen}
        options={{ tabBarIcon: ({ color }) => <Icon name="plus" color={color} /> }}
      />
      <Tab.Screen
        name="Rankings"
        component={RankingsScreen}
        options={{ tabBarIcon: ({ color }) => <Icon name="trophy" color={color} /> }}
      />
      <Tab.Screen
        name="Profile"
        component={ProfileScreen}
        options={{ tabBarIcon: ({ color }) => <Icon name="person" color={color} /> }}
      />
    </Tab.Navigator>
  );
}
