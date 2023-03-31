<!--suppress HtmlDeprecatedAttribute -->
<div align="center">
<img src="./img/whisker logo.svg" width="300" alt="whisker logo"/>

[vlang.io](https://vlang.io) | [hungrybluedev](https://hungrybluedev.in/)

[![CI][workflow_badge]][workflow_url]
[![License: MIT][license_badge]][license_url]
[![Git Latest Tag][git_tag_badge]][git_tag_url]

</div>

_whisker_ is inspired by [Mustache](https://mustache.github.io/) but is more
stable, robust and predictable. It is a fast template engine
for [V](https://vlang.io/) with a simple syntax.

## Features

1. **Logic-less templates**: different but expressive and powerful.
2. **Four Data Types**: booleans, strings, lists, and maps.
3. **Simple Data Model**: Template data be constructed in V source code or
   imported
   and exported using JSON.
4. **Partials**: External, partial templates can be plugged into the primary
   template.
5. **Safe by Default**: Tag contents are escaped by default.
6. **Customisable**: The delimiters can be changed from the default `{{...}}`.

## Motivation

The following blog posts provide more context:

1. [Announcing
   _whisker_ - easier way to do templates in V](https://hungrybluedev.tech/whisker-easier-way-to-do-templates-in-v/):
   We take a look at current template engines available in V and announce a new
   template engine.

## Prerequisites

You must have V installed. Refer to
the [official instructions](https://github.com/vlang/v/#installing-v-from-source)
for help with installation.

If you already have V installed, use `v up` to update the

## Syntax

### Normal Text Is Unaffected

```
Input
-----
Sample text

Output
------
Sample text
```

### Double Curly Braces Indicate Sections

```
Input
-----
Hello, {{name}}!

Data
----
{
   "name": "world"
}


Output
------
Hello, world!
```

### Changing Delimiters

```
Input
-----
{{=[ ]=}}
module main

fn main() {
   println('[greeting]')
}

Data
----
{
   "greeting": "Have a nice day!"
}

Output
------
module main

fn main() {
   println('Have a nice day!')
}
```

### Booleans, Positive, and Negative Sections

```
Input
-----
<nav>
<ul>
<li>Home</li>
<li>About</li>
{{-logged_in}}<li>Log In</li>{{/logged_in}}{{+logged_in}}<li>Account: {{user.name}}</li>{{/logged_in}}
</ul>
</nav>

Data 1
------
{
   "logged_in": false,
}


Output 1
--------
<nav>
<ul>
<li>Home</li>
<li>About</li>
<li>Log In</li>
</ul>
</nav>

Data 2
------
{
   "logged_in": true,
   "user": {
      "name": "whisker"
   }
}


Output 2
--------
<nav>
<ul>
<li>Home</li>
<li>About</li>
<li>Account: whisker</li>
</ul>
</nav>
```

### Maps, Lists, and Partials

```
Input
-----

<ol>
{{*items}}
{{>item}}
{{/items}}
</ol>

Partial: item
-------------
<li>{{name}}: {{description}}</li>


Data
----
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

Output
------
<ol>
<li>Banana: Rich in potassium and naturally sweet.</li>
<li>Orange: High in Vitamin C and very refreshing.</li>
</ol>
```

All the examples shown here are tested in CI in
the [readme_test.v](src/spec/readme_test.v) file.

For the full specification, refer to the unit tests and test cases in
the [`spec`](src/spec) directory.

## Installation

Run the following to install _whisker_ from GitHub using V's package manager:

```
v install --git https://github.com/hungrybluedev/whisker
```

Now, in your project, you can `import hungrybluedev.whisker` and use _whisker_
right away!

## Usage

The main struct is `whisker.Template` which can be generated either directly
from template strings or be loaded from disk from template files. It has to be
mutable because the internal state changes as the template executes for a given
data model.

A single template should be reused for different data models to produce outputs
which differ in content but not semantic structure.

> NOTE: There might be slight white-space consistencies between the generated
> and expected results. For machine-verification, it is recommended to compare
> the parsed
> and reconstructed outputs for your particular file format.

### Direct String Templates

1. **Load a template**:
   Use `whisker.new_template(input: input_str, partials: partial_map)`
   to generate a template from direct string inputs. Here, `input_str` is
   a `string` and `partial_map` is a `map[string]string`. The map's keys are the
   names of the template that are replaced by the direct template strings. Leave
   the partials field empty if there are none required.
2. **Run with Data Model**: Use `run(data)` to generate the output string. The
   data can be represented in V source code directly (refer to the spec for
   examples), or it can be loaded from JSON (using
   `whisker.from_json(data_string)`).

### Template Files

1. **Load a template**:
   Use `whisker.load_template(input: input_str, partials: partial_map)` to
   generate a template from file names. The difference here is that instead of
   providing content, you provide the relative file paths. The names of the
   partials need to be exact though, so keep an eye on that.
2. **Run with Data Model**: Same as before. You can
   use `os.read_file(path_to_json)` to read the JSON contents and then plug this
   into the `from_json` function.

It is not necessary, but it is recommended to use filenames that
contain `*.wskr.*` somewhere in the file name.

## The CLI

_whisker_ may also be used as a standalone command-line program to process
template files. It does not support direct template string input for the sake of
simplicity.

Build `src/whisker_cli` and run `whisker --help` for usage instructions.

Check [whisker_cli_test.v](src/whisker_cli/whisker_cli_test.v) for a concrete
demonstration.

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
