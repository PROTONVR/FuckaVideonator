# Vestroyer CLI for Linux

Vestroyer is a small Linux command-line tool for wrecking video quality while
keeping FPS behavior unchanged.

Current version: **1.1**

## Requirements

- Linux
- Python 3
- FFmpeg available as `ffmpeg`

## Install

Recommended:

```bash
chmod +x install.sh
./install.sh
```

The installer checks `python3` and `ffmpeg`, shows dependency names up front,
prints dependency status in green/red, and shows live package manager output
while it installs missing pieces.

Manual install:

```bash
chmod +x vestroyer
sudo cp vestroyer /usr/local/bin/vestroyer
```

Uninstall:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

## Usage

```bash
vestroyer INPUT -preset PRESET OUTPUT
```

Separate audio control:

```bash
vestroyer INPUT -preset PRESET -apreset APRESET OUTPUT
```

Examples:

```bash
vestroyer ~/videos/movie.mp4 -preset 144 ~/videos/movie-low-quality.mp4
vestroyer input.mov -preset wtf -apreset destroyed output.mp4
```

## Help

Show preset list:

```bash
vestroyer -preset help
```

Show audio preset list:

```bash
vestroyer -apreset help
```

Show full help:

```bash
vestroyer --help
```

## Presets

- `4k` - 4K UHD, nearly clean
- `1080` - Full HD
- `720` - HD
- `480` - 480p
- `360` - 360p
- `240` - 240p
- `144` - 144p
- `96` - 96p
- `wtf` - 64x36, barely visible

Aliases:

- `2160`, `uhd` -> `4k`
- `fullhd`, `fhd` -> `1080`
- `hd` -> `720`
- `36`, `64x36` -> `wtf`

## Audio presets

- `clean` - 128k
- `normal` - 96k
- `low` - 64k
- `crunchy` - 32k
- `phone` - 16k
- `destroyed` - 8k

Audio aliases:

- `128k` -> `clean`
- `96k` -> `normal`
- `64k` -> `low`
- `32k` -> `crunchy`
- `16k` -> `phone`
- `8k` -> `destroyed`

## Test presets

```bash
chmod +x test_presets.sh
./test_presets.sh
```

## Notes

Vestroyer does not use `-r` and does not add an FPS filter, so it does not
force a new FPS value. It tries `-fps_mode passthrough` first and falls back
automatically if needed.
