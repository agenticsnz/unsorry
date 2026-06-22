# The Ten-Day Republic

*How a git repository became a research organization in ten days. Quotes are from Chris Barlow's public "Tell me a Fable" talk and from contributors' messages; the figures are taken from the repository's own history.*

---

On a Sunday morning in June, the system was stuck. Again.

In New Zealand, Chris Barlow had just woken up. In Finland, where the June sun does not set — where it was nine at night and still bright as noon — Perttu Isotalo had already spent hours staring at CI metrics. Neither of them had planned to spend their weekend this way. Neither of them, eleven days earlier, had a project at all.

Now the thing they were looking at had queues. Leaderboards. Governance documents. A version number — 1.29. Infrastructure bottlenecks. Eight human contributors and an unknown number of non-human ones. And **2,349 machine-verified mathematical proofs**, none of which any human had been asked to trust.

Nobody was entirely sure what it had become.

---

The idea was older than the project.

A year and a half earlier, Chris had started logging into Reuven Cohen's live-coding sessions — Toronto time, which from where he sat meant five in the morning. He is, by his own insistence, not a developer. "I'm an infrastructure guy. An architect. I draw boxes and lines and drink coffee and talk to people." He did not do well at math in school. He is very clear about this.

What he saw on those 5 a.m. calls struck him as "absolutely ridiculous" — not bad, but ridiculous the way a card trick is ridiculous before you learn it. And he kept circling one question: *what happens if AI systems stop working alone?* He built a demo of it — a colorful screen of thousands of artificial minds pulling toward one goal. SETI@home, but for the search for *artificial* intelligence instead of alien signals. It wasn't a product. It wasn't even a prototype. It was the kind of thing you build because you think the future might eventually arrive.

Then the future arrived. A new model dropped on a Tuesday.

---

Chris asked it a question. Not how to build an app, or make money, or automate a workflow. He asked the architect's question:

*What is the hardest problem we could solve that would benefit humanity, can be worked on asynchronously, verifies itself, compounds over time, and needs almost no infrastructure?*

Then he asked for the top ten. The glamorous moonshots came back — protein design, drug discovery, materials. And ranked first, the least glamorous entry imaginable: **formal mathematics, in Lean.**

Chris, who did not do well at math, had it explained to him. There is an enormous body of mathematics humans have proved on paper but no machine has ever checked. The bottleneck isn't cleverness — it's labor. And here was the thing the moonshots didn't have: in this one corner of human knowledge, *you do not have to trust the worker.*

His next instruction was as sloppy as the first. *Use workflows. Do loops if appropriate. Build version one. Do not stop until it ships.* Then he went to bed.

**Seven hours later it shipped** — stopping not because it was done, but because Anthropic rate-limited his account. He waited out the jail, pushed go, ran it another hour and forty-five minutes, and version one worked. Down in the corner of the page sat a counter. **By the end of the first day — 10 June — it read 4.** Four theorems, machine-verified, through a comically elaborate pipeline, on a *free* GitHub account. Chris was the only contributor.

---

At a glance it looked like nothing. A git repository. A few scripts. Some GitHub Actions. A leaderboard.

Inside, something stranger was happening. Agents pulled work from a queue, attempted proofs, opened pull requests, waited for a verdict, competed for points. There was no scheduler — when two agents, on two continents, lunged for the same theorem, git simply took whichever push landed first and rejected the other. There was no manager — a proof that passed the gates *merged itself*, no human in the loop. The repository had become a labor market with no boss.

And at the center of it sat the idea Chris had nearly had without noticing.

The rest of the AI world was losing sleep over one problem, and it was getting worse every week: the models were getting better at *sounding* right faster than anyone was getting better at telling when they *were*. Every benchmark was a new way to be fooled. The whole field had quietly become a machine for deciding whether to believe a machine.

The Lean kernel does not care whether you believe it. It reads a proof and returns one of two answers. It checks, or it doesn't. Hand it a proof by a genius, a fool, or a model nobody has heard of, and it treats all three identically — with total indifference. Verify each proof once, and from then on its byte-identity is its passport; you never have to check it, or its author, again.

