<!-- vale ai-tells-experimental.HeadingTitleCase = NO -->
<!-- vale ai-tells-experimental.VocabularySwap = NO -->

# False Positive Test Cases

These sentences should NOT trigger the new sequence rules.

## OverusedVocabularyVerbs: noun uses that should NOT trigger

The company's leverage in the negotiation was substantial.

The financial leverage ratio was calculated quarterly.

We will use the showcase as a demo venue.

The climbing harness attaches at the shoulders.

The barn has a harness rack by the door.

The rope harness supports up to 200 kg.

The embark terminal at the port was closed for repairs.

## AIAdjectiveNounPairs: technical uses that should NOT trigger

(Intentionally sparse. Calibrate based on real-world false positive data.)

## StructureAnnouncements: legitimate uses that should NOT trigger

(No known false positives. Verify against real-world data.)

## AbsoluteAssertions: legitimate uses that should NOT trigger

(No known false positives. Verify against real-world data.)

## ListIntroductions: legitimate uses that should NOT trigger

(No known false positives. Patterns are tightly scoped to list-announcement phrases.)

## UnpackExplore: legitimate uses that should NOT trigger

(No known false positives. Patterns are tightly scoped to explainer announcements.)

## HedgingPhrases: genuine requirements that should NOT trigger

It is important to test this before deploying to production.

It is essential to configure the firewall before going live.

It is critical to back up the database before migrating.

It is necessary to restart the service after updating the config.

## StackedAnaphora: legitimate "No" uses that should NOT trigger

No one expected the results to be that clear.

No, I do not think that is correct.

There is no way to know for certain.

No additional configuration is required for basic usage.

## MicDrop: legitimate short sentences that should NOT trigger

This is a critical security vulnerability that must be patched immediately.

The result is not clean enough to merge.

It is important to test this before deploying to production.

All four endpoints are returning errors after the deploy.

And the reason we need to rewrite the parser is the performance regression.

Both endpoints return the same status code when the upstream service is down.

Each handler validates its input before passing it to the service layer.

Every request must include an authorization header.

Nothing in the response body indicates which shard served the request.

None of the tests cover the edge case where the token has expired.

The schema changes frequently during early development, so pin your client version.

If the configuration changes, the service automatically restarts and picks up the new values.

The API has remained stable since the v2 release despite internal refactoring.

The logging is clean and structured with proper context.

Pure functions return the same output for the same input.

Just run the migration script and restart the service.

Clean up the stale connections before deploying the new version.

Simple types are easier to serialize than complex nested structures.

Plain text logs are sufficient for local development.

Bare metal servers offer better performance for latency-sensitive workloads.

Raw SQL queries bypass the ORM's query builder for complex joins.

Same as above, but with the timeout increased to 30 seconds.

With PostgreSQL, the binary requires a running database server on the network.

With practice, developers learn to spot these patterns quickly.

## VerbTricolon: noun lists that should NOT trigger

The building plan, the meeting agenda, and the ceiling height were all wrong.

New techniques, better processes, and fast workflows enable better outcomes.

Paris attractions, London landmarks, and Tokyo highlights are all worth visiting.

The morning shift, the evening shift, and the weekend shift all need coverage.

They need servers, databases, and load balancers.

We use PostgreSQL, Redis, and Elasticsearch.

You want speed, reliability, and simplicity.
