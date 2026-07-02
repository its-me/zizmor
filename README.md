# action.zizmor

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
on:
  push:
    branches: ['**']
  pull_request:
  workflow_dispatch:

permissions:
  contents: read
  security-events: write

jobs:
  zizmor:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: its-me/action.zizmor@main
```

When `advanced-security` resolves to enabled (see below), results are
uploaded to GitHub code scanning, so they show up in the repository's
**Security** tab as well as in the job log. When it resolves to disabled
(e.g. a repository without code scanning enabled left on `auto`), the action
instead streams findings straight into the job log as inline
`::warning::`/`::error::` annotations - no SARIF file is produced or
uploaded in that case, and `output-file` is left unset.

> Note: `zizmor`'s SARIF output always exits `0`, even with findings - this
> is by design, since Advanced Security mode expects findings to be
> triaged via the Security tab rather than block the build. Use a
> [ruleset] if you want findings to block merges. When `advanced-security`
> resolves to disabled, the job fails on findings instead, since `zizmor`
> exits non-zero for its non-SARIF output formats.

[ruleset]: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#set-code-scanning-merge-protection

## Inputs

| Name                | Description                                                                                              | Default               |
| ------------------- | --------------------------------------------------------------------------------------------------------- | ---------------------- |
| `inputs`            | Whitespace-separated list of files or directories to audit.                                                | `.`                     |
| `online-audits`     | Enable online (network-backed) audits. Set `false` to run offline.                                         | `true`                  |
| `persona`           | Audit strictness: `regular`, `pedantic`, or `auditor`.                                                     | `regular`               |
| `min-severity`      | Minimum severity to report (`unknown`…`high`).                                                             | _(unset)_              |
| `min-confidence`    | Minimum confidence to report (`unknown`…`high`).                                                           | _(unset)_              |
| `version`           | The version of zizmor to use (e.g. `1.26.1`, with or without a `v` prefix), or `latest`.                   | `latest`                |
| `token`             | GitHub token used to authenticate online audits.                                                           | `${{ github.token }}`  |
| `advanced-security` | Upload results to GitHub Advanced Security (code scanning): `true`, `false`, or `auto` (upload only if code scanning is enabled for the repository). | `auto`                  |
| `annotations`       | Also emit GitHub annotations for findings. When `advanced-security` resolves to enabled, zizmor runs a second time with `--format github` so annotations appear in the job log alongside the SARIF upload, and the job's pass/fail result is driven by that second run instead of the always-zero SARIF exit code. No effect when `advanced-security` resolves to disabled, since annotations are already the fallback output. | `false`                 |
| `color`             | Whether zizmor should output colorized CLI output.                                                         | `true`                  |
| `config`            | Path to a zizmor config file, or inline zizmor configuration (YAML) to apply directly.                     | _(unset)_               |
| `fail-on-no-inputs` | Whether the action should fail if no inputs are collected by zizmor. Set `false` to succeed (with a warning) instead. | `true`                  |

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

## Improvements over the upstream action

Compared to the upstream `zizmor-action`, this action adds:

- **A custom container image** (`ghcr.io/its-me/zizmor`), built specifically
  for this action. It's about a third smaller than the official image
  (~38 MB vs ~57 MB, Alpine-based rather than Wolfi-based) while running
  the exact same `zizmor` binary and version underneath, so pulls and
  builds are faster with no change in audit behavior.
- **`advanced-security: auto`**, which detects whether GitHub code
  scanning is actually available for the repository (via the
  code-scanning API) instead of requiring you to hardcode `true` or
  `false` per repository.
- **Combinable `annotations` and `advanced-security`**: upstream treats
  these as mutually exclusive and refuses to run if both are `true`.
  Here, enabling both runs zizmor twice - once for the SARIF upload, once
  more with `--format github` - so you get a persistent Security-tab
  record *and* a build that fails on findings, in the same job (at the
  cost of auditing the repository twice).
- **A single `config` input that accepts both a file path and inline
  YAML**, auto-detected, instead of requiring a path only.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for
the full text.
