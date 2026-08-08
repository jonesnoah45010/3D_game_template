#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(pwd -P)"
REQUIREMENTS_FILE="$PROJECT_DIR/requirements.txt"
MAIN_FILE="$PROJECT_DIR/main.py"

if [[ ! -f "$REQUIREMENTS_FILE" ]]; then
    echo "Error: requirements.txt was not found in $PROJECT_DIR" >&2
    exit 1
fi

if [[ ! -f "$MAIN_FILE" ]]; then
    echo "Error: main.py was not found in $PROJECT_DIR" >&2
    exit 1
fi

VENV_DIR=""

# Prefer the conventional virtual-environment directory names.
for candidate in .venv venv env; do
    if [[ -f "$PROJECT_DIR/$candidate/pyvenv.cfg" && \
          -x "$PROJECT_DIR/$candidate/bin/python" ]]; then
        VENV_DIR="$PROJECT_DIR/$candidate"
        break
    fi
done

# Otherwise, use the first valid virtual environment directly inside the CWD.
if [[ -z "$VENV_DIR" ]]; then
    for config in "$PROJECT_DIR"/*/pyvenv.cfg; do
        [[ -e "$config" ]] || continue
        candidate="${config%/pyvenv.cfg}"
        if [[ -x "$candidate/bin/python" ]]; then
            VENV_DIR="$candidate"
            break
        fi
    done
fi

if [[ -z "$VENV_DIR" ]]; then
    echo "Error: no Python virtual environment was found in $PROJECT_DIR" >&2
    echo "Create one with: python3 -m venv .venv" >&2
    exit 1
fi

PYTHON="$VENV_DIR/bin/python"

echo "Using virtual environment: $VENV_DIR"
echo "Checking requirements..."

# pip verifies all requirement specifiers and installs only missing, outdated,
# or otherwise incompatible packages. Already-satisfied packages are unchanged.
"$PYTHON" -m pip install --requirement "$REQUIREMENTS_FILE"

echo "Requirements are satisfied. Starting main.py..."
exec "$PYTHON" "$MAIN_FILE"
