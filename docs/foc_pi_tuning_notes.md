# FOC PI Tuning Notes

This project uses a cascaded FOC structure:

1. The speed PI converts speed error into torque request.
2. The MTPA / field-weakening reference block converts torque and speed into `id_ref` and `iq_ref`.
3. The d-axis and q-axis current PIs convert current error into voltage commands.
4. Feed-forward decoupling adds the steady-state PMSM voltage terms before inverse Park and PWM generation.

## What Was Wrong

The largest problem was unit scaling in the current PI blocks. The d/q PID blocks have `UseKiTs` enabled, so the value in their `I` field must be the discrete integral increment `Ki * Ts`, not the continuous gain `Ki`.

With the old settings:

```matlab
Ki = Rs * omega_c
```

was placed directly into a block expecting:

```matlab
Ki_Ts = Rs * omega_c * Ts
```

At 20 kHz this made the current-loop integral action about 20,000 times too strong. That produces exactly the kind of current and voltage oscillation you were seeing: the proportional term may be reasonable, but the integrator hammers the voltage command into saturation almost immediately.

The second issue was the MTPA / field-weakening block receiving speed reference instead of measured motor speed. Field weakening is a voltage-limit problem at the actual electrical speed. If the reference jumps to 18,000 rpm while the rotor is still slow, the FW logic can request unnecessary negative d-axis current. That steals q-axis current and creates strange transient behavior.

The third issue was the test profile. A discontinuous speed step is useful as an abuse test, but it is a bad first tuning input because it guarantees torque saturation and integrator clamping. A ramp lets you see whether each loop is behaving before asking it to survive impossible commands.

## Current PI Tuning

For one dq axis, the electrical plant is approximately:

```text
i(s) / v(s) = 1 / (L s + R)
```

Ignoring cross-coupling for the moment, choose a desired current-loop bandwidth `omega_c` in rad/s. A simple pole-cancellation PI is:

```matlab
Kp = L * omega_c
Ki = R * omega_c
```

For the Fischer IPMSM:

```matlab
Kp_d = Ld * omega_c
Kp_q = Lq * omega_c
Ki_d = Ki_q = Rs * omega_c
```

The model runs the current loop at:

```matlab
Ts = 1/20000
```

Because the current PI blocks use `UseKiTs = on`, the block integral gains must be:

```matlab
Ki_d_Ts = Ki_d * Ts
Ki_q_Ts = Ki_q * Ts
```

The current bandwidth should usually be well below PWM frequency. A good first range is:

```text
current bandwidth = switching frequency / 20 to switching frequency / 10
```

At 20 kHz, `800 Hz` is reasonable for this average inverter model. If the real inverter, sensors, PWM update, or computational delay are modeled later, reduce toward `500 Hz` before pushing back upward.

## Speed PI Tuning

The speed loop sees torque as the control input:

```text
omega_dot = (T_e - T_load - B omega) / J
```

Ignoring damping for first tuning:

```text
omega(s) / T(s) = 1 / (J s)
```

For a PI controller from speed error to torque:

```matlab
T_ref = Kp_spd * (omega_ref - omega) + Ki_spd * integral(omega_ref - omega)
```

The closed-loop denominator is approximately:

```text
J s^2 + Kp_spd s + Ki_spd
```

Pick a natural frequency `wn_s` and damping ratio `zeta_s`:

```matlab
Kp_spd = 2 * zeta_s * wn_s * J
Ki_spd = J * wn_s^2
```

Use a speed loop much slower than the current loop. A practical first rule is:

```text
speed bandwidth <= current bandwidth / 20
```

This model uses `20 Hz` speed bandwidth and `800 Hz` current bandwidth, which gives a 40:1 separation.

## Practical Tuning Procedure

Tune in this order:

1. Disable or hold the speed loop and command small `id_ref` / `iq_ref` steps. Tune current loops until actual currents track quickly without voltage chatter.
2. Verify angle convention. Positive `iq` should produce positive torque and positive speed. If not, fix signs before touching gains.
3. Enable feed-forward decoupling. The PI output should become smaller at steady state because the feed-forward handles the PMSM cross-coupling terms.
4. Enable MTPA below base speed. Watch that `id_ref` is near zero or mildly negative and `iq_ref` carries most torque.
5. Enable field weakening above base speed. `id_ref` should become more negative as electrical speed rises, and voltage magnitude should stay below the inverter limit.
6. Enable the speed PI with a ramp reference. Increase speed bandwidth only after current tracking is clean.
7. Test aggressive steps last. If a step causes saturation, judge recovery after saturation, not the saturated interval itself.

## Reading The Signals

Healthy behavior looks like this:

```text
id_actual follows id_ref_effective
iq_actual follows iq_ref
Vd_cmd and Vq_cmd stay inside available voltage
speed follows the ramp without long saturation recovery
id_ref becomes more negative above base speed
```

Suspicious behavior:

```text
Current oscillates at or near the sample rate: integral gain or delay problem.
Current tracks with the wrong sign: Park angle, phase order, or torque sign problem.
Voltage saturates while current error grows: requested torque/speed is physically impossible.
Field weakening starts at low measured speed: FW is using reference speed or wrong electrical-speed units.
Speed overshoots after saturation: speed PI integral windup or too-aggressive speed bandwidth.
```

## Current Values

With the present parameters:

```matlab
current_bw_hz = 800
speed_bw_hz = 20
Kp_d = Ld * 2*pi*800
Kp_q = Lq * 2*pi*800
Ki_d_Ts = Rs * 2*pi*800 * Ts
Ki_q_Ts = Rs * 2*pi*800 * Ts
```

That gives a simple, explainable baseline. It is not the final race-car calibration, but it is the right kind of stable baseline: current loops first, speed loop slower, voltage headroom reserved, and field weakening tied to actual speed.
