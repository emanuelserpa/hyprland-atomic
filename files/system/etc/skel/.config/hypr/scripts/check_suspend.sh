#!/bin/bash
if cat /sys/class/power_supply/BAT0/status | grep 'Discharging' > /dev/null && cat /proc/acpi/button/lid/LID/state | grep 'closed' > /dev/null; then
    systemctl suspend
fi
