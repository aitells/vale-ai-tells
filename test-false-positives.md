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

No such file exists at that path.

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

<!-- Known limitation: the open-subject placement token (added for the
     rejected-commit corpus) fires on literal sitting with a physical or
     animate subject. Deliberate: this package targets technical prose, and
     the rule's own header tells furniture, landscape, and page-layout
     writing to disable it rather than curating a subject list that would
     miss "the rules sit in the config". Suppress per-section if legit. -->
<!-- vale ai-tells.FigurativeSits = NO -->
The cat sits on the mat by the window. She sits at her desk every morning. A cabin sits on the ridge above the lake. Our server rack sits behind the second door. The painting sits above the fireplace in the den.
<!-- vale ai-tells.FigurativeSits = YES -->

Books sit on the top shelf.

Guests sit around the table for dinner.

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
White is the move in this chess position. Nf3 is the move after the Ruy Lopez.
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

The quarterly earnings summary lists revenue by region.

An earnest apology arrived the next morning.

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

She received a scholarship and an internship.

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

## FigurativeWins: literal winning that should NOT trigger

The home team wins most games at night.

Both candidates won their primaries on the same night.

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

That assumption is widely held among practitioners.

He held the phone to his ear.

The bracket holds the panel to the frame.

The cache holds a reference to the parent object.

## FigurativeSettles: literal settling that should NOT trigger

We settled on a date for the review.

The team settled into the new office.

Dust settles on the shelf overnight.

They settled on the heuristic that names without dots are packages.

Settle ties using string ordering when the lengths match.

We settle for the simpler form here.

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
A developer named Alex joined the team. She was certain Maria would arrive on time.
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
She was tired after the long meeting. The team is excited about the launch.
<!-- vale ai-tells-experimental.PassiveVoice = YES -->

## ColonUsage: colons that should NOT trigger

### Appendix A: Glossary

Heading text is exempt, so the capitalized title half above is not flagged.

Check the output: it reports nothing when lowercase follows.

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

The directory contains three files.

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

## FigurativeFires: literal firing that should NOT trigger

The GOAWAY close timer fired before the worker stopped.

The click event fires twice in older browsers.

## FigurativeTrips: literal tripping and round trips that should NOT trigger

Round-tripping a string through the encoder preserves it.

Return the number of threads required to trip the barrier.

He tripped over a cable in the server room.

## FigurativeCarries: literal carriers that should NOT trigger

The truck carries freight across three states.

A courier carries the package uptown.

The mosquito carries the parasite between hosts.

The paper carries a formal proof in the appendix.

The final carry propagates to the next column.

The carries are summed in the last step.

The truck carries no more than three pallets.

Each bus carries zero or more passengers.

## FigurativeLands: achievements and aircraft that should NOT trigger

The plane has already landed.

The pilot landed the plane safely.

She finally landed a job at the lab.

## FigurativeSees: literal seeing that should NOT trigger

The compiler sees the annotated source, not the original.

I saw the demo last week and took notes.

## FigurativeTravels: literal travel that should NOT trigger

Sound travels faster in water than in air.

They travel light on the way to the summit.

## FigurativeBreeds: literal breeding that should NOT trigger

The kennel breeds retrievers for field work.

Mosquitoes breed in standing water.

## FigurativeDemands: literal demands that should NOT trigger

The union demanded higher wages.

Supply follows demand in tight markets.

## FigurativeLives: literal residence that should NOT trigger

My family lives in a small town.

The species lives in brackish water.

This lives in the runtime package.

## FigurativeStays: literal staying that should NOT trigger

He stayed at the hotel near the airport.

The guests stayed in the annex overnight.

## FigurativeSweeps: garbage collection and literal sweeps that should NOT trigger

The garbage collector sweeps unmarked spans in the background.

Background sweeping runs between GC cycles.

The span was swept before the next mark phase.

The compiler performs a backwards sweep over the instructions.

A parameter sweep covers the learning-rate grid.

The radar sweep completes every four seconds.

She sweeps the porch every morning.

## FigurativeReaches: literal reaching that should NOT trigger

