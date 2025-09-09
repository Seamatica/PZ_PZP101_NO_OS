/*
 * irq_setup.c
 *
 *  Created on: Apr 3, 2025
 *      Author: Chronos
 */


#include "irq_setup.h"
#include "uart_com.h"



void setup_interrupts(XScuGic* Intc, void* uartIRQCB)
{
	int Status;
	/////////////////////init gic/////////////////////////////////////
	XScuGic *intc_instance_ptr = Intc;

	//	XScuGic_DeviceInitialize(INTC_DEVICE_ID);
	XScuGic_Config *IntcConfig; //GIC config
	IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
	if (NULL == IntcConfig) {	xil_printf("IntcConfig FAILURE...\r\n");}
	Status = XScuGic_CfgInitialize(intc_instance_ptr, IntcConfig, IntcConfig->CpuBaseAddress);
	if (Status != XST_SUCCESS) {	xil_printf("XScuGic_CfgInitialize FAILURE...\r\n");}

	///////////////////////uart intr/////////////////////////////////
	XScuGic_SetPriorityTriggerType(intc_instance_ptr, GPS_UART_INT_IRQ_ID,200, 0x3);

	Status = XScuGic_Connect(intc_instance_ptr, GPS_UART_INT_IRQ_ID,(Xil_ExceptionHandler) uart_irq_Handler, uartIRQCB);
	if (Status != XST_SUCCESS) {	xil_printf(" UART XScuGic_Connect FAILURE...\r\n");}

	struct uartIRQcallback* uartIRQcallbackPtr = (struct uartIRQcallback* )uartIRQCB;
	XUartPs_SetInterruptMask(uartIRQcallbackPtr->XUartPsObj, XUARTPS_IXR_RXOVR | XUARTPS_IXR_TOUT);

	Xil_ExceptionInit();


	/*
	 * Connect the interrupt controller interrupt handler to the hardware
	 * interrupt handling logic in the processor.
	 */
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_IRQ_INT,
			(Xil_ExceptionHandler)XScuGic_DeviceInterruptHandler,
			(void *)INTC_DEVICE_ID);

	return;
}



void enable_interrupts(XScuGic* Intc)
{
	/*
	 * Enable non-critical exceptions.
	 */
	Xil_ExceptionEnableMask(XIL_EXCEPTION_IRQ);

	XScuGic_Enable(Intc, GPS_UART_INT_IRQ_ID);

	return;
}

