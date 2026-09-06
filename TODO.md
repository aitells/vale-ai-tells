# Todo

## AIAdjectiveNounPairs: promote from warning to error

`AIAdjectiveNounPairs` stays at `warning` level pending false positive calibration on real prose. Once the false positive rate drops enough, promote it to `error` to match all other rules.

- [ ] Collect false positive data on real technical documentation
- [ ] Decide whether to remove any adjectives from the token list
- [ ] Promote from `warning` to `error` in `styles/ai-tells/AIAdjectiveNounPairs.yml`
- [ ] Update README rule table description: remove "Currently at `warning` level" note

## Vale reports a punctuation match inside a masked code span

Vale masks a Markdown code span before matching, replacing what it holds with asterisks. A rule whose token is punctuation still draws a finding at the raw position inside the span, though only when that same token also matches elsewhere in the same paragraph. Reduced with one throwaway rule on token `\+\+` at `nonword: true`:

- Inside a code span only: nothing, so the mask does its job.
- Inside a span and once outside, same paragraph: two findings, the extra one pointing inside the span.
- That same pair split across two paragraphs: one finding, correctly placed.
- Outside only: one finding, correctly placed.

Paragraphs bound this, not lines. Moving the loose token down a line keeps the extra finding. A blank line clears it.

The `nonword` setting does not cause this. The same experiment with a word token draws one correctly placed finding under `nonword: true` and under the default. Punctuation is what separates the two, and `ai-tells.DoubleHyphen` carries `nonword` only so its token can match at all.

A commit message meets this through `DoubleHyphen`. One that puts a command-line flag in a code span and also holds a loose pair of hyphens elsewhere draws a finding on the flag that no rewording of the flag clears. The parser work that made code spans mask at all is part of `repotools` v0.4.0, which this repo now pins, and this misplaced finding is the one piece of that work still open.

- [ ] Report it to vale upstream with the reduced case recorded here
- [ ] Decide whether `ai-tells` can narrow the token usefully, or whether the rule waits on a vale fix
