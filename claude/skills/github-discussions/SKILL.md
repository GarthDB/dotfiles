---
name: github-discussions
description: Manages GitHub Discussions via the gh CLI GraphQL API. Use when creating, reading, updating, or commenting on GitHub Discussions, or when the user or agent attempts `gh discussion` (that subcommand does not exist).
---

# GitHub Discussions (gh + GraphQL)

## Key fact

**`gh` has no `discussion` subcommand.** All discussion operations use the GraphQL API:

```bash
gh api graphql -f query='...' ...
```

Do not try `gh discussion` — it will fail.

---

## Reading a discussion

Get a discussion by repo owner, repo name, and discussion number. Use the query to obtain `id` (node ID), `title`, and `body`.

**Query:**

```graphql
query GetDiscussion($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    discussion(number: $number) {
      id
      title
      body
    }
  }
}
```

**Example (inline variables):**

```bash
gh api graphql -f query='
  query {
    repository(owner: "adobe", name: "spectrum-design-data") {
      discussion(number: 661) { id title body }
    }
  }
'
```

Parse the JSON response to get `data.repository.discussion.id` (e.g. `D_kwDOG9zSJs4AjnYr`) for use in update/comment mutations.

---

## Looking up IDs

**Repository ID and discussion categories** (required for creating a discussion):

```graphql
query {
  repository(owner: "OWNER", name: "REPO") {
    id
    discussionCategories(first: 20) {
      nodes { id name }
    }
  }
}
```

Use `repository.id` as `repositoryId` and one of `discussionCategories.nodes[].id` as `categoryId` when creating a discussion.

---

## Creating a discussion

**Mutation:** `createDiscussion`

**Input:** `CreateDiscussionInput` — `repositoryId` (ID!), `categoryId` (ID!), `title` (String!), `body` (String!).

**Example:**

```graphql
mutation CreateDiscussion($input: CreateDiscussionInput!) {
  createDiscussion(input: $input) {
    discussion { id title url }
  }
}
```

Variables:

```json
{
  "input": {
    "repositoryId": "R_kgDOG9zSJg",
    "categoryId": "DIC_kwDOG9zSJs4CeHMZ",
    "title": "My new discussion",
    "body": "## Summary\n\nContent here."
  }
}
```

Build the payload (e.g. with Python or jq) and send:

```bash
gh api graphql --input request.json
```

---

## Updating a discussion body

**Mutation:** `updateDiscussion`

**Input:** `UpdateDiscussionInput` — `discussionId` (ID!), `body` (String), `title` (String), `categoryId` (ID) — all optional except `discussionId`.

**Query document:**

```graphql
mutation UpdateDiscussion($discussionId: ID!, $body: String!) {
  updateDiscussion(input: { discussionId: $discussionId, body: $body }) {
    discussion { id title }
  }
}
```

**Reliable pattern for large bodies (GFM, mermaid, tables):**

1. Write the new body to a file (e.g. `body.md`).
2. Build a single JSON payload that includes both the query and variables, with the body read from the file. Use a script so the body is correctly escaped as a JSON string.

   **Python example:**

   ```python
   import json
   with open("body.md") as f:
       body = f.read()
   payload = {
       "query": "mutation UpdateDiscussion($discussionId: ID!, $body: String!) { updateDiscussion(input: { discussionId: $discussionId, body: $body }) { discussion { id title } } }",
       "variables": {
           "discussionId": "D_kwDOG9zSJs4AjnYr",
           "body": body
       }
   }
   with open("payload.json", "w") as f:
       json.dump(payload, f, ensure_ascii=False)
   ```

3. Send the payload:

   ```bash
   gh api graphql --input payload.json
   ```

4. Remove temporary files when done.

**Do not** rely on `-f query=@file` or `-F variables=@file` for large bodies: the way `gh` merges form fields often does not produce a valid GraphQL request with a multi-line variable. Using a single `--input` JSON file is reliable.

---

## Adding a comment

**Mutation:** `addDiscussionComment`

**Input:** `AddDiscussionCommentInput` — `discussionId` (ID!), `body` (String!), `replyToId` (ID, optional).

**Query document:**

```graphql
mutation AddComment($input: AddDiscussionCommentInput!) {
  addDiscussionComment(input: $input) {
    comment { id }
  }
}
```

**Variables example:**

```json
{
  "input": {
    "discussionId": "D_kwDOG9zSJs4AjnYr",
    "body": "**Update:** This is a follow-up comment."
  }
}
```

For long comments, use the same pattern as for updating the body: build a full JSON payload (e.g. with Python) and send with `gh api graphql --input payload.json`.

---

## Other mutations (reference)

- **closeDiscussion** — `CloseDiscussionInput`: `discussionId` (ID!)
- **reopenDiscussion** — `ReopenDiscussionInput`: `discussionId` (ID!)
- **deleteDiscussion** — `DeleteDiscussionInput`: `id` (ID!)
- **updateDiscussionComment** — `UpdateDiscussionCommentInput`: `commentId` (ID!), `body` (String!)
- **deleteDiscussionComment** — `DeleteDiscussionCommentInput`: `id` (ID!)

Use the same pattern: define the mutation, build a JSON payload with `query` and `variables`, then `gh api graphql --input payload.json`.

---

## Pitfalls

1. **No `gh discussion`** — Use `gh api graphql` only.
2. **`-f query=@file`** — With `gh`, the `@file` syntax may not read the file content as the query string; the request can end up malformed. Prefer embedding the query in a JSON payload and using `--input`.
3. **Large or multi-line variables** — Passing variables via `-f`/`-F` can fail for large strings (e.g. markdown bodies). Build a full JSON payload (e.g. with Python) and use `--input payload.json`.
4. **GFM in body** — GitHub Flavored Markdown (tables, mermaid, etc.) is fine; no extra escaping beyond valid JSON (e.g. backslashes and quotes escaped in the JSON string).

---

## What this skill does not cover

- **Issues and pull requests** — Use `gh issue` and `gh pr`; they have dedicated subcommands.
- **Discussion categories/labels** — Only lookup is described; creating or changing categories is out of scope.
- **Polls** — `addDiscussionPollVote` and poll creation are not covered.
