---
title: xsv
homepage: https://github.com/BurntSushi/xsv
tagline: |
  xsv: A fast CSV command line toolkit written in Rust.
---

To update or switch versions, run `webi xsv@stable` (or `@v2`, `@beta`, etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/xsv
~/.local/opt/xsv
```

## Cheat Sheet

> `xsv` is a command line program for manipulating CSV files. It offers a range
> of functionalities including slicing, joining, indexing and more. Designed for
> simplicity and speed, it is an essential tool for anyone working with CSV
> data.

### Basic Usage

To count the number of rows in a CSV file:

```sh
xsv count data.csv
```

### Joining Two CSV Files

To perform an inner join on two CSV files based on a common column:

```sh
xsv join column1 file1.csv column2 file2.csv
```

### Sample Data

To randomly sample rows from a CSV file:

```sh
xsv sample 100 data.csv
```

### Analyzing Data

To display basic statistics for each column in a CSV file:

```sh
xsv stats data.csv
```
