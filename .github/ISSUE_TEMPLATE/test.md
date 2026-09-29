---
name: "🟨 Test Implementation"
about: "Adding to the seed corpus or modifying the runtime verification harness"
title: "[TEST] "
labels: test
assignees: ikostan
---

<!-- markdownlint-disable MD001 MD036 MD013 MD033 table-column-style -->

### 🧪 Test Scope & Justification
<!-- What specific GDScript syntax or edge case are we trying to capture? (e.g., Match statement, nested lambda bracket continuation). -->


### 🎯 Expected Pipeline Behavior
- [ ] **Success Pipeline:** Must produce valid `expected.instrumented.gd` and `expected.metadata.json`.
- [ ] **Expected-Failure Pipeline:** Must produce `expected.error.json` with a specific named failure mechanism.

### 🛠️ Required Artifact Checklist
- [ ] `source.gd` created with pure Unix line endings (`\n`).
- [ ] `expected.metadata.json` drafted and line numbers verified.
- [ ] `expected.instrumented.gd` (if applicable) matches exact substitution rules.
- [ ] `expected_hits.json` (if applicable) drafted for runtime verification.
- [ ] Added to the overall verification runner suite.

<!-- markdownlint-enable MD001 MD036 MD013 MD033 table-column-style -->
