/*
 * gpsdo.c
 *
 *  Created on: May 5, 2025
 *      Author: Chronos
 */


#include <stdint.h>
#include <xparameters.h>
#ifdef _XPARAMETERS_PS_H_
#include <xgpiops.h>
#include <xspips.h>
#else
#include <xgpio.h>
#include <xgpio_l.h>
#include <xspi.h>
#endif
#include "util.h"

#include "gpsdo.h"
#ifdef _XPARAMETERS_PS_H_
#include <sleep.h>
#else
static inline void usleep(unsigned long usleep)
{
	unsigned long delay = 0;

	for(delay = 0; delay < usleep * 10; delay++);
}
#endif



/******************************************************************************/
/************************ Variables Definitions *******************************/
/******************************************************************************/
#ifdef _XPARAMETERS_PS_H_
XSpiPs_Config	*spi_config_gpsdo;
XSpiPs			spi_instance_gpsdo;
//#else
//XSpi_Config		*spi_config_gpsdo;
//XSpi			spi_instance_gpsdo;
#endif



/***************************************************************************//**
 * @brief spi_init_gpsdo
*******************************************************************************/
int32_t spi_init_gpsdo(uint32_t device_id,
		 uint8_t  clk_pha,
		 uint8_t  clk_pol)
{

	uint32_t base_addr	 = 0;
	uint32_t spi_options = 0;
#ifdef _XPARAMETERS_PS_H_

	s32 cmdStatus = -100;

	spi_config_gpsdo = XSpiPs_LookupConfig(device_id);
	base_addr = spi_config_gpsdo->BaseAddress;

	cmdStatus = XSpiPs_CfgInitialize(&spi_instance_gpsdo, spi_config_gpsdo, base_addr);
	if(cmdStatus == XST_SUCCESS)
	{
		printf("XSpiPs_CfgInitialize. XST_SUCCESS\n");
	}
	else if(cmdStatus == XST_DEVICE_BUSY )
	{
		printf("XSpiPs_CfgInitialize. XST_DEVICE_BUSY\n");
	}
	else
	{
		printf("XSpiPs_CfgInitialize. Unknown error\n");
	}

	spi_options = XSPIPS_MASTER_OPTION |
		      (clk_pol ? XSPIPS_CLK_ACTIVE_LOW_OPTION : 0) |
		      (clk_pha ? XSPIPS_CLK_PHASE_1_OPTION : 0);// |
		      //XSPIPS_FORCE_SSELECT_OPTION;

	cmdStatus = XSpiPs_SetOptions(&spi_instance_gpsdo, spi_options);
	if(cmdStatus == XST_SUCCESS)
	{
		printf("XSpiPs_SetOptions. XST_SUCCESS\n");
	}
	else if(cmdStatus == XST_DEVICE_BUSY )
	{
		printf("XSpiPs_SetOptions. XST_DEVICE_BUSY\n");
	}
	else
	{
		printf("XSpiPs_SetOptions. Unknown error\n");
	}

	cmdStatus = XSpiPs_SetClkPrescaler(&spi_instance_gpsdo, XSPIPS_CLK_PRESCALE_16);
	if(cmdStatus == XST_SUCCESS)
	{
		printf("XSpiPs_SetClkPrescaler. XST_SUCCESS\n");
	}
	else if(cmdStatus == XST_DEVICE_BUSY )
	{
		printf("XSpiPs_SetClkPrescaler. XST_DEVICE_BUSY\n");
	}
	else
	{
		printf("XSpiPs_SetClkPrescaler. Unknown error\n");
	}

	cmdStatus = XSpiPs_SetDelays(&spi_instance_gpsdo, 0, 4, 0, 0);
	if(cmdStatus == XST_SUCCESS)
	{
		printf("XSpiPs_SetDelays. XST_SUCCESS\n");
	}
	else if(cmdStatus == XST_DEVICE_BUSY )
	{
		printf("XSpiPs_SetDelays. XST_DEVICE_BUSY\n");
	}
	else
	{
		printf("XSpiPs_SetDelays. Unknown error\n");
	}

//#else
//	XSpi_Initialize(&spi_instance, device_id);
//	XSpi_Stop(&spi_instance);
//	spi_config = XSpi_LookupConfig(device_id);
//	base_addr = spi_config->BaseAddress;
//	XSpi_CfgInitialize(&spi_instance, spi_config, base_addr);
//	spi_options = XSP_MASTER_OPTION |
//		      XSP_CLK_PHASE_1_OPTION |
//		      XSP_MANUAL_SSELECT_OPTION;
//	XSpi_SetOptions(&spi_instance, spi_options);
//	XSpi_Start(&spi_instance);
//	XSpi_IntrGlobalDisable(&spi_instance);
//	XSpi_SetSlaveSelect(&spi_instance, 1);
#endif
	return SUCCESS;
}

/***************************************************************************//**
 * @brief spi_write_gpsdo
*******************************************************************************/
int spi_write_gpsdo(u8 slaveSel,
			unsigned char *txbuf, unsigned n_tx)
{
#ifdef _XPARAMETERS_PS_H_
	s32 cmdStatus = -100;

	cmdStatus = XSpiPs_SetSlaveSelect(&spi_instance_gpsdo, slaveSel);
	if(cmdStatus == XST_SUCCESS)
	{
		printf("XSpiPs_SetSlaveSelect. XST_SUCCESS\n");
	}
	else if(cmdStatus == XST_DEVICE_BUSY )
	{
		printf("XSpiPs_SetSlaveSelect. XST_DEVICE_BUSY\n");
	}
	else
	{
		printf("XSpiPs_SetSlaveSelect. Unknown error\n");
	}

	cmdStatus = XSpiPs_PolledTransfer(&spi_instance_gpsdo, txbuf, NULL, n_tx);
	if(cmdStatus == XST_SUCCESS)
	{
		printf("XSpiPs_Transfer. XST_SUCCESS\n");
	}
	else if(cmdStatus == XST_DEVICE_BUSY )
	{
		printf("XSpiPs_Transfer. XST_DEVICE_BUSY\n");
	}
	else
	{
		printf("XSpiPs_Transfer. Unknown error\n");
	}

	cmdStatus = XSpiPs_SetSlaveSelect(&spi_instance_gpsdo, SPI_DEASSERT_CURRENT_SS);
	if(cmdStatus == XST_SUCCESS)
	{
		printf("XSpiPs_SetSlaveSelect:SPI_DEASSERT_CURRENT_SS -> XST_SUCCESS\n");
	}
	else if(cmdStatus == XST_DEVICE_BUSY )
	{
		printf("XSpiPs_SetSlaveSelect:SPI_DEASSERT_CURRENT_SS -> XST_DEVICE_BUSY\n");
	}
	else
	{
		printf("XSpiPs_SetSlaveSelect:SPI_DEASSERT_CURRENT_SS -> Unknown error\n");
	}

#endif
	return SUCCESS;
}
