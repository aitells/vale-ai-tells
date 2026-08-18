# Verifying the figures

Readers trust a number more than a description, so a wrong count does more damage than a wrong impression. No figure reaches the operator without independent replication.

Every verifier runs the identical prompt. Replication gains nothing from a division of labor, and giving each verifier a different subset would leave every figure checked only once.

## Build the claims table first

Each row holds the claim, the figure, and the exact command that produced it:

```text
| claim                                | figure     | command                     |
| ------------------------------------ | ---------- | --------------------------- |
| Half of all process calls ran a lint task | 125 of 250 | session.py index <t> |
| Two thirds of runs reported 1-2 each  | 34 of 49   | session.py lint <t>         |
```

Nobody can replicate a figure whose row has no command, so leave it out of the report.

## The template

Spawn three fresh delegated agents with `fork_turns: "none"`, each with this same message:

```text
Independently re-derive every figure below. Do NOT trust the
  numbers given to you; they are claims to check, not facts.

  TRANSCRIPT: <ABSOLUTE PATH>
  TOOL: <SKILL>/scripts/session.py <subcommand> <transcript>
    subcommands: index | errors | loops | lint | grep | show | meta
  ARTIFACTS: <RETRO>/artifacts/ holds the canned reports already.

  The transcript is <N> MB. NEVER read it whole; it will overflow you.
  Stream it with the tool, or with python3 and grep.

  CLAIMS
  <THE CLAIMS TABLE>

  For each claim report exactly one of AGREE, DISAGREE, or CANNOT-TELL,
  followed by YOUR figure and the command you ran to get it. Where you
  disagree, say what you think the right number is and why the stated
  one might have come out differently.

  Also check anything the figures rest on that you can test directly.
  Where a claim describes an environment fact, run the command now and
  report what you see rather than what the transcript says.

  Be terse. Do not speculate. Where you cannot verify something, say
  CANNOT-TELL and why, rather than guessing.
```

## Isolation

Verifiers are read-only. If reproducing a claim requires writes, give each verifier its own explicit temporary directory or worktree and prohibit edits in the caller's checkout. Delegated agents share the caller's filesystem, so conversation isolation alone doesn't isolate files.

## Wait for all three

A verifier that hasn't answered yet isn't an abstention, and counting it as one discards the report most likely to disagree. Ask a silent agent for status, and spawn a replacement when it doesn't respond. Hold every figure until the third report arrives.

## Consensus

- Where all three replicate a figure, it stands.
- Where one dissents, report the figure, and name the reading that differed.
- Where two dissent, something is wrong with the figure or ambiguous about the command. Re-derive it, or drop the claim.

Check whether a verifier that agrees with everything actually ran the commands. Replication means running them again, so a verdict without a command behind it proves nothing.

Record the consensus per row in the retro's claims table, so a later reader sees which figures one verifier disagreed with.
