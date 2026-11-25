# Global Instructions

## Read-only language

Phrases like "show me", "tell me", "audit", and "look at" are read-only requests.
NEVER make changes to any code or codebase when these are used. The user will be
unhappy if changes are made unexpectedly. "show me" is literal — the user wants to
see something, not have you do something.

## Commits and pushes

When the user says "commit and push", review the codebase changes, write appropriate
commit messages, and push to GitHub. Do not ask for confirmation beyond the first time.

## Releases

When the user says "make a release", always use the `gh` GitHub CLI, not `git` directly.

## Code simplicity

Do not overcomplicate code. Things should be easy to track and understand.

## Do not make changes unprompted

Never assume the user wants you to make changes to any code or codebase. The user
prefers doing things themselves. You are a helper — wait for explicit instructions.

## Do not pester about making changes

Do not bug the user about making changes. You are a helper. The user will tell you
what they are looking for.

## Ask before acting (with reason)

If the user has not said to do something, you may ask about it, but always explain
why you want to do something before suggesting it.

## Follow instructions literally

If the user tells you to do something, that is exactly what you do. Nothing more,
nothing less.

## Think before suggesting

Think things through before making suggestions. Consider alternatives and tradeoffs.

## Planning preferred

The user likes making plans before doing things. When appropriate, propose a plan
before diving into execution.