The child reaches for the top shelf.

The climber reached for the next hold.

The robot arm reaches for the part on the belt.

## FigurativeIdioms: literal descent that should NOT trigger

Come down to the lobby when you are ready.

She came down to breakfast after eight.

## FigurativeIdioms and FigurativePays: tradeoffs that name the cost and should NOT trigger

The change speeds parsing at the cost of memory.

The layout favors lookups at the expense of updates.

That will come at a cost of extra complexity.

The map is built lazily so we never pay the price of building it twice.

She paid off the mortgage in ten years.

## FigurativeIdioms: remainders that should NOT trigger

It remains to choose the exponent.

The parser returns the word and what remains after it.

The optimizer accepts a cost function and a starting point.

The endpoint accepts a cost parameter in cents.

## AnthropomorphicJustification: opinions that should NOT trigger

Public opinion shifted slowly after the report.

## FigurativeSettles and FigurativePays: negotiation and physical settling that should NOT trigger

The vendors settled on a price after two calls.

The dust settled on the workbench overnight.

The pacer settles into a steady state after a few cycles.

## NegatedObject: excluded verbs and degree idioms that should NOT trigger

The function takes no arguments and returns no value.

The string contains no padding bytes.

The job starts no earlier than midnight and uses no more memory than before.

Given no arguments, the command prints usage.

The rewrite runs no faster than the old code.

The issues no one filed remain invisible.

The parser allows zero or more spaces between tokens.

Add zero to the counter to keep the total unchanged.

The constructor makes zero values useful from the start.

A clean exit means no findings exist.

Assume no aliasing between the two buffers.

The function takes no `flags` argument beyond these.

Ensure no goroutines leak after the test completes.

The glob matches no files in an empty directory.

The search found no match in the corpus.

If you pass no arguments, the command reads standard input.

At present no workaround exists for the older parser.

## NegatedSubject: docs conditionals and excluded predicates that should NOT trigger

If no timeout is specified, the parser uses the default.

No error is returned when the file is missing.

No whitespace is allowed inside the token.

The compatibility shim is no longer needed.

No one was harmed by the change.

No law required them to file the report.

## FillerIntensifier: precise senses that should NOT trigger

A single-threaded server runs without locks.

The single-variable form silently skips every iteration.

Wrap the value in single quotes before passing it to the shell.

The registry is a singleton behind one accessor.

The singular form of the noun takes no suffix.

The word merely narrows the claim.

A lonely outpost appears in the story's second act.

No one has read the draft yet, and each one of the reviewers is busy.

## IncompleteComparison: completed comparisons that should NOT trigger

The new parser is substantially faster than the old one.

Latency is considerably lower compared with the previous release.

The v2 design is markedly simpler versus its predecessor.

Costs were dramatically reduced relative to last quarter.

Compared with the old parser, the new one is substantially faster.

Relative to last quarter, overhead is considerably lower.

## StackedHedges: single hedges that should NOT trigger

This could break existing consumers.

The change possibly affects downstream caches.

She ran as fast as she possibly could.

Fasting typically involves abstaining from calories.

The results are roughly comparable across sites.

## NounString: short technical compounds that should NOT trigger

We updated the config file path yesterday.

The unit test suite passed on the first try.

New York City Hall opened at nine.

## UniversalObject: operations verbs and excluded forms that should NOT trigger

The query returns all matches in insertion order.

The pass removes all unused imports and deletes all stale entries.

Use find to list all files under the directory.

The mutex protects all fields below it.

Each item passed all tests in the doctest run.

The team should handle all cases before the freeze.

We plan to cover all of them in the next milestone.

The parser does not handle all the legacy encodings.

The collapse eliminates all but the top level.

The poller handles every other request in the pair.

The loop clears all pending timers on shutdown.

## UniversalSubject: conditionals, adjectives, and floats that should NOT trigger

The reader stops when all bytes are consumed.

If all checks pass, the merge proceeds without review.

All three parts are optional in the pattern.

All ports are valid, including zero.

The reader, the writer, and the closer have all been observed in the trace.

