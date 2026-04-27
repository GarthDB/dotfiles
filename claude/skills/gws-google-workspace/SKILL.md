---
name: gws-google-workspace
description: Manage Gmail, Drive, Calendar, Docs, Sheets, Tasks, and other Google Workspace services via the `gws` CLI. Use when the user wants to read, search, organize, clean up, label, archive, draft, reply to, or send email; manage Drive files; check or create calendar events; or otherwise interact with Google Workspace from the terminal. Covers the `+helper` shortcuts (e.g. `gws gmail +triage`, `+send`, `+reply`, `+read`) and raw resource routing (e.g. `gws gmail users messages list`).
---

# Google Workspace CLI (`gws`)

`gws` is a CLI for the Google Workspace APIs (Gmail, Drive, Calendar, Sheets, Docs, Tasks, etc.). It exposes two surfaces:

- **`+helpers`** — opinionated shortcuts (`gws gmail +triage`, `+send`, `+reply`, `+read`). Reach for these first.
- **Raw resource routing** — `gws <service> <resource> [sub] <method>` mirrors the underlying REST API. Use when no helper fits.

Discover any method's parameters with:

```bash
gws schema gmail.users.messages.list
gws schema drive.files.list --resolve-refs
```

## Safety rails — apply every time

- **`--dry-run`** validates the request locally without sending it. Use before any `send`, `delete`, `trash`, `batchModify`, or other state-changing call.
- **Read before write.** List or `+triage` first, confirm the IDs / scope, then modify.
- **Prefer reversible ops.** For Gmail use `messages.trash` (recoverable from Trash for 30 days), not `messages.delete` or `messages.batchDelete` (permanent). For labels, use `messages.modify` to remove labels rather than `labels.delete` (which strips the label from every message).
- **Confirm before destructive batches.** Show the user the `q` query, the count, and a sample before running `batchDelete` or `batchModify` with `removeLabelIds`.

## Output and chaining

- Default output is JSON. Use `--format table` for human-readable, `--format json | jq ...` for piping.
- Auto-paginate large lists with `--page-all` and bound it with `--page-limit N` (default 10) so you don't hammer the API.

```bash
gws gmail users messages list --params '{"userId":"me","q":"is:unread"}' \
  --page-all --page-limit 5 --format json | jq -r '.messages[].id'
```

## Gotchas

- **Keyring preamble on stdout.** Every `gws` call prints `Using keyring backend: keyring` to stdout as its first line before any real output. Parse JSON starting from the first `{` (e.g. `python3 -c 'import sys,json; t=sys.stdin.read(); print(json.dumps(json.loads(t[t.find("{"):])))'` or `jq` on the body). **Do not** pre-filter with `grep -v keyring`.
- **Never chain `| grep` on HTTP-204 methods.** `messages.batchModify`, `messages.trash`, `messages.modify`, and similar state-changing calls return HTTP 204 with an empty body on success. Empty stdout + `exit 0` **is** success. If you pipe empty output through `grep`, grep exits 1 because nothing matched, and the pipeline inherits that — masking a real success as a false failure. Check `gws`'s own exit code directly.
- **`resultSizeEstimate` is capped at 201.** On `messages.list`, `resultSizeEstimate` is *not* a true count — Gmail caps it. For accurate counts, use `users labels get` on a label (it has real `messagesTotal` / `messagesUnread` fields), or page through with `--page-all` and count locally.

# Gmail — primary use case

## Inspect

```bash
gws gmail +triage                                 # 20 most recent unread
gws gmail +triage --max 5 --query 'from:boss'     # filtered
gws gmail +triage --labels                        # include label names
gws gmail +read --id 18f1a2b3c4d --headers        # body + headers
gws gmail +read --id 18f1a2b3c4d --format json | jq '.body'
```

`+triage`'s `--query` accepts the full Gmail search syntax. Useful operators:

- `is:unread`, `is:starred`, `is:important`
- `from:`, `to:`, `subject:`, `list:`
- `older_than:30d`, `newer_than:7d`
- `has:attachment`, `larger:5M`
- `category:promotions`, `category:updates`, `category:social`, `category:forums`
- `label:foo`, `-label:foo` (negate with `-`)

## Search (raw, when you need IDs)

The `q` parameter inside `--params` is the same Gmail search syntax:

```bash
gws gmail users messages list \
  --params '{"userId":"me","q":"category:promotions older_than:30d","maxResults":500}' \
  --format json | jq -r '.messages[].id'
```

## Labels

```bash
# List (note: includes both system labels like INBOX/UNREAD and user labels)
gws gmail users labels list --params '{"userId":"me"}' --format table

# Create
gws gmail users labels create --params '{"userId":"me"}' \
  --json '{"name":"Follow-up","labelListVisibility":"labelShow","messageListVisibility":"show"}'

# Apply / remove in bulk (note: addLabelIds/removeLabelIds use label IDs, not names)
gws gmail users messages batchModify --params '{"userId":"me"}' \
  --json '{"ids":["MSG_ID_1","MSG_ID_2"],"addLabelIds":["Label_42"],"removeLabelIds":["INBOX"]}'
```

