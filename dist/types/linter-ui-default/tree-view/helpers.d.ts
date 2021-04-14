import type { LinterMessage } from '../types';
import type { TreeViewHighlight } from './index';
export declare function getChunks(filePath: string, projectPath: string): Array<string>;
export declare function getChunksByProjects(filePath: string, projectPaths: Array<string>): Array<string>;
export declare function mergeChange(change: Record<string, TreeViewHighlight>, filePath: string, severity: string): void;
export declare function calculateDecorations(decorateOnTreeView: 'Files and Directories' | 'Files' | undefined, messages: Array<LinterMessage>): Record<string, TreeViewHighlight>;
