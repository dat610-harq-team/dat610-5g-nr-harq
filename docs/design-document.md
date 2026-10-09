# DAT610 Project Design Document

## 1. Project goal

This project evaluates **Hybrid Automatic Repeat Request (HARQ) in 5G NR** using MATLAB 5G Toolbox.

The working research question is:

> **How does 5G NR HARQ configuration affect throughput, BLER, retransmissions, and delivery latency under different radio channel conditions?**

The project is kept link-level and deliberately small enough to evaluate carefully. The focus is not only on changing the radio environment; we also vary HARQ settings so that HARQ is treated as the 5G mechanism under study rather than as a black box.

## 2. Simulation environment

The common simulator is built around the MATLAB 5G Toolbox downlink transport-channel/PDSCH flow. A shared entry point is used by the experiments:

```matlab
cfg = defaultConfig();
result = runSimulation(cfg, scenario);
```

`runSimulation` delegates the actual transmission and HARQ behavior to `runHarqLinkSimulation`. Each transmission attempt is recorded as an event and the same metric implementation is then used across experiments.

Current baseline settings are:

| Setting | Baseline |
| --- | --- |
| Modulation | 16QAM |
| Target code rate | 490/1024 (about 0.479) |
| Subcarrier spacing | 15 kHz |
| Resource grid | 12 RB |
| Layers | 1 |
| HARQ processes | 16 |
| RV sequence | [0 2 3 1] |
| LDPC decoder | Normalized min-sum |
| Maximum LDPC iterations | 6 |

These values provide a reproducible common baseline. The final report must motivate the selected values from 5G NR references, MATLAB documentation/example behavior, and related work where appropriate.

### Current link model

The integrated simulator currently uses symbol-domain AWGN. For a selected SNR, complex Gaussian noise is added to the PDSCH symbols before decoding. The SNR used in the current experiments is defined as **PDSCH symbol Es/N0 in dB**.

The simulator runs a finite cohort of transport blocks and continues until every admitted block has either been decoded successfully or has exhausted the configured HARQ attempt budget.

## 3. HARQ implementation and measurements

The default HARQ sequence is:

```matlab
[0 2 3 1]
```

This gives a maximum of four transmission attempts for a transport block. Sixteen HARQ processes are scheduled cyclically.

For each attempt the simulator records information including:

- transport-block ID;
- HARQ process ID;
- slot;
- attempt number;
- redundancy version;
- transport-block size;
- CRC result;
- whether the attempt is terminal.

The shared metrics are calculated from these events rather than separately inside each experiment.

### Metrics

The main evaluation metrics are:

- **First-transmission BLER:** fraction of first attempts that fail CRC.
- **Final residual BLER:** fraction of completed transport blocks that are still unsuccessful after the allowed HARQ attempts.
- **Goodput:** successfully delivered information bits divided by elapsed simulated time.
- **Mean retransmissions per delivered TB:** average number of extra attempts for successfully delivered blocks.
- **Delivery latency:** scheduling delay in slots from the first transmission to successful delivery.

The latency metric is a link-level scheduling delay, not end-to-end application latency.

## 4. Evaluation plan

The evaluation is split into three connected experiments. All experiments should use the same metric definitions and, where possible, the same baseline configuration.

### Experiment 1 — SNR

**Owner:** Person 1

The SNR experiment studies how radio quality changes HARQ behavior while keeping the HARQ configuration fixed.

The experiment has two interesting operating regions.

**Lower HARQ-recovery region.** A pilot sweep from -2 to 4 dB showed that the final residual BLER changes strongly between -1 and 0 dB. A denser study therefore uses:

```matlab
SNR = -1:0.25:0.5 dB
Seeds = [610 611 612]
1000 transport blocks per run
```

This region is intended to show when the complete HARQ sequence becomes sufficient to recover transport blocks.

**Upper first-transmission region.** Earlier results indicate that first-transmission BLER changes rapidly around 6.5--7.5 dB. The planned study uses:

```matlab
SNR = 6:0.25:8 dB
Seeds = [610 611 612]
1000 transport blocks per run
```