**Archive = remove the `INBOX` label.** There is no separate "archive" endpoint:

```bash
gws gmail users messages batchModify --params '{"userId":"me"}' \
  --json '{"ids":[...],"removeLabelIds":["INBOX"]}'
```

## Trash, untrash, delete

```bash
gws gmail users messages trash   --params '{"userId":"me","id":"MSG_ID"}'   # reversible
gws gmail users messages untrash --params '{"userId":"me","id":"MSG_ID"}'
gws gmail users messages batchDelete --params '{"userId":"me"}' \
  --json '{"ids":["MSG_ID_1","MSG_ID_2"]}'   # PERMANENT — confirm first
```

**Default to `trash` over `delete`/`batchDelete`.** Only use the permanent forms when the user explicitly asks.

## Send, draft, reply

```bash
gws gmail +send --to alice@example.com --subject 'Hello' --body 'Hi Alice!'
gws gmail +send --to a@x.com --subject 'Files' --body 'See attached' -a a.pdf -a b.csv
gws gmail +send --to a@x.com --subject 'Hi' --body '<b>Bold</b>' --html
gws gmail +send --to a@x.com --subject 'Hi' --body '...' --draft   # save instead of send

gws gmail +reply --message-id MSG_ID --body 'Thanks, got it!'
gws gmail +reply --message-id MSG_ID --body 'Looping in Carol' --cc carol@example.com
gws gmail +reply --message-id MSG_ID --body 'Draft reply' --draft

gws gmail users drafts list --params '{"userId":"me"}'
gws gmail users drafts send --params '{"userId":"me"}' --json '{"id":"DRAFT_ID"}'
```

For anything non-trivial the user wants to review (long emails, sensitive recipients), use `--draft` and tell the user to open Gmail to review and send.

## Common cleanup recipes

**Archive all promotions older than 30 days:**

```bash
ids=$(gws gmail users messages list --params \
  '{"userId":"me","q":"category:promotions older_than:30d"}' \
  --page-all --format json | jq -r '.messages[].id' | jq -R . | jq -s .)
gws gmail users messages batchModify --params '{"userId":"me"}' \
  --json "{\"ids\":$ids,\"removeLabelIds\":[\"INBOX\"]}" --dry-run
```

**Label every unread from a sender:** find the `Follow-up` label ID first, then:

```bash
ids=$(gws gmail users messages list --params \
  '{"userId":"me","q":"is:unread from:sender@example.com"}' \
  --format json | jq -r '.messages[].id' | jq -R . | jq -s .)
gws gmail users messages batchModify --params '{"userId":"me"}' \
  --json "{\"ids\":$ids,\"addLabelIds\":[\"Label_42\"]}"
```

**Group unread by sender (unsubscribe triage):**

```bash
gws gmail +triage --max 200 --query 'is:unread' --format json \
  | jq -r '.[].from' | sort | uniq -c | sort -rn | head -20
```

# Other services — quick pointers

Reach for `gws <service> --help` to enumerate commands; `+helpers` are listed first.

- **Calendar:** `gws calendar +agenda` (upcoming across calendars), `+insert` (create event), or raw `events list/insert/patch/delete`.
- **Drive:** `gws drive +upload`, `gws drive files list/get/delete`, `gws drive permissions create` for sharing.
- **Tasks:** `gws tasks tasklists list`, `gws tasks tasks list/insert/patch`.
- **Docs / Sheets / Slides:** raw `documents`, `spreadsheets`, `presentations` resources; use `gws schema ...` to find the right method.
- **Cross-service workflows:** `gws workflow +standup-report`, `+meeting-prep`, `+email-to-task`, `+weekly-digest`, `+file-announce`.

# Auth and troubleshooting

- **Exit code 2** = auth error. Token missing, expired, or insufficient scopes.
- Re-auth path depends on how `gws` was set up — check `~/.config/gws/` (override with `GOOGLE_WORKSPACE_CLI_CONFIG_DIR`). Relevant env vars:
  - `GOOGLE_WORKSPACE_CLI_TOKEN` — pre-obtained access token (highest priority).
  - `GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE` — OAuth credentials JSON.
  - `GOOGLE_WORKSPACE_CLI_CLIENT_ID` / `GOOGLE_WORKSPACE_CLI_CLIENT_SECRET` — for `gws auth login`.
- **Exit code 3** = bad arguments / input. Re-check `--params` JSON shape with `gws schema ...`.
- **Exit code 4** = could not fetch API discovery — usually network or auth.
- For verbose logs: `GOOGLE_WORKSPACE_CLI_LOG=gws=debug`.
