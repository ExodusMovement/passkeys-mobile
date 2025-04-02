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

export type RawMessagePayload = {
  rawMessage: Buffer;
};

export type EIP712MessagePayload = {
  EIP712Message: EIP712Message;
};

export type Hex = string;

export type BIP322MessagePayload = {
  bip322Message: {
    message: Buffer | Hex;
    address: string;
  };
};

export type Message =
  | RawMessagePayload
  | EIP712MessagePayload
  | BIP322MessagePayload;

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

export type CachedPublicKey = {
  key: string;
  publicKey: any;
};

export type CachedAddress = {
  key: string;
  address: {
    address: string;
    meta: {
      path: string;
      purpose: number;
      [key: string]: any;
    };
  };
};

export type ConnectResponse = {
  backedUp?: boolean;
  telemetryId: string;
  shareActivity: boolean;
  addresses: CachedAddress[];
  publicKeys: CachedPublicKey[];
  credentialId: string;
};

export type SignTransactionResponse = {
  rawTx: string;
  txId: string;
  broadcasted?: boolean;
  broadcastError?: string;
};

export type SignInInput = {
  assetName: string;
  domain?: string;
  chainId?: string;
  nonce?: string;
  issuedAt?: string;
};

export type SignInParams = {
  inputs: SignInInput[];
};

export type Base64 = string;

export type SignedMessage = {
  assetName: string;
  address: string;
  signedMessage: Base64;
  signature: Base64;
};

export type SignInResponse = ConnectResponse & {
  signatures: SignedMessage[];
};
