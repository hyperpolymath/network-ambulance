# TPCF: Tri-Perimeter Contribution Framework

## Overview

The Complete Linux Internet Repair Tool uses the **Tri-Perimeter Contribution Framework (TPCF)** for graduated trust and contribution management. TPCF recognizes that not all contributions carry equal risk, and contributors earn trust over time through demonstrated competence and community alignment.

## The Three Perimeters

```
┌─────────────────────────────────────────────────────────┐
│                   PERIMETER 1                           │
│                 Maintainer Core                         │
│           (Highest Trust, Full Access)                  │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │              PERIMETER 2                          │ │
│  │          Trusted Contributors                     │ │
│  │      (Elevated Trust, Expanded Access)            │ │
│  │                                                   │ │
│  │  ┌─────────────────────────────────────────────┐ │ │
│  │  │           PERIMETER 3                       │ │ │
│  │  │       Community Sandbox                     │ │ │
│  │  │  (Open Access, Protected Environment)       │ │ │
│  │  │                                             │ │ │
│  │  │  All Contributors Start Here!               │ │ │
│  │  │                                             │ │ │
│  │  └─────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Perimeter 3: Community Sandbox

**Who**: All new contributors, anyone can join
**Trust Level**: Public trust (assume good intent, verify actions)
**Access**: Full read, pull requests for write

### What You Can Do

- ✅ Fork the repository
- ✅ Submit pull requests (docs, code, tests)
- ✅ Open issues and feature requests
- ✅ Comment on issues and PRs
- ✅ Participate in discussions
- ✅ Run and test the tool
- ✅ Report bugs and security issues
- ✅ Improve documentation
- ✅ Add examples and tutorials
- ✅ Translate documentation (i18n/l10n)

### What Happens to Your Contributions

1. **Automatic**: CI/CD runs tests on your PR
2. **Review**: Perimeter 2/1 contributors review
3. **Feedback**: Get constructive feedback
4. **Iteration**: Make requested changes
5. **Approval**: At least one P2/P1 approval required
6. **Merge**: P1 maintainer merges after approvals

### Safety Mechanisms

- PRs cannot be merged without approval
- Automated tests must pass
- Code review by trusted contributors
- Reversible changes (git revert available)
- No direct access to main branch
- Security scans on all PRs

### Progression to Perimeter 2

Demonstrated through:
- **Quality**: 10+ meaningful contributions
- **Consistency**: 3+ months of participation
- **Community**: Positive interactions, CoC alignment
- **Technical**: Understanding of codebase architecture
- **Trust**: Pattern of helpful, correct contributions

## Perimeter 2: Trusted Contributors

**Who**: Contributors with demonstrated competence and trust
**Trust Level**: Elevated trust (trusted but verified)
**Access**: Review/approve PRs, issue triage, some commit access

### What You Can Do (In Addition to P3)

- ✅ Review and approve pull requests
- ✅ Triage and label issues
- ✅ Close duplicate/invalid issues
- ✅ Mentor new contributors (P3)
- ✅ Participate in roadmap discussions
- ✅ Make non-breaking changes with review
- ✅ Update documentation directly
- ✅ Manage project boards
- ✅ Run release candidates testing

### Responsibilities

- Code review for quality, security, style
- Mentoring P3 contributors
- Upholding Code of Conduct
- Testing pre-release versions
- Documentation maintenance
- Community engagement

### Limitations

- Cannot merge own PRs (requires P1)
- Cannot make breaking changes alone
- Cannot modify security-critical code without P1
- Cannot publish releases
- Cannot change repository settings

### Progression to Perimeter 1

Demonstrated through:
- **Expertise**: Deep knowledge of entire codebase
- **Leadership**: Mentoring others, driving features
- **Reliability**: 12+ months of consistent contribution
- **Security**: Understanding of security implications
- **Community**: Positive force in community health
- **Judgment**: Sound technical decision-making
- **Nomination**: Unanimous vote by existing P1 members

## Perimeter 1: Maintainer Core

**Who**: Core maintainers with full authority
**Trust Level**: Full trust (trusted, verified, accountable)
**Access**: Full commit access, release authority, security

### What You Can Do (In Addition to P2)

- ✅ Merge pull requests to main
- ✅ Create and publish releases
- ✅ Respond to security reports
- ✅ Modify repository settings
- ✅ Add/remove collaborators
- ✅ Make breaking changes (with consensus)
- ✅ Final decision authority on contentious issues
- ✅ Enforce Code of Conduct
- ✅ Manage secrets and credentials

### Responsibilities

- Project vision and direction
- Release management
- Security incident response
- Final code review and approval
- Community health and CoC enforcement
- Maintainer meetings and coordination
- Sustainable project stewardship

### Accountability

- Transparent decision-making
- Regular communication with community
- Following project governance
- Leading by example
- Mentoring P2 and P3 contributors
- Managing conflicts of interest

## TPCF Benefits

### For Contributors

1. **Clear Path**: Know what's needed to progress
2. **Safety**: Experiment freely in P3 sandbox
3. **Recognition**: Formal recognition of trust
4. **Growth**: Develop skills through mentorship
5. **Ownership**: Earn real responsibility

### For Maintainers

1. **Risk Management**: Graduated access = reduced risk
2. **Sustainability**: Grow maintainer pool over time
3. **Quality**: Multiple review layers ensure quality
4. **Community**: Healthy pipeline of contributors
5. **Transparency**: Clear roles and expectations

### For the Project

1. **Security**: Defense in depth through layers
2. **Velocity**: More trusted reviewers = faster merges
3. **Resilience**: Bus factor > 1 through P1 growth
4. **Quality**: Peer review at every level
5. **Inclusivity**: Clear, fair path for all

## Examples

### P3 Contribution Flow

```
1. Fork repository
2. Create feature branch
3. Make changes (add dry-run mode flag)
4. Run tests locally: ./tests/run-tests.sh
5. Push and open PR
6. CI runs tests automatically
7. P2 reviewer provides feedback
8. Address feedback, push changes
9. P2 approves PR
10. P1 maintainer merges
```

### P2 Contribution Flow

```
1. Create feature branch in main repo
2. Make changes (refactor logging)
3. Self-review first
4. Open PR, tag P1 for review
5. P1 reviews, approves
6. P1 merges (or P2 merges after approval)
7. Monitor for issues
```

### P1 Contribution Flow

```
1. Create feature branch or commit directly
2. Make changes (security fix)
3. Review own code carefully
4. Merge to main (if urgent) or PR for non-urgent
5. Tag and release if needed
6. Announce to community
7. Monitor for issues
```

## Special Cases

### Security Issues

- P3: Report via SECURITY.md, do not publicize
- P2: May be consulted on fixes, under NDA
- P1: Full access to reports, coordinate response

### Breaking Changes

- P3: Propose in issue first, get buy-in
- P2: Discuss with P1, requires approval
- P1: Can approve, but seek consensus

### Documentation

- P3: PR for any docs
- P2: Can commit directly to docs/
- P1: Can commit anywhere

### Tests

- P3: Add tests with code
- P2: Can improve test infrastructure
- P1: Can modify test framework

## TPCF and Code of Conduct

TPCF enforcement of Code of Conduct:

- **P3 violations**: Warning → temporary ban → permanent ban
- **P2 violations**: Same, but may lose P2 status
- **P1 violations**: Same, plus immediate P1 revocation

Trust is earned, and can be lost. We prioritize community health over
individual contributor access at all levels.

## TPCF Evolution

This TPCF policy can be amended by:

1. Proposal by any contributor (issue/PR)
2. Discussion period (minimum 2 weeks)
3. P1 vote (supermajority 2/3+ required)
4. Update this document
5. Announce to community

## Current Status

**Perimeter 1 Maintainers**: 1 (founding maintainer)
**Perimeter 2 Contributors**: 0 (new project)
**Perimeter 3 Contributors**: All are welcome!

## Join Us!

We're actively looking for contributors at all levels. Start in Perimeter 3
today by:

1. Opening an issue with questions or ideas
2. Improving documentation
3. Adding tests
4. Fixing bugs
5. Adding features

See CONTRIBUTING.md for detailed contribution guide.

---

**TPCF Version**: 1.0
**Last Updated**: 2025-01-22
**Governance**: See MAINTAINERS.md
**Related**: CODE_OF_CONDUCT.md, CONTRIBUTING.md, SECURITY.md