The temps were all aliased to the scratch buffer.

All feedback will be addressed in the next revision.

All callers must check the returned error.

## ExplainerHeadings: conventional doc headings that should NOT trigger

### How to Configure Vale

### What's New in the Release

### Frequently Asked Questions

### Installation and Setup

## ExplainerLeads: embedded clauses that should NOT trigger

The recipe depends on how the shell resolves the binary.

The comment explains why the test fails on Linux.

The parser knows where the file is stored on disk.

The question of why the test fails is still open.

When the input is empty: return early.

When a conversion is applied, the value narrows.

Where the page size is small, memory mapping wins.

## FigurativeQuantities: literal arrays, heaps, and hosts that should NOT trigger

The function returns an array of strings.

The parser keeps an array of tokens per line.

The allocator places large objects on the heap.

The host of the meetup opened the room.

A sine wave crosses zero twice per period.

The fix covers the seven failing tests on Windows.

Join the words with a dash.

## AnthropomorphicCognition: human pupils and human wanting that should NOT trigger

The user wants a report by Friday.

Applications that want a proxy set the environment variable.

Somebody installing a binary wants an install line.

A consumer pins exactly the API surface it wants.

She taught the students in two schools.

Teach me patience.

The compiler does not know about the alias.

## EnforcementMetaphors: timers and literal posture that should NOT trigger

Arming the ping timer starts the countdown.

The dog bared its teeth at the mail carrier.

## EvasionMetaphors: literal movement that should NOT trigger

We go around the loop twice per request.

The parade goes around the block.

The rice went uneaten.

## FigurativeOwns: resource and legal ownership that should NOT trigger

The goroutine owns the lock until the handoff.

The caller owns the returned buffer.

Tony Burns owns the copyright on every header.

The owning goroutine frees the stack.

## FigurativeClears: deletion senses that should NOT trigger

Clear the cache before the second run.

The janitor cleared the tables after lunch.

## FigurativeSurfaces: marine and road senses that should NOT trigger

The submarine surfaces at dawn.

The road surface stays rough for a mile.

## FigurativeIdioms: literal walking and fanning that should NOT trigger

She walked back to the office after lunch.

The fan-out factor stays at eight per node.

## FigurativeFalls: literal descent that should NOT trigger

The price fell sharply in the third quarter.

Night fell over the harbor.

## NominalizedScopeChange: adjectival and verb uses that should NOT trigger

The narrowing road forced the trucks to slow down.

A loosening belt squeaks before it fails.

Type narrowing is done by analyzing the code flow.

We stop narrowing when the range fits the window.

The above constraints narrow the possible bit sets.

## HouseStyle: literal houses that should NOT trigger

The house at the end of the street needs paint.

The team keeps the tooling in-house.

Our in-house style guide covers commit prose.

The house lights dim before the talk starts.

A tic in the parser drops the final byte.

## FigurativeDisguises: noun senses and comparisons that should NOT trigger

The problem is posed as a linear program.

The upgrade poses as much risk as the bug it removes.

The refactor poses as many questions as it answers.

The masquerade ball starts at nine.

His disguise fooled nobody at the door.

The parade passed as the band played.

The kids dressed up for the party.

The suite passes for the wrong reason.

## JourneyMetaphors: manner, traversal, and literal uses that should NOT trigger

The result depends on the way the shell splits arguments.

The descriptor is closed on the way out.

We work our way down the tree, one level at a time.

The search visits every node on the path to the root.

A map of the user journey documents the checkout flow.

The crew paved the driveway in one afternoon.

She was on her way to the airport when the phone rang.

## NegatedSubject and NegatedPair: docs formulas that should NOT trigger

No such file exists at that path.

Nothing but the header changes.

The function runs without arguments or results.

The record has neither a parent nor a child.

## BareHolds: literal holding that should NOT trigger

The goroutine holds the lock until the handoff.

The caller holds a reference to the buffer.

The jar holds two liters.

She holds a master's degree in physics.

The clamp holds the panel in place.

## BareReaches: measurement and literal arrival that should NOT trigger

