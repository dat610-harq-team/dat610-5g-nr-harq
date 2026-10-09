# Person 2: running the HARQ experiment

This is a runnable NR DL-SCH/PDSCH **symbol-domain AWGN** experiment for MATLAB
R2026a. It follows MathWorks' *Model 5G NR Transport Channels with HARQ* and uses
the official `HARQEntity.m` unchanged. It is the initial HARQ investigation;
the team's OFDM/TDL waveform simulation remains separate.

## Start in MATLAB

Set MATLAB's Current Folder to the `5G-NR-HARQ` repository and run:

```matlab
addpath('experiments');
output = experiment_02_harq;                 % quick pilot, plots displayed
```

You can also open `experiments/experiment_02_harq.m` and press Run. It is a
function with default arguments; do not invoke it with MATLAB's `run(...)`.

The first setup retrieves the R2026a example if needed. This machine already
has the downloaded helper. On a teammate's machine internet access is needed
once; examples are cached under `references/mathworks/R2026a/` and ignored by
Git. Setup prints a public `openExample(...)` fallback if retrieval fails.
It does not install a toolbox or change persistent MATLAB paths.

After reviewing the pilot, run a larger sweep:

```matlab
output = experiment_02_harq("study");
```

| Setting | Quick | Study |
| --- | --- | --- |
| Symbol SNR, dB | -4, 0, 7, 10 | -4, -2, 0, 2, 4, 6, 7, 8, 10 |
| New TBs per configuration/SNR/seed | 20 (shared default) | 1000 |
| Seeds | 0 | 0, 1, 2 |
| Configurations | 0, 1, 3 maximum retransmissions | Same |
| Total scenario runs | 12 | 81 |

Study mode is a larger measurement, not an automatic guarantee of sufficient
sample size. Inspect confidence intervals and add points near the decoding
transition. For example:

```matlab
settings = struct('SNRdB',5:0.5:8,'NumTransportBlocks',500, ...
    'Seeds',[610 611 612],'ShowFigures',false);
output = experiment_02_harq("study",settings);
```

Quick mode uses the shared baseline allocation and transport-block count.
Study mode processes many more blocks and can take tens of minutes or longer;
each completed scenario is saved immediately. The complete sweep is not
required to check that installation, metrics, and plotting work.

For the optional repeated-RV comparison, hold the attempt budget at four:

```matlab
settings = struct();
settings.RVSequences = {[0 2 3 1], [0 0 0 0]};
settings.Labels = ["Incremental redundancy", "Repeated RV 0"];
output = experiment_02_harq("quick",settings);
```

## Software and Assignment 1

Verified locally: MATLAB R2026a Update 5, version 26.1.0.3346908, and 5G Toolbox
26.1. Communications Toolbox 26.1 is also installed. Assignment 1's supplied
PDF names Communications Toolbox, uses an AWGN modulation experiment and
antenna tools, and refers to Canvas for installation guidance. It mentions
R2022A in its historical exercise instructions; it does **not** specify a
5G Toolbox version. The current experiment targets the user's actual R2026a
installation. The PDF's Eb/N0 variable is not the same as this experiment's
symbol Es/N0.

The implemented link uses 5G Toolbox and base MATLAB, including explicit
complex Gaussian noise; it does not require Simulink, Parallel Computing
Toolbox, Statistics and Machine Learning Toolbox, or a GPU.

## What is held fixed

- 52 resource blocks, 15 kHz subcarrier spacing, normal CP, one layer/codeword.
- 16QAM, target code rate 490/1024, full-slot allocation and fixed TBS.
- Type-A mapping, one type-1 DM-RS symbol at position 2, two CDM groups without
  data; DM-RS affects available data resources/TBS but no channel-estimation
  waveform is simulated. PT-RS is off.
- Normalized min-sum LDPC decoding, at most six iterations, automatic soft
  buffer flushing on CRC success.
- 16 HARQ processes, cyclic order, one scheduled process per 1 ms slot.
- Ideal CRC feedback without feedback-channel errors or processing-time model.

Physical settings and quick run length are inherited from `defaultConfig.m`. Retry comparisons use prefixes of its RV sequence. The shared seed "default" maps to numeric seed 0 for the independent per-TB streams. Study mode uses 1000 blocks and three consecutive seeds. The runner currently requires normal CP and one layer. HARQ process order,
attempt limit, and RV sequence are simulation choices, not claims about a
mandatory NR scheduler. `harqExperimentConfig.m` adds sweep and scheduler settings.
Do not compare the resulting absolute throughput with a commercial 5G rate.

## Link and HARQ behavior

`runHarqLinkSimulation` calls `nrTBS`, `nrDLSCH`, `nrPDSCH`, `nrPDSCHDecode`, and
`nrDLSCHDecoder`. It obtains process ID, zero-based transmission number, RV,
new-data state, and sequence timeout from the official helper. New payloads
are stored by `setTransportBlock`; subsequent attempts encode the same TB.
The decoder handles rate recovery, soft combining, LDPC decoding, and CRC.
After a failed sequence, `resetSoftBuffer` clears that process before loading
unrelated receiver information. Successful decoding clears it automatically.

The three default sequences are `[0]`, `[0 2]`, and `[0 2 3 1]`. Sequence length
is maximum **attempts**; maximum retransmissions is one less. A successful CRC
terminates the TB immediately. Sequence exhaustion records a final drop.
The repeated-RV option still combines receptions and is not a new TB at every
RV 0. There is no additional handwritten HARQ protocol state machine.

For unit-average-power modulation symbols, complex noise variance is
`10^(-SNRdB/10)`, split equally between real and imaginary components. This same
variance goes to the demodulator. SNR means PDSCH symbol Es/N0, not Eb/N0,
receiver waveform SNR, or a claimed fading-channel SINR.

