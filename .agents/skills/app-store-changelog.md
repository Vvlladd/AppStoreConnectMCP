---
name: app-store-changelog
description: Create user-facing App Store release notes by collecting and summarizing all user-impacting changes since the last git tag (or a specified ref). Use when asked to generate a comprehensive release changelog, App Store "What's New" text, or release notes based on git history or tags.
---

# App Store Changelog

## Overview
Generate a comprehensive, user-facing changelog from git history since the last tag, then translate commits into clear App Store release notes.

## Workflow

### 1) Collect changes
- Find the last release tag: `git describe --tags --abbrev=0`
- List commits since last tag: `git log $(git describe --tags --abbrev=0)..HEAD --reverse --date=short --pretty=format:'%h|%ad|%s'`
- List files changed: `git log $(git describe --tags --abbrev=0)..HEAD --name-only --pretty=format:'--- %h %s'`
- Or specify a range manually: `git log v1.2.3..HEAD --reverse --date=short --pretty=format:'%h|%ad|%s'`
- If no tags exist, use: `git log --reverse --date=short --pretty=format:'%h|%ad|%s'`

### 2) Triage for user impact
- Scan commits and files to identify user-visible changes.
- Group changes by theme (New, Improved, Fixed) and deduplicate overlaps.
- Drop internal-only work (build scripts, refactors, dependency bumps, CI).

### 3) Draft App Store notes
- Write short, benefit-focused bullets for each user-facing change.
- Use clear verbs and plain language; avoid internal jargon.
- Prefer 5 to 10 bullets unless the user requests a different length.

### 4) Validate
- Ensure every bullet maps back to a real change in the range.
- Check for duplicates and overly technical wording.
- Ask for clarification if any change is ambiguous or possibly internal-only.

## Output Format
- Title (optional): "What's New" or product name + version.
- Bullet list only; one sentence per bullet.
- Stick to storefront limits if the user provides one.

## Resources
- Git documentation: [git-log](https://git-scm.com/docs/git-log) for commit history
- App Store Connect Help: [Writing effective release notes](https://developer.apple.com/app-store/product-page/)
