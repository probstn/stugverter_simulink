/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: foc_controller_types.h
 *
 * Code generated for Simulink model 'foc_controller'.
 *
 * Model version                  : 1.79
 * Simulink Coder version         : 26.1 (R2026a) 20-Nov-2025
 * C/C++ source code generated on : Mon Aug 24 14:39:43 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: Infineon->TriCore
 * Emulation hardware selection:
 *    Differs from embedded hardware (Custom Processor->MATLAB Host Computer)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#ifndef foc_controller_types_h_
#define foc_controller_types_h_
#include "rtwtypes.h"
#ifndef DEFINED_TYPEDEF_FOR_measurement_
#define DEFINED_TYPEDEF_FOR_measurement_

/* Plant measurement bus (single precision) */
typedef struct {
  /* Rotor mechanical position [rad] */
  real_T MtrPos;

  /* Stator 3-phase currents [A] */
  real_T currents[3];

  /* Rotor mechanical speed [rad/s] */
  real_T speed;
} measurement;

#endif

/* Forward declaration for rtModel */
typedef struct tag_RTM_foc_controller_T RT_MODEL_foc_controller_T;

#endif                                 /* foc_controller_types_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
