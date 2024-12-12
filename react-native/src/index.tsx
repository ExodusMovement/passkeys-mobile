import { useRef, useEffect } from 'react';
import {
  requireNativeComponent,
  findNodeHandle,
  UIManager,
  Platform,
  NativeModules,
  type ViewStyle,
} from 'react-native';

const LINKING_ERROR =
  `The package '@exodus/react-native-passkeys' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

type ReactNativePasskeysProps = {
  color?: string;
  style?: ViewStyle;
  ref?: any;
};

const ComponentName = 'ReactNativePasskeysView';

const _ReactNativePasskeysView =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<ReactNativePasskeysProps>(ComponentName)
    : () => {
        throw new Error(LINKING_ERROR);
      };

let componentRef: any;
export const ReactNativePasskeysView = (props: ReactNativePasskeysProps) => {
  const ref = useRef();
  useEffect(() => {
    componentRef = ref;
  }, []);
  return <_ReactNativePasskeysView {...props} ref={ref} />;
};

export const connect = () => {
  if (!componentRef) throw new Error('ReactNativePasskeysView is not rendered');
  return NativeModules.ReactNativePasskeysViewManager.callMethod(
    findNodeHandle(componentRef.current),
    'connect',
    {}
  );
};
