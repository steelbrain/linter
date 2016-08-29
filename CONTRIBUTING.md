# Contributing to `linter`

:+1::tada: First off, thanks for taking the time to contribute! :tada::+1:

The following is a set of guidelines for contributing to linter.
These are just guidelines, not rules, use your best judgment and feel free to
propose changes to this document in a pull request.

This project adheres to the [Open Code of Conduct][code-of-conduct]. By participating, you are expected to uphold this code.

## Submitting Issues

* You can create an issue [here](https://github.com/steelbrain/linter/issues/new), but
  before doing that please read the notes below on collecting information and submitting issues.
  Include as many details as possible with your report.
* Include the version of Atom you are using and the OS.
* Include screenshots and animated GIFs whenever possible; they are immensely
  helpful.
* Include the behavior you expected and other places you've seen that behavior
  such as Emacs, vi, Xcode, etc.
* Check the dev tools (`alt-cmd-i`) for errors to include. If the dev tools
  are open _before_ the error is triggered, a full stack trace for the error
  will be logged. If you can reproduce the error, use this approach to get the
  full stack trace and include it in the issue.
* On Mac, check Console.app for stack traces to include if reporting a crash.
* Perform a [cursory search](https://github.com/steelbrain/linter/search?q=&type=Issues&utf8=%E2%9C%93)
  to see if a similar issue has already been submitted.
* Please setup a [profile picture](https://help.github.com/articles/how-do-i-set-up-my-profile-picture)
  to make yourself recognizable and so we can all get to know each other better.

## Pull Requests

* We prefer small, focused, single-responsibility pull requests that include tests where possible. These can be contrasted with large pull requests, pull requests with multiple unrelated concerns, and pull requests which have no tests.
* Include screenshots and animated GIFs in your pull request whenever possible.
* **Please ensure that your pull request has no lint errors.** This is a project for linters after all,
  so please ensure you have the [linter-eslint](https://atom.io/packages/linter-eslint) package installed in
  Atom.
* Include thoughtfully-worded, well-structured
  [Jasmine](http://jasmine.github.io/) specs in the `./spec` folder. Run them using `apm test`. See
  the [Specs Styleguide](#specs-styleguide) below.
* Document new code based on the
  [Documentation Styleguide](#documentation-styleguide)
* End files with a newline.
* Place requires in the following order:
    * Built in Node Modules (such as `path`)
    * Built in Atom and Atom Shell Modules (such as `atom`, `shell`)
    * Local Modules (using relative paths)
* Place class properties in the following order:
    * Class methods and properties (methods starting with a `@`)
    * Instance methods and properties
* Avoid platform-dependent code:
    * Use `require('fs-plus').getHomeDirectory()` to get the home directory.
    * Use `path.join()` to concatenate filenames.
    * Use `os.tmpdir()` rather than `/tmp` when you need to reference the
      temporary directory.
* Using a plain `return` when returning explicitly at the end of a function.
    * Not `return null`, `return undefined`, `null`, or `undefined`

## Git Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally
* Consider starting the commit message with an applicable emoji:
    * :art: `:art:` when improving the format/structure of the code
    * :racehorse: `:racehorse:` when improving performance
    * :non-potable_water: `:non-potable_water:` when plugging memory leaks
    * :memo: `:memo:` when writing docs
    * :penguin: `:penguin:` when fixing something on Linux
    * :apple: `:apple:` when fixing something on Mac OS
    * :checkered_flag: `:checkered_flag:` when fixing something on Windows
    * :bug: `:bug:` when fixing a bug
    * :fire: `:fire:` when removing code or files
    * :green_heart: `:green_heart:` when fixing the CI build
    * :white_check_mark: `:white_check_mark:` when adding tests
    * :lock: `:lock:` when dealing with security
    * :arrow_up: `:arrow_up:` when upgrading dependencies
    * :arrow_down: `:arrow_down:` when downgrading dependencies
    * :shirt: `:shirt:` when removing linter warnings

## Specs Styleguide

- Include thoughtfully-worded, well-structured
  [Jasmine](http://jasmine.github.io/) specs in the `./spec` folder.
- treat `describe` as a noun or situation.
- treat `it` as a statement about state or how an operation changes state.

### Example

```coffee
describe 'a dog', ->
  it 'barks', ->
    # spec here
describe 'when the dog is happy', ->
  it 'wags its tail', ->
    # spec here
```

### Commit Rights

* Commit rights may be given to a contributor who has shown prior history of submitting high
quality [pull requests](#specs-styleguide).
* Commit rights may be taken away from a contributor
that has repeatedly or willfully disregarded the [code of conduct][code-of-conduct].

Committers are expected to submit non-trivial changes via pull request, and receive :+1: / :-1: votes from two other contributors. Use your best judgement on what
constitutes a "trivial" change.

[code-of-conduct]: http://todogroup.org/opencodeofconduct/#Atom/opensource@github.com
