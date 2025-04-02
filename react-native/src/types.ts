import type { ViewStyle } from 'react-native';

type LoadingData = {
  isLoading: boolean | undefined;
  loadingErrorMessage: String | undefined;
};

type LoadingEvent = {
  nativeEvent: LoadingData | undefined;
};

export type PasskeysProps = {
  appId: string;
  url?: string;
  style?: ViewStyle;
  ref?: any;
  onLoadingUpdate: (event: LoadingEvent) => void;
};

type AnyObject = Record<string, unknown>;

// Simplified version of the EIP-712 message type.
// See: https://eips.ethereum.org/EIPS/eip-712.
interface EIP712Message extends AnyObject {
  domain: EIP712Domain;
  message: AnyObject;
}

interface EIP712Domain extends AnyObject {
  name?: string;
}

interface Message {
  rawMessage?: Buffer;
  EIP712Message?: EIP712Message;
}

interface RequestParams {}

export interface AuthenticatedRequestParams extends RequestParams {
  credentialId: string | Uint8Array;
}

interface SignRequestParams extends AuthenticatedRequestParams {
  baseAssetName: string;
}

export interface SignTransactionParams extends SignRequestParams {
  transaction: {
    txData: { transactionBuffer: Buffer };
    txMeta: object;
  };
  broadcast?: boolean;
  expiresAt?: number;
}

export interface SignMessageParams extends SignRequestParams {
  message: Message;
  address?: string;
}

export interface ExportPrivateKeyParams extends AuthenticatedRequestParams {
  assetName: string;
}

export type ErrorResponse = {
  error: string;
};

export type ConnectResponse = {
  addresses: any;
  publicKeys: any;
  credentialId: string;
};

export type SignTransactionResponse = {
  rawTx: string;
  txId: string;
  broadcasted?: boolean;
  broadcastError?: string;
};
