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

## HedgingPhrases: real requirements that should NOT trigger

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

We reviewed every charge for the current billing period.

The token expires after a five-minute grace period.

## ColloquialAssessments: literal uses that should NOT trigger

The plane lands at 6 PM.

The plane landed safely after the storm.

The bird lands on the branch outside the window.

The asteroid landed in the desert.

The kicker lands the field goal from 50 yards.

The dancer lands the jump cleanly.

The probe lands on the moon's south pole.

## FigurativeLands: literal landings that should NOT trigger

The skydiver lands in the field.

Snow lands on the windshield in winter.

The ball lands in the cup.

The drone lands on the pad automatically.

Public lands in the west are federally protected.

When the plane lands at 6 PM, taxi to the gate.

Once the bird lands on the branch, it sings.

Before the rocket lands, deploy the legs.

## VerbTricolon: clauses from separate sentences that should NOT trigger

We begin the pass. Later, we widen the scope, we close the loop.

The gate reads the file. Once it clears, the hook exits, the branch moves on.

## FigurativeSits: literal sitting that should NOT trigger

The cat sits on the mat by the window.

She sits at her desk every morning.

A cabin sits on the ridge above the lake.

Our server rack sits behind the second door.

Books sit on the top shelf.

Guests sit around the table for dinner.

The painting sits above the fireplace in the den.

The toddler will not sit still for the photo.

The return address sits one word above the frame pointer.

A validation wrapper sits between the app and the server.

That byte sits between the file data and the next header.

## ColloquialAssessments ("move"): literal uses that should NOT trigger

The next move in the protocol is a handshake.

His best move was to fold.

The move from monolith to services took two years.

A bold move from the new CEO.

<!-- Known limitation: chess analysis like "Nf3 is the move" or "White is the move"
     will trigger. Suppress per-section in chess writing. -->
<!-- vale ai-tells.ColloquialAssessments = NO -->
White is the move in this chess position.
Nf3 is the move after the Ruy Lopez.
<!-- vale ai-tells.ColloquialAssessments = YES -->

## ColloquialAssessments ("matters"): bare uses that should NOT trigger

<!-- Known limitation: the comparative-aphorism mic-drop
     ("X verbs more/less/faster/... than Y") now fires (added in
     v1.13.0). The shape is genuinely an AI tell most of the time,
     but legitimate human-subject uses do exist. Suppress
     per-section if legit. -->
<!-- vale ai-tells.MicDrop = NO -->
Latency matters more than throughput here.
<!-- vale ai-tells.MicDrop = YES -->

Every line of code matters when the binary is this small.

It matters whether the lock is held during the write.

<!-- Known limitation: definite-NP "The X matters." now fires (v1.12.0
     extended MicDrop from pronoun subjects to noun-phrase subjects).
     Suppress per-section if legit. -->
<!-- vale ai-tells.MicDrop = NO -->
The order of operations matters.
<!-- vale ai-tells.MicDrop = YES -->

## AnthropomorphicJustification ("work"): literal uses that should NOT trigger

<!-- Known limitation: bare "does/doing the work" now fires (v1.12.0
     dropped the qualified-shape exclusion). Human-subject uses with
     trailing "of X" qualifiers still trigger. Suppress per-section
     if legit. -->
<!-- vale ai-tells.AnthropomorphicJustification = NO -->
The team does the work of reviewing every PR.
<!-- vale ai-tells.AnthropomorphicJustification = YES -->

## AnthropomorphicJustification (agency verbs): literal uses that should NOT trigger

She earns a salary at the firm.

The paper claims a new lower bound.

Hang on a second while I check.

The portrait shows a jeweled crown.

Engineers do the hard work of maintaining the runtime.

The interns did real work on the migration tooling.

Engineers do a lot of work that nobody sees.

## VocabularySwap ("unlock"): literal uses that should NOT trigger

Unlock the door before the alarm trips.

The phone unlocks with a fingerprint.

The achievement unlocked at level 30.

## VerbTricolon: noun lists that should NOT trigger

The building plan, the meeting agenda, and the ceiling height were all wrong.

New techniques, better processes, and fast workflows enable better outcomes.

Paris attractions, London landmarks, and Tokyo highlights are all worth visiting.

The morning shift, the evening shift, and the weekend shift all need coverage.

They need servers, databases, and load balancers.

We use PostgreSQL, Redis, and Elasticsearch.

You want speed, reliability, and simplicity.

## ShipOveruse: suffixes and compounds that should NOT trigger

Our relationship and their partnership deepened over the years.

Good leadership outlasts any membership fee.

She earned a scholarship and an internship.

The flagship product and the spaceship are just props.

He attends worship at the township chapel.

The shipment arrived and every shipment is tracked.

## ResonateOveruse: noun forms that should NOT trigger

