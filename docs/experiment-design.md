# Experiment design questions

**Implementation update:** Person 2's initial AWGN HARQ experiment is now runnable on R2026a. See [the run guide](run-harq-experiment.md) for its retry-budget comparison, metric definitions, configuration, and limits. The questions below preserve the original wider integration plan.

These are planned studies, not completed algorithms or final parameter selections. Each experiment file is currently a checklist. The group should validate one scenario and agree on raw counters and metrics before writing sweeps or interpreting output.

## Experiment 1 — SNR (Person 1)

- **Independent variable:** SNR; determine and justify its range and units after inspecting the reference example.
- **Controlled variables to decide:** waveform/coding, HARQ setting, channel, run duration, random-seed policy, and measurement window.
- **Candidate dependent metrics:** BLER, throughput, average attempts, and retransmissions.
- **Expected figures:** BLER vs SNR, throughput vs SNR, and attempts/retransmissions vs SNR, with justified units and labels.
- **Open questions:** What SNR interval is informative? How many runs or blocks are needed? Is BLER measured before or after HARQ?

## Experiment 2 — HARQ configuration (Person 2)

- **Independent variable:** Decide only after tracing which HARQ controls exist in the reference implementation. No process count, redundancy-version pattern, or on/off comparison has been selected yet.
- **Controlled variables to decide:** SNR, channel, waveform/coding, run duration, and seed policy.
- **Candidate dependent metrics:** BLER, throughput, retransmissions, and average delivery attempts. Latency is conditional on a precise definition.
- **Expected figures:** Compare the selected HARQ setting against the agreed metrics; choose exact axes later.
- **Open questions:** Which control can change while keeping the comparison fair? Where are ACK/NACK and attempts observable? How are final failures treated?

## Experiment 3 — channel conditions (Person 3)

- **Independent variable:** An AWGN baseline and one TDL model, selected and justified after reference inspection.
- **Controlled variables to decide:** SNR meaning, waveform/coding, HARQ setting, duration, and seed policy.
- **Candidate dependent metrics:** BLER, throughput, retransmissions, and attempts.
- **Expected figures:** A clearly labeled channel comparison, potentially across SNR if the group chooses matched sweeps.
- **Open questions:** Which TDL profile and parameters are appropriate? How are noise and fading normalized for a fair comparison? Is mobility feasible only after the core study works?

## Interface questions for the first integration

The proposed boundary is `result = runSimulation(cfg, scenario)` followed eventually by `metrics = calculateMetrics(result.raw)`. Person 1 should map reference events to raw observations; Person 2 should determine counter definitions and metric calculations; Person 3 should verify that channel conditions are represented consistently. Decide together what `cfg`, `scenario`, `result.raw`, and each unit actually contain. The empty structs in the current MATLAB files are placeholders, not data.
