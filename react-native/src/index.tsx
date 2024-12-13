import { useRef, useEffect } from 'react';
import traverse from 'traverse';
import { Buffer } from 'buffer';
import {
  requireNativeComponent,
  findNodeHandle,
  UIManager,
  Platform,
  NativeModules,
  type ViewStyle,
} from 'react-native';

if (!global.Buffer) global.Buffer = Buffer;

const LINKING_ERROR =
  `The package '@exodus/react-native-passkeys-sdk' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

type ReactNativePasskeysProps = {
  color?: string;
  style?: ViewStyle;
  ref?: any;
};

interface Metadata {
  title: string;
}

// Simplified version of the EIP-712 message type.
// See: https://eips.ethereum.org/EIPS/eip-712.
interface EIP712Message {
  domain: EIP712Domain;
  message: Record<string, unknown>;
}

interface EIP712Domain {
  name?: string;
}

interface Message {
  rawMessage?: Buffer;
  EIP712Message?: EIP712Message;
}

interface RequestParams {}

interface AuthenticatedRequestParams extends RequestParams {
  credentialId: string | Uint8Array;
}

interface SignRequestParams extends AuthenticatedRequestParams {
  metadata: Metadata;
  baseAssetName: string;
}

interface SignTransactionParams extends SignRequestParams {
  transaction: {
    txData: { transactionBuffer: Buffer };
    txMeta: object;
  };
  expiresAt?: number;
}

interface SignMessageParams extends SignRequestParams {
  message: Message;
  address?: string;
}

// mutating
const bufferize = (object: { type?: string; data?: any }) => {
  if (!object) return;
  if (object.type === 'Buffer' && object.data) return Buffer.from(object.data);

  traverse(object).forEach(function (node: any) {
    if (
      Object.hasOwn(node, 'type') &&
      node.type === 'Buffer' &&
      Object.hasOwn(node, 'data')
    ) {
      this.update(Buffer.from(node.data));
    }
  });

  return object;
};

export default bufferize;

const ComponentName = 'ReactNativePasskeysView';

const _ReactNativePasskeysView =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<ReactNativePasskeysProps>(ComponentName)
    : () => {
        throw new Error(LINKING_ERROR);
      };

let componentRef: any;
export const Passkeys = (props: ReactNativePasskeysProps) => {
  const ref = useRef();
  useEffect(() => {
    componentRef = ref;
  }, []);
  return <_ReactNativePasskeysView {...props} ref={ref} />;
};

export const connect = async (): Promise<{
  addresses: any;
  publicKeys: any;
  credentialId: String;
}> => {
  if (!componentRef) throw new Error('Passkeys is not rendered');
  const args = Platform.select({
    ios: [findNodeHandle(componentRef.current), 'connect', {}],
    default: ['connect', {}],
  });
  // @ts-ignore
  return bufferize(
    await NativeModules.ReactNativePasskeysViewManager.callMethod(...args)
  );
};

export const signTransaction = async (
  data: SignTransactionParams
): Promise<{ rawTx: String; txId: String }> => {
  if (!componentRef) throw new Error('Passkeys is not rendered');
  const args = Platform.select({
    ios: [
      findNodeHandle(componentRef.current),
      'signTransaction',
      JSON.parse(JSON.stringify(data)),
    ],
    default: ['signTransaction', JSON.parse(JSON.stringify(data))],
  });
  // @ts-ignore
  return bufferize(
    await NativeModules.ReactNativePasskeysViewManager.callMethod(...args)
  );
};

export const signMessage = async (data: SignMessageParams): Promise<Buffer> => {
  if (!componentRef) throw new Error('Passkeys is not rendered');
  const args = Platform.select({
    ios: [
      findNodeHandle(componentRef.current),
      'signMessage',
      JSON.parse(JSON.stringify(data)),
    ],
    default: ['signMessage', JSON.parse(JSON.stringify(data))],
  });
  // @ts-ignore
  return bufferize(
    await NativeModules.ReactNativePasskeysViewManager.callMethod(...args)
  );
};
