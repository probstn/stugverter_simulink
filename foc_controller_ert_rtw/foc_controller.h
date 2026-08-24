/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: foc_controller.h
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

#ifndef foc_controller_h_
#define foc_controller_h_
#ifndef foc_controller_COMMON_INCLUDES_
#define foc_controller_COMMON_INCLUDES_
#include "rtwtypes.h"
#include "rt_nonfinite.h"
#include "math.h"
#endif                                 /* foc_controller_COMMON_INCLUDES_ */

#include "foc_controller_types.h"
#include <string.h>
#include "rt_defines.h"

/* Macros for accessing real-time model data structure */
#ifndef rtmGetErrorStatus
#define rtmGetErrorStatus(rtm)         ((rtm)->errorStatus)
#endif

#ifndef rtmSetErrorStatus
#define rtmSetErrorStatus(rtm, val)    ((rtm)->errorStatus = (val))
#endif

/* Block states (default storage) for system '<Root>' */
typedef struct {
  real_T Integrator_DSTATE;            /* '<S50>/Integrator' */
  real_T Integrator_DSTATE_f;          /* '<S111>/Integrator' */
} DW_foc_controller_T;

/* Constant parameters (default storage) */
typedef struct {
  /* Expression: dlgSett.sin_table
   * Referenced by: '<S171>/sine_table_values'
   */
  real_T sine_table_values_Value[1002];
} ConstP_foc_controller_T;

/* Real-time Model Data Structure */
struct tag_RTM_foc_controller_T {
  const char_T * volatile errorStatus;
  DW_foc_controller_T *dwork;
};

/* External data declarations for dependent source files */
extern const measurement foc_controller_rtZmeasurement;/* measurement ground */

/* Constant parameters (default storage) */
extern const ConstP_foc_controller_T foc_controller_ConstP;

/* Model entry point functions */
extern void foc_controller_initialize(RT_MODEL_foc_controller_T *const
  foc_controller_M, real_T *foc_controller_U_id_ref, real_T
  *foc_controller_U_iq_ref, measurement *foc_controller_U_measurements, real_T
  foc_controller_Y_duty[3]);
extern void foc_controller_step(RT_MODEL_foc_controller_T *const
  foc_controller_M, real_T foc_controller_U_id_ref, real_T
  foc_controller_U_iq_ref, measurement *foc_controller_U_measurements, real_T
  foc_controller_Y_duty[3]);
extern void foc_controller_terminate(RT_MODEL_foc_controller_T *const
  foc_controller_M);

/*-
 * These blocks were eliminated from the model due to optimizations:
 *
 * Block '<S13>/Data Type Duplicate' : Unused code path elimination
 * Block '<S73>/Data Type Duplicate' : Unused code path elimination
 * Block '<S73>/Data Type Duplicate1' : Unused code path elimination
 * Block '<S130>/Data Type Duplicate' : Unused code path elimination
 * Block '<S5>/ReplaceInport_Npp' : Unused code path elimination
 * Block '<S6>/Constant' : Unused code path elimination
 * Block '<S6>/Data Type Duplicate' : Unused code path elimination
 * Block '<S6>/Gain' : Unused code path elimination
 * Block '<S150>/Constant' : Unused code path elimination
 * Block '<S150>/Constant1' : Unused code path elimination
 * Block '<S150>/Data Type Duplicate' : Unused code path elimination
 * Block '<S140>/Data Type Duplicate' : Unused code path elimination
 * Block '<S140>/Data Type Propagation' : Unused code path elimination
 * Block '<S151>/Data Type Duplicate' : Unused code path elimination
 * Block '<S151>/Data Type Propagation' : Unused code path elimination
 * Block '<S6>/ReplaceInport_Vc' : Unused code path elimination
 * Block '<S6>/ReplaceInport_Vdc' : Unused code path elimination
 * Block '<S6>/Switch' : Unused code path elimination
 * Block '<S163>/Data Type Duplicate' : Unused code path elimination
 * Block '<S169>/Data Type Duplicate' : Unused code path elimination
 * Block '<S169>/Data Type Duplicate1' : Unused code path elimination
 * Block '<Root>/Scope' : Unused code path elimination
 * Block '<Root>/Scope1' : Unused code path elimination
 * Block '<Root>/Scope2' : Unused code path elimination
 * Block '<S171>/Data Type Duplicate' : Unused code path elimination
 * Block '<S171>/Data Type Propagation' : Unused code path elimination
 * Block '<S176>/Data Type Duplicate' : Unused code path elimination
 * Block '<S177>/Data Type Duplicate' : Unused code path elimination
 * Block '<Root>/id' : Unused code path elimination
 * Block '<Root>/iq' : Unused code path elimination
 * Block '<S12>/Kalpha' : Eliminated nontunable gain of 1
 * Block '<S12>/Kbeta' : Eliminated nontunable gain of 1
 * Block '<S171>/Get_FractionVal' : Eliminate redundant data type conversion
 * Block '<S74>/Offset' : Unused code path elimination
 * Block '<S74>/Unary_Minus' : Unused code path elimination
 * Block '<S130>/Constant' : Unused code path elimination
 * Block '<S5>/ReplaceInport_Offset' : Unused code path elimination
 * Block '<S140>/Constant1' : Unused code path elimination
 * Block '<S170>/Offset' : Unused code path elimination
 * Block '<S170>/Unary_Minus' : Unused code path elimination
 */

