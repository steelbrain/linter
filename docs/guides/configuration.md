# Configuring Linter

There are all sorts of useful changes you can make to how Linter behaves. The
preferred method of changing the settings is from within the Atom Settings UI.
If necessary though the settings can be changed from within your Atom
configuration file.

## Configurable settings

*   `lintOnFly`: Lint files while typing, without the need to save

*   `lintOnFlyInterval`: Interval at which providers are triggered as you type
    (in ms)

*   `ignoredMessageTypes`: Comma separated list of message types to completely
    ignore

*   `ignoreVCSIgnoredFiles`: Do Not Lint Files Ignored by VCS, e.g. ignore files
    specified in .gitignore

*   `ignoreMatchedFiles`: Do Not Lint Files that match this Glob

*   `showErrorInline`: Show Inline Error Tooltips

*   `inlineTooltipInterval`: Interval at which inline tooltip is updated (in ms)

*   `gutterEnabled`: Highlight Error Lines in Gutter

*   `gutterPosition`: Position of Gutter Highlights

*   `underlineIssues`: Underline Issues

*   `showProviderName`: Show Provider Name (When Available)

*   `showErrorPanel`: Show a list of errors at the bottom of the editor

*   `errorPanelHeight`: Height of the error panel (in px)

*   `alwaysTakeMinimumSpace`: Reduce panel height when it exceeds the height of
    the error list

*   `displayLinterInfo`: Whether to show any linter information in the status bar

*   `displayLinterStatus`: Display Linter Status Info in Status Bar (The
    `No Issues` or `X Issues` widget)

*   `showErrorTabLine`: Show "Line" Tab in the Status Bar

*   `showErrorTabFile`: Show "File" Tab in the Status Bar

*   `showErrorTabProject`: Show "Project" Tab in the Status Bar

*   `statusIconScope`: Scope of Linter Messages to Show in Status Icon

*   `statusIconPosition`: Position of Status Icon in the Status Bar
