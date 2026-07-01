# zizmor-action

A GitHub Action that runs [zizmor](https://github.com/zizmorcore/zizmor), a
static analysis tool for finding security issues in GitHub Actions workflows.

This action is a composite action built around a Docker container action
(`audit/`) that runs zizmor on top of the image published to GHCR
(`ghcr.io/its-me/zizmor`). It is designed as a drop-in replacement for the
common cases of the upstream `zizmor-action`, while keeping the first version
intentionally small.

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

Results are automatically uploaded to GitHub code scanning when
`advanced-security` resolves to enabled (see below), so they show up in the
repository's **Security** tab as well as in the job log/SARIF output.

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
| `advanced-security` | Upload results to GitHub Advanced Security (code scanning): `true`, `false`, or `auto` (upload only if the repository is public). | `auto`                  |
| `config`            | Inline zizmor configuration (YAML) to apply.                                                               | _(unset)_               |

## Outputs

| Name          | Description                                              |
| ------------- | ------------------------------------------------------- |
| `output-file` | Path (relative to the workspace) of the SARIF results.  |

## Not yet supported

Compared to the upstream action, this first version omits: `version`
pinning (use the image tag instead), `annotations`, `color`, and
`fail-on-no-inputs`.
