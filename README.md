# Productivity OS

> A real-world case study of building a productivity application with Specification-Driven Development (SDD) and an AI engineering team.

[Live Demo](https://routmartin-productivityos.vercel.app)

Productivity OS is a personal productivity workspace built around tasks, projects, goals, daily planning, focus sessions, and AI assistance.

This repository is intentionally more than a product repository. It is also a learning resource for developers who want to understand how SDD and AI agents can be used together to build a real application from idea to production.

---

## What is Productivity OS?

Productivity OS is designed to answer one simple question:

> **What should I focus on, and why does it matter?**

The product connects several layers of personal productivity:

```text
Goal
  ↓
Project
  ↓
Task
  ↓
Daily Plan / Top 3
  ↓
Focus Session
  ↓
Progress & Review
  ↓
AI Insights
```

The idea is to move beyond a simple to-do list.

A task tells you **what** to do.

A project gives the task **context**.

A goal explains **why it matters**.

A daily plan determines **when it matters**.

A focus session helps you **actually do it**.

AI then helps you **understand patterns and make better decisions**.

---

## Who is this repository for?

This repository is primarily for developers who want to learn:

- Specification-Driven Development (SDD).
- How to work with coding agents as an engineering team.
- How an AI agent can implement software from specifications rather than a single giant prompt.

It is especially useful for someone asking:

> "How do I actually use SDD on a real application?"

rather than:

> "What is SDD in theory?"

The repository shows the documents, decisions, plans, implementation workflow, reviews, UI process, and deployment journey as they evolved during the project.

---

## Why I built it this way

This project started as a real product idea, but it also became an experiment:

> **Can a developer use AI agents as part of a disciplined engineering process instead of simply asking an agent to build an entire application from one enormous prompt?**

The answer turned out to be more nuanced than I expected.

The project showed both the strengths and the weaknesses of SDD.

### What worked well

Clear specifications helped keep product behavior from being invented by the coding agent.

Architecture decisions gave the agents boundaries to work within.

A separate review agent made it easier to catch issues that the implementation agent missed.

Small vertical slices made it possible to understand what was actually being built.

### What did not work perfectly

The project also spent too much time documenting and refining decisions before enough code existed.

Some early specifications became much more detailed than they needed to be.

That experience changed the way the project uses SDD:

> **Use documentation to remove meaningful ambiguity, not to document every possible future decision.**

The goal is not maximum documentation.

The goal is enough shared context for humans and agents to work safely and consistently.

---

# The SDD Journey

The repository follows this general flow:

```text
Idea
  ↓
Specification
  ↓
Review / Reconciliation
  ↓
Architecture Decisions
  ↓
Implementation Plan
  ↓
Coding Agent
  ↓
Review Agent
  ↓
Fix
  ↓
Verification
  ↓
Deployment
```

The exact process evolved during development, but this is the core learning path.

---

## 1. Start with the problem

The first step is not:

> "Build a task manager."

It starts with understanding the product problem and the behavior we want.

For example:

- What does a task mean?
- Can a task belong to a project?
- What happens when a task is completed?
- Can a completed task be reopened?
- What does deletion mean?
- What should Top 3 contain?

These questions become product decisions rather than coding decisions.

---

## 2. Write the specification

The specifications define product behavior before implementation.

Examples include:

```text
docs/specs/
├── users/
│   └── user-management.md
├── tasks/
│   └── task-management.md
├── projects/
├── goals/
├── planning/
├── focus/
├── ai/
└── ui/
```

A specification generally describes:

- Problem.
- Goal.
- User story.
- Behavior.
- Rules.
- Constraints.
- Acceptance criteria.
- Edge cases.
- Out of scope.
- Dependencies.
- Open questions.

The important idea is:

> **The specification describes what the product should do.**

It is not an implementation tutorial.

---

## 3. Reconcile specifications

Specifications are not isolated documents.

For example, Daily Top 3 depended on Task lifecycle behavior.

That exposed a conflict around whether a completed task could be reopened.

The specifications were reconciled before implementation rather than letting the coding agent decide.

This is an important part of SDD:

```text
Spec A
   ↕
Spec B
   ↕
Shared behavior
```

The goal is to make the system consistent before code hardens the assumptions.

---

## 4. Architecture decisions

After the core behavior becomes clearer, architectural decisions can be made.

The project uses ADRs (Architecture Decision Records) for significant decisions.

Examples include:

```text
docs/decisions/
├── ADR-001 ...
├── ADR-002 technology stack
├── ADR-003 database & persistence
├── ADR-004 authentication & user isolation
├── ADR-005 API architecture
└── ADR-006 time & timezone
```

The architecture selected for the project is:

```text
Vue 3 + TypeScript
        │
        ▼
Spring Boot + Kotlin
        │
        ▼
PostgreSQL
```

The backend is a modular monolith rather than a collection of microservices.

The important lesson here is:

> **Architecture decisions answer how the system should be built.**

Specifications answer what the product should do.

---

# AI Engineering Team

One of the most useful parts of this project is the use of multiple coding agents with different responsibilities.

The workflow became:

```text
                 Human
                   │
             Product intent
                   │
                   ▼
              OpenCode
              Engineer
                   │
                   ▼
             Implementation
                   │
                   ▼
               Cline
               Reviewer
                   │
                   ▼
          Review / Findings
                   │
                   ▼
              OpenCode
              Fix issues
```

## OpenCode — Engineer

OpenCode is primarily responsible for implementation.

It reads:

- Specifications.
- ADRs.
- Architecture.
- Plans.
- Existing code.

Then it implements the requested slice.

The important rule is:

> **OpenCode does not invent product behavior when the specification is ambiguous.**

It should stop and surface the ambiguity.

## Cline — Reviewer

Cline acts as a second pair of engineering eyes.

The review focuses on:

- Specification compliance.
- Architectural boundaries.
- Security.
- Code quality.
- Missing behavior.
- Regressions.
- Implementation risks.

The reviewer does not replace the product owner.

It reviews the implementation against the agreed intent.

## Agent handoff

The repository also contains tooling to let the agents communicate through files instead of requiring the human to manually paste large amounts of context.

The general workflow is:

```text
OpenCode
   ↓
implementation
   ↓
agent review script
   ↓
Cline
   ↓
review file
   ↓
OpenCode reads review
   ↓
fixes
```

This turned the agents into a small engineering team instead of two independent chat sessions.

---

# Implementation Strategy

The project uses vertical slices rather than implementing the entire system layer by layer.

A vertical slice aims to make a real piece of product behavior work end-to-end.

For example:

```text
Register User

UI
 ↓
HTTP API
 ↓
Application Service
 ↓
Domain
 ↓
Persistence
 ↓
PostgreSQL
```

Another slice:

```text
Create Task
 ↓
List Task
 ↓
Plan
 ↓
Start
 ↓
Complete
 ↓
Delete / Restore
```

This approach made it possible to get working software early and gave the AI agents a smaller context to reason about.

---

# UI Development Journey

The frontend was intentionally developed separately from API integration.

The process was:

```text
Visual reference
      ↓
UI specification
      ↓
Mock data
      ↓
Browser implementation
      ↓
Human visual review
      ↓
Refinement
      ↓
Real API integration
```

This was an important decision.

Instead of forcing the UI to match whatever backend endpoints happened to exist at the moment, the product experience was designed first.

The UI evolved through several visual iterations.

The final direction moved from a dense SaaS-style dashboard toward a more spacious productivity workspace:

- Larger typography.
- More whitespace.
- Larger interaction surfaces.
- Stronger hierarchy.
- Less visual density.
- Comfortable desktop reading.
- More visual use of time and space.

The same visual language is then adapted for mobile rather than simply shrinking the desktop interface.

---

# Backend Architecture

The backend follows a layered structure:

```text
HTTP
 ↓
Controller
 ↓
Application Service
 ↓
Domain
 ↓
Repository
 ↓
PostgreSQL
```

For example:

```text
POST /api/v1/tasks
        ↓
TaskController
        ↓
CreateTaskService
        ↓
Task domain model
        ↓
TaskRepository
        ↓
PostgreSQL
```

A few important ideas used throughout the backend:

### Layered Architecture

Responsibilities are separated into clear areas rather than placing everything in controllers.

### Dependency Injection

Spring creates and wires dependencies rather than classes constructing their own infrastructure.

### Repository Pattern

Database access stays behind repository interfaces.

### DTOs

HTTP request/response representations are kept separate from persistence entities.

### Domain State Machines

Task, Project, and Goal lifecycle transitions are represented explicitly rather than allowing arbitrary status changes.

### Transactions

Application operations use transaction boundaries so related persistence changes succeed or fail together.

### Authentication Boundary

Authenticated identity comes from the server-side security context rather than client-supplied user IDs.

---

# Deployment Journey

The application eventually became a real deployed system.

The production architecture is:

```text
                    Internet
                       │
          ┌────────────┴────────────┐
          │                         │
          ▼                         ▼
        Vercel                 Google Cloud Run
      Vue frontend             Spring Boot API
                                      │
                                      ▼
                               Neon PostgreSQL
                                      │
                                      ▼
                              Google Secret Manager
```

## Frontend

The Vue application is deployed to Vercel.

Production configuration uses:

```text
VITE_API_BASE_URL
```

so the frontend does not hardcode the backend URL.

## Backend

The Spring Boot application is packaged as a Docker image.

The deployment flow is:

```text
Dockerfile
   ↓
Docker image
   ↓
Artifact Registry
   ↓
Cloud Run
```

The Cloud Run service runs in the Singapore region and uses:

- 1 vCPU.
- 512 MiB memory.
- Minimum instances: 0.
- Maximum instances: 1.

This is intentionally small because Productivity OS is currently a low-traffic personal application.

## Database

Production PostgreSQL is hosted on Neon.

Flyway manages schema migrations.

Secrets such as:

- Database credentials.
- JWT secret.

are stored in Google Secret Manager rather than committed to the repository.

## Authentication in production

Because the Vercel frontend and Cloud Run backend are separate origins, production authentication required:

- CORS configuration.
- Credentialed requests.
- Secure HttpOnly refresh cookies.
- `SameSite=None` for the production refresh cookie.

This was a real deployment issue discovered during integration and fixed before the production frontend was connected.

---

# Deployment Lessons

The deployment process also exposed several practical lessons.

### ARM vs AMD64

The development machine built an ARM Docker image, while Cloud Run required an image compatible with the deployment architecture.

The first deployment failed with an `exec format error`.

The fix was to build explicitly for Linux AMD64:

```bash
docker build --platform=linux/amd64 ...
```

This is a good example of why a local build succeeding does not necessarily mean a production container will run.

### CORS

Local development did not reveal the production cross-origin behavior because the frontend used a development proxy.

Once the frontend and backend were separated into Vercel and Cloud Run, CORS became a real production concern.

### SameSite cookies

The refresh token initially used `SameSite=Strict`.

That worked locally but prevented the browser from sending the refresh cookie across the production frontend/backend boundary.

The production configuration was changed to use `SameSite=None; Secure; HttpOnly`.

These problems were not theoretical architecture exercises. They were discovered by deploying the real application.

---

# Local Development

## Prerequisites

You will need:

- Node.js compatible with the frontend toolchain.
- pnpm.
- JDK 21.
- Docker.
- PostgreSQL through Docker Compose.
- Google Cloud CLI only if you want to reproduce the deployment workflow.

## Start PostgreSQL

```bash
docker compose up -d
```

## Start the backend

```bash
./gradlew :apps:api:bootRun
```

The API runs locally on:

```text
http://localhost:8080
```

Health check:

```text
GET /api/v1/health
```

## Start the frontend

```bash
cd apps/web
pnpm install
pnpm dev
```

The frontend uses the local Vite development configuration and talks to the local API through the configured development proxy.

---

# Repository Structure

The repository is organized around the product and its development process.

```text
.
├── apps/
│   ├── api/              # Spring Boot backend
│   └── web/              # Vue frontend
│
├── docs/
│   ├── architecture/     # System/domain architecture
│   ├── decisions/        # ADRs
│   ├── plans/            # Implementation plans
│   ├── specs/            # Product specifications
│   └── reviews/          # Engineering/review artifacts
│
├── scripts/
│   └── agent-review.sh   # OpenCode → Cline review handoff
│
├── .cline/
│   └── rules/            # Reviewer behavior
│
├── .opencode/
│   └── commands/         # OpenCode commands
│
├── docker-compose.yml
├── Dockerfile
└── README.md
```

---

# How to Read This Repository

If you are studying the project, don't start by reading every file.

Follow the development journey.

## Step 1 — Understand the product

Start with the specifications:

```text
docs/specs/
```

Pick one feature such as Tasks.

Understand:

- What problem it solves.
- What the rules are.
- What the lifecycle is.
- What the acceptance criteria are.

## Step 2 — Understand the architecture

Read:

```text
docs/architecture/system.md
docs/architecture/domain.md
```

Then look at the relevant ADRs.

You should now understand both:

```text
WHAT the product does
```

and:

```text
HOW the system is organized
```

## Step 3 — Look at the implementation plan

Read:

```text
docs/plans/
```

This shows how a specification was turned into an implementation sequence.

## Step 4 — Inspect the implementation

Only now jump into:

```text
apps/api/
apps/web/
```

Trace one vertical slice.

For example:

```text
POST /api/v1/tasks
```

and follow:

```text
Controller
 → Service
 → Domain
 → Repository
 → Database
```

## Step 5 — Read the review

Look at:

```text
docs/reviews/
```

This shows what an independent review agent found after implementation.

That is an important part of the learning process.

---

# How to Work With the Agent Team

A useful workflow for your own projects can look like:

```text
Human
  │
  ├── Define product intent
  │
  ▼
Specification
  │
  ▼
Architecture / ADR
  │
  ▼
Implementation Plan
  │
  ▼
OpenCode
  │
  ├── Read specs
  ├── Implement
  └── Report
  │
  ▼
Cline
  │
  ├── Review
  ├── Find defects
  └── Check spec compliance
  │
  ▼
OpenCode
  │
  └── Fix
  │
  ▼
Human verification
```

The human remains responsible for product intent and important architectural decisions.

Agents help with implementation and verification.

---

# What I Learned From This Project

The biggest lesson was not a specific framework.

It was learning **where structure helps and where structure becomes overhead**.

## 1. SDD is not "write everything before coding"

Specifications are valuable when they remove ambiguity.

They become expensive when they try to predict every future detail.

A good rule is:

> **Specify behavior that matters. Defer implementation detail until it is needed.**

## 2. Agents need boundaries

A capable coding agent can implement an impressive amount of software.

But without clear boundaries it can also make decisions that were never intended.

Specifications, ADRs, and review agents reduce that risk.

## 3. Small slices beat giant prompts

A giant prompt can produce a lot of code quickly.

But small slices make it easier to:

- understand what changed.
- review the result.
- identify defects.
- keep context under control.
- let different agents collaborate.

## 4. Review agents are valuable

An implementation agent naturally focuses on making the requested task work.

A second agent looking specifically for defects provides a different perspective.

That separation worked particularly well for this project.

## 5. Real deployment teaches different lessons

Some problems only appeared when the system became real:

- container architecture.
- CORS.
- browser cookie policies.
- Cloud Run runtime behavior.
- production secrets.
- managed database connectivity.

That is why getting software deployed early is still valuable even when the UI and architecture are evolving.

---

# Current Status

The project is currently deployed.

### Frontend

[Vercel](https://routmartin-productivityos.vercel.app)

### Backend

Google Cloud Run

### Database

Neon PostgreSQL

### Development status

The repository contains the implemented backend, the frontend workspace, UI specifications, architecture decisions, implementation plans, agent-review workflow, and deployment configuration.

The product is still evolving.

---

# Roadmap

The roadmap is intentionally flexible.

Potential future work includes:

- More complete Daily Planning.
- Daily Top 3 integration.
- Focus Session integration.
- AI capabilities.
- Weekly Review.
- Mobile experience.
- Deeper progress insights.
- Better offline/resilience behavior.
- Production observability.
- Automated CI/CD.

The project may change direction as real usage reveals what is actually useful.

---

# License

This project is licensed under the MIT License.

See [LICENSE](LICENSE) for details.

---

# Final Note

Productivity OS is not presented as a perfect example of SDD.

It is a **real case study**.

There were points where the process became too heavy.

There were decisions that had to be revisited.

There were conflicts between specifications.

There were deployment problems.

There were moments where a simpler approach would have been faster.

Those mistakes are part of the repository's value.

If you are learning SDD or experimenting with AI coding agents, don't copy this process blindly.

Instead, study the journey and ask:

> **Which parts of this process create real leverage for my project, and which parts are just ceremony?**

That question is probably more important than any individual tool or design pattern.
