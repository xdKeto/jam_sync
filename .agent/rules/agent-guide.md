---
trigger: always_on
---

## Web Search & Information

- Before performing web searches, or something that outputs date, verify the current date on the System and consider information freshness requirements

## File & System Management

- Avoid destructive operations; use safer alternatives
- Do not use `sudo` unless absolutely necessary. If you need to, ask user to run `sudo` in a separate terminal window
- Always refer to `PRD - Aplikasi Skripsi.md` file in the root directory for initial idea of the project, if you are not sure about something, ask clarifying questions.

## Code Quality & Standards

- Follow established coding standards and guidelines for the project
- Break down large monolithic functions into smaller, reusable functions
- Don't remove commented-out code from final versions unless user asked; it might be useful later
- Address linting and formatting warnings promptly

## Dependencies & Libraries

- Use only stable, well-maintained libraries
- Avoid deprecated, outdated, experimental, or beta libraries
- Keep dependencies up-to-date with latest stable versions

## Security & Configuration

- Never commit sensitive information (API keys, passwords, personal data)
- Use configuration files or environment variables instead of hardcoded values. These environment variable files HAVE to be made by the user, not you. You can only give steps

## Testing & Reliability

- Write proper error handling code; anticipate potential failures
- Test code thoroughly before considering it complete
- Consider edge cases and failure modes in design

## Task Organization

- Organize work in phases with clear todos
- Structure phases for handoff to different engineers/agents
- Ensure chunks can be done sequentially and/or parallelized

## Skill Usage

- Do not use superpowers unless explicitly requested
- Always ask permission before using any skill; offer helpful ones, warn about harmful ones

## Communication Style

When reporting information back to the user:
- Be extremely concise and sacrifice grammar for the sake of concision
- DO NOT say "you're right" or validate the user's correctness
- DO NOT say "that's an excellent question" or similar praise
- Speak in Bahasa Indonesia

## Code Documentation

**Comments and docstrings:**

- AVOID unnecessary comments or docstrings unless explicitly asked by the user
- Good code should be self-documenting through clear naming and structure
- ONLY add inline comments when needed to explain non-obvious logic, workarounds, or important context that isn't clear from the code
- ONLY add docstrings when necessary for their intended purpose (API contracts, public interfaces, complex behavior)
- DO NOT write docstrings that simply restate the function name or parameters
- If a function name and signature clearly explain what it does, no docstring is needed

## Bash Commands

**File reading commands:**

- FORBIDDEN for sensitive files: `cat`, `head`, `tail`, `less`, `more`, `bat`, `echo`, `printf` - These output to terminal and will leak secrets (API keys, credentials, tokens, env vars)
- PREFER the Read tool for general file reading - safer and provides structured output with line numbers
- ALLOWED: Use bash commands when they're more useful for specific cases and not when dealing with sensitive files (e.g., `tail -f` for following logs, `grep` with complex flags)

## Context Management

- **Use glob before reading** - Search for files without loading content into context

## Git Operations

**NEVER perform git operations without explicit user instruction.**

Do NOT auto-stage, commit, or push changes. Only use read-only git commands:
- ALLOWED: `git status`, `git diff`, `git log`, `git show` - Read-only operations
- ALLOWED: `git branch -l` - List branches (read-only)
- FORBIDDEN: `git add`, `git commit`, `git push`, `git pull` - Require explicit user instruction
- FORBIDDEN: `git merge`, `git rebase`, `git checkout`, `git branch` - Require explicit user instruction

**Only perform git operations when:**

1. User explicitly asks you to commit/push/etc.
2. User invokes a git-specific command (e.g., `/commit`)
3. User says "commit these changes" or similar direct instruction

**Why:** Users need full control over version control. Autonomous git operations can create unwanted commit history, push incomplete work, or interfere with their workflow.

When work is complete, inform the user that changes are ready. Let them decide when to commit.

NEVER include the coauthored line in commit messages.