---
title: xsv
homepage: https://github.com/BurntSushi/xsv
tagline: |
  xsv: A fast CSV command line toolkit written in Rust.
---

To update or switch versions, run `webi xsv@stable` (or `@v0.13`, `@beta`, etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/xsv
```

## Cheat Sheet

> `xsv` is a command line program for manipulating CSV files. It offers a range
> of functionalities including slicing, joining, indexing and more. Designed for
> simplicity and speed, it is an essential tool for anyone working with CSV
> data.

Get the canonical sample data:

```sh
curl -o ./worldcitiespop.csv -L https://burntsushi.net/stuff/worldcitiespop.csv
```

(or check "The Data Science Toolkit": <https://github.com/petewarden/dstkdata>)

Show the CSV's headers:

```sh
xsv headers ./worldcitiespop.csv
```

Query the CSV data any which way:

```sh
xsv search '^(John|Jane)$' --select 'First Name' ./address-book.csv |
    xsv select 'ID,First Name,Last Name' |
    xsv sort --select 'Last Name,First Name' |
    xsv slice -s 0 -n 5 |
    xsv table
```

(selects the first 5 rows, with a "First Name" of "John" or "Jane", sorted by
"Last Name", as a table)

### Basic Usage

- Subcommand Help & Global Options
- View Headers
- Take a Sample
- Select Columns
- View Vertically (`\G`)
- View as Table
- Count Rows

**Subcommand Help & Global Options**

```sh
xsv <subcommand> --help
```

Subcommands are: `cat`, `count`, `fixlengths`, `flatten`, `fmt`, `frequency`,
`headers`, `help`, `index`, `input`, `join`, `sample`, `search`, `select`,
`slice`, `sort`, `split`, `stats`, `table`.

```text
Common options:
    -h, --help             Display this message
    -o, --output <file>    Write output to <file> instead of stdout.
    -n, --no-headers       When set, the first row will not be interpreted
                           as headers. (i.e., They are not searched, analyzed,
                           sliced, etc.)
    -d, --delimiter <arg>  The field delimiter for reading CSV data.
                           Must be a single character. (default: ,)
```

**View Headers**

Shows column name and index (1-based).

```sh
xsv headers ./worldcitiespop.csv
```

```text
1   Country
2   City
3   AccentCity
4   Region
5   Population
6   Latitude
7   Longitude
```

**Sample Data**

```sh
xsv sample 2 ./worldcitiespop.csv
```

```text
Country,City,AccentCity,Region,Population,Latitude,Longitude
us,provo,Provo,UT,105764,40.2338889,-111.6577778
lv,riga,Riga,25,742570,56.95,24.1
```

**Select Columns**

```sh
xsv sample 2 ./worldcitiespop.csv |
    xsv select Country,City
```

```text
Country,City
us,provo
lv,riga
```

```sh
xsv sample 2 ./worldcitiespop.csv |
    xsv select --no-headers 1,2
```

```text
us,provo
lv,riga
```

**Select Rows**

Rows are **0-indexed** and do not include the header, unless `--no-headers` is
given.

```sh
# xsv slice -s <start> -l <howmany>
xsv slice -s 0 -l 2 ./worldcitiespop.csv |
    xsv table
```

```text
Country  City        AccentCity  Region  Population  Latitude    Longitude
ad       aixas       Aixàs       06                  42.4833333  1.4666667
ad       aixirivali  Aixirivali  06                  42.4666667  1.5
```

**View Vertically**

Like `\G` in SQL.

```sh
xsv sample 2 ./worldcitiespop.csv |
    xsv select Country,City |
    xsv flatten
```

```text
Country  us
City     provo
#
Country  lv
City     riga
```

**View as a Table**

Makes all columns the same width, truncated to `-c N`.

```sh
xsv search 'Provo|Riga' ./worldcitiespop.csv |
    xsv table -c 10
```

```text
Country  City           AccentCity     Region  Population  Latitude    Longitude
us       provo          Provo          UT      105764      40.2338889  -111.65777...
lv       riga           Riga           25      742570      56.95       24.1
```

### How to Query & Analyze Data

**Count Number of Rows**:

```sh
xsv count ./worldcitiespop.csv
```

```text
3173958
```

**Search by Column Value**

```sh
# xsv search <RegExp> [--select 'Column 1,Column 2']
xsv search '^(provo|riga)$' --select 'City' ./worldcitiespop.csv |
    xsv search '^(us|lv)$' --select Country
```

**Join CSVs**

Like a SQL INNER JOIN (other options available).

```sh
# The equivalent of
# SELECT *
# FROM "countries-by-name"
# INNER JOIN "countries-by-code"
# ON "Country Code" = "Code"

xsv join \
    "Country Code" ./contries-by-name.csv \
    "Code" countries-by-code.csv
```

**Basic Statistics**

```sh
xsv stats ./worldcitiespop.csv |
    xsv table -c 11
```

```text
field       type     sum             min             max             min_length  max_length  mean            stddev
Country     Unicode                  ad              zw              2           2
City        Unicode                   bab el ahm...  Þykkvibaer      1           91
AccentCity  Unicode                   Bâb el Ahm...  ïn Bou Chel...  1           91
Region      Unicode                  00              Z9              0           2
Population  Integer  2289584999      7               31480498        0           8           47719.57063...  302885.5592...
Latitude    Float    86294096.37...  -54.933333      82.483333       1           12          27.18816580...  21.95261384...
Longitude   Float    117718483.5...  -179.983333...  180             1           14          37.08885989...  63.22301045...
```

### Extended Help

We don't generally print the full help, but since this is so vast and it's
useful to be able to search it all on a single page...

```text
cat         Concatenate by row or column
count       Count records
fixlengths  Makes all records have same length
flatten     Show one field per line
fmt         Format CSV output (change field delimiter)
frequency   Show frequency tables
headers     Show header names
index       Create CSV index for faster access
input       Read CSV data with special quoting rules
join        Join CSV files
sample      Randomly sample CSV data
search      Search CSV data with regexes
select      Select columns from CSV
slice       Slice records from CSV
sort        Sort CSV data
split       Split CSV data into many files
stats       Compute basic statistics
table       Align CSV data into columns
```

**How to view ALL help, at once**

```sh
xsv --list |
    tail -n +2 |
    grep -v '^$' |
    cut -c 5- |
    cut -d' ' -f1 |
    xargs -I '{}' xsv '{}' --help
```

**All Usage and Options**

(descriptions and common help omitted)

#### `xsv cat --help`

```text
Usage:
    xsv cat rows    [options] [<input>...]
    xsv cat columns [options] [<input>...]
    xsv cat --help

cat options:
    -p, --pad              When concatenating columns, this flag will cause
                           all records to appear. It will pad each row if
                           other CSV data isn't long enough.
```

#### `xsv count --help`

```text
Usage:
    xsv count [options] [<input>]
```

#### `xsv fixlengths --help`

```text
Usage:
    xsv fixlengths [options] [<input>]

fixlengths options:
    -l, --length <arg>     Forcefully set the length of each record. If a
                           record is not the size given, then it is truncated
                           or expanded as appropriate.
```

#### `xsv flatten --help`

```text
Usage:
    xsv flatten [options] [<input>]

flatten options:
    -c, --condense <arg>  Limits the length of each field to the value
                           specified. If the field is UTF-8 encoded, then
                           <arg> refers to the number of code points.
                           Otherwise, it refers to the number of bytes.
    -s, --separator <arg>  A string of characters to write after each record.
                           When non-empty, a new line is automatically
                           appended to the separator.
                           [default: #]
```

#### `xsv fmt --help`

```text
Usage:
    xsv fmt [options] [<input>]

fmt options:
    -t, --out-delimiter <arg>  The field delimiter for writing CSV data.
                               [default: ,]
    --crlf                     Use '\r\n' line endings in the output.
    --ascii                    Use ASCII field and record separators.
    --quote <arg>              The quote character to use. [default: "]
    --quote-always             Put quotes around every value.
    --escape <arg>             The escape character to use. When not specified,
                               quotes are escaped by doubling them.
```

#### `xsv frequency --help`

```text
Usage:
    xsv frequency [options] [<input>]

frequency options:
    -s, --select <arg>     Select a subset of columns to compute frequencies
                           for. See 'xsv select --help' for the format
                           details. This is provided here because piping 'xsv
                           select' into 'xsv frequency' will disable the use
                           of indexing.
    -l, --limit <arg>      Limit the frequency table to the N most common
                           items. Set to '0' to disable a limit.
                           [default: 10]
    -a, --asc              Sort the frequency tables in ascending order by
                           count. The default is descending order.
    --no-nulls             Don't include NULLs in the frequency table.
    -j, --jobs <arg>       The number of jobs to run in parallel.
                           This works better when the given CSV data has
                           an index already created. Note that a file handle
                           is opened for each job.
                           When set to '0', the number of jobs is set to the
                           number of CPUs detected.
                           [default: 0]
```

#### `xsv headers --help`

```text
Usage:
    xsv headers [options] [<input>...]

headers options:
    -j, --just-names       Only show the header names (hide column index).
                           This is automatically enabled if more than one
                           input is given.
    --intersect            Shows the intersection of all headers in all of
                           the inputs given.
```

#### `xsv index --help`

```text
Usage:
    xsv index [options] <input>
    xsv index --help

index options:
    -o, --output <file>    Write index to <file> instead of <input>.idx.
                           Generally, this is not currently useful because
                           the only way to use an index is if it is specially
                           named <input>.idx.
```

#### `xsv input --help`

```text
Usage:
    xsv input [options] [<input>]

input options:
    --quote <arg>          The quote character to use. [default: "]
    --escape <arg>         The escape character to use. When not specified,
                           quotes are escaped by doubling them.
    --no-quoting           Disable quoting completely.
```

#### `xsv join --help`

```text
Usage:
    xsv join [options] <columns1> <input1> <columns2> <input2>
    xsv join --help

join options:
    --no-case              When set, joins are done case insensitively.
    --left                 Do a 'left outer' join. This returns all rows in
                           first CSV data set, including rows with no
                           corresponding row in the second data set. When no
                           corresponding row exists, it is padded out with
                           empty fields.
    --right                Do a 'right outer' join. This returns all rows in
                           second CSV data set, including rows with no
                           corresponding row in the first data set. When no
                           corresponding row exists, it is padded out with
                           empty fields. (This is the reverse of 'outer left'.)
    --full                 Do a 'full outer' join. This returns all rows in
                           both data sets with matching records joined. If
                           there is no match, the missing side will be padded
                           out with empty fields. (This is the combination of
                           'outer left' and 'outer right'.)
    --cross                USE WITH CAUTION.
                           This returns the cartesian product of the CSV
                           data sets given. The number of rows return is
                           equal to N * M, where N and M correspond to the
                           number of rows in the given data sets, respectively.
    --nulls                When set, joins will work on empty fields.
                           Otherwise, empty fields are completely ignored.
                           (In fact, any row that has an empty field in the
                           key specified is ignored.)
```

#### `xsv sample --help`

```text
Usage:
    xsv sample [options] <sample-size> [<input>]
    xsv sample --help

Common options:
    -h, --help             Display this message
    -o, --output <file>    Write output to <file> instead of stdout.
    -n, --no-headers       When set, the first row will be consider as part of
                           the population to sample from. (When not set, the
                           first row is the header row and will always appear
                           in the output.)
    -d, --delimiter <arg>  The field delimiter for reading CSV data.
                           Must be a single character. (default: ,)
```

#### `xsv search --help`

```text
Usage:
    xsv search [options] <regex> [<input>]
    xsv search --help

search options:
    -i, --ignore-case      Case insensitive search. This is equivalent to
                           prefixing the regex with '(?i)'.
    -s, --select <arg>     Select the columns to search. See 'xsv select -h'
                           for the full syntax.
    -v, --invert-match     Select only rows that did not match
```

#### `xsv select --help`

```text
  Select the first and fourth columns:
  $ xsv select 1,4

  Select the first 4 columns (by index and by name):
  $ xsv select 1-4
  $ xsv select Header1-Header4

  Ignore the first 2 columns (by range and by omission):
  $ xsv select 3-
  $ xsv select '!1-2'

  Select the third column named 'Foo':
  $ xsv select 'Foo[2]'

  Re-order and duplicate columns arbitrarily:
  $ xsv select 3-1,Header3-Header1,Header1,Foo[2],Header1

  Quote column names that conflict with selector syntax:
  $ xsv select '"Date - Opening","Date - Actual Closing"'

Usage:
    xsv select [options] [--] <selection> [<input>]
    xsv select --help
```

#### `xsv slice --help`

```text
Usage:
    xsv slice [options] [<input>]

slice options:
    -s, --start <arg>      The index of the record to slice from.
    -e, --end <arg>        The index of the record to slice to.
    -l, --len <arg>        The length of the slice (can be used instead
                           of --end).
    -i, --index <arg>      Slice a single record (shortcut for -s N -l 1).
```

#### `xsv sort --help`

```
Usage:
    xsv sort [options] [<input>]

sort options:
    -s, --select <arg>     Select a subset of columns to sort.
                           See 'xsv select --help' for the format details.
    -N, --numeric          Compare according to string numerical value
    -R, --reverse          Reverse order
```

#### `xsv split --help`

```text
Usage:
    xsv split [options] <outdir> [<input>]
    xsv split --help

split options:
    -s, --size <arg>       The number of records to write into each chunk.
                           [default: 500]
    -j, --jobs <arg>       The number of spliting jobs to run in parallel.
                           This only works when the given CSV data has
                           an index already created. Note that a file handle
                           is opened for each job.
                           When set to '0', the number of jobs is set to the
                           number of CPUs detected.
                           [default: 0]
    --filename <filename>  A filename template to use when constructing
                           the names of the output files.  The string '{}'
                           will be replaced by a value based on the value
                           of the field, but sanitized for shell safety.
                           [default: {}.csv]
```

#### `xsv stats --help`

```
Usage:
    xsv stats [options] [<input>]

stats options:
    -s, --select <arg>     Select a subset of columns to compute stats for.
                           See 'xsv select --help' for the format details.
                           This is provided here because piping 'xsv select'
                           into 'xsv stats' will disable the use of indexing.
    --everything           Show all statistics available.
    --mode                 Show the mode.
                           This requires storing all CSV data in memory.
    --cardinality          Show the cardinality.
                           This requires storing all CSV data in memory.
    --median               Show the median.
                           This requires storing all CSV data in memory.
    --nulls                Include NULLs in the population size for computing
                           mean and standard deviation.
    -j, --jobs <arg>       The number of jobs to run in parallel.
                           This works better when the given CSV data has
                           an index already created. Note that a file handle
                           is opened for each job.
                           When set to '0', the number of jobs is set to the
                           number of CPUs detected.
                           [default: 0]
```

#### `xsv table --help`

```text
Usage:
    xsv table [options] [<input>]

table options:
    -w, --width <arg>      The minimum width of each column.
                           [default: 2]
    -p, --pad <arg>        The minimum number of spaces between each column.
                           [default: 2]
    -c, --condense <arg>  Limits the length of each field to the value
                           specified. If the field is UTF-8 encoded, then
                           <arg> refers to the number of code points.
                           Otherwise, it refers to the number of bytes.
```
