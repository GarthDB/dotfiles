---
name: github-issues-projects
description: Manages GitHub Issues, Projects v2, labels, milestones, and native sub-issues via the gh CLI. Use when creating or updating issues, project boards, custom fields, labels, milestones, or sub-issue parent/child links—or when the user tries `gh milestone` or `gh issue subtask` (those subcommands do not exist).
---

# GitHub Issues, Labels, Milestones & Projects v2 (gh CLI)

## Auth requirements

Projects v2 require the **project** scope:

```bash
gh auth refresh -s project
```

Labels, milestones (REST), and issues typically need **repo** scope (often already granted). If project commands return **403** or **404**, refresh with `-s project` first.

```bash
gh auth status
```

---

## Labels (`gh label`)

**Create (idempotent upsert — same name updates in place):**

```bash
gh label create NAME --color FFFFFF --description "Human-readable description" --force
```

Color is **6-character hex without `#`**.

**List:**

```bash
gh label list
```

**Edit:**

```bash
gh label edit NAME --color 0E8A16 --description "Updated description"
```

**Delete:**

```bash
gh label delete NAME --yes
```

---

## Milestones (REST only — no `gh milestone`)

**There is no `gh milestone` subcommand.** Use `gh api` against the REST milestones API only. There is no GraphQL `createMilestone` mutation for this workflow—REST is the path.

**Create:**

```bash
gh api repos/OWNER/REPO/milestones -f title="Release 1.0" -f description="Ship criteria" -f due_on="2026-04-01T00:00:00Z"
```

**List:**

```bash
gh api repos/OWNER/REPO/milestones
```

**Update (example — close milestone):**

```bash
gh api repos/OWNER/REPO/milestones/NUMBER -X PATCH -f state=closed
```

**Delete:**

```bash
gh api repos/OWNER/REPO/milestones/NUMBER -X DELETE
```

Replace `OWNER`, `REPO`, and `NUMBER` (milestone number from the API list response).

---

## Issues (`gh issue`)

**Create:**

```bash
gh issue create --title "Short title" --body "Body text" --label bug --label triage --milestone "Release 1.0" --assignee USER
```

`--milestone` takes the **milestone title** (string), not the milestone number.

**Adding to a project:** Do NOT use `--project` on `gh issue create` for org-level projects — it only resolves repo-scoped project numbers and will fail with `not found` for org projects. Instead, create the issue first, then add it via `gh project item-add` (see Projects v2 section).

**Large body from file:**

```bash
gh issue create --title "RFC: New API" --body "$(cat body.md)"
```

**Edit:**

```bash
gh issue edit NUMBER --add-label priority-high --remove-label triage --milestone "Release 1.0"
```

**Close / reopen:**

```bash
gh issue close NUMBER
gh issue reopen NUMBER
```

**List with filters (JSON):**

```bash
gh issue list --label bug --milestone "Release 1.0" --state open --json number,title,labels
```

**View:**

```bash
gh issue view NUMBER
```

Run `gh issue create --help` for repo default (`-R OWNER/REPO`) and other flags.

---

## Sub-issues (REST only — no `gh issue subtask`)

GitHub's native sub-issues feature (GA 2025) lets you nest issues under a parent. `gh` has no first-class subcommand; use the REST API.

**The API takes a sub-issue's internal database `id`, not its `number`.** Always resolve the number → id first; passing the issue number returns 404.

**Resolve an issue number to its internal id:**

```bash
gh api repos/OWNER/REPO/issues/ISSUE_NUMBER --jq '.id'
```

**List sub-issues of a parent:**

```bash
gh api repos/OWNER/REPO/issues/PARENT_NUMBER/sub_issues
```

Returns `[]` if the feature is enabled and the parent has no children. A 404 means the feature isn't enabled on the repo (rare — it's on by default for new repos).

**Add an existing issue as a sub-issue:**

```bash
gh api -X POST repos/OWNER/REPO/issues/PARENT_NUMBER/sub_issues -F sub_issue_id=INTERNAL_ID
```