Payload and noise have separate random streams, indexed by TB and attempt.
Thus changing the retry budget does not consume the random draws that belong
to later TBs. Equal seeds match initial attempts across configurations; seeds
within a sweep must be distinct. The simulation does not reset global `rng`.

## Metrics and observation window

The simulator admits the requested number of **distinct new TBs**, then stops
admission and resolves every outstanding TB. Empty processes idle during the
drain. Those idle slots and all retransmission slots remain in elapsed time.
This makes reliability a complete-cohort statistic. Goodput includes finite
cohort drain overhead, which can matter in quick mode; use larger cohorts for
reporting and state this measurement policy.

| Output | Definition |
| --- | --- |
| `firstTransmissionBLER` | Failed first attempts / distinct admitted TBs |
| `finalResidualBLER` | TBs dropped at attempt limit / resolved TBs |
| `goodputBitsPerSecond` | Delivered TB information bits, once per TB / elapsed simulated seconds |
| `meanRetransmissionsPerDeliveredTb` | Mean attempts minus one, conditional on delivery |
| `retransmissionProbability` | Fraction of resolved TBs actually retransmitted |
| `retransmissionResourceShare` | Retransmission attempts / all attempts |
| `meanDeliveryLatencySlots` | Mean successful slot minus first slot plus one, conditional on delivery |
| `meanDeliveryLatencySeconds` | Conditional slot delay times slot duration; per-run output |
| `meanAttemptsPerDeliveredTb` | Mean transmission attempts conditional on delivery |

All conditional means are NaN if no TB is delivered. Do not turn them into
zero. Always consider them alongside final failure rate. With this scheduler,
delivery takes `1 + (attempts-1)*NHARQProcesses` slots. This is a simulated
scheduling delay, not a measured NR HARQ RTT or end-to-end latency.

Summaries pool counts across seeds and weight conditional means by delivered
TBs. Reliability columns include 95% Wilson binomial intervals. These are
appropriate for independent TB outcomes in this fixed AWGN model; reassess
uncertainty estimation before reusing it with time-correlated fading. Zero
observed failures has a nonzero upper confidence bound. Other plots show point
estimates, not confidence intervals.

## Saved files and inspection

Each invocation creates a unique run folder below `results/data/` and a
matching figure folder below `results/figures/`. Existing runs are retained.

- `manifest.mat`: chosen configuration, MATLAB/toolbox versions, reference ID.
- `HARQEntity.m`: exact helper used for this run, with its original copyright.
- `config##_snr##_seed##.mat`: full scenario, configuration, link settings,
  events, and metrics; written after each completed scenario.
- `config##_snr##_seed##_events.csv`: one row per TB transmission attempt.
- `per_run.csv`: individual-seed metrics.
- `summary.csv` and `summary.mat`: pooled metrics and reliability intervals.
- `harq_comparison.png` and `.fig`: reliability, goodput, retransmissions,
  and delivery-attempt plots. Quick plots are labeled as quick.

Inspect one TB or its attempt distribution:

```matlab
events = output.results{end}.raw.events;
events(events.tbId == 1,:)
terminal = events(events.terminal,:);
groupsummary(terminal,{'attempt','crcError'}) % delivery/drop by terminal attempt
output.summary
```

Event fields are `tbId`, `harqProcessId`, `codewordId`, `slot`, `attempt`, `rv`,
`tbsBits`, `crcError`, `terminal`, `firstSlot`, and `softBufferReset`. IDs and
slots are scoped to one scenario. A terminal CRC failure is a drop; a terminal
CRC success is delivery. The reset flag records explicit timeout resets,
not the decoder's automatic reset on success.

## Validation and team integration

```matlab
addpath('experiments');
tests = runtests('tests');
assertSuccess(tests);
```

The tests cover shared baseline inheritance, hand-calculated histories/censoring, undefined means
when everything fails, helper progression and repeated RVs, high-SNR decoding,
repeatability, retry limits, process reuse/reset, drain time, matched initial
attempts, soft-combining recovery, and pooled summaries. Synthetic histories
are test fixtures only. Actual integration tests use the installed NR encoder
and decoder.

`runSimulation.m`, the channel files, and experiments 1/3 remain the team's
integration placeholders. Person 1 can later emit this same `raw.events` table
and duration from the waveform reference, then call `calculateMetrics(raw)`.
Person 3 should integrate TDL at the waveform/channel-estimation level; do not
claim TDL results from this AWGN symbol experiment. The other HARQ placeholder
files are not called by this runner.

## Sources

- [MathWorks: Model 5G NR Transport Channels with HARQ](https://www.mathworks.com/help/5g/gs/model-5g-nr-transport-channels-with-harq.html), retrieved through the installed R2026a example catalog using ID `5g/Modeling5GNRTransportChannelsWithHARQExample`.
- [MathWorks: NR PDSCH Throughput](https://www.mathworks.com/help/5g/ug/nr-pdsch-throughput.html), next integration reference for OFDM and TDL/CDL.
- [nrDLSCH](https://www.mathworks.com/help/5g/ref/nrdlsch-system-object.html), [nrDLSCHDecoder](https://www.mathworks.com/help/5g/ref/nrdlschdecoder-system-object.html), [setTransportBlock](https://www.mathworks.com/help/5g/ref/nrdlsch.settransportblock.html), [resetSoftBuffer](https://www.mathworks.com/help/5g/ref/nrdlschdecoder.resetsoftbuffer.html).

Web documentation may display a newer release. Local R2026a implementations
and the retrieved helper were inspected and the experiment was tested with
R2026a. `setupExample` is an example-retrieval utility inspected in that release,
not a HARQ API promised across releases. Downloaded MathWorks files remain
unchanged in the ignored cache.
