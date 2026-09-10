# Working this repo set from more than one session at once

Sylvia runs one Claude session per repo and connects them by message. That is the intended shape:
`tfw-update-ops` is a command post holding no mod code, fixes land in each mod's own repo, and each
session keeps its context on one codebase.

**"One repo, one owner-session" is the rule for *authorship*. It does not protect the
*filesystem*.** Every session on the machine shares one working tree per repo. That gap caused a
real incident on 2026-09-10 and this document exists so the next pair of sessions does not
rediscover it.

## The incident

The ops session ran `git add -A` in `tfw-update-ops` and committed. The commit picked up a
59-line edit to `tools/capture_baseline.ps1` that **the CMSF session had written and left
uncommitted**. Nothing was lost and the code was what its author would have shipped, but it went in
under the wrong session's commit message and the author's own next commit showed no change for that
file.

The near-miss was worse than the miss. The other session had, independently, read
`capture_baseline.ps1`, patched it in memory, and written it back. **Had the two writes interleaved
the other way, one session's edits would have vanished silently** — no conflict, no warning, and
`git` cannot help because the loss happens before the file is ever staged.

## The rules

**1. Never `git add -A` (or `git add .`, or `git commit -a`) in a repo another session may be
working in.** Stage the explicit paths you personally wrote this turn. This is the rule that would
have prevented the incident outright, and it costs nothing.

**2. Check `git status` before you commit, and account for every path you are about to stage.** A
file you did not touch appearing in the list is the signal. Do not assume it is stale local noise.

**3. Claim a shared file before editing it.** Say which file, in a message, before the first edit —
not after. `state/status.md` was claimed this way and the protocol worked perfectly; the two files
that collided were the ones neither session had claimed.

**4. Re-read immediately before writing a file another session might hold.** An in-memory copy
minutes old is a stale copy. Patch-and-write-back on a shared file is the specific pattern that
silently destroys another session's work.

**5. Leave another session's uncommitted work alone.** If you find edits you did not make, they are
in flight. Say so and route it to its author; do not commit them for them, and do not revert them.

**6. Audit and analysis agents get told the filesystem is shared, and told to be read-only.** A
fan-out of subagents multiplies this hazard by the number of agents. Put the constraint in the
prompt explicitly — "do not modify any file, do not run build scripts, read-only git only" — rather
than assuming a read-only *task* produces read-only *behaviour*.

## The structural fix

`git worktree` per session would make the collision impossible rather than merely discouraged: each
session gets its own checkout of the same repository, commits land in the same history, and no
session can see or stage another's in-flight edits.

**Not adopted** — it changes how every path in the repo set resolves, and the per-machine root
resolution in `registry/repos.json` already carries enough complexity. Recorded as the option if
the rules above prove insufficient.

## What belongs in `CLAUDE.md` instead

Rules 1 and 3 are the load-bearing ones and would be better enforced from `CLAUDE.md`, where every
session reads them at start-up rather than only when it finds this file.

**That edit is Sylvia's to make, deliberately.** `CLAUDE.md` governs how every agent in the repo
behaves, and no session should rewrite it because a peer session suggested it — a peer cannot
authorise a change to the rules that constrain it. Flagged here; not acted on.
