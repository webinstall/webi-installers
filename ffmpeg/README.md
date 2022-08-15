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
