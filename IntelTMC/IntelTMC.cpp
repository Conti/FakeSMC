/*
 *  IntelTMC.cpp
 *  HWSensors
 *
 *  Created by Sergey on 19.12.10.
 *  Copyright 2010 slice. All rights reserved.
 *
 */

#include "IntelTMC.h"
#include "FakeSMC.h"


#define super IOService
OSDefineMetaClassAndStructors(IntelTMC, IOService)

bool IntelTMC::addSensor(const char* key, const char* type, unsigned char size, int index)
{
	if (kIOReturnSuccess == fakeSMC->callPlatformFunction(kFakeSMCAddKeyHandler, false, (void *)key, (void *)type, (void *)size, (void *)this))
		return sensors->setObject(key, OSNumber::withNumber(index, 32));	
	return false;
}

IOService* IntelTMC::probe(IOService *provider, SInt32 *score)
{
	if (super::probe(provider, score) != this) return 0;
	UInt32 vendor_id = 0, device_id = 0, class_id = 0;
	if (OSDictionary * dictionary = serviceMatching(kGenericPCIDevice)) {
		if (OSIterator * iterator = getMatchingServices(dictionary)) {
			
			IOPCIDevice* device = 0;
			
			while (device = OSDynamicCast(IOPCIDevice, iterator->getNextObject())) {
				OSData *data = OSDynamicCast(OSData, device->getProperty(fVendor));
				if (data)
					vendor_id = *(UInt32*)data->getBytesNoCopy();
				
				data = OSDynamicCast(OSData, device->getProperty(fDevice));				
				if (data)
					device_id = *(UInt32*)data->getBytesNoCopy();
        
				data = OSDynamicCast(OSData, device->getProperty(fClass));				
				if (data)
					class_id = *(UInt32*)data->getBytesNoCopy();
				
				if ((vendor_id==0x8086) && (class_id==0x118000)){
					InfoLog("found TMC chip id=%x", (UInt16)device_id);
					VCard = device;
				}
			}
		}
	}	
	return this;
}

bool IntelTMC::start(IOService * provider)
{
	if (!provider || !super::start(provider)) return false;
	
	if (!(fakeSMC = waitForService(serviceMatching(kFakeSMCDeviceService)))) {
		WarningLog("Can't locate fake SMC device, kext will not load");
		return false;
	}
  if (!VCard) {
    return false;
  }
	
	IOMemoryDescriptor *		theDescriptor;
	IOPhysicalAddress bar = (IOPhysicalAddress)((VCard->configRead32(TBAR)) & ~0xf);
  if (bar) {
    DebugLog(" register space from OS=%08lx\n", (long unsigned int)bar);
    theDescriptor = IOMemoryDescriptor::withPhysicalAddress (bar, 0x100, kIODirectionOutIn); // | kIOMapInhibitCache);
    if(theDescriptor != NULL)
    {
      mmio = theDescriptor->map();
      if(mmio != NULL)
      {
        mmio_base = (volatile UInt8 *)mmio->getVirtualAddress();
#if DEBUG				
        DebugLog(" MCHBAR mapped\n");
        for (int i=0; i<0x2f; i +=16) {
          DebugLog("%04lx: ", (long unsigned int)i+0x1000);
          for (int j=0; j<16; j += 1) {
            DebugLog("%02lx ", (long unsigned int)INVID8(i+j+0x1000));
          }
          DebugLog("\n");
        }
#endif				
      }
    }	    
  }
  if (!mmio) { //try again with other BAR
    bar = (IOPhysicalAddress)((VCard->configRead32(TBARB)) & ~0xf);
    DebugLog(" register space from BIOS=%08lx\n", (long unsigned int)bar);
    theDescriptor = IOMemoryDescriptor::withPhysicalAddress (bar, 0x100, kIODirectionOutIn); // | kIOMapInhibitCache);
    if(theDescriptor != NULL)
    {
      mmio = theDescriptor->map();
      if(mmio != NULL)
      {
        mmio_base = (volatile UInt8 *)mmio->getVirtualAddress();
#if DEBUG				
        DebugLog(" MCHBAR mapped\n");
        for (int i=0; i<0x2f; i +=16) {
          DebugLog("%04lx: ", (long unsigned int)i+0x1000);
          for (int j=0; j<16; j += 1) {
            DebugLog("%02lx ", (long unsigned int)INVID8(i+j+0x1000));
          }
          DebugLog("\n");
        }
#endif				
      }
      else
      {
        InfoLog(" MCHBAR failed to map\n");
        return -1;
      }			
    }	    
  }
	
	char name[5];
	//try to find empty key
	for (int i = 0; i < 0x10; i++) {
						
		snprintf(name, 5, KEY_FORMAT_GPU_DIODE_TEMPERATURE, i); 
			
		UInt8 length = 0;
		void * data = 0;
			
		IOReturn result = fakeSMC->callPlatformFunction(kFakeSMCGetKeyValue, true, (void *)name, (void *)&length, (void *)&data, 0);
			
		if (kIOReturnSuccess == result) {
			continue;
		}
		if (addSensor(name, TYPE_SP78, 2, i)) {
			numCard = i;
			break;
		}
	}
		
	if (kIOReturnSuccess != fakeSMC->callPlatformFunction(kFakeSMCAddKeyHandler, false, (void *)name, (void *)TYPE_SP78, (void *)2, this)) {
		WarningLog("Can't add key to fake SMC device, kext will not load");
		return false;
	}
	
	return true;	
}


bool IntelTMC::init(OSDictionary *properties)
{
    if (!super::init(properties))
		return false;
	
	if (!(sensors = OSDictionary::withCapacity(0)))
		return false;
	
	return true;
}

void IntelTMC::stop (IOService* provider)
{
	sensors->flushCollection();
	
	super::stop(provider);
}

void IntelTMC::free ()
{
	sensors->release();
	
	super::free();
}

IOReturn IntelTMC::callPlatformFunction(const OSSymbol *functionName, bool waitForFunction, void *param1, void *param2, void *param3, void *param4 )
{
	UInt16 t;

	if (functionName->isEqualTo(kFakeSMCGetValueCallback)) {
		const char* name = (const char*)param1;
		void* data = param2;
		
		if (name && data) {
			if (OSNumber *number = OSDynamicCast(OSNumber, sensors->getObject(name))) {				
				UInt32 index = number->unsigned16BitValue();
				if (index != numCard) {
					return kIOReturnBadArgument;
				}
			}
			short value;
			if (mmio_base) {
				OUTVID(TSE, 0xB8);
				//		if ((INVID16(TSC1) & (1<<15)) && !(INVID16(TSC1) & (1<<8)))//enabled and ready
				for (int i=0; i<1000; i++) {  //attempts to ready
					
					if ((INVID16(TSIU) & (1<<10)) == 0)   //valid?
						break;
					IOSleep(10);
				}				
				value = INVID8(ITV);
			}				
			
			t = value;
			bcopy(&t, data, 2);
			
			return kIOReturnSuccess;
		}
		
		//DebugLog("bad argument key name or data");
		
		return kIOReturnBadArgument;
	}
	
	return super::callPlatformFunction(functionName, waitForFunction, param1, param2, param3, param4);
}
