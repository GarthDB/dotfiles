---
name: gtd-email-zero
description: Process Gmail using David Allen's GTD methodology — daily triage to inbox zero with batched dispositions for delete / file / do-now / defer / delegate. Use when the user wants to "process email", "do email triage", "get to inbox zero", "do my GTD inbox", "clear unread", or similar. Pushes deferred actions to Things 3 via the `things:///add` URL scheme. Pairs with the `gws-google-workspace` skill for the actual Gmail operations.
---

# GTD Email Zero

Apply David Allen's *Getting Things Done* email workflow to Gmail. **Every unread message gets exactly one of five dispositions, then leaves the inbox.** Inbox zero is a state, not a goal.

This skill assumes the lower-level `gws-google-workspace` skill is loaded — it covers the Gmail command shapes (`gws gmail +triage`, `users messages batchModify`, etc.). Load both for any email-processing task.

## The decision tree

For each unread message, ask in order:

1. **Is it actionable?**
   - **No** → does it have reference value?
     - No → **Delete** (`messages.trash` — reversible for 30 days).
     - Yes → **File** (`@Reference` + remove `INBOX`).
   - **Yes** → continue.
2. **Will it take less than 2 minutes?**
   - Yes → **Do** now (reply via `+reply`, then archive).
3. **Am I the right person?**
   - No → **Delegate** (forward via `+send`, apply `@Waiting`, archive — the wait is on someone else).
4. **Otherwise** → **Defer**: capture as a Things 3 task, archive the email.

The deferred task becomes the "next action." The email is no longer the to-do list — Things is.

## Label scheme (already created)

| Label | ID | Purpose |
|---|---|---|
| `@Action` | `Label_58` | Staging area for actionable items not yet captured in Things. Aim to keep empty. |
| `@Waiting` | `Label_59` | Delegated; waiting on someone else's response. Reviewed weekly. |
| `@Someday` | `Label_60` | Maybe later. Not on the active list. |
| `@Reference` | `Label_61` | Filed for lookup. Single bucket; subdivide only when a real pattern emerges. |
| `@Backlog/Amnesty-YYYY-MM-DD` | varies | Bulk-archive bucket created during inbox amnesty. |

