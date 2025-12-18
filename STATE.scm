;;; STATE.scm - Project Checkpoint
;;; complete-linux-internet-repair
;;; Format: Guile Scheme S-expressions
;;; Purpose: Preserve AI conversation context across sessions
;;; Reference: https://github.com/hyperpolymath/state.scm

;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

;;;============================================================================
;;; METADATA
;;;============================================================================

(define metadata
  '((version . "0.2.0")
    (schema-version . "1.0")
    (created . "2025-12-15")
    (updated . "2025-12-17")
    (project . "complete-linux-internet-repair")
    (repo . "github.com/hyperpolymath/complete-linux-internet-repair")))

;;;============================================================================
;;; PROJECT CONTEXT
;;;============================================================================

(define project-context
  '((name . "complete-linux-internet-repair")
    (tagline . "A comprehensive, automated toolkit for diagnosing and repairing internet connectivity issues on Linux systems.")
    (version . "0.2.0")
    (license . "AGPL-3.0-or-later")
    (rsr-compliance . "gold")

    (tech-stack
     ((primary . "Bash 4.0+")
      (ci-cd . "GitHub Actions (SHA-pinned) + GitLab CI + Bitbucket Pipelines")
      (security . "CodeQL + OSSF Scorecard + TruffleHog + ShellCheck")))))

;;;============================================================================
;;; CURRENT POSITION
;;;============================================================================

(define current-position
  '((phase . "v0.2 - Security Hardening Complete")
    (overall-completion . 45)

    (components
     ((rsr-compliance
       ((status . "complete")
        (completion . 100)
        (notes . "All workflows SHA-pinned, SPDX headers on all files, permissions declared")))

      (security
       ((status . "complete")
        (completion . 100)
        (notes . "All GitHub Actions SHA-pinned, input sanitization, backup system, privilege checks")))

      (documentation
       ((status . "good")
        (completion . 60)
        (notes . "README, SECURITY.md, CLAUDE.md, META/ECOSYSTEM/STATE.scm complete")))

      (testing
       ((status . "foundation")
        (completion . 30)
        (notes . "ShellCheck, syntax validation, integration tests on 5 distros")))

      (core-functionality
       ((status . "implemented")
        (completion . 70)
        (notes . "DNS, interfaces, routing, firewall, NetworkManager diagnostics and repairs")))))

    (working-features
     ("SHA-pinned GitHub Actions (all 11 workflows)"
      "RSR Gold compliance achieved"
      "Multi-platform mirroring (GitHub, GitLab, Bitbucket)"
      "SPDX license headers on all files"
      "Network diagnostics: DNS, interfaces, routing, firewall, connectivity"
      "Network repairs: DNS reset, interface restart, routing fix, NM restart"
      "Interactive guided mode"
      "Dry-run mode for safe preview"
      "Automatic backup before modifications"
      "Multi-distro support: Ubuntu, Debian, Fedora, Arch"))))

;;;============================================================================
;;; ROUTE TO MVP (Updated Roadmap)
;;;============================================================================

(define route-to-mvp
  '((target-version . "1.0.0")
    (definition . "Production-ready release with comprehensive testing and documentation")

    (milestones
     ((v0.2
       ((name . "Security Hardening")
        (status . "complete")
        (completed . "2025-12-17")
        (items
         ("SHA-pin all GitHub Actions"
          "Add SPDX headers to all workflows"
          "Add permissions declarations"
          "Replace branch references with commit SHAs"
          "Verify input sanitization"))))

      (v0.3
       ((name . "Enhanced Diagnostics")
        (status . "in-progress")
        (items
         ("Add Wi-Fi diagnostics (wpa_supplicant, iwconfig)"
          "Add VPN detection and diagnostics"
          "Add IPv6 support"
          "Improve hardware/driver detection"
          "Add systemd-resolved diagnostics"))))

      (v0.5
       ((name . "Test Coverage & Quality")
        (status . "pending")
        (items
         ("Unit tests for all diagnostic functions"
          "Unit tests for all repair functions"
          "Integration tests on Fedora, Arch"
          "Test coverage > 70%"
          "Add BATS test framework"))))

      (v0.7
       ((name . "User Experience")
        (status . "pending")
        (items
         ("Improved TUI with colors and progress"
          "Better error messages with suggested fixes"
          "Log rotation and management"
          "Configuration file support"
          "Localization (i18n) foundation"))))

      (v0.9
       ((name . "Pre-release Polish")
        (status . "pending")
        (items
         ("Performance optimization"
          "Memory usage audit"
          "Security audit"
          "Man page documentation"
          "Completion scripts (bash, zsh, fish)"))))

      (v1.0
       ((name . "Production Release")
        (status . "pending")
        (items
         ("Comprehensive test coverage (>80%)"
          "All documentation complete"
          "Package for major distros (deb, rpm, AUR)"
          "GitHub Release automation"
          "Announce on Linux forums/reddit"))))))))

