# zizmor-action

A GitHub Action that runs [zizmor](https://github.com/zizmorcore/zizmor), a
static analysis tool for finding security issues in GitHub Actions workflows.

This action is a composite action that builds and runs a Docker image
(based on `ghcr.io/its-me/zizmor`) directly from its own checked-out files
(via `github.action_path`), so behavior always matches the exact version of
the action that was invoked - regardless of which repository calls it. It is
designed as a drop-in replacement for the common cases of the upstream
`zizmor-action`, while keeping the first version intentionally small.

## Usage

```yaml
name: zizmor
on: [push, pull_request]

permissions:
  contents: read
  security-events: write

jobs:
  zizmor:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: its-me/zizmor@main
        with:
          inputs: .
```

When `advanced-security` resolves to enabled (see below), results are
uploaded to GitHub code scanning, so they show up in the repository's
**Security** tab as well as in the job log. When it resolves to disabled
(e.g. a repository without code scanning enabled left on `auto`), the action
instead streams findings straight into the job log as inline
`::warning::`/`::error::` annotations - no SARIF file is produced or
uploaded in that case, and `output-file` is left unset.

> Note: zizmor exits non-zero when it finds issues, so the job will fail on
> findings; the upload step still runs regardless, via `if: always()`.

## Inputs

| Name                | Description                                                                                              | Default               |
| ------------------- | --------------------------------------------------------------------------------------------------------- | ---------------------- |
| `inputs`            | Whitespace-separated list of files or directories to audit.                                                | `.`                     |
| `online-audits`     | Enable online (network-backed) audits. Set `false` to run offline.                                         | `true`                  |
| `persona`           | Audit strictness: `regular`, `pedantic`, or `auditor`.                                                     | `regular`               |
| `min-severity`      | Minimum severity to report (`unknown`…`high`).                                                             | _(unset)_              |
| `min-confidence`    | Minimum confidence to report (`unknown`…`high`).                                                           | _(unset)_              |
| `token`             | GitHub token used to authenticate online audits.                                                           | `${{ github.token }}`  |
| `config`            | Path to a zizmor config file, or inline zizmor configuration (YAML) to apply directly.                     | _(unset)_               |
| `advanced-security` | Upload results to GitHub Advanced Security (code scanning): `true`, `false`, or `auto` (upload only if code scanning is enabled for the repository). | `auto`                  |

`config` accepts either form and detects which one you gave it: if the
value spans multiple lines it's treated as inline YAML, otherwise it's
checked against the workspace for a matching file and used as a path if
found, falling back to inline YAML otherwise.

> [!NOTE]
> A single-line inline config (e.g. `config: "rules: {}"`) that happens to
> also match an existing file path in your repository will be treated as a
> path, not inline content. This is a rare edge case, but if you hit it,
> either rename the conflicting file or make the inline config span
> multiple lines.

## Outputs

| Name          | Description                                                                                   |
| ------------- | ----------------------------------------------------------------------------------------------- |
| `output-file` | Absolute path (under the runner's temp directory) of the SARIF results. Only set when `advanced-security` is active. |

## Not yet supported

Compared to the upstream action, this first version omits: `version`
pinning (use the image tag instead), `annotations`, `color`, and
`fail-on-no-inputs`.
