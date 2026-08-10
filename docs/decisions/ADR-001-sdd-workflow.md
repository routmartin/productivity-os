# ADR-001: Use Specification-First AI Development

## Status

Accepted

## Context

This project is both a productivity application and an experiment in AI-assisted
software development.

Unstructured agent-driven coding can make changes difficult to understand, review,
and verify.

## Decision Drivers

- Make AI changes observable.
- Reduce accidental scope expansion.
- Separate product intent from implementation.
- Make behavior testable.
- Preserve human control over important decisions.
- Produce useful data for SDD experiments.

## Options

### Option A — Prompt Directly to Code

Idea -> AI -> Code

### Option B — Specification-First

Idea -> Specification -> Plan -> Code -> Verification

### Option C — Fully Autonomous Multi-Agent Development

Idea -> Agent Team -> Code

## Decision

Use Option B as the default development workflow.

AI may challenge specifications and propose designs, but approved product intent
remains under human control.

## Reasoning

Specification-first development gives us a stable artifact against which the
implementation can be reviewed.

It also makes it possible to measure whether structured AI development reduces
rework and defects.

## Consequences

### Positive

- Better observability
- Better reviewability
- Clearer requirements
- Easier regression verification
- Stronger foundation for multi-agent experiments

### Negative

- More upfront work
- Small features require some documentation
- Workflow may feel slower initially

## Rejected Alternatives

Fully autonomous implementation is intentionally deferred until the controlled
workflow has been evaluated.

## Related Specifications

- `docs/specs/README.md`
- `docs/specs/planning/daily-top-three.md`
