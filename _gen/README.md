# Retired historical generators

These 22 scripts are preserved as `.py.retired` files for historical reference. Their old `.py` entrypoints were retired after the 5 September 2026 audit. None is used by the current project, CI, or validation workflow.

Do not execute them against this checkout. They overwrite current source or reports, can restore removed audio and obsolete movement/authority behavior, and can recreate fixed success counts without current engine evidence. A filename such as `counts.py` did not mean the script was read-only.

Edit the authoritative `src/` files and use `python scripts/validate.py` from the repository root. For guarded Studio tests, follow `qa/README.md` and `scripts/build_studio_audit.py`.

The original filenames, exact hashes, reviewed behavior and retirement mapping are recorded in `docs/REAUDIT_LEGACY_GENERATORS_2026_09_05.json`. No script content was deleted or altered. Restoration is possible by removing the `.retired` suffix, but any revival needs a fresh review and isolated destination before execution.
