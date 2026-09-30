# Three-person team plan

Every member should understand the complete path from experiment settings through NR transmit/receive behavior, raw counters, metrics, and figures. Primary ownership divides investigation and later implementation work; it does not make the modules independent scientific studies. `runSimulation(cfg, scenario)` and `calculateMetrics(raw)` are proposed boundaries. Decide the contents of `cfg`, `scenario`, and `raw` together after tracing the reference.

## Ownership and review

| Member | Primary files | Main responsibility | Reviewer |
| --- | --- | --- | --- |
| Person 1 — Core Simulation and SNR | `src/runSimulation.m`, `src/config/defaultConfig.m`, `experiments/experiment_01_snr.m` | Run and map the official NR HARQ/PDSCH example; establish one baseline; adapt it to `runSimulation`; accept SNR as a scenario setting; collect raw counters; build the SNR sweep and its baseline metrics/figures. | Person 2 |
| Person 2 — HARQ Mechanism and Metrics | `src/harq/createHarqState.m`, `src/harq/updateHarqState.m`, `src/harq/recordHarqEvent.m`, `src/metrics/calculateMetrics.m`, `experiments/experiment_02_harq.m` | Study ACK/NACK, HARQ process state, transmission attempts, and redundancy versions; define and instrument counters; calculate and test metrics; build a reference-validated HARQ comparison. | Person 3 |
| Person 3 — Channel Models and Channel Experiment | `src/channel/createChannel.m`, `src/channel/applyChannel.m`, `experiments/experiment_03_channel.m` | Map reference channel handling; establish AWGN; investigate and validate one 5G Toolbox TDL case; isolate channel operations; build the channel comparison. Doppler/mobility follows only if the basic comparison is stable. | Person 1 |

The review rotation is Person 1 work → Person 2 reviews; Person 2 work → Person 3 reviews; Person 3 work → Person 1 reviews. `src/plotting/plotResults.m` and cross-cutting documentation should be reviewed by the owner of the experiment using them and at least one other member.

## Git workflow and interfaces

Work on short-lived branches and request review before merging. Do not develop directly on `main`. Example branches are `feature/baseline-simulation`, `feature/harq-metrics`, and `feature/channel-models`, followed by `experiment/snr`, `experiment/harq-config`, and `experiment/channel` when the shared baseline is ready. Keep each branch focused and integrate interface changes early.

The proposed future call shape is:

```matlab
cfg = defaultConfig();
scenario.SNRdB = chosenSNRdB; % Set after justifying a value.
result = runSimulation(cfg, scenario);
metrics = calculateMetrics(result.raw);
```

This is an integration **target**, not a working example: `chosenSNRdB` is undecided and the functions return empty placeholders. The group must decide the fields of `result.raw` after inspecting the reference. Person 1 maps reference events into the agreed shape; Person 2 checks counter meaning and proposes metric calculations; Person 3 checks channel assumptions and scenario settings. Resolve interface disagreements together rather than letting one module silently reinterpret another's data.

## Experiment and report ownership

| Member | Experiment | Report contribution |
| --- | --- | --- |
| Person 1 | SNR sweep | Simulation scenario and SNR experiment/results |
| Person 2 | HARQ configuration | HARQ background and HARQ experiment/results |
| Person 3 | Channel conditions | Channel description and channel experiment/results |

All three share the introduction, integration of related work, conclusions, and final review. The official DAT610 report template belongs in `report/` once obtained.

## Literature split

Each member finds at least two relevant sources in the first week and records what was varied, measured, and justified. Person 1 covers HARQ overview, MATLAB/5G NR methodology, and SNR/link performance. Person 2 covers HARQ mechanisms, retransmissions, redundancy versions, and reliability/throughput tradeoffs. Person 3 covers TDL models, Doppler, mobility, and channel effects. Use [literature/references.md](../literature/references.md); do not invent citations.

## First week

- **Person 1:** Run the official MATLAB NR HARQ/PDSCH example; locate its main loop; document inputs and outputs; establish one baseline; start mapping it into `runSimulation.m`.
- **Person 2:** Trace ACK/NACK and HARQ process state; propose raw-result fields; investigate and document candidate metric definitions. Implement and test calculations only after the group agrees on the counters. Synthetic test counters may later serve as fixtures, never as scientific results.
- **Person 3:** Inspect channel configuration; identify AWGN and available TDL options; propose channel configuration fields; draft `createChannel.m`; validate one basic channel setup.
- **All three:** Find at least two sources each, confirm the research question and interfaces, and review the first integration together.

## Integration milestones and scope

1. Map the official reference flow and agree on measurements, units, and interfaces.
2. Establish one reproducible baseline run returning verified raw counters.
3. Confirm that `calculateMetrics(result.raw)` operates on those counters and that one figure is correctly labeled.
4. Add the SNR, HARQ, and channel comparisons with controlled variables recorded.
5. Review repeatability, figures, limitations, and report claims together.

Mobility, multiple TDL profiles, HARQ-process-count studies, redundancy-version comparisons, and MCS/modulation studies are optional extensions. Do not add them merely to spread work across members.
