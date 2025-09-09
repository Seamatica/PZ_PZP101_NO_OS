/*
 * uart_com.c
 *
 *  Created on: Apr 3, 2025
 *      Author: Chronos
 */


#include "uart_com.h"


int Uart_Init(struct uartIRQcallback* uartIRQCB, u16 DeviceId, XUartPsFormat* uart_format)
{
	int Status;
	XUartPs_Config *Config;

	//uart_RecvBufferPtr = uart_RecvBuffer;
	//TotalRecvCnt = 0;

	Config = XUartPs_LookupConfig(DeviceId);
	if (NULL == Config) {
		return XST_FAILURE;
	}
	Status = XUartPs_CfgInitialize(uartIRQCB->XUartPsObj, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	Status = XUartPs_SelfTest(uartIRQCB->XUartPsObj);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}


	XUartPs_SetOperMode(uartIRQCB->XUartPsObj, XUARTPS_OPER_MODE_NORMAL);
	XUartPs_SetDataFormat(uartIRQCB->XUartPsObj, uart_format);
	XUartPs_SetFifoThreshold(uartIRQCB->XUartPsObj, 8);
	XUartPs_SetRecvTimeout(uartIRQCB->XUartPsObj, 80);
	return XST_SUCCESS;
}


void uart_irq_Handler(void *CallBackRef)
{
	struct uartIRQcallback* uartIRQcallbackPtr = (struct uartIRQcallback* )CallBackRef;

	XUartPs *UartInstancePtr = uartIRQcallbackPtr->XUartPsObj;
	u32 ReceivedCount = 0 ;
	u32 IsrStatus ;

	IsrStatus = XUartPs_ReadReg(UartInstancePtr->Config.BaseAddress,
				   XUARTPS_IMR_OFFSET);
	IsrStatus &= XUartPs_ReadReg(UartInstancePtr->Config.BaseAddress,
				   XUARTPS_ISR_OFFSET);

	if (IsrStatus & (u32)XUARTPS_IXR_RXOVR)
	{
		if(uartIRQcallbackPtr->TotalRecvCnt +8 + 1 < uartIRQcallbackPtr->uart_BUFFER_SIZE){
			ReceivedCount = XUartPs_Recv(UartInstancePtr, uartIRQcallbackPtr->uart_RecvBufferPtr, (uartIRQcallbackPtr->uart_BUFFER_SIZE - uartIRQcallbackPtr->TotalRecvCnt)) ;
			uartIRQcallbackPtr->TotalRecvCnt += ReceivedCount ;
			uartIRQcallbackPtr->uart_RecvBufferPtr += ReceivedCount ;
		}

		XUartPs_WriteReg(UartInstancePtr->Config.BaseAddress, XUARTPS_ISR_OFFSET, XUARTPS_IXR_RXOVR) ;

	}

	if(IsrStatus & (u32)XUARTPS_IXR_TOUT){
		uartIRQcallbackPtr->uart_time_out_flag = 1;
		if(uartIRQcallbackPtr->TotalRecvCnt +8 + 1 < uartIRQcallbackPtr->uart_BUFFER_SIZE){
			ReceivedCount = XUartPs_Recv(UartInstancePtr, uartIRQcallbackPtr->uart_RecvBufferPtr, (uartIRQcallbackPtr->uart_BUFFER_SIZE - uartIRQcallbackPtr->TotalRecvCnt)) ;
			uartIRQcallbackPtr->TotalRecvCnt += ReceivedCount ;
			uartIRQcallbackPtr->uart_RecvBufferPtr += ReceivedCount ;
		}

		XUartPs_WriteReg(UartInstancePtr->Config.BaseAddress, XUARTPS_ISR_OFFSET, XUARTPS_IXR_TOUT) ;
		uartIRQcallbackPtr->uart_RecvBufferPtr = uartIRQcallbackPtr->uart_RecvBuffer;
		uartIRQcallbackPtr->TotalRecvCnt = 0;
	}

}


void uart_send(XUartPs *InstancePtr,u8 *data, int length){
	int SentCount = 0;
	while (SentCount < length) {
		/* Transmit the data */
		SentCount += XUartPs_Send(InstancePtr,
					   &data[SentCount], 1);
	}
}
