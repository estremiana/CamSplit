import React from 'react';
import { View, Text, Button } from 'react-native';

export default function HomeScreen({ navigation }) {
  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <Text>Welcome to CamSplit!</Text>
      <Button title="Upload Bill" onPress={() => navigation.navigate('Upload Bill')} />
    </View>
  );
} 