This region shows when the link becomes reliable enough that retransmissions are rarely required.

Planned figures:

- first-transmission and final residual BLER vs PDSCH symbol Es/N0;
- goodput vs PDSCH symbol Es/N0;
- mean retransmissions per delivered TB vs PDSCH symbol Es/N0;
- mean delivery latency vs PDSCH symbol Es/N0.

BLER results are aggregated across runs and reported with Wilson 95% confidence intervals. Continuous metrics also record seed-to-seed variation.

### Experiment 2 — HARQ configuration

**Owner:** Person 2

This experiment changes the HARQ retry/RV configuration while holding the underlying link settings constant. The implemented comparison supports sequences such as:

```matlab
[0]
[0 2]
[0 2 3 1]
```

This directly tests the reliability/performance trade-off of allowing more HARQ transmissions.

The main comparison will use the same metrics as Experiment 1: final reliability, goodput, retransmission cost, and delivery delay. SNR points should be chosen where the configurations produce visibly different behavior rather than only testing a trivially good or impossible link.

Planned figures compare the HARQ configurations across selected SNR values.

### Experiment 3 — Channel conditions

**Owner:** Person 3

The channel study will compare the validated AWGN baseline with one 5G Toolbox TDL fading model.

This part is still under integration. The current shared HARQ engine works on PDSCH symbols, while `nrTDLChannel` operates on a time-domain waveform. A correct TDL experiment therefore needs a waveform processing path including OFDM modulation/demodulation and the required receiver processing before PDSCH decoding.

The group should not treat a direct symbol-to-TDL connection as a valid result.

The intended comparison is:

- AWGN baseline;
- one justified TDL profile;
- matched SNR and common HARQ configuration.

Doppler/mobility is optional and should only be added if the basic TDL comparison is working and scientifically clear.

Planned figures will compare BLER, goodput, and retransmission behavior between the two channel conditions.

## 5. Reproducibility and implementation details

Runs use explicit random seeds. Experiment 1 currently uses seeds 610, 611, and 612 for the larger studies. Payload generation and noise generation use controlled random streams.

Each experiment run can save:

- a manifest containing configuration and environment information;
- individual MATLAB result files;
- per-run CSV data;
- an aggregated summary;
- report-ready figures.

The SNR experiment also records the MATLAB release, installed toolboxes, the resolved `HARQEntity` helper, and the SNR definition.

Quick runs and pilot sweeps are used for validation and for locating useful operating regions. They should not automatically be treated as final statistical evidence.

## 6. Validation

Before using results in the report, the group will check:

1. repeated runs with the same seed reproduce the same result;
2. high-SNR cases approach reliable first transmission;
3. poor-link cases produce additional HARQ attempts and, when sufficiently poor, residual failures;
4. retry counts agree with the configured RV sequence;
5. goodput, latency, BLER, and event counts are internally consistent;
6. all admitted transport blocks reach a terminal state;
7. channel comparisons use a consistent and clearly stated SNR definition.

Existing tests cover important HARQ and metric behavior. Final channel validation will be added when the waveform TDL path is complete.

## 7. Figures and report use

Figures will follow the course plotting requirements:

- proper axis names and units;
- no title inside the plot when the report caption provides the title;
- no screenshots of MATLAB plots;
- only parameters and ranges that can be explained physically or from references.

The report should focus on a small number of figures that directly answer the research question rather than showing every pilot run.

The expected report structure is:

1. Introduction and motivation
2. HARQ/5G NR background and related work
3. Design and evaluation settings
4. Results and analysis
5. Conclusions
6. References
7. Code appendix

## 8. Remaining work

Before final evaluation, the main remaining tasks are:

- complete the multi-seed lower and upper SNR studies;
- run and summarize the HARQ-configuration study on the agreed baseline;
- integrate and validate the waveform-domain TDL channel path;
- agree on and document final common parameters;
- connect parameter choices and interpretation to literature;
- select the final report figures and state limitations clearly.

The project will prioritize correct, explainable experiments over adding extra modulation, MIMO, mobility, or many channel profiles.
