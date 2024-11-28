import { SafeAreaView, StyleSheet } from 'react-native';

import { ReactNativePasskeysView } from '@exodus/react-native-passkeys';

export default function App() {
  return (
    <SafeAreaView style={styles.container}>
      <ReactNativePasskeysView style={styles.box} />
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
});
