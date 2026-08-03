# Todo

## AIAdjectiveNounPairs: promote from warning to error

`AIAdjectiveNounPairs` stays at `warning` level pending false positive calibration on real prose. Once the false positive rate drops enough, promote it to `error` to match all other rules.

- [ ] Collect false positive data on real technical documentation
- [ ] Decide whether to remove any adjectives from the token list
- [ ] Promote from `warning` to `error` in `styles/ai-tells/AIAdjectiveNounPairs.yml`
- [ ] Update README rule table description: remove "Currently at `warning` level" note

## vale-commit-msg: name the Markdown parser with `--ext=.md`

A commit message reaches vale as a buffer with no file extension, so vale parses it as plain text and never strips code spans. A CLI flag inside a code span trips `ai-tells.DoubleHyphen` in a commit message while the same text stays clean in a document, which contradicts the rule's own message. `.vale.ini` cannot repair this: vale keys `[formats]` on a file extension, and `COMMIT_AGENTMSG = md`, `.COMMIT_AGENTMSG = md`, and `* = md` all leave the buffer as plain text.

The fix is `--ext=.md` on the vale invocation in the `vale-commit-msg` hook in `repotools`, alongside the `--path` that already selects the scope. It preserves that scope. The `ai-tells-commits` rules and a bare `--` both still fire, and only the flag inside the code span stops. Handed to an in-progress `repotools` session on 2026-08-03.

- [ ] Land `--ext=.md` in the upstream `scripts/vale-commit-msg.sh`, and correct its comment claiming `[formats]` resolves the parser
- [ ] Move this repo's `.pre-commit-config.yaml` rev and `apm.yml` pin onto the tag carrying it
- [ ] Check that `--all-files` inside a code span survives `mise run lint-commit-msg` afterwards
