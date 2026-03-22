# Todo

## AIAdjectiveNounPairs: promote from warning to error

`AIAdjectiveNounPairs` ships at `warning` level pending false positive
calibration on real prose. Once the false positive rate drops enough, promote
it to `error` to match all other rules.

- [ ] Collect false positive data on real technical documentation
- [ ] Decide whether to remove any adjectives from the token list
- [ ] Promote from `warning` to `error` in `styles/ai-tells/AIAdjectiveNounPairs.yml`
- [ ] Update README rule table description: remove "Currently at `warning` level" note