/*-
 * The generated code includes comments that allow you to trace directly
 * back to the appropriate location in the model.  The basic format
 * is <system>/block_name, where system is the system number (uniquely
 * assigned by Simulink) and block_name is the name of the block.
 *
 * Use the MATLAB hilite_system command to trace the generated code back
 * to the model.  For example,
 *
 * hilite_system('<S3>')    - opens system 3
 * hilite_system('<S3>/Kp') - opens and selects block Kp which resides in S3
 *
 * Here is the system hierarchy for this model
 *
 * '<Root>' : 'foc_controller'
 * '<S1>'   : 'foc_controller/Clarke Transform'
 * '<S2>'   : 'foc_controller/Id Controller'
 * '<S3>'   : 'foc_controller/Inverse Park Transform'
 * '<S4>'   : 'foc_controller/Iq Controller'
 * '<S5>'   : 'foc_controller/Mechanical to Electrical Position'
 * '<S6>'   : 'foc_controller/PWM Reference Generator'
 * '<S7>'   : 'foc_controller/Park Transform'
 * '<S8>'   : 'foc_controller/SinCos Embedded Optimized'
 * '<S9>'   : 'foc_controller/Clarke Transform/Variant'
 * '<S10>'  : 'foc_controller/Clarke Transform/Variant/mcb'
 * '<S11>'  : 'foc_controller/Clarke Transform/Variant/mcb/Clarke Transform'
 * '<S12>'  : 'foc_controller/Clarke Transform/Variant/mcb/Clarke Transform/Two phase input'
 * '<S13>'  : 'foc_controller/Clarke Transform/Variant/mcb/Clarke Transform/Two phase input/Two phase CRL wrap'
 * '<S14>'  : 'foc_controller/Id Controller/Anti-windup'
 * '<S15>'  : 'foc_controller/Id Controller/D Gain'
 * '<S16>'  : 'foc_controller/Id Controller/External Derivative'
 * '<S17>'  : 'foc_controller/Id Controller/Filter'
 * '<S18>'  : 'foc_controller/Id Controller/Filter ICs'
 * '<S19>'  : 'foc_controller/Id Controller/I Gain'
 * '<S20>'  : 'foc_controller/Id Controller/Ideal P Gain'
 * '<S21>'  : 'foc_controller/Id Controller/Ideal P Gain Fdbk'
 * '<S22>'  : 'foc_controller/Id Controller/Integrator'
 * '<S23>'  : 'foc_controller/Id Controller/Integrator ICs'
 * '<S24>'  : 'foc_controller/Id Controller/N Copy'
 * '<S25>'  : 'foc_controller/Id Controller/N Gain'
 * '<S26>'  : 'foc_controller/Id Controller/P Copy'
 * '<S27>'  : 'foc_controller/Id Controller/Parallel P Gain'
 * '<S28>'  : 'foc_controller/Id Controller/Reset Signal'
 * '<S29>'  : 'foc_controller/Id Controller/Saturation'
 * '<S30>'  : 'foc_controller/Id Controller/Saturation Fdbk'
 * '<S31>'  : 'foc_controller/Id Controller/Sum'
 * '<S32>'  : 'foc_controller/Id Controller/Sum Fdbk'
 * '<S33>'  : 'foc_controller/Id Controller/Tracking Mode'
 * '<S34>'  : 'foc_controller/Id Controller/Tracking Mode Sum'
 * '<S35>'  : 'foc_controller/Id Controller/Tsamp - Integral'
 * '<S36>'  : 'foc_controller/Id Controller/Tsamp - Ngain'
 * '<S37>'  : 'foc_controller/Id Controller/postSat Signal'
 * '<S38>'  : 'foc_controller/Id Controller/preInt Signal'
 * '<S39>'  : 'foc_controller/Id Controller/preSat Signal'
 * '<S40>'  : 'foc_controller/Id Controller/Anti-windup/Disc. Clamping Parallel'
 * '<S41>'  : 'foc_controller/Id Controller/Anti-windup/Disc. Clamping Parallel/Dead Zone'
 * '<S42>'  : 'foc_controller/Id Controller/Anti-windup/Disc. Clamping Parallel/Dead Zone/Enabled'
 * '<S43>'  : 'foc_controller/Id Controller/D Gain/Disabled'
 * '<S44>'  : 'foc_controller/Id Controller/External Derivative/Disabled'
 * '<S45>'  : 'foc_controller/Id Controller/Filter/Disabled'
 * '<S46>'  : 'foc_controller/Id Controller/Filter ICs/Disabled'
 * '<S47>'  : 'foc_controller/Id Controller/I Gain/Internal Parameters'
 * '<S48>'  : 'foc_controller/Id Controller/Ideal P Gain/Passthrough'
 * '<S49>'  : 'foc_controller/Id Controller/Ideal P Gain Fdbk/Disabled'
 * '<S50>'  : 'foc_controller/Id Controller/Integrator/Discrete'
 * '<S51>'  : 'foc_controller/Id Controller/Integrator ICs/Internal IC'
 * '<S52>'  : 'foc_controller/Id Controller/N Copy/Disabled wSignal Specification'
 * '<S53>'  : 'foc_controller/Id Controller/N Gain/Disabled'
 * '<S54>'  : 'foc_controller/Id Controller/P Copy/Disabled'
 * '<S55>'  : 'foc_controller/Id Controller/Parallel P Gain/Internal Parameters'
 * '<S56>'  : 'foc_controller/Id Controller/Reset Signal/Disabled'
 * '<S57>'  : 'foc_controller/Id Controller/Saturation/Enabled'
 * '<S58>'  : 'foc_controller/Id Controller/Saturation Fdbk/Disabled'
 * '<S59>'  : 'foc_controller/Id Controller/Sum/Sum_PI'
 * '<S60>'  : 'foc_controller/Id Controller/Sum Fdbk/Disabled'
 * '<S61>'  : 'foc_controller/Id Controller/Tracking Mode/Disabled'
 * '<S62>'  : 'foc_controller/Id Controller/Tracking Mode Sum/Passthrough'
 * '<S63>'  : 'foc_controller/Id Controller/Tsamp - Integral/TsSignalSpecification'
 * '<S64>'  : 'foc_controller/Id Controller/Tsamp - Ngain/Passthrough'
 * '<S65>'  : 'foc_controller/Id Controller/postSat Signal/Forward_Path'
 * '<S66>'  : 'foc_controller/Id Controller/preInt Signal/Internal PreInt'
 * '<S67>'  : 'foc_controller/Id Controller/preSat Signal/Forward_Path'
 * '<S68>'  : 'foc_controller/Inverse Park Transform/Variant'
 * '<S69>'  : 'foc_controller/Inverse Park Transform/Variant/mcb'
 * '<S70>'  : 'foc_controller/Inverse Park Transform/Variant/mcb/Inverse Park Transform'
 * '<S71>'  : 'foc_controller/Inverse Park Transform/Variant/mcb/Inverse Park Transform/Select'
 * '<S72>'  : 'foc_controller/Inverse Park Transform/Variant/mcb/Inverse Park Transform/Select/Two Inputs'
 * '<S73>'  : 'foc_controller/Inverse Park Transform/Variant/mcb/Inverse Park Transform/Select/Two Inputs/Two inputs CRL'
 * '<S74>'  : 'foc_controller/Inverse Park Transform/Variant/mcb/Inverse Park Transform/Select/Two Inputs/Two inputs CRL/Switch_Axis'
 * '<S75>'  : 'foc_controller/Iq Controller/Anti-windup'
 * '<S76>'  : 'foc_controller/Iq Controller/D Gain'
 * '<S77>'  : 'foc_controller/Iq Controller/External Derivative'
 * '<S78>'  : 'foc_controller/Iq Controller/Filter'
 * '<S79>'  : 'foc_controller/Iq Controller/Filter ICs'
 * '<S80>'  : 'foc_controller/Iq Controller/I Gain'
 * '<S81>'  : 'foc_controller/Iq Controller/Ideal P Gain'
 * '<S82>'  : 'foc_controller/Iq Controller/Ideal P Gain Fdbk'
 * '<S83>'  : 'foc_controller/Iq Controller/Integrator'
 * '<S84>'  : 'foc_controller/Iq Controller/Integrator ICs'
 * '<S85>'  : 'foc_controller/Iq Controller/N Copy'
 * '<S86>'  : 'foc_controller/Iq Controller/N Gain'
 * '<S87>'  : 'foc_controller/Iq Controller/P Copy'
 * '<S88>'  : 'foc_controller/Iq Controller/Parallel P Gain'
 * '<S89>'  : 'foc_controller/Iq Controller/Reset Signal'
 * '<S90>'  : 'foc_controller/Iq Controller/Saturation'
 * '<S91>'  : 'foc_controller/Iq Controller/Saturation Fdbk'
 * '<S92>'  : 'foc_controller/Iq Controller/Sum'
 * '<S93>'  : 'foc_controller/Iq Controller/Sum Fdbk'
 * '<S94>'  : 'foc_controller/Iq Controller/Tracking Mode'
 * '<S95>'  : 'foc_controller/Iq Controller/Tracking Mode Sum'
 * '<S96>'  : 'foc_controller/Iq Controller/Tsamp - Integral'
 * '<S97>'  : 'foc_controller/Iq Controller/Tsamp - Ngain'
 * '<S98>'  : 'foc_controller/Iq Controller/postSat Signal'
 * '<S99>'  : 'foc_controller/Iq Controller/preInt Signal'
 * '<S100>' : 'foc_controller/Iq Controller/preSat Signal'
 * '<S101>' : 'foc_controller/Iq Controller/Anti-windup/Disc. Clamping Parallel'
 * '<S102>' : 'foc_controller/Iq Controller/Anti-windup/Disc. Clamping Parallel/Dead Zone'
 * '<S103>' : 'foc_controller/Iq Controller/Anti-windup/Disc. Clamping Parallel/Dead Zone/Enabled'
 * '<S104>' : 'foc_controller/Iq Controller/D Gain/Disabled'
 * '<S105>' : 'foc_controller/Iq Controller/External Derivative/Disabled'
 * '<S106>' : 'foc_controller/Iq Controller/Filter/Disabled'
 * '<S107>' : 'foc_controller/Iq Controller/Filter ICs/Disabled'
 * '<S108>' : 'foc_controller/Iq Controller/I Gain/Internal Parameters'
 * '<S109>' : 'foc_controller/Iq Controller/Ideal P Gain/Passthrough'
 * '<S110>' : 'foc_controller/Iq Controller/Ideal P Gain Fdbk/Disabled'
 * '<S111>' : 'foc_controller/Iq Controller/Integrator/Discrete'
 * '<S112>' : 'foc_controller/Iq Controller/Integrator ICs/Internal IC'
 * '<S113>' : 'foc_controller/Iq Controller/N Copy/Disabled wSignal Specification'
 * '<S114>' : 'foc_controller/Iq Controller/N Gain/Disabled'
 * '<S115>' : 'foc_controller/Iq Controller/P Copy/Disabled'
 * '<S116>' : 'foc_controller/Iq Controller/Parallel P Gain/Internal Parameters'
 * '<S117>' : 'foc_controller/Iq Controller/Reset Signal/Disabled'
 * '<S118>' : 'foc_controller/Iq Controller/Saturation/Enabled'
 * '<S119>' : 'foc_controller/Iq Controller/Saturation Fdbk/Disabled'
 * '<S120>' : 'foc_controller/Iq Controller/Sum/Sum_PI'
 * '<S121>' : 'foc_controller/Iq Controller/Sum Fdbk/Disabled'
 * '<S122>' : 'foc_controller/Iq Controller/Tracking Mode/Disabled'
 * '<S123>' : 'foc_controller/Iq Controller/Tracking Mode Sum/Passthrough'
 * '<S124>' : 'foc_controller/Iq Controller/Tsamp - Integral/TsSignalSpecification'
 * '<S125>' : 'foc_controller/Iq Controller/Tsamp - Ngain/Passthrough'
 * '<S126>' : 'foc_controller/Iq Controller/postSat Signal/Forward_Path'
 * '<S127>' : 'foc_controller/Iq Controller/preInt Signal/Internal PreInt'
 * '<S128>' : 'foc_controller/Iq Controller/preSat Signal/Forward_Path'
 * '<S129>' : 'foc_controller/Mechanical to Electrical Position/MechToElec'
 * '<S130>' : 'foc_controller/Mechanical to Electrical Position/MechToElec/floating-point'
 * '<S131>' : 'foc_controller/Mechanical to Electrical Position/MechToElec/floating-point/Compensate Offset'
 * '<S132>' : 'foc_controller/Mechanical to Electrical Position/MechToElec/floating-point/Mech To Elec'
 * '<S133>' : 'foc_controller/Mechanical to Electrical Position/MechToElec/floating-point/Compensate Offset/If Action Subsystem'
 * '<S134>' : 'foc_controller/Mechanical to Electrical Position/MechToElec/floating-point/Compensate Offset/If Action Subsystem1'
 * '<S135>' : 'foc_controller/Mechanical to Electrical Position/MechToElec/floating-point/Mech To Elec/Variant Subsystem'
 * '<S136>' : 'foc_controller/Mechanical to Electrical Position/MechToElec/floating-point/Mech To Elec/Variant Subsystem/Dialog'
 * '<S137>' : 'foc_controller/PWM Reference Generator/Amplitude Gain'
 * '<S138>' : 'foc_controller/PWM Reference Generator/Limiter'
 * '<S139>' : 'foc_controller/PWM Reference Generator/ModWaveToVolts'
 * '<S140>' : 'foc_controller/PWM Reference Generator/ModWavetoDuty'
 * '<S141>' : 'foc_controller/PWM Reference Generator/Modulation method'
 * '<S142>' : 'foc_controller/PWM Reference Generator/Normalize'
 * '<S143>' : 'foc_controller/PWM Reference Generator/Signal Routing'
 * '<S144>' : 'foc_controller/PWM Reference Generator/Voltage Input'
 * '<S145>' : 'foc_controller/PWM Reference Generator/Amplitude Gain/Passthrough'
 * '<S146>' : 'foc_controller/PWM Reference Generator/Limiter/Passthrough'
 * '<S147>' : 'foc_controller/PWM Reference Generator/ModWaveToVolts/Select'
 * '<S148>' : 'foc_controller/PWM Reference Generator/ModWaveToVolts/Signal Routing'
 * '<S149>' : 'foc_controller/PWM Reference Generator/ModWaveToVolts/Select/TerminateVdc'
 * '<S150>' : 'foc_controller/PWM Reference Generator/ModWaveToVolts/Signal Routing/SingleSignal'
 * '<S151>' : 'foc_controller/PWM Reference Generator/ModWavetoDuty/Saturation Dynamic'
 * '<S152>' : 'foc_controller/PWM Reference Generator/Modulation method/SVPWM'
 * '<S153>' : 'foc_controller/PWM Reference Generator/Modulation method/SVPWM/Gain'
 * '<S154>' : 'foc_controller/PWM Reference Generator/Modulation method/SVPWM/Half(Vmin+Vmax)'
 * '<S155>' : 'foc_controller/PWM Reference Generator/Modulation method/SVPWM/Gain/Gain2bySqrt3'
 * '<S156>' : 'foc_controller/PWM Reference Generator/Normalize/PassFirstInput'
 * '<S157>' : 'foc_controller/PWM Reference Generator/Signal Routing/Passthrough'
 * '<S158>' : 'foc_controller/PWM Reference Generator/Voltage Input/Valphabeta'
 * '<S159>' : 'foc_controller/PWM Reference Generator/Voltage Input/Valphabeta/Inverse Clarke Transform'
 * '<S160>' : 'foc_controller/PWM Reference Generator/Voltage Input/Valphabeta/Inverse Clarke Transform/Variant'
 * '<S161>' : 'foc_controller/PWM Reference Generator/Voltage Input/Valphabeta/Inverse Clarke Transform/Variant/mcb'
 * '<S162>' : 'foc_controller/PWM Reference Generator/Voltage Input/Valphabeta/Inverse Clarke Transform/Variant/mcb/Inverse Clarke Transform'
 * '<S163>' : 'foc_controller/PWM Reference Generator/Voltage Input/Valphabeta/Inverse Clarke Transform/Variant/mcb/Inverse Clarke Transform/Two phase input'
 * '<S164>' : 'foc_controller/Park Transform/Variant'
 * '<S165>' : 'foc_controller/Park Transform/Variant/mcb'
 * '<S166>' : 'foc_controller/Park Transform/Variant/mcb/Park Transform'
 * '<S167>' : 'foc_controller/Park Transform/Variant/mcb/Park Transform/Select'
 * '<S168>' : 'foc_controller/Park Transform/Variant/mcb/Park Transform/Select/Two Inputs'
 * '<S169>' : 'foc_controller/Park Transform/Variant/mcb/Park Transform/Select/Two Inputs/Two inputs CRL'
 * '<S170>' : 'foc_controller/Park Transform/Variant/mcb/Park Transform/Select/Two Inputs/Two inputs CRL/Switch_Axis'
 * '<S171>' : 'foc_controller/SinCos Embedded Optimized/Sine-Cosine Lookup'
 * '<S172>' : 'foc_controller/SinCos Embedded Optimized/Sine-Cosine Lookup/Interpolation'
 * '<S173>' : 'foc_controller/SinCos Embedded Optimized/Sine-Cosine Lookup/WrapUp'
 * '<S174>' : 'foc_controller/SinCos Embedded Optimized/Sine-Cosine Lookup/datatype'
 * '<S175>' : 'foc_controller/SinCos Embedded Optimized/Sine-Cosine Lookup/WrapUp/Compare To Zero'
 * '<S176>' : 'foc_controller/SinCos Embedded Optimized/Sine-Cosine Lookup/WrapUp/If Action Subsystem'
 * '<S177>' : 'foc_controller/SinCos Embedded Optimized/Sine-Cosine Lookup/WrapUp/If Action Subsystem1'
 * '<S178>' : 'foc_controller/SinCos Embedded Optimized/Sine-Cosine Lookup/datatype/datatype no change'
 */
#endif                                 /* foc_controller_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
