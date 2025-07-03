# Modules



___
*<p align=center>Modules are available in Boop version 1.2.0 and above.</p>*
___

Just to be very clear before we get started: **Boop does not support commonJS/node/ES6 modules**. It has a custom import system that may or may not be compatible with some existing modules. The same mechanism is also exposed to Python, Ruby, Perl, Lua and Node.js bridges. In languages other than JavaScript and Node.js the import function defaults to `boop_require`. You can set a global override or per-runtime keyword in the Runtime preferences. The chosen keyword is passed to interpreters via the `BOOP_REQUIRE_NAME` environment variable.

## Importing modules

To import a module, use the `require` function in JavaScript and Node.js, or the configured keyword (default `boop_require`) in Python, Ruby, Perl and Lua. It will return the contents of `module.exports`:

```javascript
const test = require('lib/testLib')
const test = require('modules/otherLib.js')
```
// In Python/Ruby/Perl/Lua use `boop_require('lib/testLib')` (or your custom keyword)

If you do not include a `.js` extension, the system will add one automatically.

You can also use destructuring to only get a single function out:

```javascript
const { base64decode } = require('lib/base64')
// or

const { base64encode } = require('lib/base64')
```

## Creating modules

Modules are run in a pseudo-sandbox, in somewhat similar (but not equal) way to CommonJS. The sandbox contains a `module` object with an `exports` property. Whatever that property contains is what will be returned by the require function.

```javascript
// testModule.js

module.exports = "Hello World"
```
```javascript
// script.js
const greeting = require('testModule.js')
```

The above example is essentially the same as:

```javascript
// script.js
const greeting = "Hello World"
```

Module imports can also be nested, though you should probably avoid that.

```javascript
// lib/deepModule.js

module.exports = "Hello World"
```

```javascript
// lib/shallowModule.js
const greeting = require('lib/deepModule')

module.exports = greeting
```

```javascript
// script.js
const greeting = require('lib/shallowModule')
```

When using nested requires, the module name is based on the path of your script, not of the current module.

## Built in modules

Boop ships with a couple of modules, with the prefix `@boop/`, which you can use in your own scripts.

| Module name        | Description   |
| ------------------ | ------------- |
| `@boop/base64`     | Base 64 encoding and decoding |
| `@boop/lodash.boop`| Subset of lodash string functions (see below) |
| `@boop/he`         | HTML entities encoder/decoder |
| `@boop/vkBeautify` | XML, CSS, and SQL formatter and minifier |
| `@boop/js-yaml`    | Parses and Stringifies YAML objects |
| `@boop/hashes`     | Common crypto hashes |

If you need a new module that you think could be used by more scripts, feel free to open a PR adding more functionality.

#### Lodash

The built in lodash module was created with the following command and only includes a few functions and their direct dependencies:

```bash
$ lodash include=camelCase,deburr,escapeRegExp,kebabCase,snakeCase,startCase,size
```

If you'd like to add more functions, feel free to rebuild with additional parameters and submit a PR.
