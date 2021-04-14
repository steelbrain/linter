import type TooltipDelegate from './delegate';
import type { Message } from '../types';
declare type Props = {
    key: string;
    message: Message;
    delegate: TooltipDelegate;
};
export default function MessageElement(props: Props): import("solid-js/jsx-runtime").JSX.Element;
export {};
