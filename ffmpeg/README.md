---
title: ffmpeg
homepage: https://ffmpeg.org/
tagline: |
  FFmpeg: A complete, cross-platform solution to record, convert and stream audio and video.
---

## Updating `ffmpeg`

```bash
webi ffmpeg@stable
```

Disclaimer: ffmpeg does not provide official binaries, so
<https://github.com/eugeneware/ffmpeg-static> is used.

## Cheat Sheet

> FFmpeg is useful for converting between various audio, video, and image
> formats.

Many simple conversions can be auto-detected by file extension and the options
that produce the most similar quality by default.

```bash
ffmpeg -i input.m4a output.mp3
```
