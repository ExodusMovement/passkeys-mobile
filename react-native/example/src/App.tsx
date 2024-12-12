import { useState } from 'react';
import { SafeAreaView, StyleSheet, TouchableOpacity, Text } from 'react-native';

import {
  ReactNativePasskeysView,
  connect,
  signMessage,
} from '@exodus/react-native-passkeys';
import { Buffer } from 'buffer';

global.Buffer = Buffer;

export default function App() {
  const [addresses, setAddresses] = useState();
  const [credentialId, setCredentialId] = useState();

  return (
    <SafeAreaView style={styles.container}>
      {!credentialId && (
        <TouchableOpacity
          onPress={async () => {
            try {
              const { addresses, credentialId: id } = await connect();
              setAddresses(addresses);
              setCredentialId(id);
              console.log('addresses', addresses);
            } catch (error) {
              console.error(error);
            }
          }}
        >
          <Text>Connect</Text>
        </TouchableOpacity>
      )}
      {credentialId && (
        <TouchableOpacity
          onPress={async () => {
            try {
              const signedMessageResponse = await signMessage({
                message: {
                  rawMessage: Buffer.from('Hello World!'),
                },
                baseAssetName: 'ethereum',
                credentialId,
              });
              console.log('signedMessageResponse', signedMessageResponse);
            } catch (error) {
              console.error(error);
            }
          }}
        >
          <Text>Sign Message</Text>
        </TouchableOpacity>
      )}

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
