# Bluetooth Module

## Current components

- `bar/Bluetooth.qml`
- `bar/BluetoothPopup.qml`
- `scripts/bluetooth-status.py`
- `scripts/bluetooth-action.py`

## Bar behavior

Typical states:
- off -> grey Bluetooth-off icon;
- on, no connection -> cyan Bluetooth;
- connected -> green Bluetooth + count.

Interactions:
- left click -> popup;
- middle click -> power toggle.
- the popup header gear opens Blueberry advanced settings.

## Popup behavior

Supports:
- power state;
- connected devices;
- paired devices;
- discovered devices;
- connect;
- disconnect;
- pair;
- battery where BlueZ exposes it;
- contextual state/errors;
- Blueberry fallback.

The bar uses the shared `ActionFeedback.qml` for action busy state and
target-specific errors. Discovery remains a separate long-running process.

## Discovery policy

Discovery should only be active while useful.

Do not create permanent background discovery traffic.

## UX posture

The current Bluetooth implementation is considered good enough.

Future work should be polish, not a rewrite, unless explicit need appears.

Good polish candidates:
- more compact empty state;
- better scanning indicator;
- per-device icons;
- cleaner device naming;
- refined activity spinner/state.

## Avoid

Do not rewrite to raw BlueZ D-Bus solely for architecture aesthetics.

Do not destabilize pairing/connect behavior.
