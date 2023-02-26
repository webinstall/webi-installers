---
title: jq
homepage: https://stedolan.github.io/jq/
tagline: |
  jq is a lightweight and flexible command-line JSON processor.
---

To update or switch versions, run `webi jq@stable` (or `@v1.6`, `@beta`, etc).

## Cheat Sheet

> `jq` is like `sed` for JSON data - you can use it to slice and filter and map
> and transform structured data with the same ease that `sed`, `awk`, `grep` and
> friends let you play with text.

All jq selectors begin with `.` - don't forget that!

Be sure to checkout the
[official tutorial](https://stedolan.github.io/jq/tutorial/) and
[jq manual](https://stedolan.github.io/jq/manual/) for more info.

You can also [try online](https://jqplay.org/).

### How to select a single a property from an object

```sh
echo '{ "name": "foo" }' | jq '.name'
```

```text
"foo"
```

### How to remove quotes from strings

The `-r` or `--raw-output` flag unwraps strings:

```sh
echo '{ "name": "foo" }' | jq -r '.name'
```

```text
foo
```

### How to select a whole object

```sh
echo '{ "name": "foo" }' | jq '.'
```

```text
{
  "name": "foo"
}
```

### How to select an element from an array

```sh
echo '[ { "name": "foo" } ]' | jq '.[0]'
```

```text
{
  "name": "foo"
}
```

### How to select a single property from an array element

```sh
echo '[ { "name": "foo" } ]' | jq -r '.[0].name'
```

```text
foo
```

### How to select some properties from multiple elements

```sh
echo '[ { "name": "foo" }, { "name": "bar" } ]' \
    | jq -r '.[].name'
```

```text
foo
bar
```

### How transform or zip an array

Anything that doesn't start with a `.` is part of the transformation template.

Anything that collects starts with `.[]`.

Anything that transforms has a pipe and selector `| .whatever`.

Be sure to checkout the
[official tutorial](https://stedolan.github.io/jq/tutorial/) and
[jq manual](https://stedolan.github.io/jq/manual/) for more info.

```sh
echo '[ { "name": "foo", "age": 0 }, { "name": "bar", "age": 2 } ]' \
    | jq '{ names: [.[] | .name], ages: [.[] | .age] }'
```

```text
{
  "names": [
    "foo",
    "bar"
  ],
  "ages": [
    0,
    2
  ]
}
```
