# Algorithm supervisor architecture

`algorithm.slx` separates system state from control mode. The Stateflow chart
owns all power-stage permissions; the control blocks only calculate candidate
commands. `Duty Command Arbitration` is the single owner of the final PWM duty
output.

## System states

| State | PWM | Active mode | Purpose |
|---|---:|---:|---|
| `IDLE` | Off | `OFF` | Safe unselected state |
| `READY` | Off | `OFF` | Valid mode selected; waiting for enable |
| `RUN` | On | Latched request | Execute the selected control mode |
| `CALIBRATION` | Procedure-dependent | `OFF` | Current-zero and/or resolver-zero sequence |
| `FAULT` | Off | `OFF` | Latched safety shutdown until fault clears and reset is requested |

`FAULT` is intentionally a fifth safety state. It is not a user-selectable
operating mode and should not be merged with `IDLE`, because commissioning
tools must be able to distinguish a normal stop from a protection trip.

## Control modes

| Request | Mode | Command path |
|---:|---|---|
| `0` | `OFF` | Neutral duty |
| `1` | `TORQUE` | External torque request → MTPA/FW → FOC |
| `2` | `SPEED` | Speed PI torque request → MTPA/FW → FOC |
| `3` | `OPEN_LOOP` | Limited rotating voltage vector; FOC duty is not selected |

Only values 1–3 can enter `RUN`. A mode change while running immediately
returns to `READY`, disables PWM, and requires the enable command to be
released before it can be asserted again. This prevents a live transfer
between controllers with different internal states.

## Calibration policy

| Situation | Current zero | Angle zero |
|---|---:|---:|
| Every boot | Always | Only if no stored angle exists |
| Request `1` (`CURRENT_ZERO`) | Yes | No, unless the stored angle is missing |
| Request `2` (`RESOLVER_ZERO`) | No after boot | Yes |
| Request `3` (`FULL`) | Yes | Yes |

Current-zero calibration always uses neutral PWM. Resolver alignment uses the
small commissioning modulation limit, then samples the angle. Calibration is
never treated as a control mode.

## Hardware-test gates

Before connecting the traction supply or enabling gate drivers:

1. Confirm boot leaves duty at `[0.5, 0.5, 0.5]`, gate drivers disabled, and
   the enable request cleared.
2. Verify current offsets with the power stage disabled.
3. Perform resolver alignment at the configured low modulation and confirm
   rotation direction and electrical-angle polarity.
4. Start with torque mode and a current/torque limit below the mechanical rig
   limit; validate protection trips before speed mode.
5. Treat open-loop as a commissioning-only mode and keep its modulation and
   frequency limits conservative.
6. Review the brief dq voltage-command peak above `foc.V_phase_max`; duty is
   limited, but integrator saturation/anti-windup should be checked on the rig.

The top-level model is rebuilt reproducibly by
The top-level layout is stored directly in `models/algorithm.slx`. Long cross-sheet dependencies use
named Goto/From tags; local data paths remain direct wires.
