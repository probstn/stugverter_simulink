# Reliable SIL/HIL workflow

The controller always executes at a simulated sample time of 50 microseconds.
HIL uses XCP on UDP to send one speed/ADC sample to the TC387 and receive one
PWM result. Because Windows, Simscape, and UDP cannot guarantee a 20 kHz
request/response loop in wall-clock real time, `foc.hilPacingRate` slows only
wall-clock execution. It does not change controller or plant sample times.

The target receive path places complete STIM samples in a 256-entry cross-core
FIFO. Core 0 drains short bursts without skipping algorithm steps. A delayed
packet holds the previous PWM output; it never resets controller state.

Use the sections in `main.m` in order. The entry models have distinct roles:

- `stugverter_sim.slx`: one simulated plant with exclusive SIL and TC387/XCP
  controller variants selected by `simulation_mode`.
- `stugverter_monitor.slx`: read-only XCP DAQ monitor; no plant and no STIM.

All models save with pacing disabled. `run_hil.m` and `run_hardware.m` enable
pacing only on their `SimulationInput`, so running SIL is never slowed by a
setting left behind by HIL.

1. Run SIL.
2. Generate Embedded Coder output.
3. Deploy generated sources to `firmware/algorithm`.
4. Build, flash, reset, and run the TC387 through winIDEA.
5. Run HIL.
6. Run the combined SIL/HIL equivalence regression.

The validation compares physical plant speed on a common 50-microsecond grid.
It fails if RMSE exceeds 10 RPM, maximum pointwise error exceeds 25 RPM, or the
final-speed difference exceeds 10 RPM.

## Validated result (2026-09-10)

- Speed RMSE: 0.521 RPM
- Maximum pointwise speed difference: 1.840 RPM
- Peak-speed difference: 0.072 RPM
- Final-speed difference: -1.289 RPM
- AURIX controller execution: 1.96 microseconds observed versus 50 microseconds available
The corresponding controller image was rebuilt, flashed, and verified to boot
with neutral PWM duty, disabled gate drivers, and a cleared enable request.
