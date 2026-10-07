# 5G NR HARQ — DAT610 group project

We are investigating how 5G NR HARQ affects reliability and performance under changing radio conditions, using MATLAB 5G Toolbox. Our question is: **How does HARQ configuration affect throughput, BLER, retransmissions, and delivery latency under different radio channel conditions?**

| Work area | Owner | Start here |
| --- | --- | --- |
| Baseline simulation and SNR experiment | Person 1 | [`src/runSimulation.m`](src/runSimulation.m), [`experiment_01_snr.m`](experiments/experiment_01_snr.m) |
| HARQ behavior and metrics | Person 2 | [`src/harq/`](src/harq/), [`calculateMetrics.m`](src/metrics/calculateMetrics.m) |
| Channel models and comparison | Person 3 | [`src/channel/`](src/channel/), [`experiment_03_channel.m`](experiments/experiment_03_channel.m) |

**Run Person 2's experiment:** With MATLAB R2026a and 5G Toolbox, set the Current Folder to this repository and run:

```matlab
addpath('experiments');
output = experiment_02_harq;          % Quick AWGN pilot
% output = experiment_02_harq("study"); % Larger multi-seed sweep
```

See the [HARQ run guide](docs/run-harq-experiment.md) for settings, outputs, metric definitions, assumptions, and tests. It adapts the official MathWorks transport-channel example and reuses its HARQ helper. The [team plan](docs/team-plan.md), [original experiment questions](docs/experiment-design.md), and [initial plan](docs/initial-plan.md) describe the wider group project.

The folders separate orchestration, HARQ, channels, metrics, plotting, experiments, literature, report material, and generated results. Runs create separate data and figure directories under `results/`, which Git ignores.

**Current status:** Person 2's symbol-domain NR DL-SCH/PDSCH AWGN experiment, metric collection, retry-budget sweep, plots, and validation tests are runnable on R2026a. Quick runs are validation pilots, not final report results. The team's waveform simulation (`runSimulation.m`), TDL/channel integration, and experiments 1/3 remain placeholders. HARQ settings and the final scientific experiment should still be reviewed by the group.
