import { useRef, useEffect } from 'react';
import {
  requireNativeComponent,
  findNodeHandle,
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
  color?: string;
  style?: ViewStyle;
};

const ComponentName = 'ReactNativePasskeysView';

const _ReactNativePasskeysView =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<ReactNativePasskeysProps>(ComponentName)
    : () => {
        throw new Error(LINKING_ERROR);
      };

let componentRef;
export const ReactNativePasskeysView = (props) => {
  const ref = useRef();
  useEffect(() => {
    componentRef = ref;
  }, []);
  return <_ReactNativePasskeysView {...props} ref={ref} />;
};

export const connect = () =>
  new Promise((resolve, reject) => {
    UIManager.dispatchViewManagerCommand(
      findNodeHandle(componentRef.current),
      UIManager.getViewManagerConfig(ComponentName).Commands.callMethod,
      ['connect', {}]
    );
  });

setTimeout(async () => {
  console.log('test here');
  const result = await connect();
  console.log('test result', result);
}, 3000);
