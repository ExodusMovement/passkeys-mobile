# @passkeys/react-native

@passkeys/react-native

## Installation

```sh
npm install @passkeys/react-native
```

## Usage

```js
import {
  Passkeys,
  connect,
  signMessage,
  signTransaction,
  exportPrivateKey,
  shareWallet,
} from '@passkeys/react-native';

// ...

<Passkeys appId="test" />;

const { addresses, credentialId: id } = await connect();

const signedMessageResponse = await signMessage({
  message: {
    rawMessage: Buffer.from('Hello World!'),
  },
  baseAssetName: 'ethereum',
  credentialId,
});

const signedMessageResponse = await signMessage({
  message: {
    EIP712Message: {
      types: {
        EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
        ],
        DummyType: [{ name: 'name', type: 'string' }],
      },
      primaryType: 'DummyType',
      domain: {
        name: 'Passkeys Network',
        version: '1',
        chainId: 1,
        verifyingContract: '0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC',
      },
      message: {
        name: 'Fred',
      },
    },
  },
});

const signTransactionResponse = await signTransaction({
  transaction: {
    txData: {
      transactionBuffer: Buffer.from(
        'AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAEDlQMu5tnOGTuT6craZOCkndrjA9o2EJb1rBw/ohlcpypy8Z7Z8rsF8SRaO8FE7vKMoIjCMnrsYrINFR5JNNf2tAbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCppgV9A6KWVpt6hEMng2GqzikT9gsGmsvUzYWZIQ6KoPcBAgMBAQAJA0BCDwAAAAAA',
        'base64'
      ),
    },
    txMeta: Object.create(null),
  },
  baseAssetName: 'solana',
  credentialId,
});

const { rawTx, txId, broadcasted, broadcastError } = await signTransaction({
  transaction: {
    txData: {
      transactionBuffer: Buffer.from(
        'AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAEDlQMu5tnOGTuT6craZOCkndrjA9o2EJb1rBw/ohlcpypy8Z7Z8rsF8SRaO8FE7vKMoIjCMnrsYrINFR5JNNf2tAbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCppgV9A6KWVpt6hEMng2GqzikT9gsGmsvUzYWZIQ6KoPcBAgMBAQAJA0BCDwAAAAAA',
        'base64'
      ),
    },
    txMeta: Object.create(null),
  },
  broadcast: true,
  baseAssetName: 'solana',
  credentialId,
});

const exportPrivateKeyResponse = await exportPrivateKey({
  assetName: 'solana',
  credentialId,
});

const shareWalletResponse = await shareWallet({
  credentialId,
});
```

## License

MIT
