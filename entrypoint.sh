#!/bin/sh
set -eu

TARGETS="${INPUT_INPUTS:-.}"
PERSONA="${INPUT_PERSONA:-regular}"
ONLINE="${INPUT_ONLINE_AUDITS:-true}"
FORMAT="${INPUT_FORMAT:-sarif}"

WORKDIR="${GITHUB_WORKSPACE:-$(pwd)}"

set -- --format "$FORMAT" --persona "$PERSONA"

if [ "${INPUT_COLOR:-true}" = "true" ]; then
  set -- "$@" --color=always
else
  set -- "$@" --color=never
fi

if [ "$ONLINE" = "true" ]; then
  if [ -n "${INPUT_TOKEN:-}" ]; then
    set -- "$@" --gh-token "$INPUT_TOKEN"
  fi
else
  set -- "$@" --offline
fi

if [ -n "${INPUT_MIN_SEVERITY:-}" ]; then
  set -- "$@" --min-severity "$INPUT_MIN_SEVERITY"
fi

if [ -n "${INPUT_MIN_CONFIDENCE:-}" ]; then
  set -- "$@" --min-confidence "$INPUT_MIN_CONFIDENCE"
fi

if [ -n "${INPUT_CONFIG:-}" ]; then
  case "$INPUT_CONFIG" in
    *"
"*)
      # Contains a newline: can't be a file path, must be inline YAML.
      IS_PATH=false
      ;;
    *)
      if [ -f "${WORKDIR}/${INPUT_CONFIG}" ] || [ -f "$INPUT_CONFIG" ]; then
        IS_PATH=true
      else
        IS_PATH=false
      fi
      ;;
  esac

  if [ "$IS_PATH" = true ]; then
    CONFIG_PATH="$INPUT_CONFIG"
  else
    CONFIG_PATH="$(mktemp)"
    printf '%s\n' "$INPUT_CONFIG" > "$CONFIG_PATH"
  fi
  set -- "$@" --config "$CONFIG_PATH"
fi

echo "::group::zizmor invocation"
echo "zizmor $* $TARGETS"
echo "::endgroup::"

set +e
if [ "$FORMAT" != "sarif" ]; then
  # Non-sarif formats exit non-zero on findings, so just stream and propagate.
  zizmor "$@" $TARGETS # shellcheck disable=SC2086
  STATUS=$?
else
  SARIF_PATH="${RUNNER_TEMP:-/tmp}/zizmor.sarif"

  # --format sarif always exits 0 on findings by design: results are meant to
  # surface via GitHub code scanning rather than fail the build.
  zizmor "$@" $TARGETS > "$SARIF_PATH" # shellcheck disable=SC2086
  STATUS=$?

  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "output-file=${SARIF_PATH}" >> "$GITHUB_OUTPUT"
  fi
fi
set -e

if [ "$STATUS" -eq 3 ] && [ "${INPUT_FAIL_ON_NO_INPUTS:-true}" = "false" ]; then
  echo "::warning::No inputs were collected by zizmor"
  exit 0
fi

exit "$STATUS"
