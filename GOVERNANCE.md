# Governance

## Project Lead

This project is led by **SeaMc** as the Project Lead, responsible for:

- Final decisions on ISA design
- Release cadence
- Maintainer appointments
- Dispute arbitration

## Decision Making

### ISA Design Changes

The ISA is the foundation of this project. Any design changes must go through:

1. Open an Issue describing the motivation and proposal
2. Public discussion (at least 7 days, unless it is an urgent fix)
3. The Project Lead makes the final decision and provides rationale

### Code Merging

- General code changes: merged after review by at least one maintainer
- Core module changes (`fpd.v`, `usexc.v`, `retire.v`, `cu.v`): require confirmation from the Project Lead
- ISA-related changes: require synchronized updates to both documentation and code, and confirmation from the Project Lead

### Dispute Resolution

When disagreements cannot be resolved through discussion, the Project Lead makes the final decision. The decision will be recorded in the relevant Issue.

## Maintainers

| Role | Name | Contact |
|---|---|---|
| Project Lead | SeaMc | sauthm_2015@qq.com |
| Maintainer | -- | -- |

Maintainers are appointed by the Project Lead. Contributors may be considered after meeting the following criteria:

- Consistent contributions for at least 3 months
- Implementation of at least 5 instructions or equivalent work
- Participation in code reviews
- Understanding of ISA design intent and project direction

## Becoming a Maintainer

If you have consistently contributed to this project and wish to become a maintainer, please open an Issue expressing your interest. The Project Lead will evaluate your contribution history and level of involvement.

## Code of Conduct

All participants must abide by the [Code of Conduct](CODE_OF_CONDUCT.md). Violators may be disqualified from participation.

---

*This document may be revised at any time. Revisions require approval from the Project Lead and must be announced in the repository.*
