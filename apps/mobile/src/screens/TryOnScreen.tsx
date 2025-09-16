import React from 'react';
import { View, Text, Platform, StyleSheet } from 'react-native';
import NativeBodyTryOnView from '../native/BodyTryOnView';

export default function TryOnScreen() {
  if (Platform.OS !== 'ios') {
    return (
      <View style={styles.center}>
        <Text>iOS requis (ARKit).</Text>
      </View>
    );
  }
  return (
    <View style={styles.container}>
      <NativeBodyTryOnView
        style={StyleSheet.absoluteFillObject}
        garmentName="tshirt"
        jointMapResource="GarmentJointMap"
      />
      <View style={styles.hud}>
        <Text style={styles.hudText}>Bouge les bras : le vêtement suit les articulations.</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: 'black' },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  hud: { position: 'absolute', top: 40, left: 0, right: 0, alignItems: 'center' },
  hudText: { color: '#fff', fontWeight: '600', textAlign: 'center', paddingHorizontal: 16 },
});
