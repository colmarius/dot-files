# AGENTS.md

This file applies to the entire repository.

## Repository Purpose

Personal dotfiles repository for macOS/Linux shell and CLI tooling setup.

Main goals:
- Keep configs easy to restore on a new machine.
- Keep bootstrap and shell startup files safe and maintainable.
- Keep changes low-risk for daily shell usage.

## Repo Layout

- `files/`: source dotfiles that are linked into `$HOME` by `clone_and_link.sh`.
- `clone_and_link.sh`: bootstrap script used for first install and updates.
- `scripts/lint-shell.sh`: strict shell lint entrypoint (used in CI).
- `scripts/lint-shell-all.sh`: advisory lint over broader shell config, including zsh files.
- `.github/workflows/shellcheck.yml`: CI lint workflow.
- `README.md` and `SETUP.md`: user-facing setup and maintenance docs.

## Change Guidelines

- Prefer small, targeted edits over broad refactors.
- Preserve behavior unless a change request explicitly asks to change it.
- Be conservative with shell startup files; failures can block terminal startup.
- Keep scripts POSIX/Bash compatible according to existing shebang and style.
- Do not introduce secrets, tokens, private keys, or machine-specific sensitive data.

## Validation Checklist

Run after shell-related changes:

```bash
bash scripts/lint-shell.sh
```

Optional broader advisory scan:

```bash
bash scripts/lint-shell-all.sh
```

If you need advisory lint to fail for cleanup work:

```bash
STRICT=1 bash scripts/lint-shell-all.sh
```

## ShellCheck Notes

- Repo-level config is in `.shellcheckrc`.
- `scripts/lint-shell.sh` is the authoritative strict lint command.
- Keep CI green by ensuring `scripts/lint-shell.sh` passes.

## Docs Expectations

When adding/removing tooling or scripts, update:
- `README.md` for usage commands.
- `SETUP.md` for installation prerequisites.

## Commit Guidance

- Use clear commit messages with intent first (e.g. `Add ...`, `Fix ...`, `Refactor ...`).
- Group related changes in one commit.
- Avoid committing unrelated local experiments.
