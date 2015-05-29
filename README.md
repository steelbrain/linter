Linter-Plus
==========

Linter-Plus is a base Linter Provider for Atom. It allows packages to consume an extremely easy to use API and lint files like a piece of cake.
This package was inspired from AtomLinter.

#### Installation

```sh
apm install linter-plus
```

#### Registering a Linter

Registering a linter is a piece of cake. It provides three base classes `Error`, `Warning` and `Trace` to be used. Linters can both be synchronous or Asynchronous (Promise based).

Add this to your package.json file
```js
"providedServices": {
  "linter-plus": {
    "versions": {
      "0.1.0": "provideLinter"
    }
  }
}
```

and then have a function named `provideLinter` in your main file.
Linter-Plus expects an object like this from that function

```js
{
  scopes: ['source.php'] # Replace it with a source of choice
  scope: 'file' or 'project' # lintOnFly must be false for global
  lintOnFly: false # Replace to true to indicate your linter supports LintOnFly
  lint: function(TextEditor, TextBuffer, wasTriggeredOnChange):array<Message> | Promise<array<Message>>
}
```
An error in the above example can be a `Warning` or `Error` provided to the lint function.

#### Error Object Shapes
```js
// Error
{
  Type: "Error",
  Message: ?String,
  HTML: ?String,
  File: String,
  Position: ?Range,
  Trace: array<Trace>
}
// Warning
{
  Type: "Warning",
  Message: ?String,
  HTML: ?String,
  File: String,
  Position: ?Range,
  Trace: array<Trace>
}
// Trace
{
  Type: "Trace",
  Message: ?String,
  HTML: ?String,
  File: String,
  Position: ?Range
}
```

#### Why not use AtomLinter

My initial idea was to submit a PR to AtomLinter and make the appropriate changes. But It would've made so many API breaking changes that I thought to create a separate package for it.

#### Example Linter

Have a look at [Linter-Hack](https://github.com/steelbrain/Atom-Hack/blob/rewrite/lib/atom-hack.coffee).

#### License
This project is licensed under the terms of MIT License. See the License file for more info.