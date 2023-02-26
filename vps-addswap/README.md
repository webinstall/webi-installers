---
title: VPS Add Swap
homepage: https://webinstall.dev/vps-addswap
tagline: |
  VPS Add Swap: because a little RAM can go a long way.
linux: true
---

## Cheat Sheet

> Creates permanent swap space that will be activated on each boot.

`vps-addswap` will

1. create a permanent swapfile `/var/swapfile`
2. format and activate the swapfile
3. add '/var/swapfile none swap sw 0 0' to `/etc/fstab`

### What is `swap`?

Simply put, swap space is a substitute for RAM that lives on a storage drive.

### Why use permanent `swap`?

In a word: Money.

Whereas once upon a time RAM was expensive in real life, now it is very cheap.

In "the cloud", however, RAM is not just expensive - it's very, _very_
expensive - as in _hundreds_-of-dollars-per-month expensive.

For most applications this isn't a problem because you don't need much RAM - or
when you do, you need it according to workload, which is easy (and cheap) to
distribute across many otherwise underpowered server instances.

However, when you need to use Python, R, etc to process large batches of data
sequentially - such as the multi-gigabyte datasets common in Machine Learning,
Artificial Intelligience, Data Mining, etc - or when you need a very rare burst
of RAM for a very short-lived task - such as an `npm run build`, swap can be a
big cost saver.

The good news is that quite often you can also have your cake and eat it too:
most language runtimes (i.e. Node.js, Go, Java, etc) allow you to tune
parameters that limit the amount of RAM they are allowed to allocate
dynamically, which means that you can take advantage of large swap space for
sequential processing tasks without causing your apps to be slow.

### How to allocate swap space?

Typically you should place swap files in `/var`, which is the volume that will
be optimized for fast writes (on servers that do so).

```sh
sudo fallocate -l 2G /var/swapfile
sudo chmod 0600 /var/swapfile
sudo mkswap /var/swapfile
```

This method is preferrable to `truncate` and `dd` for SSDs as it will NOT
actually write the file to its full size, and therefore will be instant.

On an HDD (rotational drive), `dd` may be a better choice, as you need to
allocate contiguous space all at once.

```sh
sudo dd if=/dev/zero of=/var/swapfile bs=2G count=1
```

### How much swap to use?

If you need to run common tasks with `npm run build` - such as compiling
`sass` - 2G would be a good place to start.

If you need to process large datasets, somewhere between 1x-2x the size of the
largest dataset should do - noting that the dataset will likely take up more
space in RAM/swap than as a file on disk.

### How to activate swap space?

```sh
sudo swapon /var/swapfile
```

If you get an errors about "holes" or allocations, you'll either need to defrag
or try allocating far more space than you need with `dd`, delete the dd file,
and create the swap file again.

### How to activate swap on boot?

You need to open `/etc/fstab` and add a line like this:

```text
/var/swapfile none swap sw 0 0
```
