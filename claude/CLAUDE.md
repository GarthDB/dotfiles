# Global Claude Code Rules

## Beads Task Tracking

When working in a project with beads initialized (`bd status` succeeds):
- Run `bd ready` at session start to see available tasks
- Claim a task before starting: `bd update <id> --claim`
- Create subtasks for complex work: `bd create --parent <id> --title "..."`
- Mark done when finished: `bd close <id>`
- Use `bd dep add <child> <parent>` to establish dependencies
- Use `bd show <id>` to understand task context and dependencies
- Reference GitHub Issues in task descriptions when applicable
- Do NOT use `bd edit` (requires interactive editor — use `bd update` with flags instead)
- Run `bd prime` for full workflow context and command reference

## Skills

### graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.
