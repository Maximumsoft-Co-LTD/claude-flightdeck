# Design: D009 — Typo fix — admin page title

> **Sprint:** S03 — Analytics
> **Task:** URLSH-S03.05
> **Repo:** backend (server-rendered admin page, single template)
> **Status:** Scheduled
> **Type:** docs
> **Size:** XS  (per [`SIZE_TIERS.md`](../../_templates/SIZE_TIERS.md) — single file, no logic, no behaviour change)
> **Author:** @bob
> **Date:** 2026-05-14

## Overview

The admin landing page reads "Url Shortner" — should be "URL Shortener".

## Approach

Single template change: `internal/adapters/http/admin/templates/index.html`, line 7, the `<title>` tag.

## Steps

1. Edit `internal/adapters/http/admin/templates/index.html` line 7: `<title>Url Shortner</title>` → `<title>URL Shortener</title>` — verify: open `http://localhost:8080/admin/` in browser, browser tab now reads "URL Shortener"

## Rollback

Revert the commit.

## Why XS (not S)

- Single file
- No logic
- No behaviour change visible to API callers (the redirect / shorten paths are untouched)
- Sentence-test passes: "fix typo in admin page title"

This is the canonical XS example for the AI-Workflows template — the
sections from the full DESIGN_TEMPLATE that don't apply at XS
(architecture, key decisions, data flow, test plan, acceptance
criteria with multiple rows, observability) have all been **deleted**,
not left empty with placeholder text. Empty sections erode the gating
discipline (per `SIZE_TIERS.md`).