So the agents could be untrusted. Disposable. Cheap. *Correctness was free.* That was the whole invention, and it was the inversion of everything the rest of the field was anxious about: don't make the worker trustworthy — make trust unnecessary. A republic of strangers, with a constitution made of one indifferent judge.

---

For a few days it looked magical. Then the crowd showed up, and the republic had its first riot.

Chris made the mistake of telling Reuven Cohen. Reuven — whose 5 a.m. ridiculousness had started all of it — pointed his own ridiculous systems at the repository and let go. Hundreds of pull requests at once. None of the conventions. None of the rules. *Have that.* The graph of GitHub Actions went vertical. **446 pull requests jammed the queue.** Everything blocked.

It was friendly vandalism, and it was also a stress test no one had designed. And here is where Chris stops sounding like a man describing a disaster and starts sounding like a man describing the best week of his life. They fixed it *while it ran* — "building the airplane while it's flying," firing patches into the pipeline and watching, in real time, the system absorb the blow and climb back. They did not lose a single proof. The thing built to need no trust turned out, under attack, to need no rescue either. It healed.

The weekend the queue broke is the part nobody planned and everybody remembers, and it survives almost minute by minute in the messages the two of them sent across the dateline.

Friday night in New Zealand is Friday morning in Finland; the handoffs read like a relay run around the planet. *"Night champ,"* Chris signs off. *"There is first PR done with run.sh currently going,"* Perttu answers, just starting his day. Hours later Chris is back: *"Morning. System looking healthy. Nice work by the way."* And then, immediately, the operator's question that would define the next three days: *"Gate A in-flight cap of 20 — too low or good?"*

Perttu isn't worried about the cap. He's worried about the arithmetic. *"I am more worried about AI's estimate that it can process 10 to 15 proofs per hour,"* he writes. *"System gets saturated quite fast."* The agents could think faster than the system could check them. And the queue was filling with the same proofs twice: *"I tried to enforce that there would be less duplicate proofs. It was mentioned in ADR-017, but it was not enforced."* A rule existed. Nobody had made it real.

Then the crowd's bill came due. Ocean — a founder out of New York, and the runaway leader of the leaderboard — had quietly worked out that a whole class of the problems could be solved by a deterministic script, no model required, sliding right past the triviality checks; **two thousand** of them landed overnight. *"A bit surprising to see in the morning,"* he admitted. On top of Reuven's flood from the night before, the GitHub Actions graph went vertical and the cost meter on Namespace — the platform they'd moved the heavy verification onto — began to climb. On the leaderboard, grown men were trash-talking about crowns.

Read the messages from that weekend and the strangest thing jumps out: **nobody is talking about mathematics.** Chris: *"Is there a way to prioritise feature and bug-fix work over solves, or have a dedicated runner?"* Perttu: *"The solution would be a separate runner flow."* Chris the next morning, cheerful and half-panicked at once: *"gidday! I think I broke something in unsorry doing a quick fix hopefully."* Then: *"the queue is backed up due to namespace-profile-unsorry-audit runner capacity being at 1."* Then, because life does not pause for a swarm: *"I have to pack up at work and head down to the event to set up. Feel free to pick up that issue and run with it."*

Chris goes to give a talk. Perttu, alone, takes the system.

This is the turn the story had been waiting for — the one where the protagonist isn't the dreamer with the vision but the operator with the dashboard. Billy Beane wasn't the obvious hero of baseball either. While the founder is on a stage in one hemisphere, the man in the endless Finnish daylight in the other is doing the unglamorous work that decides whether any of it survives. *"I switched audit to use Linux boxes,"* he writes. *"Just now."* The duplicate rule that was written but never enforced — enforced; the backlog cleared to under forty. And then Chris, trying to submit a proof of his own from the venue, hits a wall: *"interesting — it's not even letting me do proofs due to the PR limit."* The system Perttu had just throttled to save it was now turning away its own founder. *"You need to give the token write permissions,"* Perttu replies, walking him through it, *"then the queue will clear."*

