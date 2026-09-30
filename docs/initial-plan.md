# Initial project plan

## Research question

> How does 5G NR HARQ configuration affect throughput, BLER, retransmissions, and delivery latency under different radio channel conditions?

This University of Stavanger DAT610 Wireless Communications project plans to investigate the question using MATLAB 5G Toolbox. The group should first run and trace the official MathWorks 5G NR HARQ/PDSCH reference example. The repository currently contains no working simulator or scientific results.

## Proposed project flow

An experiment will eventually choose a scenario and call `runSimulation(cfg, scenario)`. Person 1 will investigate how to coordinate the verified NR transmit/receive flow. Person 2 will investigate HARQ state and raw counters; Person 3 will investigate channel setup and application. The group will decide what `result.raw` must contain before Person 2 implements `calculateMetrics(raw)`. Plotting and saving results come after a validated run.

The raw-counter names mentioned in earlier planning, such as block outcomes, bits, transmission attempts, and elapsed time, are **candidates**, not a settled schema. Find the corresponding events in the reference example before choosing fields or units.

## Measurements to investigate

- **BLER:** Decide whether the study needs first-transmission BLER, final delivery failure after HARQ, or both. Decide the denominator and observation window.
- **Throughput:** Determine which bits count as delivered and which simulated time interval is appropriate.
- **Retransmissions and attempts:** Decide how to count an initial transmission, a repeat attempt, and a failed block.
- **Delivery latency:** Define start and end events and units before adding it. Omit it if the chosen link-level baseline cannot support a sound measure.

## Planned evaluations

1. Establish one reproducible, understood baseline. Record MATLAB/toolbox versions, settings, and measurement locations.
2. Investigate and justify an SNR range while holding other conditions fixed.
3. Identify a HARQ setting that the reference actually permits the group to vary fairly.
4. Understand AWGN and validate one justified TDL comparison.
5. Review plots, repeatability, uncertainty, and limitations together before reporting conclusions.

Mobility/Doppler, multiple TDL profiles, process-count studies, redundancy-version comparisons, and MCS/modulation studies are optional later extensions. The current scaffold makes none of these technical choices for the group.
