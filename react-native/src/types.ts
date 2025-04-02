import type { ViewStyle } from 'react-native';

export type LoadingData = {
  isLoading: boolean | undefined;
  loadingErrorMessage: String | undefined;
};

export type LoadingEvent = {
  nativeEvent: LoadingData | undefined;
};

export type PasskeysProps = {
  appId: string;
  url?: string;
  style?: ViewStyle;
  ref?: any;
  onLoadingUpdate: (event: LoadingEvent) => void;
};

export type AnyObject = Record<string, unknown>;

// Simplified version of the EIP-712 message type.
// See: https://eips.ethereum.org/EIPS/eip-712.
export interface EIP712Message extends AnyObject {
  domain: EIP712Domain;
  message: AnyObject;
}

export interface EIP712Domain extends AnyObject {
  name?: string;
}

export interface Message {
  rawMessage?: Buffer;
  EIP712Message?: EIP712Message;
}

export interface RequestParams {}

export interface AuthenticatedRequestParams extends RequestParams {
  credentialId: string | Uint8Array;
}

export interface SignRequestParams extends AuthenticatedRequestParams {
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

type SignInInput = {
  assetName: string;
  domain?: string;
  chainId?: string;
  nonce?: string;
  issuedAt?: string;
};

export type SignInParams = {
  inputs: SignInInput[];
};

type Base64 = string;

export type SignedMessage = {
  assetName: string;
  address: string;
  signedMessage: Base64;
  signature: Base64;
};

export type SignInResponse = ConnectResponse & {
  signatures: SignedMessage[];
};
