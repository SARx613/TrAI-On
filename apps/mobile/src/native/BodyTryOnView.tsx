import type { ComponentType } from 'react';
import { requireNativeComponent, Platform, ViewProps } from 'react-native';

type NativeProps = ViewProps & {
  garmentName?: string;
  jointMapResource?: string;
};

const NativeBodyTryOnView: ComponentType<NativeProps> =
  Platform.OS === 'ios'
    ? requireNativeComponent<NativeProps>('BodyTryOnView')
    : () => null;

export default NativeBodyTryOnView;
