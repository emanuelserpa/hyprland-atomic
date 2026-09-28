# Printing

`bar/Printer.qml` owns the shared printer state and cancellation process.
Its compact `PrinterPopup.qml` shows reachable printers and a short queue view.
The **Abrir fila de impressão** button opens `PrinterQueueWindow.qml`, a
regular desktop window with a scrollable list of pending documents and a
cancel action for each job. Both surfaces use the same `printer-status.py`
result and `printer-action.py cancel` command.
Hyprland's `quickshell-printer-queue-float` rule matches this window's title
and opens it centered at 700×500. Other compositors may tile regular windows.
The window uses the shared `Theme.qml` colors, typography, and popup framing.

The status helper uses CUPS commands (`lpstat` and, when available, `lpq`).
It checks whether configured destinations are reachable before showing them
or their jobs. It reports the full pending job count and returns up to 100
job entries for the UI. Document titles depend on `lpq`; when unavailable,
the CUPS job ID is shown. The queue refreshes every two seconds while a job
exists or its window is open, and on explicit refresh or after cancellation.

Cancellation affects the selected CUPS job immediately and shows an inline
error if it fails. The shared `ActionFeedback.qml` carries cancellation busy
and error state; printer errors remain until the next action. Completed jobs,
pause/resume, and document previews are outside this queue's scope.

Document titles come from `lpq` (parsed by column position, not spacing,
since single-space gaps misalign fixed splits). Jobs ranked `active` in
`lpq` show a "● imprimindo" marker. The exact page being printed is not
exposed: the `lpd` backend never updates IPP progress counters
(`job-media-sheets-completed` stays 0 even for finished jobs).