The cavity has a resonant frequency.

Acoustic resonance filled the hall.

## OverusedVocabulary (hype verbs): literal forms that should NOT trigger

The supercharged engine roared to life.

A turbocharged sedan passed us.

## ContrastiveFormulas: non-appositive commas that should NOT trigger

She gave a talk, not knowing the demo would fail.

We merged a fix, not that anyone noticed.

## ContrastiveNegation: non-tells that should NOT trigger

The feature is no longer supported.

She paused, no longer sure of the answer.

We left at dawn, no sooner than we had to.

## GrowthMetaphors: scoped words that should NOT trigger

We chose the most viable option available.

Set the random seed before training the model.

The store sells fresh organic produce.

Her earliest memories date from infancy.

## FigurativeRides: literal riding that should NOT trigger

She rides the bus to work every day.

He rides a horse on weekends.

The kids ride bikes to school.

## FigurativeRides: literal riding and vehicles that should NOT trigger

She rides the bus to campus every morning.

He rides the elevator to the tenth floor.

She rides the bus to the office every morning.

Run the cleanup script to get rid of the stale cache entries.

## FigurativeQuiet: literal quiet that should NOT trigger

The room was quiet during the exam.

Please be quiet in the library.

We enabled the quiet flag to suppress output.

It was a quiet evening at home.

She asked the children to keep quiet.

## FigurativeLoud: literal loudness that should NOT trigger

The room was loud during the concert.

She played loud music all afternoon.

He read the passage out loud to the class.

I was just thinking out loud.

There was a loud noise from the server room.

## FigurativeWins: precedence jargon and literal winning that should NOT trigger

The last write wins in this store.

The more specific rule wins when they conflict.

The home team wins most games at night.

She wins the chess tournament again.

## AnthropomorphicJustification (self-*): technical adjectives that should NOT trigger

A self-healing cluster restarts failed nodes.

The system is self-correcting by design.

## FigurativeCarries: literal carrying that should NOT trigger

The courier carries a backpack full of parts.

The truck carries freight across the state.

She carried the groceries upstairs.

The function carries out the validation logic.

The team carries out data processing nightly.

The build carried over settings from the previous release.

The release notes carry over exceptions we already documented.

## FigurativeFalls: literal falling that should NOT trigger

The price fell sharply after the announcement.

The temperature falls below freezing at night.

Night falls early in December.

She fell down the stairs and bruised her knee.

Leaves fall from the trees in autumn.

Rain falls steadily on the roof.

The ball falls to the floor when you drop it.

## OrganicConsequence: literal falling out that should NOT trigger

The pen fell out of my pocket.

She fell out of the boat.

The card fell out of the envelope.

## HollowAcknowledgment: plain "without" clauses that should NOT trigger

She left without saying goodbye.

He fixed the bug without breaking anything.

The script runs without printing output.

The team names the release after a constellation.

The linter identifies three issues in the file.

## FigurativeStrikes: literal striking that should NOT trigger

Strike a match to light the burner.

Lightning strikes the tower during storms.

The workers went on strike for higher pay.

## FigurativeLends: literal lending that should NOT trigger

Please lend me the book until Friday.

The bank lends money at a fixed rate.

## FigurativeDraws: literal drawing that should NOT trigger

Draw a card from the top of the deck.

She drew water from the well.

The sheriff drew his weapon.

The nurse drew blood for the test.

## FigurativeCasts: literal casting that should NOT trigger

Cast the fishing line toward the reeds.

They cast the bronze statue in one pour.

Voters cast their ballots by noon.

The director cast her in the lead role.

## FigurativeHolds: literal holding that should NOT trigger

She holds a master's degree in physics.

He held the rope while she climbed.

The jar holds two liters.

The court holds session on Mondays.

The clamp holds the panel in place.

## AnthropomorphicJustification (adjudication): literal settling that should NOT trigger

We settled on a date for the review.

The team settled into the new office.

Dust settles on the shelf overnight.

## FigurativeRuns: literal running that should NOT trigger

Run the tests before you push.

The server runs on port 8080.

The demo is up and running.

The pipeline runs nightly and the script runs in about five seconds.

The cron job runs across every region.

The suite runs through every fixture twice.

The binary runs under Docker in CI.

The daemon runs under systemd with a service file.

The workflow runs on every push to main.

The cable runs under the floor to the rack.

The road runs across the valley.

She went for a run this morning.

## SemicolonUsage: legitimate semicolons that should NOT trigger

We visited Paris, France; Berlin, Germany; and Tokyo, Japan.

Compute the centroid; if it is on the far side, reverse the order.

## FigurativeAnchor: literal anchor uses that should NOT trigger

Use the anchor tag to link within the page.

She is the news anchor for the evening broadcast.

The boat is anchored in the harbor overnight.

