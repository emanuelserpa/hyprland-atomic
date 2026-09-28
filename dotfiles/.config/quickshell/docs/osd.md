# OSD

## Current supported OSD types

- speaker/output volume;
- microphone;
- brightness.

## Behavior

- appears near lower part of screen;
- focused monitor only;
- short display duration;
- ignores exclusion;
- generic renderer reused by typed helpers.

## Data sources

### Audio
PipeWire default sink/source.

### Brightness
Backlight device discovered via `brightnessctl`, then observed through sysfs/FileView.

This avoids subprocess polling for every brightness update.

## Preserve

Do not replace working event-driven/observed state with high-frequency polling.

Keep animations and lifetime short.
