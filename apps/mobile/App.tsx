import React from 'react';
import { SafeAreaView, StatusBar } from 'react-native';
import TryOnScreen from './src/screens/TryOnScreen';

export default function App() {
  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: 'black' }}>
      <StatusBar barStyle="light-content" />
      <TryOnScreen />
    </SafeAreaView>
  );
}
