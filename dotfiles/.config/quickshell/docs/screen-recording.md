# Screen recording

The compact pill in the right bar cluster opens three recording modes:

- **Window:** click a visible window through `slurp`'s predefined rectangles on Hyprland; select its area manually on labwc.
- **Full screen:** record the focused Hyprland monitor, or select an output on labwc.
- **Selection:** drag a region with `slurp`.

`scripts/screen-recording.py` starts `wf-recorder` and returns JSON to QML.
The active process and output path are stored in a private runtime state file,
so the pill can recover its recording indicator after a Quickshell reload.
Stopping sends SIGINT to that specific recorder process to finalize the MP4.

Videos are saved under the XDG Videos directory in `Gravações de tela`.
The bar shows elapsed time while recording (plus a `󰕾` audio icon when recording
with sound). Click the pill, then **Parar gravação** to finish. A window recording
captures the window's chosen screen rectangle; it does not follow the window if
moved or resized.

Audio recording can be toggled on/off directly inside the popup before starting
a recording. When enabled, `scripts/screen-recording.py` passes `-a` to `wf-recorder`,
capturing audio through the default PipeWire/PulseAudio sink or source.

Dependencies: `wf-recorder`, `slurp` (`hyprctl` only on Hyprland). Errors and the saved path are
shown in the popup. Canceling a selection starts no recording.
