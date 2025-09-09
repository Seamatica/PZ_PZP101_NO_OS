/*
 * uart_com.h
 *
 *  Created on: Apr 3, 2025
 *      Author: Chronos
 */
#ifndef SRC_UART_COM_H_
#define SRC_UART_COM_H_

#include "xuartps.h"
#include "xparameters.h"
#include "sleep.h"


#define GPS_UART_DEVICE_ID     XPAR_PS7_UART_0_DEVICE_ID
#define GPS_UART_INT_IRQ_ID    XPAR_XUARTPS_0_INTR


struct uartIRQcallback
{
	XUartPs *XUartPsObj;
	u8 *uart_RecvBufferPtr;
	u8* uart_RecvBuffer;
	u32 uart_BUFFER_SIZE;
	volatile u32 TotalRecvCnt;
	volatile int uart_time_out_flag;
};

int Uart_Init(struct uartIRQcallback* uartIRQCB, u16 DeviceId, XUartPsFormat* uart_format);
void uart_irq_Handler(void *CallBackRef);
void uart_send(XUartPs *InstancePtr,u8 *data,int length);  //my_uart_send

#endif /* SRC_UART_COM_H_ */
