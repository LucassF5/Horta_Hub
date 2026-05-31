---
description: "Generates a Pull Request description for GitHub. Use to create standardized PR descriptions with context from commits and changes on the current branch."
agent: "agent"
tools: []
---

# Generate Pull Request Description

Analyze the current branch and generate a standardized PR description for Horta Hub.

## Steps

1. Run `git log main..HEAD --oneline` to list the branch commits
2. Run `git diff main..HEAD --stat` to see changed files
3. If needed, read the changed files to understand context

## PR Format

Generate the title and description in **English** following this template:

```markdown
## What was done

Clear and objective summary of the changes (2-3 sentences).

## Changes

- Bullet points with each significant change
- Group by area when there are many changes (model, controller, views, specs)

## How to test

1. Steps for manual testing (if applicable)
2. Test command: `bundle exec rspec spec/path/to/relevant_spec.rb`

## Checklist

- [ ] Tests passing (`bundle exec rspec`)
- [ ] RuboCop clean (`rubocop`)
- [ ] Brakeman clean (`brakeman -q`)
```

## Rules

- PR title: use the same pattern as commits (`type: description`)
- Valid types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
- Be concise but informative
- Mention impact on other areas if applicable
- If there are migrations, mention in the "How to test" section that `rails db:migrate` is required
