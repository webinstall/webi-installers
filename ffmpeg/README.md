---
title: ffmpeg
homepage: https://ffmpeg.org/
tagline: |
  FFmpeg: A complete, cross-platform solution to record, convert and stream audio and video.
---

To update or switch versions, run `webi ffmpeg@stable` (or `@v4.4`, `@beta`,
etc).

## Cheat Sheet

> FFmpeg is useful for converting between various audio, video, and image
> formats.

Many simple conversions can be auto-detected by file extension and the options
that produce the most similar quality by default.

```sh
ffmpeg -i input.m4a output.mp3
```

Important information per https://johnvansickle.com/ffmpeg/release-readme.txt

> Notes: A limitation of statically linking `glibc` is the loss of DNS
> resolution. Installing `nscd` through your package manager will fix this.

_This is relevant if using ffmpeg to relay to an RTMP server via domain name._

```sh
# for example, this will not work without `nscd` installed.

ffmpeg -re -stream_loop -1 -i "FooBar.m4v" -c copy -f flv rtmp://stream.example.com/foo/bar
```
