---
title: rclone
homepage: https://github.com/rclone/rclone
tagline: |
  rclone: "rsync for cloud storage".
---

To update or switch versions, run `webi rclone@stable` (or `@v1.54`, `@beta`,
etc).

## Cheat Sheet

> rclone is like rsync, but optimized for cloud storage and SSDs. rclone is also
> faster than rsync for many use cases.

`rclone` is compatible with a wide range of cloud storage providers including:

- Google Drive
- S3
  - (AWS, Minio, Digital Ocean, etc)
- Dropbox
- Backblaze B2
- One Drive
- Swift
- Hubic
- Wasabi
- Google Cloud Storage
- Yandex Files

### How to copy local files, like rsync

`rclone`s cloud-first, SSD-first optimizations can cause performance issues when
copying between HDDs. For performance more similar to `cp` (better than `rsync`)
you can use the following options:

`--tranfers=1` will only copy one file at a time, preventing thrashing and
fragmentation.

`--check-first` will catalog files before copying.

`--order-by name` will copy files one directory at a time.

Example:

```sh
rclone sync -vP --transfers=1 --order-by name --check-first ~/ /Volumes/Backup/home
```

Example, excluding common temporary directories:

```sh
rclone sync -vP --transfers=1 --order-by name --check-first \
  --exclude 'node_modules/**' --exclude '.Spotlight-*/**' --exclude '.cache*/**' \
  ~/ /Volumes/Backup/home
```
