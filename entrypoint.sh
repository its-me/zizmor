#!/bin/sh
set -eu

TARGETS="${INPUT_INPUTS:-.}"
PERSONA="${INPUT_PERSONA:-regular}"
ONLINE="${INPUT_ONLINE_AUDITS:-true}"
FORMAT="${INPUT_FORMAT:-sarif}"
ANNOTATIONS="${INPUT_ANNOTATIONS:-false}"

WORKDIR="${GITHUB_WORKSPACE:-$(pwd)}"

set -- --persona "$PERSONA"

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

set +e

if [ "$FORMAT" = "sarif" ]; then
  SARIF_PATH="${RUNNER_TEMP:-/tmp}/zizmor.sarif"

  echo "::group::zizmor invocation (sarif)"
  echo "zizmor --format sarif $* $TARGETS"
  echo "::endgroup::"

  # --format sarif always exits 0 on findings by design: results are meant to
  # surface via GitHub code scanning rather than fail the build.
  # shellcheck disable=SC2086
  zizmor --format sarif "$@" $TARGETS > "$SARIF_PATH"
  SARIF_STATUS=$?

  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "output-file=${SARIF_PATH}" >> "$GITHUB_OUTPUT"
  fi

  if [ "$ANNOTATIONS" = "true" ]; then
    # Run a second pass so real GitHub annotations show up in the job log
    # alongside the SARIF upload; its exit code drives the job result since
    # the SARIF pass above always exits 0.
    echo "::group::zizmor invocation (github)"
    echo "zizmor --format github $* $TARGETS"
    echo "::endgroup::"

    # shellcheck disable=SC2086
    zizmor --format github "$@" $TARGETS
    STATUS=$?
  else
    STATUS=$SARIF_STATUS
  fi
else
  echo "::group::zizmor invocation"
  echo "zizmor --format $FORMAT $* $TARGETS"
  echo "::endgroup::"

  # Non-sarif formats exit non-zero on findings, so just stream and propagate.
  # shellcheck disable=SC2086
  zizmor --format "$FORMAT" "$@" $TARGETS
  STATUS=$?
fi

set -e

if [ "$STATUS" -eq 3 ] && [ "${INPUT_FAIL_ON_NO_INPUTS:-true}" = "false" ]; then
  echo "::warning::No inputs were collected by zizmor"
  exit 0
fi

exit "$STATUS"
