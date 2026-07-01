#!/bin/sh
set -eu

TARGETS="${INPUT_INPUTS:-.}"
PERSONA="${INPUT_PERSONA:-regular}"
ONLINE="${INPUT_ONLINE_AUDITS:-true}"

SARIF_NAME="zizmor.sarif"
WORKDIR="${GITHUB_WORKSPACE:-$(pwd)}"
SARIF_PATH="${WORKDIR}/${SARIF_NAME}"

set -- --format sarif --persona "$PERSONA"

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

echo "::group::zizmor invocation"
echo "zizmor $* $TARGETS"
echo "::endgroup::"

zizmor "$@" $TARGETS > "$SARIF_PATH" # shellcheck disable=SC2086

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "output-file=${SARIF_NAME}" >> "$GITHUB_OUTPUT"
fi

# --format sarif always exits 0, so count findings in the SARIF itself.
FINDINGS=$(grep -c '"ruleId"' "$SARIF_PATH" || true)

if [ "$FINDINGS" -eq 0 ]; then
  echo "zizmor completed with no findings. SARIF written to ${SARIF_NAME}."
  exit 0
fi

echo "zizmor found ${FINDINGS} finding(s). SARIF written to ${SARIF_NAME}."
exit 1
