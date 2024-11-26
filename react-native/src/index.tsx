import {
  requireNativeComponent,
  UIManager,
  Platform,
  type ViewStyle,
} from 'react-native';

const LINKING_ERROR =
  `The package '@exodus/react-native-passkeys' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

type ReactNativePasskeysProps = {
  color: string;
  style: ViewStyle;
};

const ComponentName = 'ReactNativePasskeysView';

export const ReactNativePasskeysView =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<ReactNativePasskeysProps>(ComponentName)
    : () => {
        throw new Error(LINKING_ERROR);
      };
