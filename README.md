# 5G NR HARQ — DAT610 group project

We are investigating how 5G NR HARQ affects reliability and performance under changing radio conditions, using MATLAB 5G Toolbox. Our question is: **How does HARQ configuration affect throughput, BLER, retransmissions, and delivery latency under different radio channel conditions?**

| Work area | Owner | Start here |
| --- | --- | --- |
| Baseline simulation and SNR experiment | Person 1 | [`src/runSimulation.m`](src/runSimulation.m), [`experiment_01_snr.m`](experiments/experiment_01_snr.m) |
| HARQ behavior and metrics | Person 2 | [`src/harq/`](src/harq/), [`calculateMetrics.m`](src/metrics/calculateMetrics.m) |
| Channel models and comparison | Person 3 | [`src/channel/`](src/channel/), [`experiment_03_channel.m`](experiments/experiment_03_channel.m) |

**Start here:** Read the [team plan](docs/team-plan.md) and [experiment questions](docs/experiment-design.md). Then run and trace the official MathWorks 5G NR HARQ/PDSCH reference example. Agree on interfaces and measurements before filling in the MATLAB files. The [initial plan](docs/initial-plan.md) lists the shared research scope.

The folders separate orchestration, HARQ, channels, metrics, plotting, experiments, literature, report material, and generated results. `results/data/` and `results/figures/` are empty placeholders.

**Current status:** This repository contains structure, ownership, function contracts, and investigation breadcrumbs. The MATLAB functions return empty placeholders; experiment files are checklists. There is no NR simulation, HARQ state machine, channel implementation, metric calculation, sweep, figure, or scientific result yet. Configuration values and metric definitions still need investigation and group agreement.
