import type { UI, Linter, Message, Indie } from '../types';
declare function validateUI(ui: UI): boolean;
declare function validateLinter(linter: Linter): boolean;
declare function validateIndie(indie: Indie): boolean;
declare function validateMessages(linterName: string, entries: Array<Message>): boolean;
export { validateUI as ui, validateLinter as linter, validateIndie as indie, validateMessages as messages };
