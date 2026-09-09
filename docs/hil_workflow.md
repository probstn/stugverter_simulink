# Reliable SIL/HIL workflow

The controller always executes at a simulated sample time of 50 microseconds.
HIL uses XCP on UDP to send one speed/ADC sample to the TC387 and receive one
PWM result. Because Windows, Simscape, and UDP cannot guarantee a 20 kHz
request/response loop in wall-clock real time, `foc.hilPacingRate` slows only
wall-clock execution. It does not change controller or plant sample times.

The target receive path places complete STIM samples in a 256-entry cross-core
FIFO. Core 0 drains short bursts without skipping algorithm steps. A delayed
packet holds the previous PWM output; it never resets controller state.

Use the sections in `stugverter.m` in order:

1. Run SIL.
2. Generate Embedded Coder output.
3. Deploy generated sources to `firmware/algorithm`.
4. Build, flash, reset, and run the TC387 through winIDEA.
5. Run HIL.
6. Run the combined SIL/HIL equivalence regression.

The validation compares physical plant speed on a common 50-microsecond grid.
It fails if RMSE exceeds 10 RPM, maximum pointwise error exceeds 25 RPM, or the
final-speed difference exceeds 10 RPM.

## Validated result (2026-09-09)

- Speed RMSE: 0.572 RPM
- Maximum pointwise speed difference: 1.932 RPM
- Peak-speed difference: 0.316 RPM
- Final-speed difference: -0.364 RPM
- AURIX controller execution: 0.90 microseconds average versus 50 microseconds available
- SIL/HIL PWM RMS difference: 0.01927 after one-sample alignment
- XCP transmit errors: 0
- HIL FIFO overruns: 0
