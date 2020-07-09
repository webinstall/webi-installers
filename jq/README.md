---
title: jq
homepage: https://stedolan.github.io/jq/
tagline: |
  jq is a lightweight and flexible command-line JSON processor.
---

## Updating `jq`

```bash
webi jq@stable
```

Use the `@beta` tag for pre-releases.

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

```bash
echo '{ "name": "foo" }' | jq '.name'
```

```txt
"foo"
```

### How to remove quotes from strings

The `-r` or `--raw-output` flag unwraps strings:

```bash
echo '{ "name": "foo" }' | jq -r '.name'
```

```txt
"foo"
```

### How to select a whole object

```bash
echo '{ "name": "foo" }' | jq '.'
```

```txt
{
  "name": "foo"
}
```

### How to select an element from an array

```bash
echo '[ { "name": "foo" } ]' | jq '.[0]'
```

```txt
{
  "name": "foo"
}
```

### How to select a single property from an array element

```bash
echo '[ { "name": "foo" } ]' | jq -r '.[0].name'
```

```txt
foo
```

### How to select some properties from multiple elements

```bash
echo '[ { "name": "foo" }, { "name": "bar" } ]' \
    | jq -r '.[].name'
```

```txt
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

```bash
echo '[ { "name": "foo", "age": 0 }, { "name": "bar", "age": 2 } ]' \
    | jq '{ names: [.[] | .name], ages: [.[] | .age] }'
```

```txt
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
