/*
 * irq_setup.h
 *
 *  Created on: Apr 3, 2025
 *      Author: Chronos
 */

#ifndef SRC_IRQ_SETUP_H_
#define SRC_IRQ_SETUP_H_

#include "xscugic.h"
#include "xparameters_ps.h"	/* defines XPAR values */

#define PLATFORM_EMAC_BASEADDR XPAR_XEMACPS_0_BASEADDR
#define INTC_DEVICE_ID		XPAR_SCUGIC_SINGLE_DEVICE_ID
#define INTC_BASE_ADDR		XPAR_SCUGIC_0_CPU_BASEADDR
#define INTC_DIST_BASE_ADDR	XPAR_SCUGIC_0_DIST_BASEADDR

void setup_interrupts(XScuGic* Intc, void* uartIRQCB);
void enable_interrupts(XScuGic* Intc);

#endif /* SRC_IRQ_SETUP_H_ */
