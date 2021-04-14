import type { Point, TextEditor, TextEditorElement, PointLike } from 'atom';
import type TooltipElement from '../tooltip/index';
export declare function getBufferPositionFromMouseEvent(event: MouseEvent, editor: TextEditor, editorElement: TextEditorElement): Point | null;
export declare function mouseEventNearPosition({ event, editor, editorElement, tooltipElement, screenPosition, }: {
    event: {
        clientX: number;
        clientY: number;
    };
    editor: TextEditor;
    editorElement: TextEditorElement;
    tooltipElement: TooltipElement['element'];
    screenPosition: PointLike;
}): boolean;
export declare function hasParent(givenElement: HTMLElement, selector: string): boolean;