Bolt the bracket so it is anchored to the wall.

Negotiators exploit anchoring bias in pricing.

The mall's anchor tenant signed a lease.

## StrategyBuzzwords: literal uses that should NOT trigger

The engine's flywheel cracked at high rpm.

The castle's moat was dry that summer.

The moat around the old castle was deep and wide.

Sailors steer by the North Star.

Settlers joined the Oklahoma land grab of 1889.

## EmptyPadding: non-noun follow-words that should NOT trigger

The library is named after its original author.

<!-- Known limitation: the broad modifier-plus-noun sequence flags a
     modifier before a proper name, because the POS tagger labels a
     mid-sentence name as a common noun (NN), not a proper noun (NNP).
     It also flags literal uses such as "named pipe" and "various
     reasons." This breadth was a deliberate choice; suppress
     per-section where the literal sense is common. -->
<!-- vale ai-tells.EmptyPadding = NO -->
A developer named Alex joined the team.
She was certain Maria would arrive on time.
<!-- vale ai-tells.EmptyPadding = YES -->

## PassiveVoice: predicate adjectives that should NOT trigger

The results were mixed.

The talk was indeed useful.

The color is red.

The committee reviewed the proposal and wrote the report.

### PassiveVoice: known tagger limitations

<!-- Known limitation: participles that double as adjectives ("tired,"
     "excited") tag as VBN even in predicate-adjective position, so
     these fire. Deliberate: the rule carries no exception list, and
     the genuine passive sense ("the electron is excited by a photon")
     must stay flagged. Users decide what to except. -->
<!-- vale ai-tells-experimental.PassiveVoice = NO -->
She was tired after the long meeting.
The team is excited about the launch.
<!-- vale ai-tells-experimental.PassiveVoice = YES -->

## ColonUsage: colons that should NOT trigger

### Appendix A: Glossary

Heading text is exempt, so the capitalized title half above stays clean.

Check the output: it stays clean when lowercase follows.

Run it again: I checked twice.

Rotate the key first: API tokens expire monthly.

Meet at 10:30: Lunch follows at noon.

He said: "Go home now."

<!-- Known limitation: Vale strips markup before matching, so a run-in
     bold label reads as a plain "Label: Sentence" construction and
     flags. Disable the rule where that convention is established. -->
<!-- vale ai-tells.ColonUsage = NO -->
**Example:** Run-in bold labels flag without this suppression.
<!-- vale ai-tells.ColonUsage = YES -->

## LabelAndExplain: legitimate colons that should NOT trigger

The output: green.

The command: a dry run.

The API: a set of endpoints for managing users and their sessions.

The staged files: config.yml, main.go, and the integration test suite.

The following options are available: verbose, quiet, and debug output.

## CataphoricForecasting: literal counts that should NOT trigger

The commit changed all three files.

The build took about five minutes to finish.

We identified four factors during the review.

The directory holds three files.

The map labels the four corners.

The service runs on two servers behind a load balancer.

We compared the two functions line by line.

These three tests cover the edge cases.

Three years ago the team migrated the stack.

Two weeks later the bug came back.

The two weeks of onboarding cover environment setup.

The three of us reviewed the patch.

The bar splits into two pieces.

The release rolls out in three regions.

The report covers four phases of the project.

The stream splits into two channels.

The survey covers four categories of feedback.

## HeadingTitleCase: ordinal prefixes that should NOT trigger

<!-- vale ai-tells-experimental.HeadingTitleCase = YES -->

### Section 1: Data collection methods

### Appendix A

### Appendix B: Survey instruments

### Chapter IV: The long road home

### Part II

### Step 3 Configure the server

### 1.1 This heading keeps its first word capitalized

### 2. Introduction to the test suite

<!-- vale ai-tells-experimental.HeadingTitleCase = NO -->

## ConclusionMarkers: adjective/adverb senses that should NOT trigger

The team weighed the overall design against throughput.

The rollout ultimately depends on the vendor timeline.

## FormalTransitions: mid-sentence adverbs that should NOT trigger

We built the module specifically for low latency.

Fundamentally sound architecture keeps the team productive.

Both approaches are essentially interchangeable in practice.

There are several items of note in the audit report.

## FalseBalance: precise technical compounds that should NOT trigger

The scheduler is context-dependent by design, and timeouts are situation-dependent.

## FormalRegister: precise technical nouns that should NOT trigger

The framework is documented in the appendix.

The methodology is documented in the appendix.

## VocabularySwap: technical adjective senses that should NOT trigger

The streamlined process saved hours of manual work.

The job ran with elevated privileges on the host.

## NegationDensity: ordinary negation that should NOT trigger

Vale has no narrower setting for that format. The option in this section has no effect either.

The file is no longer present and no one has read it, no matter when it was written.
