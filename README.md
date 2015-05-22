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
  "linter.plus": {
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
  scopes: ['.source.php'] # Replace it with a source of choice

  lint: function(TextEditor, TextBuffer, {Error, Warning, Trace}):array<Error>
  --- or if you prefer async ---
  lint: function(TextEditor, TextBuffer, {Error, Warning, Trace}):Promise<array<Error>>
}
```
An error in the above example can be a `Warning` or `Error` provided to the lint function.

#### API
```js
class PlusTrace
  constructor:(@Message, @File, @Position)
class PlusError
  constructor:(@Message, @File, @Position, @Trace)
class PlusWarning
  constructor:(@Message, @File, @Position, @Trace)
```

#### Why not use AtomLinter

My initial idea was to submit a PR to AtomLinter and make the appropriate changes. But It would've made so many API breaking changes that I thought to create a separate package for it.

#### Example Linter

Have a look at [Linter-Hack](https://github.com/steelbrain/Atom-Hack/blob/rewrite/lib/atom-hack.coffee).

#### License
This project is licensed under the terms of MIT License. See the License file for more info.