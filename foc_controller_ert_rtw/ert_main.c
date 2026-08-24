/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: ert_main.c
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

#include <stddef.h>
#include <stdio.h>            /* This example main program uses printf/fflush */
#include "foc_controller.h"            /* Model header file */

static RT_MODEL_foc_controller_T foc_controller_M_;
static RT_MODEL_foc_controller_T *const foc_controller_MPtr = &foc_controller_M_;/* Real-time model */
static DW_foc_controller_T foc_controller_DW;/* Observable states */

/* '<Root>/id_ref' */
static real_T foc_controller_U_id_ref;

/* '<Root>/iq_ref' */
static real_T foc_controller_U_iq_ref;

/* '<Root>/measurements' */
static measurement foc_controller_U_measurements;

/* '<Root>/duty' */
static real_T foc_controller_Y_duty[3];

/*
 * Associating rt_OneStep with a real-time clock or interrupt service routine
 * is what makes the generated code "real-time".  The function rt_OneStep is
 * always associated with the base rate of the model.  Subrates are managed
 * by the base rate from inside the generated code.  Enabling/disabling
 * interrupts and floating point context switches are target specific.  This
 * example code indicates where these should take place relative to executing
 * the generated code step function.  Overrun behavior should be tailored to
 * your application needs.  This example simply sets an error status in the
 * real-time model and returns from rt_OneStep.
 */
void rt_OneStep(RT_MODEL_foc_controller_T *const foc_controller_M);
void rt_OneStep(RT_MODEL_foc_controller_T *const foc_controller_M)
{
  static boolean_T OverrunFlag = false;

  /* Disable interrupts here */

  /* Check for overrun */
  if (OverrunFlag) {
    rtmSetErrorStatus(foc_controller_M, "Overrun");
    return;
  }

  OverrunFlag = true;

  /* Save FPU context here (if necessary) */
  /* Re-enable timer or interrupt here */
  /* Set model inputs here */

  /* Step the model */
  foc_controller_step(foc_controller_M, foc_controller_U_id_ref,
                      foc_controller_U_iq_ref, &foc_controller_U_measurements,
                      foc_controller_Y_duty);

  /* Get model outputs here */

  /* Indicate task complete */
  OverrunFlag = false;

  /* Disable interrupts here */
  /* Restore FPU context here (if necessary) */
  /* Enable interrupts here */
}

/*
 * The example main function illustrates what is required by your
 * application code to initialize, execute, and terminate the generated code.
 * Attaching rt_OneStep to a real-time clock is target specific. This example
 * illustrates how you do this relative to initializing the model.
 */
int_T main(int_T argc, const char *argv[])
{
  RT_MODEL_foc_controller_T *const foc_controller_M = foc_controller_MPtr;

  /* Unused arguments */
  (void)(argc);
  (void)(argv);

  /* Pack model data into RTM */
  foc_controller_M->dwork = &foc_controller_DW;

  /* Initialize model */
  foc_controller_initialize(foc_controller_M, &foc_controller_U_id_ref,
    &foc_controller_U_iq_ref, &foc_controller_U_measurements,
    foc_controller_Y_duty);

  /* Attach rt_OneStep to a timer or interrupt service routine with
   * period 5.0E-5 seconds (base rate of the model) here.
   * The call syntax for rt_OneStep is
   *
   *  rt_OneStep(foc_controller_M);
   */
  printf("Warning: The simulation will run forever. "
         "Generated ERT main won't simulate model step behavior. "
         "To change this behavior select the 'MAT-file logging' option.\n");
  fflush((NULL));
  while (rtmGetErrorStatus(foc_controller_M) == (NULL)) {
    /*  Perform application tasks here */
  }

  /* Terminate model */
  foc_controller_terminate(foc_controller_M);
  return 0;
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