**Remove a sub-issue link (note singular `sub_issue`, not `sub_issues`):**

```bash
gh api -X DELETE repos/OWNER/REPO/issues/PARENT_NUMBER/sub_issue -F sub_issue_id=INTERNAL_ID
```

**Bulk pattern — convert checkboxes in a parent issue body into native sub-issues:**

```bash
# 1. Create each sub-issue, capture the printed issue numbers
gh issue create --title "Subtask one" --body "Parent: #PARENT_NUMBER" --label enhancement
gh issue create --title "Subtask two" --body "Parent: #PARENT_NUMBER" --label enhancement
# ...

# 2. For each new issue number, resolve to internal id and link
for n in 80 81 82 83 84 85; do
  id=$(gh api repos/OWNER/REPO/issues/$n --jq '.id')
  gh api -X POST repos/OWNER/REPO/issues/PARENT_NUMBER/sub_issues -F sub_issue_id=$id
done

# 3. Edit the parent body to remove the checklist — GitHub auto-renders the
#    sub-issues panel above the body. Don't retroactively create sub-issues
#    for already-shipped subtasks; note them in the parent body instead.
gh issue edit PARENT_NUMBER --body "Updated overview…"
```

**Auto-close on PR merge:** sub-issues are still regular issues, so a PR body with `Closes #SUBISSUE_NUMBER` closes them on merge as usual. The parent issue does not auto-close when all children close.

---

## Projects v2 (`gh project`)

**Create (returns JSON with `number`, `id`, `url` — capture `number` for later commands):**

```bash
gh project create --owner OWNER --title "Q2 Roadmap" --format json
```

**List:**

```bash
gh project list --owner OWNER
```

**View:**

```bash
gh project view PROJECT_NUMBER --owner OWNER
```

**Add an existing issue to the project (requires full issue URL, not issue number):**

```bash
gh project item-add PROJECT_NUMBER --owner OWNER --url "https://github.com/OWNER/REPO/issues/ISSUE_NUMBER"
```

**Create a draft issue in the project:**

```bash
gh project item-create PROJECT_NUMBER --owner OWNER --title "Draft title" --body "Draft body"
```

**List items:**

```bash
gh project item-list PROJECT_NUMBER --owner OWNER --format json
```

**List fields:**

```bash
gh project field-list PROJECT_NUMBER --owner OWNER --format json
```

**Create a custom field (single select example):**

```bash
gh project field-create PROJECT_NUMBER --owner OWNER --name "Phase" --data-type "SINGLE_SELECT"
```

---

## Setting single-select (and other) field values on project items

Use **option IDs** for single-select — not option display names. **Item ID** is the project-internal ID, not the GitHub issue number.

**Step 1 — Project node ID:**

```bash
gh project list --owner OWNER --format json --jq '.projects[] | select(.number == PROJECT_NUMBER) | .id'
```

**Step 2 — Field ID and option IDs:**

```bash
gh project field-list PROJECT_NUMBER --owner OWNER --format json --jq '.fields[] | select(.name == "Status")'
```

Read `.id` for the field and `.options[]` with `.id` and `.name` for each option.

**Step 3 — Item ID for a linked issue:**

```bash
gh project item-list PROJECT_NUMBER --owner OWNER --format json --jq '.items[] | select(.content.number == ISSUE_NUMBER) | .id'
```

**Step 4 — Set single-select value:**

```bash
gh project item-edit --id ITEM_ID --field-id FIELD_ID --project-id PROJECT_NODE_ID --single-select-option-id OPTION_ID
```

**Other field types on `gh project item-edit`:**

```bash
gh project item-edit --id ITEM_ID --field-id FIELD_ID --project-id PROJECT_NODE_ID --text "value"
gh project item-edit --id ITEM_ID --field-id FIELD_ID --project-id PROJECT_NODE_ID --number 42
gh project item-edit --id ITEM_ID --field-id FIELD_ID --project-id PROJECT_NODE_ID --date "2026-04-01"
gh project item-edit --id ITEM_ID --field-id FIELD_ID --project-id PROJECT_NODE_ID --iteration-id ITERATION_ID
```

