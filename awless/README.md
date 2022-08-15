---
title: awless
homepage: https://github.com/wallix/awless
tagline: |
  awless is a powerful, innovative and small surface command line interface (CLI) to manage Amazon Web Services.
---

To update or switch versions, run `webi awless@stable` (or `@v2`, `@beta`, etc).

## Cheat Sheet

awless is modeled after popular command-line tools such as Git. Most commands
are in the form of:

```sh
awless verb [entity] [parameter=value ...]
```

If you already have awscli installed and configured, awless will use your
existing `~/.aws/credentials` file. If not, you can review and configure awless
with `awless config`.

Unlike the standard awscli tools, `awless` aims to be more human readable.

### List resources

For instance, let's list some resources:

```sh
awless list vpcs
```

Which outputs a friendly human readable table!

```sh
|         ID ▲          | NAME | DEFAULT |   STATE   |     CIDR      |
|-----------------------|------|---------|-----------|---------------|
| vpc-00fd208a070000000 |      | false   | available | 172.16.0.0/16 |
| vpc-22222222          |      | true    | available | 172.31.0.0/16 |
```

There's also filter capabilities, in case the list is long. For example, let's
list all EC2 instances with "api" in the name:

```sh
awless list instances --filter name=api
```

In addition to the default table output, there's also csv, tsv, json.

```sh
awless list loadbalancers --format csv
```

### Create resources

awless allows specifying things by name rather than ID by using the `@` prefix.

```sh
awless create subnet cidr=10.0.0.0/24 vpc=@wordpress-vpc name=wordpress-public-subnet
```

### Delete resources

If you leave out a parameter, awless will prompt you for the missing
information.

```sh
awless delete i-123456789000abcd
```

It will correctly detect what you were probably trying to do:

```sh
Did you mean `awless delete instance ids=i-051fcef0537a53eb0` ?  [Y/n]
```

### Advanced

For a more advanced tutorial about awless' features, see the official
[Getting Started](https://github.com/wallix/awless/wiki/Getting-Started) guide.
