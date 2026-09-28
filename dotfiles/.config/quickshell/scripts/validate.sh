#!/usr/bin/env bash
set -uo pipefail

export PYTHONDONTWRITEBYTECODE=1

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [[ "${1:-}" == "--visual" ]]; then
    exec "$REPO_ROOT/scripts/visual-check.sh"
fi

OK_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

record_ok() {
    local msg="$1"
    echo -e "[OK] $msg"
    OK_COUNT=$((OK_COUNT + 1))
}

record_warn() {
    local msg="$1"
    echo -e "[WARN] $msg"
    WARN_COUNT=$((WARN_COUNT + 1))
}

record_fail() {
    local msg="$1"
    echo -e "[FAIL] $msg"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

# -----------------------------------------------------------------------------
# A. Python Syntax Check
# -----------------------------------------------------------------------------
py_syntax_ok=true
py_count=0
while IFS= read -r py_file; do
    py_count=$((py_count + 1))
    if ! python3 -m py_compile "$py_file" 2>/dev/null; then
        record_fail "Python syntax error in: $py_file"
        py_syntax_ok=false
    fi
done < <(find scripts tests -type f -name "*.py" | sort)

if [ "$py_syntax_ok" = true ]; then
    record_ok "Python syntax ($py_count files compiled)"
fi

# Clean up any potential pycache accidentally created
find "$REPO_ROOT" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# -----------------------------------------------------------------------------
# A2. QML Static Check (qmllint)
# -----------------------------------------------------------------------------
# Catches whole-shell breakers (unknown types, syntax errors) that would
# otherwise only surface as "Failed to load configuration" on hot-reload.
# Only hard errors fail; style warnings are ignored.
qmllint_bin=""
for cand in /usr/lib/qt6/bin/qmllint "$(command -v qmllint 2>/dev/null || true)"; do
    [ -n "$cand" ] && [ -x "$cand" ] && { qmllint_bin="$cand"; break; }
done

if [ -z "$qmllint_bin" ]; then
    record_warn "qmllint not found (skipping static QML check)"
else
    qml_lint_fail=""
    qml_lint_count=0
    while IFS= read -r qml_file; do
        qml_lint_count=$((qml_lint_count + 1))
        lint_out="$("$qmllint_bin" -I "$REPO_ROOT" -I /usr/lib/qt6/qml "$qml_file" 2>&1)"
        lint_rc=$?
        if [ "$lint_rc" -ne 0 ] || echo "$lint_out" | grep -qE "^Error"; then
            record_fail "qmllint error in: $qml_file"$'\n'"$lint_out"
            qml_lint_fail=true
        fi
    done < <(find . -not -path './.*' -name "*.qml" | sort)
    if [ -z "$qml_lint_fail" ]; then
        record_ok "qmllint static check ($qml_lint_count files, errors only)"
    fi
fi

# -----------------------------------------------------------------------------
# B. Executable Bits Check
# -----------------------------------------------------------------------------
exec_ok=true
exec_count=0
for script in scripts/*; do
    [ -f "$script" ] || continue
    # Check if first line has a shebang
    first_line="$(head -n 1 "$script" 2>/dev/null || true)"
    if [[ "$first_line" =~ ^#! ]]; then
        exec_count=$((exec_count + 1))
        if [ ! -x "$script" ]; then
            record_fail "Script has shebang but is not executable: $script"
            exec_ok=false
        fi
    fi
done

if [ "$exec_ok" = true ]; then
    record_ok "Executable scripts ($exec_count checked)"
fi

# -----------------------------------------------------------------------------
# C. QML Module & qmldir Sanity
# -----------------------------------------------------------------------------
qml_sanity_ok=true
qmldir_count=0

while IFS= read -r qmldir_path; do
    qmldir_count=$((qmldir_count + 1))
    qml_dir="$(dirname "$qmldir_path")"
    while IFS= read -r line || [ -n "$line" ]; do
        # Trim whitespace
        line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [ -z "$line" ] && continue
        [[ "$line" =~ ^# ]] && continue
        [[ "$line" =~ ^module[[:space:]] ]] && continue

        # Extract the last token which should be the .qml filename
        target_file="$(echo "$line" | awk '{print $NF}')"
        if [[ "$target_file" =~ \.qml$ ]]; then
            if [ ! -f "$qml_dir/$target_file" ]; then
                record_fail "qmldir in $qml_dir references missing file: $target_file"
                qml_sanity_ok=false
            fi
        fi
    done < "$qmldir_path"
done < <(find . -name "qmldir" | sort)

# Verify standard local modules exist
for mod in bar components launcher notifications osd services; do
    if [ ! -d "$REPO_ROOT/$mod" ]; then
        record_fail "Expected QML module directory missing: $mod"
        qml_sanity_ok=false
    fi
done

# Reverse direction: every .qml file must be registered in its dir's qmldir.
# An unregistered component fails at runtime ("X is not a type") while
# passing every other check, and can crash the shell on startup.
# Exception: shell.qml is the root entry point, not a module type.
while IFS= read -r qmldir_path; do
    qml_dir="$(dirname "$qmldir_path")"
    registered="$(awk '!/^#/ && !/^module[[:space:]]/ && NF {print $NF}' "$qmldir_path" | grep '\.qml$' || true)"
    while IFS= read -r qml_file; do
        base="$(basename "$qml_file")"
        [ "$base" = "shell.qml" ] && continue
        if ! grep -qxF "$base" <<< "$registered"; then
            record_fail "QML file not registered in $qml_dir/qmldir: $base"
            qml_sanity_ok=false
        fi
    done < <(find "$qml_dir" -maxdepth 1 -type f -name "*.qml" | sort)
done < <(find . -name "qmldir" | sort)

if [ "$qml_sanity_ok" = true ]; then
    record_ok "QML module files & singletons ($qmldir_count qmldir checked)"
fi

# -----------------------------------------------------------------------------
# D. shell.qml Baseline Sanity
# -----------------------------------------------------------------------------
shell_baseline_ok=true
if [ ! -f "$REPO_ROOT/shell.qml" ]; then
    record_fail "Missing root shell.qml"
    shell_baseline_ok=false
fi

if [ ! -f "$REPO_ROOT/Theme.qml" ]; then
    record_fail "Missing root Theme.qml"
    shell_baseline_ok=false
fi

# Essential components instantiated in shell.qml
for comp in \
    "services/ClipboardService.qml" \
    "launcher/Spotlight.qml" \
    "bar/Bar.qml" \
    "osd/Osd.qml" \
    "notifications/NotificationToasts.qml"; do
    if [ ! -f "$REPO_ROOT/$comp" ]; then
        record_fail "shell.qml baseline component missing: $comp"
        shell_baseline_ok=false
    fi
done

if [ "$shell_baseline_ok" = true ]; then
    record_ok "shell.qml baseline & root components"
fi

# -----------------------------------------------------------------------------
# E. JSON Helpers Execution (Safe Non-Destructive Helpers)
# -----------------------------------------------------------------------------
run_json_helper() {
    local name="$1"
    shift
    local cmd=("$@")

    local stdout_file
    stdout_file="$(mktemp)"
    local stderr_file
    stderr_file="$(mktemp)"

    local rc=0
    python3 -B "${cmd[@]}" >"$stdout_file" 2>"$stderr_file" || rc=$?

    # Verify JSON validity via python
    local json_check
    json_check="$(python3 -c "
import json, sys
try:
    with open('$stdout_file', 'r', encoding='utf-8') as f:
        data = json.load(f)
    available = data.get('available', True)
    status = data.get('status', 'ok')
    err = data.get('error', '')
    if status == 'error' or available is False:
        print('WARN:' + (str(err) or 'service unavailable'))
    else:
        print('OK')
except Exception as e:
    print('FAIL:' + str(e))
" 2>/dev/null || echo "FAIL:parser crash")"

    rm -f "$stdout_file" "$stderr_file"

    if [[ "$json_check" =~ ^OK ]]; then
        record_ok "JSON helper: $name"
    elif [[ "$json_check" =~ ^WARN:(.*) ]]; then
        local reason="${BASH_REMATCH[1]}"
        record_warn "$name: $reason"
    else
        record_fail "JSON helper: $name returned invalid output ($json_check)"
    fi
}

run_json_helper "network-status" scripts/network-status.py
run_json_helper "bluetooth-status" scripts/bluetooth-status.py
run_json_helper "kdeconnect-status" scripts/kdeconnect-status.py
run_json_helper "printer-status" scripts/printer-status.py
run_json_helper "energy-profile" scripts/energy-profile.py status
run_json_helper "nightlight-status" scripts/nightlight-manager.py status
run_json_helper "weather" scripts/waybar-wttr.py

# -----------------------------------------------------------------------------
# F. Undesirable Files Check
# -----------------------------------------------------------------------------
# Some JSON helper probes import neighboring Python modules after the initial
# syntax cleanup. Remove their generated bytecode before checking repo hygiene.
find "$REPO_ROOT" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
unwanted_files=()
while IFS= read -r f; do
    [ -n "$f" ] && unwanted_files+=("$f")
done < <(find . -not -path '*/.*' \( -name "__pycache__" -o -name "*.pyc" -o -name "*.tmp" -o -name "*~" -o -name "*.swp" \) 2>/dev/null)

if [ ${#unwanted_files[@]} -gt 0 ]; then
    record_fail "Unwanted files/directories found: ${unwanted_files[*]}"
else
    record_ok "No __pycache__ or temporary files"
fi

# -----------------------------------------------------------------------------
# G. Runtime Dependency Checks (Obsolete Dependencies)
# -----------------------------------------------------------------------------
obsolete_ok=true

# Check for CopyQ in runtime files (excluding .git, docs, markdown, import tool, and validate.sh itself)
copyq_matches="$(grep -Rni "copyq" --exclude-dir=.git --exclude-dir=docs --exclude-dir=tests --exclude="*.md" --exclude="clipboard-import-copyq.py" --exclude="validate.sh" . 2>/dev/null || true)"
if [ -n "$copyq_matches" ]; then
    record_fail "Obsolete CopyQ reference found in runtime code:\n$copyq_matches"
    obsolete_ok=false
fi

# Check for SwayNC in runtime code
swaync_matches="$(grep -Rni "swaync" --exclude-dir=.git --exclude-dir=docs --exclude-dir=tests --exclude="*.md" --exclude="validate.sh" . 2>/dev/null || true)"
if [ -n "$swaync_matches" ]; then
    record_fail "Obsolete SwayNC reference found in runtime code:\n$swaync_matches"
    obsolete_ok=false
fi

# Check for obsolete config/bar.json
if [ -f "$REPO_ROOT/config/bar.json" ]; then
    record_fail "Obsolete config/bar.json exists"
    obsolete_ok=false
fi

if [ "$obsolete_ok" = true ]; then
    record_ok "Runtime dependency checks (no obsolete CopyQ/SwayNC)"
fi

# -----------------------------------------------------------------------------
# H. Unit Tests Execution
# -----------------------------------------------------------------------------
test_out_file="$(mktemp)"
test_rc=0
python3 -B -m unittest discover -s "$REPO_ROOT/tests" -p "test_*.py" >"$test_out_file" 2>&1 || test_rc=$?

test_summary="$(tail -n 3 "$test_out_file" | tr '\n' ' ')"
rm -f "$test_out_file"

# Clean up pycache from tests
find "$REPO_ROOT" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

if [ "$test_rc" -eq 0 ]; then
    # Extract test count if possible
    if [[ "$test_summary" =~ Ran\ ([0-9]+)\ test ]]; then
        record_ok "Unit tests (${BASH_REMATCH[1]} tests passed)"
    else
        record_ok "Unit tests (all passed)"
    fi
else
    record_fail "Unit tests failed: $test_summary"
fi

# -----------------------------------------------------------------------------
# I. Compositor Agnosticism & Leakage Check
# -----------------------------------------------------------------------------
agnostic_ok=true

# Check for hyprctl leakage in QML (only bar/Submap.qml allowed as modal submap indicator)
hyprctl_qml_leaks="$(grep -Rnl "hyprctl" --include="*.qml" --exclude="Submap.qml" "$REPO_ROOT" 2>/dev/null || true)"
if [ -n "$hyprctl_qml_leaks" ]; then
    record_fail "Compositor leakage: direct hyprctl calls found in QML files (use scripts/compositor-dispatch.sh):\n$hyprctl_qml_leaks"
    agnostic_ok=false
fi

# Check for Lua dispatcher syntax in QML
lua_qml_leaks="$(grep -Rnl "hl\.dsp" --include="*.qml" "$REPO_ROOT" 2>/dev/null || true)"
if [ -n "$lua_qml_leaks" ]; then
    record_fail "Compositor leakage: Lua dispatcher syntax (hl.dsp) found in QML files:\n$lua_qml_leaks"
    agnostic_ok=false
fi

# Check compositor-dispatch.sh existence and executable bit
if [ ! -x "$REPO_ROOT/scripts/compositor-dispatch.sh" ]; then
    record_fail "Missing or non-executable scripts/compositor-dispatch.sh"
    agnostic_ok=false
fi

if [ "$agnostic_ok" = true ]; then
    record_ok "Compositor agnosticism (no hyprctl/Lua leakage in UI QML)"
fi

# -----------------------------------------------------------------------------
# H. Spotlight Open-Latency Budget (150ms, WARN only)
# -----------------------------------------------------------------------------
# Measures app-side open latency via the Spotlight probe (openRequestedAt ->
# onVisibleChanged). Needs a live quickshell session; skipped otherwise.
if command -v quickshell >/dev/null 2>&1 \
    && quickshell ipc call spotlight toggle >/dev/null 2>&1; then
    sleep 2
    quickshell ipc call spotlight toggle >/dev/null 2>&1 || true
    sleep 1
    latest_log="$(ls -t "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/quickshell/by-id/*/log.qslog 2>/dev/null | head -n1)"
    latency_ms="$(grep -a -o -E 'Spotlight open latency: [0-9]+ms' "$latest_log" 2>/dev/null | tail -n1 | grep -a -o -E '[0-9]+' || true)"
    if [ -z "$latency_ms" ]; then
        record_warn "Spotlight latency probe produced no reading (session busy?)"
    elif [ "$latency_ms" -gt 150 ]; then
        record_warn "Spotlight open latency ${latency_ms}ms exceeds 150ms budget"
    else
        record_ok "Spotlight open latency ${latency_ms}ms (budget 150ms)"
    fi
else
    record_warn "Spotlight latency probe skipped (no live quickshell IPC)"
fi

# -----------------------------------------------------------------------------
# Final Summary
# -----------------------------------------------------------------------------
echo ""
if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "Validation passed: $OK_COUNT OK, $WARN_COUNT WARN, $FAIL_COUNT FAIL"
    exit 0
else
    echo "Validation failed: $OK_COUNT OK, $WARN_COUNT WARN, $FAIL_COUNT FAIL"
    exit 1
fi