---

## Pitfalls

1. **No `gh milestone` subcommand** — Use `gh api repos/OWNER/REPO/milestones`. Do not run `gh milestone`.
2. **`gh project item-add` needs a URL** — Not `ISSUE_NUMBER` alone. Build `https://github.com/OWNER/REPO/issues/NUMBER`.
3. **Single-select fields need option IDs** — `item-edit` does not accept the option name; use `field-list` JSON and map name → `.options[].id`.
4. **`--project` on `gh issue create` only works for repo-scoped projects** — It takes a project number (integer from the URL), but it **cannot find org-level projects** (returns `not found`). For org projects, omit `--project` and use `gh project item-add` after creation instead. This is the recommended pattern for all projects to avoid ambiguity.
5. **`--milestone` on `gh issue create` is the milestone title** — A string name, not the milestone `number` from the REST API.
6. **No batch API** — Loop in shell and call `gh` per item. Example pattern for many issues:

```bash
for title in "One" "Two"; do
  gh issue create --title "$title" --label batch
done
```

7. **Project scope** — Run `gh auth refresh -s project` before `gh project` commands if you see 403/404 on projects.
8. **Sub-issue API takes internal `id`, not `number`** — `POST /issues/PARENT/sub_issues` 404s if you pass the issue number. Resolve via `gh api repos/OWNER/REPO/issues/N --jq .id` first. The DELETE endpoint is singular `/sub_issue` (not `sub_issues`).
9. **No `gh issue subtask`** — Sub-issues are REST-only (see Sub-issues section). Don't attempt `gh issue subtask`.

---

## Putting it all together

**1. Labels (idempotent):**

```bash
gh label create type-bug --color d73a4a --description "Bug" --force
gh label create type-feature --color a2eeef --description "Feature" --force
```

**2. Milestones (REST):**

```bash
gh api repos/OWNER/REPO/milestones -f title="v1.0" -f description="First GA" -f due_on="2026-06-01T00:00:00Z"
```

**3. Issues with labels and milestones (no `--project` — add to project separately):**

```bash
gh issue create --title "Ship widget" --body "Details…" --label type-feature --milestone "v1.0" -R OWNER/REPO
```

**4. Project board (capture number from JSON output):**

```bash
gh project create --owner OWNER --title "v1.0 Board" --format json
```

**5. Add issues to the project (required for org-level projects):**

```bash
gh project item-add PROJECT_NUMBER --owner OWNER --url "https://github.com/OWNER/REPO/issues/ISSUE_NUMBER"
```

**Bulk-add multiple issues:**

```bash
for i in 100 101 102 103; do
  gh project item-add PROJECT_NUMBER --owner OWNER --url "https://github.com/OWNER/REPO/issues/$i"
done
```

**6. Set Status (single-select) on items:**

```bash
PROJECT_NODE_ID="$(gh project list --owner OWNER --format json --jq '.projects[] | select(.number == PROJECT_NUMBER) | .id')"
FIELD_ID="$(gh project field-list PROJECT_NUMBER --owner OWNER --format json --jq -r '.fields[] | select(.name == "Status") | .id')"
OPTION_ID="$(gh project field-list PROJECT_NUMBER --owner OWNER --format json --jq -r '.fields[] | select(.name == "Status") | .options[] | select(.name == "In Progress") | .id')"
ITEM_ID="$(gh project item-list PROJECT_NUMBER --owner OWNER --format json --jq -r '.items[] | select(.content.number == ISSUE_NUMBER) | .id')"
gh project item-edit --id "$ITEM_ID" --field-id "$FIELD_ID" --project-id "$PROJECT_NODE_ID" --single-select-option-id "$OPTION_ID"
```

---

## What this skill does not cover

- **Discussions** — Use the `github-discussions` skill (`gh api graphql`).
- **Pull requests** — Use `gh pr` (separate from this skill).
- **GitHub Actions / workflows** — Out of scope.
- **Project templates, views, or charts** — Out of scope.