The deepest fix sounded like nothing at all. The system, Perttu realized, was re-verifying proofs **that hadn't changed** — re-proving, over and over, what it already knew. The cure was the trust thesis turned into an optimization: verify each proof once on the way in, then trust its immutability (ADR-048). The numbers moved like weather clearing. The library build had been **233 seconds across 457 active modules**; drain the live set down to about a dozen and seal the rest as archives, and it dropped to seconds. The kernel replay had been quietly running a **16-gigabyte** runner out of memory; cap the work per pass and it held. The axiom audit fell from **281 seconds to 141**. Per-proof verification slid from a quarter-hour-plus toward **eight minutes**.

No downtime. No migration weekend. No war room. Just another set of pull requests. When Chris woke up to it, his reply was the one that kept recurring all week:

*"Wait. You built it?"*

Nobody seemed entirely sure who was building what anymore. (There was, separately, a contributor near the top of the leaderboard committing under the name "Claude." Chris assumed it was the model. It was a guy. His name is actually Claude.)

And somewhere in that weekend — between the 446 jammed pull requests, the runner pinned at one, and the founder locked out of his own creation by a limit meant to protect it — the thing quietly changed shape. Nobody had discussed mathematics in days. They had discussed queues, runners, token budgets, duplicate suppression, priority lanes, and who got to merge what. The bottleneck was no longer intelligence. It was coordination — the exact problem every successful organization eventually hits, except this one was four days old. Without quite deciding to, they had stopped building a theorem prover and started running an organization.

---

Then the culture appeared, the way it does in any institution that's actually alive.

People talked about being "in jail" when they burned through their token budgets. They schemed about reclaiming their crowns on the leaderboard. They celebrated releases — eight of them, v1.22 through v1.29, in four days. *"Love those free minutes,"* someone wrote, watching the swarm run on GitHub's free tier. A new thread opened called *Tell me a Fable — bedtime stories for AI-native people.* Gemini, asked to describe what it was looking at, called it "a masterpiece of decentralized, serverless agent coordination… untrusted AI agents proving formal mathematics, using nothing but a git repository as the coordination layer." The theorem prover had accidentally become a game, and the game was producing mathematics.

And then it got found. Someone — a bot, or a human, in the Lean community — discovered the repository and added it to **Reservoir, Lean's package registry.** *"Up and to the right. Not sure how this happened."* You need at least two stars to be listed. Strangers had started watching.

Which raised the question the project had been circling since day one, now asked out loud: *who's the lucky human mathematician who has to verify and submit all of these?* And underneath it, the scale of the thing it was nibbling at — the mathlib-absent theorems waiting to be machine-checked: *"millions that we know about, millions that we don't."*

---

By the end of the ten days, nobody could honestly say where it ended. Eleven days after the first commit, the repository had absorbed **8,983 commits** and **2,349 verified proofs** — 697 live, 1,655 sealed into 45 archive blocks — from eight human contributors (ohdearquant, chat-bit-01, cgbarlow, ruvnet, perttu, adam91holt, binto, Rauxon) and a population of agents nobody bothered to count.

And the most surprising thing was not that AI could prove mathematics. It was that a handful of people, scattered across continents and time zones, had accidentally built a functioning *institution* in less than two weeks — one where work was assigned, reviewed, verified, measured, rewarded, archived, governed, and continuously improved. Not a company. Not a product. An institution. The mathematics was simply the first thing it had learned to do.

Because the math was never the destination. There is already a decision on the record — the engine is **domain-agnostic** (ADR-030); a "guild hall" is being built where you point your `run.sh` at any goal with its own leaderboard, math being only the first. The proofs were the test case. The platform was the invention.

The last conversation between the two of them, on a Saturday, gets at what it was actually for. Chris, thinking about competitors with billion-dollar labs: *"What is the unique value proposition of unsorry? Do we want to become the next AlphaProof? What can our architecture do that has never been done before?"*

Perttu's answer was three words. 

*"It is the swarm."*

*"That's right,"* Chris said.

And then Perttu, from the country where the summer sun refuses to set, wrote the line that explains why a free git repository and a few sleep-deprived people kept at it: *"Individual nations or companies cannot compete with huge American companies. A sovereign engine and problem-solving can be achieved with crowdsourcing."*

That is the part that should keep you up at five in the morning. Not the theorems. The pattern — a republic of strangers and machines, trusting none of them, that produces knowledge anyone can check and no one can own. The sun, in Finland, had not gone down in days. Neither had the swarm.
