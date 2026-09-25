# Taste

- Communicates in Chinese and expects replies in Chinese. Confidence: 0.7
- Prefers using the `gh` CLI for GitHub operations (inspecting Actions runs, logs, API). Confidence: 0.5
- Expects dependency/tool versions (e.g. GitHub Actions in CI workflows) to be current: verify the actual latest release via upstream lookups instead of relying on memorized/training-data versions, and don't leave known-deprecated pins in place. Confidence: 0.85
- When committing, include the auto-generated `.commandcode/` files (settings.json, taste, etc.) in the commit rather than leaving them out. Confidence: 0.8
