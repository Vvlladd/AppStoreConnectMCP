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

## 7. API Coverage Expansion

### Tier A — Release Operations & App Info
- **`get_app_info`** — Read app-level metadata (subtitle, categories, content rating)
- **`update_app_info`** — Change categories, subtitle, privacy URL without Xcode
- **`get_version_phased_release`** — Check phased release status (% rollout)
- **`manage_phased_release`** — Pause/resume/complete phased rollouts
- **`get_review_submission_status`** — Check if submission is waiting, in review, approved, rejected
- **`list_in_app_purchases`** — See all IAPs and subscriptions for an app

### Tier B — TestFlight
- **`list_beta_groups`** — See TestFlight groups
- **`add_beta_tester`** — Invite testers by email
- **`list_beta_testers`** — List current testers
- **`submit_for_beta_review`** — Submit build for TestFlight review
- **`set_beta_build_details`** — Set "what to test" notes

### Tier C — App Store Metadata Deep Dive
- **`manage_screenshots`** — Upload/list/delete screenshots per locale
- **`manage_preview_videos`** — Upload app previews
- **`manage_app_pricing`** — Set pricing tier, schedule price changes
- **`list_territories`** — See available territories/pricing

### Tier D — Analytics, Sales & Reviews
- **`get_sales_reports`** — Download financial/sales reports
- **`get_app_analytics`** — Downloads, impressions, conversion rates
- **`list_customer_reviews`** — Read App Store reviews
- **`respond_to_review`** — Reply to customer reviews from Claude

### Tier E — Provisioning & Signing
- **`manage_certificates`** — List/create signing certificates
- **`manage_profiles`** — Provisioning profiles
- **`manage_devices`** — Register test devices
- **`manage_bundle_ids`** — Register new bundle IDs
- **`manage_capabilities`** — Enable push notifications, HealthKit, etc.

## Priority

| Phase | Focus | Why |
|-------|-------|-----|
| **Phase 1** | Composite workflows (#1) + Validation (#2) | Biggest differentiation — turns an API wrapper into a release assistant |
| **Phase 2** | Release ops & TestFlight (#7 Tier A+B) | Most-used daily workflows after what's already built |
| **Phase 3** | Safety (#5) + Diff tools (#4) | Prevents mistakes, helps teams review changes |
| **Phase 4** | MCP Resources & Prompts (#3) | Leverages the full MCP spec, unique in the ecosystem |
| **Phase 5** | Reviews & Analytics (#7 Tier D) | Close the feedback loop — read reviews, track metrics from Claude |
| **Phase 6** | Metadata deep dive (#7 Tier C) + Batch ops (#6) | Screenshots, pricing, multi-app power features |
| **Phase 7** | Provisioning & Signing (#7 Tier E) | Advanced ops for teams managing certs/profiles |
