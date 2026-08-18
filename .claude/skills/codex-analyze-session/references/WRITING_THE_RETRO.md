# Writing the retrospective

The preflight created `RETRO.md` from `templates/RETRO.md` and filled in its header. Write the rest.

Someone reads a retrospective once and acts on it, but the evidence has to remain available afterwards. A summary that exists only in a closed conversation helps nobody, so this gets written to disk.

## Lead with the cost

Open with what the session actually cost and why, not with an impression. `artifacts/loops.txt` gives the number, since rounds beyond the first, added up, are the wasted round trips.

The operator already knows the session went badly. What they can't see without this document is how much of that waste was avoidable.

## Cite a line number for every claim

Use `L1938` form. An assertion without a line number is one nobody checked.

Where the session reached a conclusion, say whether it holds. A retraction the session made is a claim like any other and needs the same test. One session here retracted a correct finding because its test had silently stopped checking anything, which made the retraction wrong rather than the original claim.

## Rank by round trips, not by irritation

A rare pattern costing twenty round trips ranks higher than a common one costing two. List frequency in the table next to the cost, never instead of it.

## Sort the fixes by what reaches them

Tooling reaches some. Instruction reaches others. Neither reaches the rest.

Be strict about that last category. Some repeated work follows from having a strict gate at all, and removing it would cost more than accepting it. Saying so directly serves the reader better than a recommendation nobody acts on.

Rules measuring a whole block are the clearest example. Editing one sentence changes the measurement for the entire block, so such a rule can fire again after an edit that fixed a different rule. That interaction is a consequence of the rule's design rather than a defect to fix.

## Prefer a mechanism to a reminder

A fix a script can enforce belongs in the script. Number the mechanical fixes in the order you would build them, and say how many round trips each would have saved.

State the cost too. A hook that runs on each write enforces a rule and adds latency to each write, and a recommendation listing only the improvement gives the reader no way to compare it against the others.

## What belongs in the method note

Anything affecting how much a reader should trust the findings belongs in the method note. Put a test that stopped checking anything there. Agents overwriting each other's files belong there as well.

Readers trust this section most. A document stating where its own process failed is more credible than one reporting only successes.

## Name every artifact

List the files in `artifacts/` and say what each one shows. Add anything else the analysis depended on by passing extra paths to `new-retro.sh`, which copies them in next to the canned reports.

Include any test script you wrote and any rule definition you had to read. A later reader can then check the work instead of doing it again.

## Hand back the path

Give the operator the retro path when you report the summary. The document is the deliverable, not the conversation.
