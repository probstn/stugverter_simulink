# ADC measurements in algorithm.slx

`algorithm/adc_to_sensor` uses native Simulink blocks only. It is inside the
algorithm model referenced by `stugverter_sil/Processor/Model`, so conversion and
speed-estimator state are included when generating code from `algorithm.slx`.

The existing input interface is an `adc_values` bus containing five `uint16`
channels: `ia`, `ib`, `ic`, `resolver_sin`, and `resolver_cos`.

- **Current measurement** converts each channel to single precision before
  subtracting the ADC midpoint, then scales to amperes. Its three explicit
  outputs are packed in phase A, B, C order for the existing measurement bus.
- **Position measurement** removes the SIN/COS midpoint, normalizes both
  channels, applies `atan2(sin, cos)`, and wraps the mechanical angle to
  `[0, 2*pi)` radians.
- **Speed from position** calculates the shortest signed difference between
  consecutive measured angles and divides by `foc.Ts`. The first sample outputs
  zero, including when the rotor starts at a nonzero angle. A first-order filter
  uses `sensor.speed_alpha`, derived from the existing 150 Hz cutoff.

The output remains the single-precision `algo_measurement` bus: `MtrPos` [rad],
`currents` [A, three elements], and `speed` [rad/s]. All estimator delays run at
`foc.Ts` (50 microseconds by default).

Calibration remains in `scripts/controller_params.m`: `sensor.ADC_mid`,
`sensor.ADC_span`, and `sensor.I_max`. With the existing calibration, count 2048
means zero current and count 4095 means +120 A. Count 0 is slightly below -120 A
because the negative ADC range contains one extra count.

Assumptions: SIN/COS are matched, centered signals representing one mechanical
revolution; valid ADC values are 0–4095; motion is less than pi radians per
sample. Sensor fault detection is not implemented. The simulation's ADC
emulation remains in `stugverter_sil`; it is not part of the algorithm deployment.

## Reproduce validation

From the project root in MATLAB:

```matlab
init;
results = validate_adc_to_sensor;
```

This creates a temporary harness copied from the saved sensor subsystem,
checks all 4096 current ADC codes on all phases, quantized resolver rotation in
both directions, wraparound, stationary nonzero startup, stopping, and
acceleration. It compares against independent double-precision equations and
checks single-precision output types. It then runs the existing full motor
profile acceptance checks and generates/compiles `algorithm` using its saved
code-generation configuration. Temporary code/cache paths are printed.

`rebuild_adc_to_sensor` reconstructs the subsystem if needed; normal simulation
and code generation use the saved SLX and do not require rebuilding.

For the additional host compilation check, validation temporarily sets
`GenCodeOnly=off` and `InstructionSetExtensions=None`, then restores both.
The saved configuration uses `grt.tlc` with SSE2, which cannot be compiled on
this Apple Silicon host. Code generation with the saved configuration is also
supported; target-specific AURIX compilation and deployment are separate checks.

## Validation result — MATLAB R2026a, 2026-09-08

- 12,000 sensor samples passed, including every 12-bit current code.
- Maximum current error: 5.5758e-6 A.
- Maximum circular position error: 5.0033e-7 rad.
- Maximum filtered speed error: approximately 0.0012 rad/s.
- Nonzero stationary startup: zero speed throughout the first 1,000 samples.
- Forward/reverse steady speed checks: +1800 / -1800 rad/s passed.
- Existing 0.8 s `stugverter_sil` acceptance checks passed; peak speed 18169.4 RPM,
  final speed 6001.3 RPM against a 6000 RPM reference.
- `algorithm.slx` standalone C generation passed with the saved configuration.
- Standalone host compilation passed with SIMD disabled temporarily.

No hardware deployment or AURIX target compilation was performed.
