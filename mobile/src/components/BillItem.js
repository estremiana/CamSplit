import React from 'react';
import { View, Text } from 'react-native';

export default function BillItem({ item }) {
  return (
    <View>
      <Text>{item.name}: ${item.price}</Text>
    </View>
  );
} 