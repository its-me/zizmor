# zizmor-action

A GitHub Action that runs [zizmor](https://github.com/zizmorcore/zizmor), a
static analysis tool for finding security issues in GitHub Actions workflows.

This action is a Docker container action built on top of the zizmor image
published to GHCR (`ghcr.io/its-me/zizmor`). It is designed as a drop-in
replacement for the common cases of the upstream `zizmor-action`, while
keeping the first version intentionally small.

## Usage

```yaml
name: zizmor
on: [push, pull_request]

permissions:
  contents: read

jobs:
  zizmor:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: its-me/zizmor@main
        with:
          inputs: .
```

### Uploading results to code scanning (optional)

This first version produces a SARIF file but leaves the upload step to you:

```yaml
      - uses: its-me/zizmor@main
        id: zizmor
        with:
          inputs: .
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: ${{ steps.zizmor.outputs.output-file }}
```

> Note: zizmor exits non-zero when it finds issues, so use `if: always()` on
> the upload step if you want results published even when the audit fails.

## Inputs

| Name             | Description                                                            | Default              |
| ---------------- | ---------------------------------------------------------------------- | -------------------- |
| `inputs`         | Whitespace-separated list of files or directories to audit.            | `.`                  |
| `online-audits`  | Enable online (network-backed) audits. Set `false` to run offline.    | `true`               |
| `persona`        | Audit strictness: `regular`, `pedantic`, or `auditor`.                 | `regular`            |
| `min-severity`   | Minimum severity to report (`unknown`…`high`).                         | _(unset)_            |
| `min-confidence` | Minimum confidence to report (`unknown`…`high`).                       | _(unset)_            |
| `token`          | GitHub token used to authenticate online audits.                      | `${{ github.token }}`|

## Outputs

| Name          | Description                                              |
| ------------- | ------------------------------------------------------- |
| `output-file` | Path (relative to the workspace) of the SARIF results.  |

## Not yet supported

Compared to the upstream action, this first version omits: automatic SARIF
upload (`advanced-security`), `version` pinning (use the image tag instead),
`config`, `annotations`, `color`, and `fail-on-no-inputs`.
