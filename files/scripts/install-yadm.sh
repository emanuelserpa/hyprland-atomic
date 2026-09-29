#!/usr/bin/env bash
set -euo pipefail

yadm_version='3.5.0'
curl -fsSL \
  "https://raw.githubusercontent.com/yadm-dev/yadm/${yadm_version}/yadm" \
  -o /usr/bin/yadm
chmod 0755 /usr/bin/yadm
