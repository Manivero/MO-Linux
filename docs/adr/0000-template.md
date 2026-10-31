# ADR NNNN — Title

- **Status:** Proposed / Accepted / Superseded by ADR-XXXX / Deprecated
- **Date:** YYYY-MM-DD
- **Phase origin:** Phase 0 (or later)
- **Decision owner:** Project owner (per Project Initiation v2 §8) / Technical lead (autonomous)
- **Confidence:** Hypothesis / Measured / Verified

## Context

What problem are we solving? What constraints apply? What is the relevant project priority from §2 of Project Initiation v2?

## Options considered

List each candidate with its trade-offs. For technical decisions the comparison must include at least: idle RAM impact, boot-time impact, hardware-compatibility impact, support cost, license implications.

| Option | Pros | Cons |
|---|---|---|
| A | … | … |
| B | … | … |

## Decision

The chosen option, in one sentence, with the version (if pinned) and the date the upstream state was checked.

## Rationale

Why this option over the others, against the §2 priority order (reliability > performance > RAM > compatibility > boot time > UX > modularity > own code only if measured).

## Consequences

- Positive: …
- Negative: …
- Risks: …

## Revisit triggers

Concrete measurable conditions under which this decision will be revisited. E.g. "if Phase 5 measurement shows systemd idle RSS > 50 MB on the Legacy profile, reopen ADR-0001".

## Verification plan

How we will know this decision holds up: build test, QEMU test, hardware test, benchmark — each with the script or document path that proves it.