Look up current IDs (in case they've changed) with:

```bash
gws gmail users labels list --params '{"userId":"me"}' --format json | jq '.labels[] | select(.name | startswith("@"))'
```

## Daily triage workflow

Run this once a day, time-box to ~10 minutes.

### 1. Pull the batch

```bash
gws gmail +triage --max 50 --query 'is:unread in:inbox' --format json
```

This returns `{id, date, from, subject}` for each message — sufficient input for proposing dispositions in one round-trip. Only reach for `users messages get $ID` when a disposition decision genuinely needs the body or snippet (rare — most unread mail can be dispositioned from sender + subject alone).

### 2. Propose dispositions

For each message, propose **one** of: `Delete | File | Do | Delegate | Defer` with a one-line reason. Format as a table the user can scan in 30 seconds:

```
#  | From            | Subject                       | Disp.    | Reason
1  | newsletter@... | Daily digest                  | Delete   | low-value newsletter, no reply needed
2  | bank@...        | Statement available          | File     | reference; no action
3  | colleague@...   | Quick question about X       | Do       | <2 min reply
4  | client@...      | RFP attached                 | Defer    | needs ~30 min review → Things
...
```

### 3. Get user approval

Ask: "Apply these dispositions? Reply with row numbers to override (e.g. `4 Delegate to alice`), or `go` to execute as-is."

### 4. Execute as a single pass

Group by disposition and execute in batches. After a `batchModify` call, empty stdout + exit 0 = success (HTTP 204). **Do not pipe `batchModify` through `grep`** — grep's exit-1 on no-match will mask a real success as a false failure; check `gws`'s exit code directly.

```bash
# Delete (trash via batched TRASH label — same semantics as messages.trash, batched for speed)
gws gmail users messages batchModify --params '{"userId":"me"}' \
  --json '{"ids":[...trash_ids...],"addLabelIds":["TRASH"],"removeLabelIds":["INBOX","UNREAD"]}'

# File to Reference
gws gmail users messages batchModify --params '{"userId":"me"}' \
  --json '{"ids":[...file_ids...],"addLabelIds":["Label_61"],"removeLabelIds":["INBOX","UNREAD"]}'

# Defer: archive (next step pushes to Things)
gws gmail users messages batchModify --params '{"userId":"me"}' \
  --json '{"ids":[...defer_ids...],"removeLabelIds":["INBOX","UNREAD"]}'

# Delegate: forward each (per message — `+send` only takes one), then label
for id in DELEGATE_IDS; do
  gws gmail +reply --message-id "$id" --to recipient@example.com --body "..." --draft  # or actual forward
done
gws gmail users messages batchModify --params '{"userId":"me"}' \
  --json '{"ids":[...delegate_ids...],"addLabelIds":["Label_59"],"removeLabelIds":["INBOX","UNREAD"]}'

# Do (replies happen first, per message via +reply, then archive)
gws gmail users messages batchModify --params '{"userId":"me"}' \
  --json '{"ids":[...done_ids...],"removeLabelIds":["INBOX","UNREAD"]}'
```

For each **Defer**, push to Things 3:

```bash
title="One-line action verb-phrase"  # e.g. "Reply to client RFP with timeline"
notes="From: $sender
Subject: $subject
Gmail ID: $msg_id
Gmail link: https://mail.google.com/mail/u/0/#inbox/$msg_id"

open "things:///add?title=$(jq -rn --arg s "$title" '$s|@uri')&notes=$(jq -rn --arg n "$notes" '$n|@uri')&list-id=inbox"
```

Tasks land in Things' Inbox; you move them to the right Project/Area in Things itself — that part is human judgment.

### 5. Stop

Stopping rule: **50 messages or 10 minutes, whichever comes first.** Tomorrow is another day. If unread is dropping over time, the system is working.

## Weekly review

Run this once a week, ~20 minutes:

1. **`@Waiting`** — `gws gmail users messages list --params '{"userId":"me","q":"label:@Waiting"}'`. Anything older than ~5 days without a reply? Nudge the recipient or move to `@Someday` / drop.
2. **`@Someday`** — anything ready to promote to a Things task? Anything safely droppable?
3. **`@Action`** — should be empty. If not, those are stragglers that need to become Things tasks.
4. **Things `today` / `inbox`** — open the Things 3 app and review Inbox + Today. (The `things3` CLI reads may fail due to schema drift; use the app UI for review.)

## The amnesty rule

If `gws gmail users labels get --params '{"userId":"me","id":"INBOX"}'` ever shows `messagesUnread > 500`, **do another amnesty**. Do not try to climb out item-by-item — that's the failure mode.

To run another amnesty: create `@Backlog/Amnesty-YYYY-MM-DD` for today's date, then bulk `batchModify` everything `older_than:7d` → add the new amnesty label, remove `INBOX` and `UNREAD`. Same shape as the original amnesty in `Phase 2` of the original plan.

## Approval discipline (NON-NEGOTIABLE)

- **Always propose, then execute.** No autonomous deletes, forwards, sends, or archives.
- **Show counts and samples** before any `batchModify` with more than 10 IDs.
- **Use `--dry-run`** on the first batch of any new operation type.
- **Override is one-row-at-a-time** during approval — the user types row numbers with overrides; everything else proceeds as proposed.
- **No `messages.delete` or `messages.batchDelete` ever** unless the user types those exact words. `trash` is the disposition for "delete."

## Things 3 quick reference

- **Write (canonical, dependency-free):** `open "things:///add?title=...&notes=...&list-id=inbox"` (URL-encode args via `jq -rn --arg x "..." '$x|@uri'`). This goes straight to the Things 3 app's URL handler and has no dependency on any CLI — tasks always land.
- **Read — use the Things 3 app UI.** The `things3 <subcommand>` CLI (rust-things3) reads directly from the Things SQLite database and is prone to schema-drift errors like `no such column: parent` whenever Things 3 updates its schema. Do **not** use `things3 inbox` / `today` / etc. for user-facing verification — open the app instead.
- Things URL scheme docs: https://culturedcode.com/things/support/articles/2803573/
- Future upgrade: the `things3 mcp` server can be wired into `~/.claude/settings.json` so Claude calls native MCP tools instead of shelling to `open`. Skip until the URL scheme proves clunky (and only after the CLI's schema drift is fixed, since the MCP server reads the same database).

## Why this works

GTD's central insight: **the inbox is not a to-do list.** It's a queue of decisions. Email zero comes from making each decision once and letting the trusted system (Things) hold the resulting commitments. The skill enforces this by making "leave it in the inbox" not an option — every message gets a disposition, every disposition leaves the inbox.
