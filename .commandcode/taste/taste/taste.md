# Taste
- Communicates in Chinese and expects replies in Chinese. Confidence: 0.7
- Prefers using the `gh` CLI for GitHub operations (inspecting Actions runs, logs, API). Confidence: 0.5
- Expects dependency/tool versions (e.g. GitHub Actions in CI workflows) to be current: verify the actual latest release via upstream lookups instead of relying on memorized/training-data versions, and don't leave known-deprecated pins in place. Confidence: 0.85
- When committing, include the auto-generated `.commandcode/` files (settings.json, taste, etc.) in the commit rather than leaving them out. Confidence: 0.8
- Expects changes carried all the way through: after editing, commit and push, then actively verify the deployment/CI run actually succeeded (watch the workflow, check the live result) instead of just reporting the edit. Confidence: 0.7
- Holds a high bar for generated documentation of config/module options: every option must have a concrete, meaningful `description` plus an `example` — no empty descriptions and no auto-generated placeholder text. Confidence: 0.55
- Dislikes gratuitous/unnecessary edits to idiomatic code: keep changes scoped to the requested task and preserve established conventions (e.g. keep `lib.mkEnableOption` for `enable` options instead of rewriting it by hand as `mkOption`). Confidence: 0.65