The counter reaches zero after the last decrement.

The reader reaches EOF on the final line.

The child reaches the top shelf on tiptoe.

The train reaches the station at nine.

The timeout is reached after thirty seconds.

The paragraph count never reached two.

## MortalityMetaphors: literal death that should NOT trigger

The patient died before the transfer.

The battery dies after a week on the shelf.

The tree survives the winter under a tarp.

## MotionMetaphors: literal motion that should NOT trigger

The bird feeds its chicks at dawn.

The ladder leans against the wall.

The loaf bakes in the oven for an hour.

A swamp cooler runs on evaporation.

## FigurativeNouns: literal nouns that should NOT trigger

She wrote a short story about the harbor.

The door knob came loose.

The story behind the outage is long.

## FigurativeKeeps: plain upkeep that should NOT trigger

The gitignore entry keeps that file out of history.

The lock keeps the garbage collector from being invoked.

## NegatedSubject and NegatedObject, strengthened forms that should NOT trigger

Zero padding is allowed only to the left.

None is returned when the loader is missing.

The rate is one, so no adjustment is needed.

Bisect starts by running the target with no changes enabled.

There is essentially no demand for this.

## BareNames: literal naming that should NOT trigger

The committee names the release after a constellation.

The complaint names the contractor as a defendant.

The type names that appear in the output are sorted.

The parents named the child after her grandmother.

A variable named the same as its type is legal.

## NamedAdjective: terms of art that should NOT trigger

The named pipe blocks until the reader opens it.

A named tuple exposes its fields by attribute.

The named group in the regex is optional.

The file named foo is read first.

The named storm made landfall on Tuesday.

## CoordinatedReveal: plain coordination that should NOT trigger

The direction reverses at all times, and it doesn't matter at all.

The list is sorted, and the leading entry is the oldest.

It is passed explicitly to the function that needs it.

The value is dead, and only when the register frees.

The bits are twos-complement and the leading bit always indicates sign.

## ConsequenceParticiple: participles in an ordinary sense that should NOT trigger

The cache stays cold after the sweeper drops the row.

When the buffer is empty, the reader leaves early.

The parser checks the header first, making sure the length field is present.

Leaving aside the cold path, the reader takes one lock per page.

After three retries the client gives up.

The meaning of the flag depends on the platform.

The tool prints the file, making a best effort to preserve existing contents.

Hiding the socket behind the wrapper makes it possible to swap the transport, making it possible to test offline too.

Both callers share one row, and the second one waits.

Making the buffer larger did not help.

Once the count reaches zero the loop ends, and the reader returns.

Because the comparison ignores case, the sort is stable.

## ShellNounCopula: the noun with a plain complement or a relative clause that should NOT trigger

The reason is the cache, and the fix is to clear it.

The result is a list of paths sorted by name.

The difference is small enough to ignore.

The question is answered in the next section.

The problem that the parser reports includes the line and column.

The idea that names are stable comes from the spec.

That problem is on the list for the next release.

The key is stored in the keychain.

The point of the flag is to skip the probe.

The reason that the build failed was a missing pin.

The rule is that a name resolves in the package that declares it.

The first is that the socket closes early.

## SummativeAppositive: lists, ordinary appositives, and plain afterthoughts that should NOT trigger

Every read costs a lookup, a decode, and a copy.

The change adds a cost, a benefit, and a risk to the design.

Alice, a friend from the platform team, reviewed the patch.

Pass a regular expression, a pattern that matches the filenames you want.

The renderer calls the formatter, a tool that rewrites files in place.

The plan has a cost. It shows up in the benchmarks.

The old path never drew that distinction.

The curve bends at one marked point, which is the point where the cursor stops.

The tool reads a manifest, a lock file, and a schema.

The retry count is three, which is what the upstream limiter requires.

## AbstractionSubject: literal measurements and passive mechanisms that should NOT trigger

That gap between the two values is 4 bytes.

That constraint is enforced by the database.

This gap is about 4 bytes wide.

If that invariant is true, the loop ends.

These constraints are checked by the compiler at link time.

