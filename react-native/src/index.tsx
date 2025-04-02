import { useEffect, useRef } from 'react';
import traverse from 'traverse';
import { Buffer } from 'buffer';
import {
  findNodeHandle,
  NativeModules,
  Platform,
  requireNativeComponent,
  UIManager,
} from 'react-native';

import type {
  AuthenticatedRequestParams,
  ConnectResponse,
  ErrorResponse,
  ExportPrivateKeyParams,
  PasskeysProps,
  SignInParams,
  SignInResponse,
  SignMessageParams,
  SignTransactionParams,
  SignTransactionResponse,
} from './types';

if (!global.Buffer) global.Buffer = Buffer;

const LINKING_ERROR =
  `The package '@passkeys/react-native' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

// possibly mutating
export const bufferize = (object: { type?: string; data?: any }) => {
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

export const isErrorResponse = <R extends object>(
  response: R | ErrorResponse
): response is ErrorResponse => {
  return Object.hasOwn(response, 'error');
};

const ComponentName = 'PasskeysView';

const PasskeysView =
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
  return <PasskeysView {...props} ref={ref} />;
};

const callMethod = async <T,>(name: string, params?: object): Promise<T> => {
  if (!componentRef) {
    throw new Error(`Cannot call ${name}. Passkeys is not rendered`);
  }

  const payload = params ? JSON.parse(JSON.stringify(params)) : {};

  const args = Platform.select({
    ios: [findNodeHandle(componentRef.current), name, payload],
    default: [name, payload],
  });

  const response = await NativeModules.PasskeysViewManager.callMethod(...args);

  return bufferize(response) as T;
};

export const connect = async () => {
  return callMethod<ConnectResponse | ErrorResponse>('connect');
};

export const signIn = async (data: SignInParams) => {
  return callMethod<SignInResponse | ErrorResponse>('signIn', data);
};

export const signTransaction = async (data: SignTransactionParams) =>
  callMethod<SignTransactionResponse | ErrorResponse>('signTransaction', data);

export const signMessage = async (data: SignMessageParams) =>
  callMethod<Buffer | ErrorResponse>('signMessage', data);

export const exportPrivateKey = async (data: ExportPrivateKeyParams) =>
  callMethod<undefined | ErrorResponse>('exportPrivateKey', data);

export const shareWallet = async (data: AuthenticatedRequestParams) =>
  callMethod<undefined | ErrorResponse>('shareWallet', data);

export type * from './types';
