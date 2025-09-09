/*
 * gpsdo.h
 *
 *  Created on: May 5, 2025
 *      Author: Chronos
 */

#ifndef SRC_GPSDO_H_
#define SRC_GPSDO_H_

#include <xparameters.h>


#define GPSDO_SPI_DEVICE_ID				XPAR_PS7_SPI_1_DEVICE_ID

#define 	SPI_DEASSERT_CURRENT_SS   0x0F

//const u8 CLK_SPI_nCS_id = 0;
//const u8 DAC_SPI_nCS_id = 1;


int32_t spi_init_gpsdo(uint32_t device_id,
				 uint8_t  clk_pha,
				 uint8_t  clk_pol);
int spi_write_gpsdo(u8 slaveSel,
		unsigned char *txbuf, unsigned n_tx);

#endif /* SRC_GPSDO_H_ */
