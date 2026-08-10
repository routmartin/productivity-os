# System Architecture

## Status

Initial

## Purpose

Define the high-level architecture without prematurely locking implementation
details.

## Initial Architecture

```text
Client
  |
  v
Application API
  |
  +--> Domain / Application Services
  |
  +--> Persistence
  |
  +--> AI Service Boundary
```

## Architectural Principles

### Domain-first behavior

Business behavior should be represented in domain/application services rather than
being scattered across UI code.

### Clear AI boundary

AI functionality should be behind an explicit service boundary so deterministic
product behavior remains testable without an LLM.

### Specification traceability

Important behavioral changes should be traceable from specification to tests and
implementation.

### Small vertical slices

Features should preferably be implemented end-to-end in small, reviewable slices.

## Current Technology Decision

No application framework is mandated by the SDD foundation.

Technology choices should be captured in ADRs once the implementation stack is chosen.
