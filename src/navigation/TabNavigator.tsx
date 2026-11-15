import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import Ionicons from '@expo/vector-icons/Ionicons';
import { ProfileScreen } from '../screens/ProfileScreen';
import { FeedScreen } from '../screens/FeedScreen';
import { RankingsScreen } from '../screens/RankingsScreen';
import { CheckInScreen } from '../screens/CheckInScreen';
import { colors, TAB_BAR_HEIGHT } from '../constants/theme';

type IconName = React.ComponentProps<typeof Ionicons>['name'];

const Tab = createBottomTabNavigator();

// Icons only, no labels. Filled icon = this tab is open.
function tabIcon(active: IconName, inactive: IconName) {
  return ({ color, focused }: { color: string; focused: boolean }) => (
    <Ionicons name={focused ? active : inactive} size={26} color={color} />
  );
}

export function TabNavigator() {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarShowLabel: false,
        tabBarStyle: {
          backgroundColor: colors.card,
          borderTopColor: colors.border,
          height: TAB_BAR_HEIGHT,
        },
        tabBarActiveTintColor: colors.accent,
        tabBarInactiveTintColor: colors.inactive,
      }}
    >
      <Tab.Screen name="Feed" component={FeedScreen} options={{ tabBarIcon: tabIcon('home', 'home-outline') }} />
      <Tab.Screen
        name="CheckIn"
        component={CheckInScreen}
        options={{ tabBarIcon: tabIcon('add-circle', 'add-circle-outline') }}
      />
      <Tab.Screen
        name="Rankings"
        component={RankingsScreen}
        options={{ tabBarIcon: tabIcon('trophy', 'trophy-outline') }}
      />
      <Tab.Screen
        name="Profile"
        component={ProfileScreen}
        options={{ tabBarIcon: tabIcon('person', 'person-outline') }}
      />
    </Tab.Navigator>
  );
}
