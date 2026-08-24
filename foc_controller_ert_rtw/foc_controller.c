/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: foc_controller.c
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

#include "foc_controller.h"
#include <math.h>
#include "rt_nonfinite.h"
#include "foc_controller_types.h"
#include "rtwtypes.h"
#include <string.h>

const measurement foc_controller_rtZmeasurement = { 0.0,/* MtrPos */
  { 0.0, 0.0, 0.0 },                   /* currents */
  0.0                                  /* speed */
};

/* Model step function */
void foc_controller_step(RT_MODEL_foc_controller_T *const foc_controller_M,
  real_T foc_controller_U_id_ref, real_T foc_controller_U_iq_ref, measurement
  *foc_controller_U_measurements, real_T foc_controller_Y_duty[3])
{
  DW_foc_controller_T *foc_controller_DW = foc_controller_M->dwork;
  real_T rtb_DeadZone;
  real_T rtb_DeadZone_k;
  real_T rtb_IntegralGain;
  real_T rtb_IntegralGain_d;
  real_T rtb_Min;
  real_T rtb_Saturation;
  real_T rtb_Sum4;
  real_T rtb_Sum6;
  real_T rtb_Switch_pc_idx_0;
  real_T rtb_one_by_two;
  uint16_T rtb_Get_Integer;
  int8_T tmp;
  int8_T tmp_0;

  /* If: '<S131>/If' incorporates:
   *  Constant: '<S130>/Constant1'
   *  Constant: '<S133>/Constant'
   *  Gain: '<S136>/Number of pole pairs'
   *  Inport: '<Root>/measurements'
   *  SignalConversion generated from: '<Root>/measurements'
   *  Sum: '<S133>/Add'
   *  Switch: '<S130>/Switch'
   */
  if (foc_controller_U_measurements->MtrPos <= 0.0) {
    /* Outputs for IfAction SubSystem: '<S131>/If Action Subsystem' incorporates:
     *  ActionPort: '<S133>/Action Port'
     */
    rtb_IntegralGain_d = foc_controller_U_measurements->MtrPos +
      6.283185307179586;

    /* End of Outputs for SubSystem: '<S131>/If Action Subsystem' */
  } else {
    rtb_IntegralGain_d = foc_controller_U_measurements->MtrPos;
  }

  rtb_DeadZone_k = 4.0 * rtb_IntegralGain_d;

  /* End of If: '<S131>/If' */

  /* Gain: '<S173>/convert_pu' incorporates:
   *  Gain: '<S132>/Multiply'
   *  Gain: '<S132>/Multiply1'
   *  Rounding: '<S132>/Floor'
   *  Sum: '<S132>/Add'
   */
  rtb_DeadZone_k = (rtb_DeadZone_k - floor(0.15915494309189535 * rtb_DeadZone_k)
                    * 6.283185307179586) * 0.15915494309189535;

  /* If: '<S173>/If' incorporates:
   *  Constant: '<S175>/Constant'
   *  RelationalOperator: '<S175>/Compare'
   */
  if (rtb_DeadZone_k < 0.0) {
    /* Outputs for IfAction SubSystem: '<S173>/If Action Subsystem' incorporates:
     *  ActionPort: '<S176>/Action Port'
     */
    /* DataTypeConversion: '<S176>/Convert_uint16' */
    rtb_IntegralGain_d = floor(rtb_DeadZone_k);
    if (rtIsInf(rtb_IntegralGain_d)) {
      rtb_IntegralGain_d = 0.0;
    } else {
      rtb_IntegralGain_d = fmod(rtb_IntegralGain_d, 65536.0);
    }

    /* Sum: '<S176>/Sum' incorporates:
     *  DataTypeConversion: '<S176>/Convert_back'
     *  DataTypeConversion: '<S176>/Convert_uint16'
     */
    rtb_DeadZone_k -= (real_T)(rtb_IntegralGain_d < 0.0 ? (int32_T)(int16_T)
      -(int16_T)(uint16_T)-rtb_IntegralGain_d : (int32_T)(int16_T)(uint16_T)
      rtb_IntegralGain_d);

    /* End of Outputs for SubSystem: '<S173>/If Action Subsystem' */
  } else {
    /* Outputs for IfAction SubSystem: '<S173>/If Action Subsystem1' incorporates:
     *  ActionPort: '<S177>/Action Port'
     */
    /* DataTypeConversion: '<S177>/Convert_uint16' */
    rtb_IntegralGain_d = trunc(rtb_DeadZone_k);
    if (rtIsNaN(rtb_IntegralGain_d) || rtIsInf(rtb_IntegralGain_d)) {
      rtb_IntegralGain_d = 0.0;
    } else {
      rtb_IntegralGain_d = fmod(rtb_IntegralGain_d, 65536.0);
    }

    /* Sum: '<S177>/Sum' incorporates:
     *  DataTypeConversion: '<S177>/Convert_back'
     *  DataTypeConversion: '<S177>/Convert_uint16'
     */
    rtb_DeadZone_k -= (real_T)(int16_T)(uint16_T)rtb_IntegralGain_d;

    /* End of Outputs for SubSystem: '<S173>/If Action Subsystem1' */
  }

  /* End of If: '<S173>/If' */

  /* Gain: '<S171>/indexing' */
  rtb_DeadZone_k *= 800.0;

  /* DataTypeConversion: '<S171>/Get_Integer' */
  rtb_IntegralGain_d = trunc(rtb_DeadZone_k);
  if (rtIsNaN(rtb_IntegralGain_d) || rtIsInf(rtb_IntegralGain_d)) {
    rtb_IntegralGain_d = 0.0;
  } else {
    rtb_IntegralGain_d = fmod(rtb_IntegralGain_d, 65536.0);
  }

  rtb_Get_Integer = (uint16_T)(rtb_IntegralGain_d < 0.0 ? (int32_T)(uint16_T)
    -(int16_T)(uint16_T)-rtb_IntegralGain_d : (int32_T)(uint16_T)
    rtb_IntegralGain_d);

  /* End of DataTypeConversion: '<S171>/Get_Integer' */

  /* Sum: '<S171>/Sum2' incorporates:
   *  DataTypeConversion: '<S171>/Data Type Conversion1'
   */
  rtb_IntegralGain_d = rtb_DeadZone_k - (real_T)rtb_Get_Integer;

  /* Selector: '<S171>/Lookup' incorporates:
   *  Constant: '<S171>/sine_table_values'
   *  Sum: '<S171>/Sum'
   */
  rtb_DeadZone_k = foc_controller_ConstP.sine_table_values_Value[rtb_Get_Integer];

  /* Sum: '<S172>/Sum4' incorporates:
   *  Constant: '<S171>/offset'
   *  Constant: '<S171>/sine_table_values'
   *  Product: '<S172>/Product'
   *  Selector: '<S171>/Lookup'
   *  Sum: '<S171>/Sum'
   *  Sum: '<S172>/Sum3'
   */
  rtb_Sum4 = (foc_controller_ConstP.sine_table_values_Value[(int32_T)
              (rtb_Get_Integer + 1U)] - rtb_DeadZone_k) * rtb_IntegralGain_d +
    rtb_DeadZone_k;

  /* Selector: '<S171>/Lookup' incorporates:
   *  Constant: '<S171>/offset'
   *  Constant: '<S171>/sine_table_values'
   *  Sum: '<S171>/Sum'
   *  Sum: '<S172>/Sum5'
   */
  rtb_DeadZone_k = foc_controller_ConstP.sine_table_values_Value[(int32_T)
    (rtb_Get_Integer + 200U)];

  /* Sum: '<S172>/Sum6' incorporates:
   *  Constant: '<S171>/offset'
   *  Constant: '<S171>/sine_table_values'
   *  Product: '<S172>/Product1'
   *  Selector: '<S171>/Lookup'
   *  Sum: '<S171>/Sum'
   *  Sum: '<S172>/Sum5'
   */
  rtb_Sum6 = (foc_controller_ConstP.sine_table_values_Value[(int32_T)
              (rtb_Get_Integer + 201U)] - rtb_DeadZone_k) * rtb_IntegralGain_d +
    rtb_DeadZone_k;

  /* Outputs for Atomic SubSystem: '<S12>/Two phase CRL wrap' */
  /* Gain: '<S13>/one_by_sqrt3' incorporates:
   *  Inport: '<Root>/measurements'
   *  SignalConversion generated from: '<Root>/measurements'
   *  Sum: '<S13>/a_plus_2b'
   */
  rtb_one_by_two = ((foc_controller_U_measurements->currents[0] +
                     foc_controller_U_measurements->currents[1]) +
                    foc_controller_U_measurements->currents[1]) *
    0.5773502691896258;

  /* Outputs for Atomic SubSystem: '<S168>/Two inputs CRL' */
  /* Sum: '<Root>/Subtract' incorporates:
   *  AlgorithmDescriptorDelegate generated from: '<S13>/a16'
   *  Inport: '<Root>/id_ref'
   *  Inport: '<Root>/measurements'
   *  Product: '<S169>/acos'
   *  Product: '<S169>/bsin'
   *  SignalConversion generated from: '<Root>/measurements'
   *  Sum: '<S169>/sum_Ds'
   */
  rtb_IntegralGain_d = foc_controller_U_id_ref -
    (foc_controller_U_measurements->currents[0] * rtb_Sum6 + rtb_one_by_two *
     rtb_Sum4);

  /* End of Outputs for SubSystem: '<S168>/Two inputs CRL' */
  /* End of Outputs for SubSystem: '<S12>/Two phase CRL wrap' */

  /* Sum: '<S59>/Sum' incorporates:
   *  DiscreteIntegrator: '<S50>/Integrator'
   *  Gain: '<S55>/Proportional Gain'
   */
  rtb_DeadZone_k = 2.312 * rtb_IntegralGain_d +
    foc_controller_DW->Integrator_DSTATE;

  /* Saturate: '<S57>/Saturation' */
  if (rtb_DeadZone_k > 346.4101615137755) {
    rtb_Saturation = 346.4101615137755;
  } else if (rtb_DeadZone_k < -346.4101615137755) {
    rtb_Saturation = -346.4101615137755;
  } else {
    rtb_Saturation = rtb_DeadZone_k;
  }

  /* End of Saturate: '<S57>/Saturation' */

  /* Outputs for Atomic SubSystem: '<S168>/Two inputs CRL' */
  /* Outputs for Atomic SubSystem: '<S12>/Two phase CRL wrap' */
  /* Sum: '<Root>/Subtract1' incorporates:
   *  AlgorithmDescriptorDelegate generated from: '<S13>/a16'
   *  Inport: '<Root>/iq_ref'
   *  Inport: '<Root>/measurements'
   *  Product: '<S169>/asin'
   *  Product: '<S169>/bcos'
   *  SignalConversion generated from: '<Root>/measurements'
   *  Sum: '<S169>/sum_Qs'
   */
  rtb_IntegralGain = foc_controller_U_iq_ref - (rtb_one_by_two * rtb_Sum6 -
    foc_controller_U_measurements->currents[0] * rtb_Sum4);

  /* End of Outputs for SubSystem: '<S12>/Two phase CRL wrap' */
  /* End of Outputs for SubSystem: '<S168>/Two inputs CRL' */

  /* Sum: '<S120>/Sum' incorporates:
   *  DiscreteIntegrator: '<S111>/Integrator'
   *  Gain: '<S116>/Proportional Gain'
   */
  rtb_DeadZone = 2.312 * rtb_IntegralGain +
    foc_controller_DW->Integrator_DSTATE_f;

  /* Saturate: '<S118>/Saturation' */
  if (rtb_DeadZone > 346.4101615137755) {
    rtb_one_by_two = 346.4101615137755;
  } else if (rtb_DeadZone < -346.4101615137755) {
    rtb_one_by_two = -346.4101615137755;
  } else {
    rtb_one_by_two = rtb_DeadZone;
  }

  /* End of Saturate: '<S118>/Saturation' */

  /* Outputs for Atomic SubSystem: '<S72>/Two inputs CRL' */
  /* Gain: '<Root>/Gain_Vd_to_pu' incorporates:
   *  Product: '<S73>/dcos'
   *  Product: '<S73>/qsin'
   *  Sum: '<S73>/sum_alpha'
   */
  rtb_Min = (rtb_Saturation * rtb_Sum6 - rtb_one_by_two * rtb_Sum4) *
    0.0028867513459481286;

  /* End of Outputs for SubSystem: '<S72>/Two inputs CRL' */

  /* Gain: '<S163>/Ka' */
  rtb_Switch_pc_idx_0 = rtb_Min;

  /* Gain: '<S163>/one_by_two' */
  rtb_Min *= 0.5;

  /* Outputs for Atomic SubSystem: '<S72>/Two inputs CRL' */
  /* Gain: '<S163>/sqrt3_by_two' incorporates:
   *  Gain: '<Root>/Gain_Vq_to_pu'
   *  Product: '<S73>/dsin'
   *  Product: '<S73>/qcos'
   *  Sum: '<S73>/sum_beta'
   */
  rtb_one_by_two = (rtb_one_by_two * rtb_Sum6 + rtb_Saturation * rtb_Sum4) *
    0.0028867513459481286 * 0.8660254037844386;

  /* End of Outputs for SubSystem: '<S72>/Two inputs CRL' */

  /* Gain: '<S163>/Kb' incorporates:
   *  Sum: '<S163>/add_b'
   */
  rtb_Sum4 = rtb_one_by_two - rtb_Min;

  /* Gain: '<S163>/Kc' incorporates:
   *  Sum: '<S163>/add_c'
   */
  rtb_Min = (0.0 - rtb_Min) - rtb_one_by_two;

  /* Gain: '<S154>/one_by_two' incorporates:
   *  MinMax: '<S154>/Max'
   *  MinMax: '<S154>/Min'
   *  Sum: '<S154>/Add'
   */
  rtb_one_by_two = (fmax(fmax(rtb_Switch_pc_idx_0, rtb_Sum4), rtb_Min) + fmin
                    (fmin(rtb_Switch_pc_idx_0, rtb_Sum4), rtb_Min)) * -0.5;

  /* Sum: '<S152>/Add3' incorporates:
   *  Gain: '<S155>/Gain'
   */
  foc_controller_Y_duty[0] = rtb_Switch_pc_idx_0 + rtb_one_by_two;

  /* Sum: '<S152>/Add1' incorporates:
   *  Gain: '<S155>/Gain'
   *  Sum: '<S152>/Add3'
   */
  foc_controller_Y_duty[1] = rtb_Sum4 + rtb_one_by_two;

  /* Sum: '<S152>/Add2' incorporates:
   *  Gain: '<S155>/Gain'
   *  Sum: '<S152>/Add3'
   */
  foc_controller_Y_duty[2] = rtb_one_by_two + rtb_Min;

  /* Gain: '<S155>/Gain' incorporates:
   *  Sum: '<S152>/Add3'
   */
  rtb_Switch_pc_idx_0 = 1.1547005383792517 * foc_controller_Y_duty[0];

  /* Switch: '<S151>/Switch2' incorporates:
   *  Constant: '<S140>/Constant2'
   *  Constant: '<S140>/Constant3'
   *  RelationalOperator: '<S151>/LowerRelop1'
   *  RelationalOperator: '<S151>/UpperRelop'
   *  Switch: '<S151>/Switch'
   */
  if (rtb_Switch_pc_idx_0 > 1.0) {
    rtb_Switch_pc_idx_0 = 1.0;
  } else if (rtb_Switch_pc_idx_0 < -1.0) {
    /* Switch: '<S151>/Switch' incorporates:
     *  Constant: '<S140>/Constant3'
     */
    rtb_Switch_pc_idx_0 = -1.0;
  }

  /* Outport: '<Root>/duty' incorporates:
   *  Constant: '<S140>/Constant'
   *  Gain: '<S140>/Gain'
   *  Gain: '<S155>/Gain'
   *  RelationalOperator: '<S151>/LowerRelop1'
   *  Sum: '<S140>/Sum'
   *  Sum: '<S152>/Add3'
   *  Switch: '<S151>/Switch2'
   */
  foc_controller_Y_duty[0] = 0.5 * rtb_Switch_pc_idx_0 + 0.5;

  /* Gain: '<S155>/Gain' incorporates:
   *  Sum: '<S152>/Add3'
   */
  rtb_Switch_pc_idx_0 = 1.1547005383792517 * foc_controller_Y_duty[1];

  /* Switch: '<S151>/Switch2' incorporates:
   *  Constant: '<S140>/Constant2'
   *  Constant: '<S140>/Constant3'
   *  RelationalOperator: '<S151>/LowerRelop1'
   *  RelationalOperator: '<S151>/UpperRelop'
   *  Switch: '<S151>/Switch'
   */
  if (rtb_Switch_pc_idx_0 > 1.0) {
    rtb_Switch_pc_idx_0 = 1.0;
  } else if (rtb_Switch_pc_idx_0 < -1.0) {
    /* Switch: '<S151>/Switch' incorporates:
     *  Constant: '<S140>/Constant3'
     */
    rtb_Switch_pc_idx_0 = -1.0;
  }

  /* Outport: '<Root>/duty' incorporates:
   *  Constant: '<S140>/Constant'
   *  Gain: '<S140>/Gain'
   *  Gain: '<S155>/Gain'
   *  RelationalOperator: '<S151>/LowerRelop1'
   *  Sum: '<S140>/Sum'
   *  Sum: '<S152>/Add3'
   *  Switch: '<S151>/Switch2'
   */
  foc_controller_Y_duty[1] = 0.5 * rtb_Switch_pc_idx_0 + 0.5;

  /* Gain: '<S155>/Gain' incorporates:
   *  Sum: '<S152>/Add3'
   */
  rtb_Switch_pc_idx_0 = 1.1547005383792517 * foc_controller_Y_duty[2];

  /* Switch: '<S151>/Switch2' incorporates:
   *  Constant: '<S140>/Constant2'
   *  Constant: '<S140>/Constant3'
   *  RelationalOperator: '<S151>/LowerRelop1'
   *  RelationalOperator: '<S151>/UpperRelop'
   *  Switch: '<S151>/Switch'
   */
  if (rtb_Switch_pc_idx_0 > 1.0) {
    rtb_Switch_pc_idx_0 = 1.0;
  } else if (rtb_Switch_pc_idx_0 < -1.0) {
    /* Switch: '<S151>/Switch' incorporates:
     *  Constant: '<S140>/Constant3'
     */
    rtb_Switch_pc_idx_0 = -1.0;
  }

  /* Outport: '<Root>/duty' incorporates:
   *  Constant: '<S140>/Constant'
   *  Gain: '<S140>/Gain'
   *  Gain: '<S155>/Gain'
   *  RelationalOperator: '<S151>/LowerRelop1'
   *  Sum: '<S140>/Sum'
   *  Sum: '<S152>/Add3'
   *  Switch: '<S151>/Switch2'
   */
  foc_controller_Y_duty[2] = 0.5 * rtb_Switch_pc_idx_0 + 0.5;

  /* DeadZone: '<S103>/DeadZone' */
  if (rtb_DeadZone > 346.4101615137755) {
    rtb_DeadZone -= 346.4101615137755;
  } else if (rtb_DeadZone >= -346.4101615137755) {
    rtb_DeadZone = 0.0;
  } else {
    rtb_DeadZone -= -346.4101615137755;
  }

  /* End of DeadZone: '<S103>/DeadZone' */

  /* Gain: '<S108>/Integral Gain' */
  rtb_IntegralGain *= 0.03706;

  /* DeadZone: '<S42>/DeadZone' */
  if (rtb_DeadZone_k > 346.4101615137755) {
    rtb_DeadZone_k -= 346.4101615137755;
  } else if (rtb_DeadZone_k >= -346.4101615137755) {
    rtb_DeadZone_k = 0.0;
  } else {
    rtb_DeadZone_k -= -346.4101615137755;
  }

  /* End of DeadZone: '<S42>/DeadZone' */

  /* Gain: '<S47>/Integral Gain' */
  rtb_IntegralGain_d *= 0.03706;

  /* Switch: '<S40>/Switch1' incorporates:
   *  Constant: '<S40>/Clamping_zero'
   *  Constant: '<S40>/Constant'
   *  Constant: '<S40>/Constant2'
   *  RelationalOperator: '<S40>/fix for DT propagation issue'
   */
  if (rtb_DeadZone_k > 0.0) {
    tmp = 1;
  } else {
    tmp = -1;
  }

  /* Switch: '<S40>/Switch2' incorporates:
   *  Constant: '<S40>/Clamping_zero'
   *  Constant: '<S40>/Constant3'
   *  Constant: '<S40>/Constant4'
   *  RelationalOperator: '<S40>/fix for DT propagation issue1'
   */
  if (rtb_IntegralGain_d > 0.0) {
    tmp_0 = 1;
  } else {
    tmp_0 = -1;
  }

  /* Switch: '<S40>/Switch' incorporates:
   *  Constant: '<S40>/Clamping_zero'
   *  Constant: '<S40>/Constant1'
   *  Logic: '<S40>/AND3'
   *  RelationalOperator: '<S40>/Equal1'
   *  RelationalOperator: '<S40>/Relational Operator'
   *  Switch: '<S40>/Switch1'
   *  Switch: '<S40>/Switch2'
   */
  if ((rtb_DeadZone_k != 0.0) && (tmp == tmp_0)) {
    rtb_IntegralGain_d = 0.0;
  }

  /* Update for DiscreteIntegrator: '<S50>/Integrator' incorporates:
   *  Switch: '<S40>/Switch'
   */
  foc_controller_DW->Integrator_DSTATE += rtb_IntegralGain_d;
  if (foc_controller_DW->Integrator_DSTATE > 346.4101615137755) {
    foc_controller_DW->Integrator_DSTATE = 346.4101615137755;
  } else if (foc_controller_DW->Integrator_DSTATE < -346.4101615137755) {
    foc_controller_DW->Integrator_DSTATE = -346.4101615137755;
  }

  /* End of Update for DiscreteIntegrator: '<S50>/Integrator' */

  /* Switch: '<S101>/Switch1' incorporates:
   *  Constant: '<S101>/Clamping_zero'
   *  Constant: '<S101>/Constant'
   *  Constant: '<S101>/Constant2'
   *  RelationalOperator: '<S101>/fix for DT propagation issue'
   */
  if (rtb_DeadZone > 0.0) {
    tmp = 1;
  } else {
    tmp = -1;
  }

  /* Switch: '<S101>/Switch2' incorporates:
   *  Constant: '<S101>/Clamping_zero'
   *  Constant: '<S101>/Constant3'
   *  Constant: '<S101>/Constant4'
   *  RelationalOperator: '<S101>/fix for DT propagation issue1'
   */
  if (rtb_IntegralGain > 0.0) {
    tmp_0 = 1;
  } else {
    tmp_0 = -1;
  }

  /* Switch: '<S101>/Switch' incorporates:
   *  Constant: '<S101>/Clamping_zero'
   *  Constant: '<S101>/Constant1'
   *  Logic: '<S101>/AND3'
   *  RelationalOperator: '<S101>/Equal1'
   *  RelationalOperator: '<S101>/Relational Operator'
   *  Switch: '<S101>/Switch1'
   *  Switch: '<S101>/Switch2'
   */
  if ((rtb_DeadZone != 0.0) && (tmp == tmp_0)) {
    rtb_IntegralGain = 0.0;
  }

  /* Update for DiscreteIntegrator: '<S111>/Integrator' incorporates:
   *  Switch: '<S101>/Switch'
   */
  foc_controller_DW->Integrator_DSTATE_f += rtb_IntegralGain;
  if (foc_controller_DW->Integrator_DSTATE_f > 346.4101615137755) {
    foc_controller_DW->Integrator_DSTATE_f = 346.4101615137755;
  } else if (foc_controller_DW->Integrator_DSTATE_f < -346.4101615137755) {
    foc_controller_DW->Integrator_DSTATE_f = -346.4101615137755;
  }

  /* End of Update for DiscreteIntegrator: '<S111>/Integrator' */
}

/* Model initialize function */
void foc_controller_initialize(RT_MODEL_foc_controller_T *const foc_controller_M,
  real_T *foc_controller_U_id_ref, real_T *foc_controller_U_iq_ref, measurement *
  foc_controller_U_measurements, real_T foc_controller_Y_duty[3])
{
  DW_foc_controller_T *foc_controller_DW = foc_controller_M->dwork;

  /* Registration code */

  /* states (dwork) */
  (void) memset((void *)foc_controller_DW, 0,
                sizeof(DW_foc_controller_T));

  /* external inputs */
  *foc_controller_U_id_ref = 0.0;
  *foc_controller_U_iq_ref = 0.0;
  *foc_controller_U_measurements = foc_controller_rtZmeasurement;

  /* external outputs */
  (void)memset(&foc_controller_Y_duty[0], 0, 3U * sizeof(real_T));
}

/* Model terminate function */
void foc_controller_terminate(RT_MODEL_foc_controller_T *const foc_controller_M)
{
  /* (no terminate code required) */
  UNUSED_PARAMETER(foc_controller_M);
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
