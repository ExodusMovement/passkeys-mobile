import { SafeAreaView, StyleSheet, TouchableOpacity, Text } from 'react-native';

import {
  ReactNativePasskeysView,
  connect,
} from '@exodus/react-native-passkeys';

export default function App() {
  return (
    <SafeAreaView style={styles.container}>
      <TouchableOpacity
        onPress={async () => {
          try {
            const { addresses } = await connect();
            console.log('addresses', addresses)
          } catch (error) {
            console.error(error);
          }
        }}
      >
        <Text>Connect</Text>
      </TouchableOpacity>
      <ReactNativePasskeysView style={styles.passkeys} />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: '100%',
    height: '100%',
    marginVertical: 20,
  },
  passkeys: {
    width: 0,
    height: 0,
  },
});
