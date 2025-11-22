# Maintainers

This document lists the maintainers of the Complete Linux Internet Repair Tool project.

## Active Maintainers

### Project Lead

**[Your Name]** (@[your-github-username])
- **Role**: Project Lead, Primary Maintainer
- **Responsibilities**:
  - Overall project direction and vision
  - Architecture decisions
  - Release management
  - Security response coordination
  - Final decision authority on contentious issues
- **Focus Areas**: All
- **Contact**: [your-email@example.com]
- **Timezone**: [Your Timezone]
- **Since**: 2025-01-22

## Maintainer Responsibilities

Maintainers are responsible for:

1. **Code Review**: Review and merge pull requests
2. **Issue Triage**: Label, prioritize, and respond to issues
3. **Security**: Respond to security reports and coordinate fixes
4. **Releases**: Tag and publish releases
5. **Community**: Enforce Code of Conduct, welcome newcomers
6. **Documentation**: Keep docs up-to-date
7. **Testing**: Ensure test quality and coverage
8. **Communication**: Regular status updates to community

## Maintainer Levels

### L1: Core Maintainer (Currently: 1)
- Full commit access to main branch
- Can merge PRs and manage releases
- Security incident response authority
- Voting rights on project direction

### L2: Module Maintainer (Currently: 0)
- Expert in specific module (diagnostics, repairs, etc.)
- Review authority for their module
- Can approve PRs in their domain
- Recommended for promotion to L1

### L3: Reviewer (Currently: 0)
- Trusted community member
- Can review and approve PRs
- No direct commit access
- In training for L2

## Becoming a Maintainer

We follow the TPCF (Tri-Perimeter Contribution Framework) for trust progression:

### Path to L3 Reviewer
- **Requirements**:
  - 10+ substantial contributions (PRs, issues, reviews)
  - Demonstrated code quality and testing practices
  - Positive community interactions
  - Understanding of project architecture
  - 3+ months of consistent participation
- **Nomination**: Current maintainers nominate, consensus required
- **Perimeter**: Promotion from TPCF Perimeter 3 to Perimeter 2

### Path to L2 Module Maintainer
- **Requirements**:
  - Expert knowledge in specific module
  - 25+ contributions, including major features
  - Consistent high-quality code reviews
  - Documentation contributions
  - 6+ months as L3 Reviewer
- **Nomination**: L1 maintainers nominate, consensus required
- **Perimeter**: Perimeter 2 with expanded privileges

### Path to L1 Core Maintainer
- **Requirements**:
  - Deep understanding of entire codebase
  - Security awareness and response capability
  - Demonstrated leadership and community building
  - Release management experience
  - 50+ contributions across all areas
  - 12+ months as L2 Module Maintainer
- **Nomination**: Existing L1 maintainers vote, unanimous required
- **Perimeter**: Promotion to TPCF Perimeter 1

## Maintainer Meetings

- **Frequency**: Monthly (or as needed)
- **Format**: Async-first (GitHub Discussions), sync if needed
- **Agenda**: Project roadmap, security issues, community health
- **Notes**: Published in `docs/meetings/` directory

## Decision Making

### Consensus Model

We use **lazy consensus** for most decisions:

1. **Proposal**: Anyone can propose via issue/PR
2. **Discussion**: Minimum 72 hours for feedback
3. **Objections**: If no objections, proposal accepted
4. **Disagreement**: If objections, discuss to consensus
5. **Escalation**: If no consensus, maintainer vote (simple majority)
6. **Final Call**: Project Lead can make final decision if needed

### Voting

When voting is required:

- **Quorum**: 50%+ of L1 maintainers must participate
- **Threshold**: Simple majority (>50%) for most issues
- **Supermajority**: 2/3+ for:
  - Adding/removing maintainers
  - Major architecture changes
  - License changes
  - Code of Conduct changes

## Emeritus Maintainers

Maintainers who have stepped down but contributed significantly:

*None yet - founding project*

## Adding/Removing Maintainers

### Adding
1. Nomination by current L1 maintainer
2. Review of contributions and community engagement
3. Vote by L1 maintainers (supermajority required)
4. Update MAINTAINERS.md and repository permissions
5. Announcement to community

### Removing
Maintainers may be removed for:
- **Inactivity**: No activity for 6+ months (emeritus status offered)
- **Code of Conduct violation**: Serious or repeated violations
- **Abandonment**: Announced departure from project
- **Request**: Maintainer requests to step down

Process:
1. Discussion among L1 maintainers
2. Attempt to contact maintainer (if inactive)
3. Vote (supermajority required for CoC violations)
4. Update MAINTAINERS.md and revoke access
5. Announcement with gratitude for contributions

## Contact

- **General**: Open an issue on GitHub
- **Security**: See SECURITY.md for reporting vulnerabilities
- **Private**: [maintainers@project-domain.com] (if available)
- **Code of Conduct**: See CODE_OF_CONDUCT.md for reporting

## Maintainer Emeritus

When maintainers step down, they are honored here with emeritus status:

| Name | GitHub | Role | Active Period | Notable Contributions |
|------|--------|------|---------------|----------------------|
| *Awaiting first emeritus maintainer* | | | | |

## Recognition

We thank all maintainers for their service to the community. Maintainership is
a responsibility, not a privilege, and we honor those who take it on.

---

**Last Updated**: 2025-01-22
**Governance Model**: TPCF + Lazy Consensus
**Version**: 1.0
