/*
 *  SMBus.h
 *  
 *
 *  Created by Slice on 22.02.12.
 *  Copyright 2012 Applelife.ru. All rights reserved.
 *   * Originally restored from pcefi10.5 by netcas
 */

//Datasheets
/*
ADM1021
FE DeviceID=0x41
FF Revision=...
00 Local Temperature
01 Remote Temperature
02 Status
03 Config
0F Single measure bit6=0 - RUN =1 Stop

ADT7470
Address 0x58 or 0x5A or 0x5C
0x20-0x29 T sensors 

0x2A 0x2B - Tach1 (low, high bytes) if absent 0xFFFF
0x2C 0x2D - Tach2
0x2E 0x2F - Tach3
0x30 0x31 - Tach4
measure period in 11.11ms
0x3E Vendor 0x41
0x3D DeviceID 0x70
0x3F Revision 0x00

0x36 Fans presents if bits 0-3 set then fan is absent

ADT7473
Address 0x5C
0x21 - Vccp
0x22 - Vcc
0x25 - remote T1
0x26 - local T2
0x27 - remote T3

0x28 - 0x2F -Fans1-4
0x3E Vendor 0x41
0x3D DeviceID 0x73


ADT7475
Address 0x5C
0x21 - Vccp
0x22 - Vcc
0x25 - remote T1
0x26 - local T2
0x27 - remote T3

0x28 - 0x2F -Fans1-4
0x3E Vendor 0x41
0x3D DeviceID 0x75


ADT7476
Address 0x58 or 0x5A or 0x5C
0x20 - V 2.5V
0x21 - Vccp
0x22 - Vcc
0x23 - V 5V
0x24 - V 12V
0x25 - remote T1
0x26 - local T2
0x27 - remote T3

0x28 - 0x2F -Fans1-4
0x3E Vendor 0x41
0x3D DeviceID 0x76
*/

#define rdtsc(low,high) \
__asm__ __volatile__("rdtsc" : "=a" (low), "=d" (high))

#define SMBHSTSTS 0
#define SMBHSTCNT 2
#define SMBHSTCMD 3
#define SMBHSTADD 4
#define SMBHSTDAT 5
#define SBMBLKDAT 7

/** Read one byte from the intel i2c, used for reading SPD on intel chipsets only. */
unsigned char smb_read_byte_intel(uint32_t base, uint8_t adr, uint8_t cmd)
{
  int l1, h1, l2, h2;
  unsigned long long t;
	
  outb(base + SMBHSTSTS, 0x1f);					// reset SMBus Controller
  outb(base + SMBHSTDAT, 0xff);
	
  rdtsc(l1, h1);
  while ( inb(base + SMBHSTSTS) & 0x01)    // wait until read
  {  
    rdtsc(l2, h2);
    t = ((h2 - h1) * 0xffffffff + (l2 - l1)) / (Platform.CPU.TSCFrequency / 100);
    if (t > 5)
      return 0xFF;                  // break
  }
	
  outb(base + SMBHSTCMD, cmd);
  outb(base + SMBHSTADD, (adr << 1) | 0x01 );
  outb(base + SMBHSTCNT, 0x48 );
	
  rdtsc(l1, h1);
	
 	while (!( inb(base + SMBHSTSTS) & 0x02))		// wait til command finished
	{	
		rdtsc(l2, h2);
		t = ((h2 - h1) * 0xffffffff + (l2 - l1)) / (Platform.CPU.TSCFrequency / 100);
		if (t > 5)
			break;									// break after 5ms
  }
  return inb(base + SMBHSTDAT);
}

/* SPD i2c read optimization: prefetch only what we need, read non prefetcheable bytes on the fly */
#define READ_SPD(spd, base, slot, x) spd[x] = smb_read_byte_intel(base, 0x50 + slot, x)


static void read_smb_intel(pci_dt_t *smbus_dev)
{ 
  int        i, speed;
  uint8_t    spd_size, spd_type;
  uint32_t   base, mmio, hostc;
  //  bool       dump = false;
  RamSlotInfo_t*  slot;
  
	uint16_t cmd = pci_config_read16(smbus_dev->dev.addr, 0x04);
	DBG("SMBus CmdReg: 0x%x\n", cmd);
	pci_config_write16(smbus_dev->dev.addr, 0x04, cmd | 1);
  
	mmio = pci_config_read32(smbus_dev->dev.addr, 0x10);// & ~0x0f;
  base = pci_config_read16(smbus_dev->dev.addr, 0x20) & 0xFFFE;
	hostc = pci_config_read8(smbus_dev->dev.addr, 0x40);
  verbose("Scanning SMBus [%04x:%04x], mmio: 0x%x, ioport: 0x%x, hostc: 0x%x\n", 
          smbus_dev->vendor_id, smbus_dev->device_id, mmio, base, hostc);
  
  
  // Search MAX_RAM_SLOTS slots
  for (i = 0; i <  MAX_RAM_SLOTS; i++){
    spd_size = smb_read_byte_intel(base, 0x50 + i, 0);
    
  } // for
}

