module main

import v.vmod

const embedded_vmod = $embed_file('v.mod', .zlib)
const manifest = vmod.decode(embedded_vmod.to_string()) or {
	eprintln('Could not decode the v.mod file. Please restore to original state.')
	exit(1)
}

pub const version = manifest.version
pub const app_name = manifest.name
pub const description = manifest.description
pub const instructions = '
whisker can operate on template strings stored in *.wskr.[html/json/*] template
files for storing inputs. This also applies for partial templates.
There is no strict requirement on file names and extensions, by having "wskr"
somewhere in there makes it readily apparent that we are using whisker templates.

Passing in strings directly is supported using the V API. The command-line
only allows for usage on files.

Template data models are encoded and decoded using JSON (unless we support more
types) but the DataModel sum-type can be used directly to construct the desired
input for a template in V code directly.

Sample usage:

whisker --input base.wskr.html --partials "head:head.wskr.html,main:main template.wskr.html"
	--data data.wskr.json --out

Do not use spaces after the commas. Spaces are allowed for file names.
'
