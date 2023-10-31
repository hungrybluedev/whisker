<!--suppress HtmlDeprecatedAttribute -->
<div align="center">
<img src="https://raw.githubusercontent.com/hungrybluedev/whisker/main/docs/img/whisker%20logo.svg" width="300" alt="whisker logo"/>

[vlang.io](https://vlang.io) | [hungrybluedev](https://hungrybluedev.in/)

[![CI][workflow_badge]][workflow_url]
[![License: MIT][license_badge]][license_url]
[![Git Latest Tag][git_tag_badge]][git_tag_url]

</div>

_whisker_ is inspired by [Mustache](https://mustache.github.io/) but is more
stable, robust and predictable. It is a fast template engine
for [V](https://vlang.io/) with a simple syntax.

## Features

1. **Logic-less**: Different but expressive and powerful.
2. **Four Data Types**: Booleans, Strings, Lists, and Maps.
3. **Composable**: Supports nested iteration and partial recursion.
4. **Simple Data Model**: Template data be constructed in V source code or
   imported and exported using JSON.
5. **Partials**: External, partial templates can be plugged into the primary
   template.
6. **Safe by Default**: Tag contents are HTML escaped by default.
7. **Customisable**: The delimiters can be changed from the default `{{...}}`.

## Motivation

The following blog posts provide more context:

1. [Announcing
   _whisker_ - easier way to do templates in V](https://hungrybluedev.tech/whisker-easier-way-to-do-templates-in-v/):
   We take a look at current template engines available in V and announce a new
   template engine.
2. [Writing whisker’s tokeniser using the Theory of Computation](https://hungrybluedev.tech/writing-whiskers-tokeniser-using-the-theory-of-computation/):
   We show how we use fundamental CS principles to implement an FSM-based
   tokeniser for whisker.


## Prerequisites

You must have V installed. Refer to
the [official instructions](https://github.com/vlang/v/#installing-v-from-source)
for help with installation.

If you already have V installed, use `v up` to update the toolchain and standard
library.

## Installation

Run the following to install _whisker_ from GitHub using V's package manager:

```
v install --git https://github.com/hungrybluedev/whisker
```

This should install in `hungrybluedev.whisker` first and then relocate it
to `whisker`. Now, in your project, you can `import whisker` and use _whisker_
right away!

## Usage

The main struct is `whisker.template.Template` which can be generated either
directly from template strings or be loaded from disk from template files. A
single template should be reused for different data models to produce outputs
which differ in content but not semantic structure.

> **Note**
> There might be slight white-space consistencies between the generated
> and expected results. For machine-verification, it is recommended to compare
> the parsed and reconstructed outputs for your particular file format.

### Direct String Templates

1. **Load a template**:
   Use `template.from_strings(input: input_str, partials: partial_map)`
   to generate a template from direct string inputs. Here, `input_str` is
   a `string` and `partial_map` is a `map[string]string`. The map's keys are the
   names of the template that are replaced by the direct template strings. Leave
   the partials field empty if there are none required.
2. **Run with Data Model**: Use `run(data)` to generate the output string. The
   data can be represented in V source code directly (refer to the spec for
   examples), or it can be loaded from JSON (using
   `datamodel.from_json(data_string)`).

This is a copy-paste-able example to get started immediately:

```v
module main

import whisker.datamodel
import whisker.template

fn main() {
	simple_template := template.from_strings(input: 'Hello, {{name}}!')!
	data := datamodel.from_json('{"name": "World"}')!

	println(simple_template.run(data)!) // prints "Hello, World!"
}
```

### Template Files

1. **Load a template**:
   Use `template.load_file(input: input_str, partials: partial_map)` to
   generate a template from file names. The difference here is that instead of
   providing content, you provide the relative file paths. The names of the
   partials need to be exact though, so keep an eye on that.
2. **Run with Data Model**: Same as before. You can
   use `os.read_file(path_to_json)` to read the JSON contents and then plug this
   into the `datamodel.from_json` function.

It is not necessary, but it is recommended to use filenames that
contain `*.wskr.*` somewhere in the file name.
Check [json_test.v](spec/json_test.v) and [html_test.v](spec/html_test.v) for
examples with template files.

## The CLI

_whisker_ may also be used as a standalone command-line program to process
template files. It does not support direct template string input for the sake of
simplicity.

Build `whisker` with `v cmd/whisker` and run `cmd/whisker/whisker --help` for
usage instructions. You can specify a `bin` subdirectory as output folder and
add it to path as well:

```bash
# Create an output directory
mkdir cmd/bin

# Build the executable
v cmd/whisker -o cmd/bin/whisker

# Run the executable
cmd/bin/whisker --help
```

Check [whisker_cli_test.v](cmd/whisker/whisker_cli_test.v) for a concrete
demonstration.

## Syntax

### Normal Text Is Unaffected

#### Input

```
Sample text
```

#### Output

```
Sample text
```

### Double Curly Braces Indicate Sections

#### Input

```
Hello, {{name}}!
```

#### Data

```json
{
  "name": "world"
}
```

#### Output

```
Hello, world!
```

### Changing Delimiters

#### Input

```v
{{=[ ]=}}
module main

fn main() {
    println('[greeting]')
}
```

#### Data

```json
{
  "greeting": "Have a nice day!"
}
```

#### Output

```v
module main

fn main() {
    println('Have a nice day!')
}
```

### Booleans, Positive, and Negative Sections

#### Input

```html

<nav>
    <ul>
        <li>Home</li>
        <li>About</li>
        {{-logged_in}}
        <li>Log In</li>
        {{/logged_in}}
        {{+logged_in}}
        <li>Account: {{user.name}}</li>
        {{/logged_in}}
    </ul>
</nav>
```

#### Data 1

```json
{
  "logged_in": false
}
```

#### Output 1

```html

<nav>
    <ul>
        <li>Home</li>
        <li>About</li>
        <li>Log In</li>

    </ul>
</nav>
```

#### Data 2

```json
{
  "logged_in": true,
  "user": {
    "name": "whisker"
  }
}
```

#### Output 2

```html

<nav>
    <ul>
        <li>Home</li>
        <li>About</li>

        <li>Account: whisker</li>
    </ul>
</nav>
```

Positive and negative sections also apply to lists and maps. An empty list or map means a negative section and a non-empty one represents a positive section.

List:

#### Input

```html

{{+vacation}}
<h1>Currenty on vacation</h1>
<ul>
{{*.}}
<li>{{.}}</li>
{{/.}}
</ul>
{{/vacation}}
{{-vacation}}
<p>Nobody is on vacation currently</p>
{{/vacation}}
```

#### Data 1

```json
{
  "vacation": []
}
```

#### Output 1

```html
<p>Nobody is on vacation currently</p>
```

#### Data 2

```json
{
  "vacation": ["Homer", "Marge"]
}
```

#### Output 2

```html
<h1>Currenty on vacation</h1>
<ul>
<li>Homer</li>
<li>Marge</li>
</ul>
```

Map:

#### Input

```html

{{+user}}
<p>Welcome {{last_name}}, {{first_name}}</h1>
{{/user}}
{{-user}}
<p>Create account?</p>
{{/user}}
```

#### Data 1

```json
{
    "user" : {}
}
```

#### Output 1

```html
<p>Create account?</p>
```

#### Data 2

```json
{
    "user" : {
        "last_name": "Simpson", 
        "first_name": "Homer"
    }
}
```

#### Output 2

```html
<p>Welcome Simpson, Homer</h1>
```

### Maps, Lists, and Partials

#### Input

```html

<ol>
    {{*items}}
    {{>item}}
    {{/items}}
</ol>
```

#### Partial: item

```html

<li>{{name}}: {{description}}</li>
```

#### Data

```json
{
  "items": [
    {
      "name": "Banana",
      "description": "Rich in potassium and naturally sweet."
    },
    {
      "name": "Orange",
      "description": "High in Vitamin C and very refreshing."
    }
  ]
}
```

#### Output

```html

<ol>
    <li>Banana: Rich in potassium and naturally sweet.</li>
    <li>Orange: High in Vitamin C and very refreshing.</li>
</ol>
```

All the examples shown here are tested in CI in
the [readme_test.v](spec/readme_test.v) file.

For the full specification, refer to the unit tests and test cases in
the [`spec`](spec) directory.

## License

This project is distributed under the [MIT License](LICENSE).

[workflow_badge]: https://github.com/hungrybluedev/whisker/actions/workflows/main.yml/badge.svg

[license_badge]: https://img.shields.io/badge/License-MIT-blue.svg

[workflow_url]: https://github.com/hungrybluedev/whisker/actions/workflows/main.yml

[license_url]: https://github.com/hungrybluedev/whisker/blob/main/LICENSE

[git_tag_url]: https://github.com/hungrybluedev/whisker/tags

[git_tag_badge]: https://img.shields.io/github/v/tag/hungrybluedev/whisker?color=purple&include_prereleases&sort=semver

## Acknowledgements

Thanks to the original Mustache project for inspiration and the specification.