;;;============================================================================
;;; BLOCKERS & ISSUES
;;;============================================================================

(define blockers-and-issues
  '((critical
     ())  ;; No critical blockers

    (high-priority
     ())  ;; No high-priority blockers

    (medium-priority
     ((test-coverage
       ((description . "Test coverage needs expansion")
        (impact . "Risk of regressions on edge cases")
        (needed . "BATS test framework, mocked network tests")))

      (ipv6-support
       ((description . "IPv6 not fully supported")
        (impact . "Limited usefulness on IPv6-only networks")
        (needed . "Add IPv6 diagnostics and repairs")))))

    (low-priority
     ((wifi-diagnostics
       ((description . "Wi-Fi specific diagnostics limited")
        (impact . "Less helpful for wireless issues")
        (needed . "wpa_supplicant, iwconfig integration")))

      (distribution-coverage
       ((description . "Not tested on all distros")
        (impact . "May have issues on OpenSUSE, Gentoo")
        (needed . "Expand CI matrix")))))))

;;;============================================================================
;;; CRITICAL NEXT ACTIONS
;;;============================================================================

(define critical-next-actions
  '((immediate
     (("Add Wi-Fi diagnostics" . high)
      ("Add IPv6 basic support" . high)
      ("Expand test coverage" . medium)))

    (this-week
     (("Implement BATS test framework" . high)
      ("Add systemd-resolved diagnostics" . medium)
      ("Test on Fedora containers" . medium)))

    (this-month
     (("Reach v0.5 milestone" . high)
      ("Complete v0.3 Enhanced Diagnostics" . high)
      ("Add configuration file support" . medium)))))

;;;============================================================================
;;; SESSION HISTORY
;;;============================================================================

(define session-history
  '((snapshots
     ((date . "2025-12-17")
      (session . "security-audit-and-sha-pinning")
      (accomplishments
       ("Audited all 11 GitHub Actions workflows"
        "SHA-pinned all external actions"
        "Added SPDX headers to all workflows"
        "Added permissions declarations"
        "Replaced branch refs (main/master) with commit SHAs"
        "Fixed critical security issues: trufflehog@main, shellcheck@master"
        "Updated STATE.scm with detailed roadmap"
        "Achieved RSR Gold compliance"))
      (notes . "Security hardening complete. All workflows now use immutable SHA references."))

     ((date . "2025-12-15")
      (session . "initial-state-creation")
      (accomplishments
       ("Added META.scm, ECOSYSTEM.scm, STATE.scm"
        "Established RSR compliance foundation"
        "Created initial project checkpoint"))
      (notes . "First STATE.scm checkpoint created via automated script")))))

;;;============================================================================
;;; HELPER FUNCTIONS (for Guile evaluation)
;;;============================================================================

(define (get-completion-percentage component)
  "Get completion percentage for a component"
  (let ((comp (assoc component (cdr (assoc 'components current-position)))))
    (if comp
        (cdr (assoc 'completion (cdr comp)))
        #f)))

(define (get-blockers priority)
  "Get blockers by priority level"
  (cdr (assoc priority blockers-and-issues)))

(define (get-milestone version)
  "Get milestone details by version"
  (assoc version (cdr (assoc 'milestones route-to-mvp))))

;;;============================================================================
;;; EXPORT SUMMARY
;;;============================================================================

(define state-summary
  '((project . "complete-linux-internet-repair")
    (version . "0.2.0")
    (overall-completion . 45)
    (next-milestone . "v0.3 - Enhanced Diagnostics")
    (critical-blockers . 0)
    (high-priority-issues . 0)
    (updated . "2025-12-17")))

;;; End of STATE.scm