The reverse lookup costs one read.

The test asserts that ordering is preserved across restarts.

This loop runs in quadratic time.

This distinction is documented in the package comment.

The parser handles this ambiguity by reading one more token.

This restriction is imposed by the compiler.

## StrawmanContrast: ordinary alternatives and open-ended contrasts that should NOT trigger

Rather than walking the whole tree, the reader walks the index.

Use the index instead of the whole tree.

Pass the `--instead-of-default` flag to change the fallback.

The table maps names to ids and vice versa.

A module can import its dependencies but not the reverse.

The rule prefers the shorter form, rather than the longer one, when both parse.

The value is stored as text, rather than parsed.

Iterate over the selected modules, not all modules.

The run took ten minutes, instead of the usual two, because the cache was cold.

The default returns an empty list, rather than nothing.

## ScopePartition: literal sides, "at a time," and trailing adverbials that should NOT trigger

The type on the right-hand side of the declaration is the alias target.

On the plus side, the link ends here.

The client side of the handshake sends the first message.

The server filters entries on the client side before returning them.

Only one worker runs the loop at a time, so the counter is safe.

At any time, the caller may cancel the request.

The link step applies the offsets at link time, before the loader runs.

The server-side handler checks the token on every request.

A search reverses that join.

The type at compile time may differ from the value at run time.

## StackedAnaphora: discourse-marker and determiner "For" openers that should NOT trigger

For now, the lookup is one hop. For details, see the schema section.

For each key, the loader reads one file. For the rest, it reads a directory.

## RestatementMarkers: literal "same," "practice," "effect," and "meaning" that should NOT trigger

The reader gets the same value on each call.

Both suites pass in practice tests and in staging.

The call returns a list of offsets.

Each flag changed meaning in the last release.

The change took effect in practice and the join reversed.

One buffer serves both functions, in effect.

Both readers take the same lock.

Each flag entry lists the meaning and the default.

Position decides the meaning of each byte.

## PseudoCleft: questions and embedded clauses that should NOT trigger

What is the offset?

What value is the default for the timeout?

The function documents what the join returns.

What remains is unclear until the sweep finishes.

What happens if the file is the same as the source?

Where the input is a list, the reader takes the first element.

The only difference is the direction.

All the rows are the same width.

We check what the value is before the write.

## FigurativeNouns and FigurativeSurfaces: exported-names and physical surfaces that should NOT trigger

The API surface is small on purpose.

Each release reduces the attack surface.

The surface area of the cube is six times the square of its edge.

The proposal separates the surface syntax from the semantics.

The lander touched the surface of the moon at dawn.

Sand the top surface before you paint it.

## EmphaticCopula: bold markup that should NOT trigger

This design **is** intentional.

The fix **actually** works as expected.

We **never** skip the validation step.

The report **always** posts on Fridays.

## FigurativeShape: geometry, graphics, and compiler senses that should NOT trigger

The shape of the curve flattens after the third sample.

Each GC shape gets its own stenciled copy of the function.

The turtle shape defaults to a classic arrow.

A diamond-shaped embedding appears twice in the graph.

The shape type records the size and alignment of the instantiation.

The shapes of the letters hint at the eyes of the gopher.

## FusionMetaphors and DepletionMetaphors: literal senses that should NOT trigger

She folded the map in half.

The bridge collapsed in the storm.

Tight coupling between the modules made the refactor slow.

The engine stalled at the light.

The starvation of low-priority threads is a known scheduler problem.

## MotionMetaphors, EnforcementMetaphors, and FigurativeIdioms: literal senses that should NOT trigger

The dog trailed the scent across the field.

## FigurativeNouns: literal grains, lenses, and seams that should NOT trigger

A grain of sand jammed the mechanism.

The lens cap protects the front element.

The seam allowance is one centimeter.

Fine-grained locks replaced the global one.

## AnthropomorphicAdjectives: people, medicine, and physical senses that should NOT trigger

The surgeon called the growth a benign tumor.

A healthy person recovers in a week.

She left a generous tip.

The noisy room made the call hard to hear.
