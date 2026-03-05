# Roadmap

Our goal is not to be the biggest App Store Connect MCP (208 atomic tools), but the **smartest** — fewer tools that do more per call, with built-in intelligence and safety.

## 1. Composite Workflow Tools

Instead of forcing agents to chain 6+ tool calls for a release, provide high-level workflows:

- **`prepare_release`** — One call: checks build readiness → creates version → attaches latest valid build → copies metadata from previous version → returns what's ready and what's missing
- **`release_status`** — One call: shows version state, build status, missing metadata per locale, review status, phased release progress — the full picture
- **`clone_version_metadata`** — Copy all localizations from one version to another (common when creating a new release)

## 2. Validation & Intelligence

Not just CRUD — tools that think:

- **`validate_for_submission`** — Checks everything Apple requires before submit: build attached? All required locales have descriptions? Age rating set? Screenshots present? Returns a checklist with pass/fail
- **`suggest_keywords`** — Analyze existing metadata and suggest missing keywords per locale
- **`review_risk_check`** — Flag common rejection reasons (missing privacy URL, demo account needed, etc.)

## 3. MCP Resources & Prompts

Go beyond tools — use the full MCP spec:

- **Resources**: Expose app metadata as readable resources (`appstoreconnect://apps/{id}/metadata`) — agents can read without tool calls
- **Prompts**: Pre-built prompt templates like "Release Checklist for {app}" or "Write Release Notes for {version}" that guide the AI

## 4. Diff & Comparison

- **`compare_versions`** — Show what changed between two versions (metadata diff, different build, changed locales)
- **`compare_locales`** — Show which locales are missing fields vs a reference locale
- **`changelog_from_commits`** — If git info is available, auto-generate release notes from commits

## 5. Safety & DX

- **Dry-run mode** — `"dry_run": true` on any mutating tool shows what would happen without doing it
- **Undo support** — Track recent actions, offer rollback (e.g., detach build, delete version just created)
- **Rate limit awareness** — Surface remaining API quota in tool responses

## 6. Multi-App Batch Operations

- **`bulk_update_metadata`** — Update promotional text across all apps at once
- **`release_all_approved`** — Release all versions in "Pending Developer Release" state
- **`audit_all_apps`** — Check all apps for common issues (expired builds, stale versions, missing metadata)

## Priority

| Phase | Focus | Why |
|-------|-------|-----|
| **Phase 1** | Composite workflows (#1) + Validation (#2) | Biggest differentiation — turns an API wrapper into a release assistant |
| **Phase 2** | Safety (#5) + Diff tools (#4) | Prevents mistakes, helps teams review changes |
| **Phase 3** | MCP Resources & Prompts (#3) | Leverages the full MCP spec, unique in the ecosystem |
| **Phase 4** | Batch operations (#6) | Power-user features for multi-app accounts |
