import React from 'react';
import { View, Text, Button } from 'react-native';

export default function AssignScreen({ navigation }) {
  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <Text>Assign Items to People</Text>
      {/* TODO: Add assignment UI */}
      <Button title="See Results" onPress={() => navigation.navigate('Results')} />
    </View>
  );
} 