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
  `The package '@passkeys/react-native' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

type LoadingData = {
  isLoading: boolean | undefined;
  loadingErrorMessage: String | undefined;
};

type LoadingEvent = {
  nativeEvent: LoadingData | undefined;
};

type PasskeysProps = {
  appId: string;
  url?: string;
  style?: ViewStyle;
  ref?: any;
  onLoadingUpdate: (event: LoadingEvent) => void;
};

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
  baseAssetName: string;
}

interface SignTransactionParams extends SignRequestParams {
  transaction: {
    txData: { transactionBuffer: Buffer };
    txMeta: object;
  };
  broadcast?: boolean;
  expiresAt?: number;
}

interface SignMessageParams extends SignRequestParams {
  message: Message;
  address?: string;
}

interface ExportPrivateKeyParams extends AuthenticatedRequestParams {
  assetName: string;
}

type ErrorResponse = {
  error: string;
};

// possibly mutating
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

const ComponentName = 'PasskeysView';

const _PasskeysView =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<PasskeysProps>(ComponentName)
    : () => {
        throw new Error(LINKING_ERROR);
      };

let componentRef: any;
export const Passkeys = (props: PasskeysProps) => {
  const ref = useRef();
  useEffect(() => {
    componentRef = ref;
  }, []);
  return <_PasskeysView {...props} ref={ref} />;
};

export const connect = async (): Promise<
  | {
      addresses: any;
      publicKeys: any;
      credentialId: String;
    }
  | ErrorResponse
> => {
  if (!componentRef) throw new Error('Passkeys is not rendered');
  const args = Platform.select({
    ios: [findNodeHandle(componentRef.current), 'connect', {}],
    default: ['connect', {}],
  });
  // @ts-ignore
  return bufferize(await NativeModules.PasskeysViewManager.callMethod(...args));
};

export const signTransaction = async (
  data: SignTransactionParams
): Promise<
  | {
      rawTx: String;
      txId: String;
      broadcasted?: boolean;
      broadcastError?: string;
    }
  | ErrorResponse
> => {
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
  return bufferize(await NativeModules.PasskeysViewManager.callMethod(...args));
};

export const signMessage = async (
  data: SignMessageParams
): Promise<Buffer | ErrorResponse> => {
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
  return bufferize(await NativeModules.PasskeysViewManager.callMethod(...args));
};

export const exportPrivateKey = async (
  data: ExportPrivateKeyParams
): Promise<undefined | ErrorResponse> => {
  if (!componentRef) throw new Error('Passkeys is not rendered');
  const args = Platform.select({
    ios: [
      findNodeHandle(componentRef.current),
      'exportPrivateKey',
      JSON.parse(JSON.stringify(data)),
    ],
    default: ['exportPrivateKey', JSON.parse(JSON.stringify(data))],
  });
  // @ts-ignore
  return bufferize(await NativeModules.PasskeysViewManager.callMethod(...args));
};

export const shareWallet = async (
  data: AuthenticatedRequestParams
): Promise<undefined | ErrorResponse> => {
  if (!componentRef) throw new Error('Passkeys is not rendered');
  const args = Platform.select({
    ios: [
      findNodeHandle(componentRef.current),
      'shareWallet',
      JSON.parse(JSON.stringify(data)),
    ],
    default: ['shareWallet', JSON.parse(JSON.stringify(data))],
  });
  // @ts-ignore
  return bufferize(await NativeModules.PasskeysViewManager.callMethod(...args));
};
