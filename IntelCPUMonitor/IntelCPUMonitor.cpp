/*
 *  IntelCPUMonitor.cpp
 *  HWSensors
 *
 *  Created by Slice on 20.12.10.
 *  Copyright 2010 mozodojo. All rights reserved.
 *
 */

#include "IntelCPUMonitor.h"
#include "FakeSMC.h"
#include "FakeSMCUtils.h"

#define Debug true

#define LogPrefix "IntelCPUMonitor: "
#define DebugLog(string, args...)	do { if (Debug) { IOLog (LogPrefix "[Debug] " string "\n", ## args); } } while(0)
#define WarningLog(string, args...) do { IOLog (LogPrefix "[Warning] " string "\n", ## args); } while(0)
#define InfoLog(string, args...)	do { IOLog (LogPrefix string "\n", ## args); } while(0)


void UCState(__unused void * magic)
{
	UInt32 i = cpu_number();
	if(i < MaxCpuCount) {
        initPMCCounters(i);
        lastUCC[i]=UCC[i];
        lastUCR[i]=UCR[i];
        UCC[i]=ReadUCC();
        UCR[i]=ReadUCR();
	}
}

void IntelState(__unused void * magic)
{
	UInt32 i = cpu_number();
	if(i < MaxCpuCount) {
		UInt64 msr = rdmsr64(MSR_IA32_PERF_STS);
		GlobalState[i].Control = msr & 0xFFFF;
	}
}

void IntelThermal(__unused void * magic)
{
	UInt32 i = cpu_number();
	if(i < MaxCpuCount) {
		UInt64 msr = rdmsr64(MSR_IA32_THERM_STATUS);
		if (msr & 0x80000000) {
			GlobalThermalValue[i] = (msr >> 16) & 0x7F;
			GlobalThermalValueIsObsolete[i]=false;
		}
	}
}

void IntelState2(__unused void * magic)
{
	UInt32 i = cpu_number() >> 1;
	if(i < MaxCpuCount) {
		UInt64 msr = rdmsr64(MSR_IA32_PERF_STS);
		GlobalState[i].Control = msr & 0xFFFF;
	}
}

void IntelThermal2(__unused void * magic)
{
	UInt32 i = cpu_number() >> 1;
	if(i < MaxCpuCount) {
		UInt64 msr = rdmsr64(MSR_IA32_THERM_STATUS);
		if (msr & 0x80000000) {
			GlobalThermalValue[i] = (msr >> 16) & 0x7F;
			GlobalThermalValueIsObsolete[i]=false;
		}
	}
}

// Power states!
enum {
    kMyOnPowerState = 1
};

static IOPMPowerState myTwoStates[2] = {
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {1, kIOPMPowerOn, kIOPMPowerOn, kIOPMPowerOn, 0, 0, 0, 0, 0, 0, 0, 0}
};

#define super IOService
OSDefineMetaClassAndStructors(IntelCPUMonitor, FakeSMCPlugin)

bool IntelCPUMonitor::init(OSDictionary *properties)
{
	DebugLog("Initialising...");
	
    if (!super::init(properties))
		return false;
	
	return true;
}

IOService* IntelCPUMonitor::probe(IOService *provider, SInt32 *score)
{
  bool RPltSet = false;
	DebugLog("Probing...");
	
	if (super::probe(provider, score) != this) return 0;
	
	InfoLog("Based on code by mercurysquad, superhai (C)2008. Turbostates measurement added by Navi");
	
	cpuid_update_generic_info();
	
	if (strcmp(cpuid_info()->cpuid_vendor, CPUID_VID_INTEL) != 0)	{
		WarningLog("No Intel processor found, kext will not load");
		return 0;
	}
	
	if(!(cpuid_info()->cpuid_features & CPUID_FEATURE_MSR))	{
		WarningLog("Processor does not support Model Specific Registers, kext will not load");
		return 0;
	}
	
	count = cpuid_info()->core_count;//cpuid_count_cores();
	threads = cpuid_info()->thread_count;
	//uint64_t msr = rdmsr64(MSR_CORE_THREAD_COUNT);  //nehalem only
	//uint64_t m2 = msr >> 32;
	
	if(count == 0)	{
		WarningLog("CPUs not found, kext will not load");
		return 0;
	}
	
	CpuFamily = cpuid_info()->cpuid_family;
	CpuModel = cpuid_info()->cpuid_model;
	CpuStepping =  cpuid_info()->cpuid_stepping;
	CpuMobile = false;
	userTjmax = 0;
	if (OSNumber* number = OSDynamicCast(OSNumber, getProperty("TjMax"))) {
		// User defined Tjmax
		userTjmax = number->unsigned32BitValue();
		IOLog("User defined TjMax=%d\n", (int)userTjmax);
		snprintf(Platform, 4, "n");
	}
  if (OSString* name = OSDynamicCast(OSString, getProperty("RPlt"))) {
    snprintf(Platform, 4, "%s", name ? name->getCStringNoCopy() : "n");
    if ((Platform[0] != 'n') &&  (Platform[0] != 'N')) {
      RPltSet = true;
    }    
  }
	// Calculating Tjmax
	switch (CpuFamily)
	{
		case 0x06: 
		{
			switch (CpuModel) 
			{
				case CPUID_MODEL_PENTIUM_M:
					tjmax[0] = 100; 
					CpuMobile = true;
          if (!RPltSet) {
            snprintf(Platform, 4, "M70");
            RPltSet = true;
          }
					
					break;
					
				case CPUID_MODEL_YONAH:
					tjmax[0] = 85; 
					if (rdmsr64(0x17) & (1<<28)) {
						CpuMobile = true;
					}
          if (!RPltSet) {
					  snprintf(Platform, 4, "K22");
            RPltSet = true;
          }
					break;					
					
				case CPUID_MODEL_MEROM: // Intel Core (65nm)
					if (rdmsr64(0x17) & (1<<28)) {
						CpuMobile = true;
					}
					
					switch (CpuStepping) 
          {
            case 0x02: // G0
              tjmax[0] = 80;  //why 95?
              //snprintf(Platform, 4, "M71");
              break;
            case 0x06: // B2
              switch (count) 
              {
                case 2:
                  tjmax[0] = 80; break;
                case 4:
                  tjmax[0] = 90; break;
                default:
                  tjmax[0] = 85; break;
              }
              //tjmax[0] = 80;
              break;
            case 0x0B: // G0
              tjmax[0] = 90; break;
            case 0x0D: // M0
              if (CpuMobile) {
                tjmax[0] = 100;
              } else {
                tjmax[0] = 85;
              }							
              break;
            default:
              tjmax[0] = 85; break;
          } 
          if (!RPltSet) {
					  snprintf(Platform, 4, "M75");
            RPltSet = true;
          }
					break;
					
				case CPUID_MODEL_PENRYN: // Intel Core (45nm)
                               // Mobile CPU ?
					if (rdmsr64(0x17) & (1<<28)) { //mobile
						CpuMobile = true;
						tjmax[0] = 105; 
            if (!RPltSet) {
						  snprintf(Platform, 4, "M82");
              RPltSet = true;
            }
					}
					else {
						switch (CpuStepping) {
							case 7:
								tjmax[0] = 95;
								break;
							default:
								tjmax[0] = 100;
								break;
						}
            if (!RPltSet) {
						  snprintf(Platform, 4, "K36");
              RPltSet = true;
            }
					}
          
					break;
					
				case CPUID_MODEL_ATOM: // Intel Atom (45nm)
					switch (CpuStepping)
          {
            case 0x02: // C0
              tjmax[0] = 100; break;
            case 0x0A: // A0, B0
              tjmax[0] = 100; break;
            default:
              tjmax[0] = 90; break;
          }
          if (!RPltSet) {
					  snprintf(Platform, 4, "T9");
            RPltSet = true;
          }
					break;
					
				case CPUID_MODEL_NEHALEM:
				case CPUID_MODEL_FIELDS:
				case CPUID_MODEL_DALES:
				case CPUID_MODEL_DALES_32NM:
				case CPUID_MODEL_WESTMERE:
				case CPUID_MODEL_NEHALEM_EX:
				case CPUID_MODEL_WESTMERE_EX:
				case CPUID_MODEL_SANDYBRIDGE:
                case CPUID_MODEL_IVYBRIDGE:
				case CPUID_MODEL_JAKETOWN:
				{
					nehalemArch = true;
					
					for (int i = 0; i < count; i++) {
						tjmax[i] = (rdmsr64(MSR_IA32_TEMPERATURE_TARGET) >> 16) & 0xFF;
					}
					
				} 
/*          if (!RPltSet) {
					  snprintf(Platform, 4, "T9");
            RPltSet = true;
          } */
					break;
					
				default:
					WarningLog("Unsupported Intel processor found, kext will not load");
					return 0;
			}
		} break;
			
		default:
			WarningLog("Unknown Intel family processor found, kext will not load");
			return 0;
	}
  
  SandyArch = (CpuModel == CPUID_MODEL_SANDYBRIDGE) || (CpuModel == CPUID_MODEL_JAKETOWN) || (CpuModel == CPUID_MODEL_IVYBRIDGE);
    if(SandyArch)
    {
        BaseFreqRatio = BaseOperatingFreq();
 
        DebugLog("Base Ratio = %d", BaseFreqRatio);
    }
  if (!RPltSet) {
    if (SandyArch) {
      if (CpuMobile) {
        snprintf(Platform, 4, "k90i");
      } else {
        snprintf(Platform, 4, "k62");
      }
    } else {
      snprintf(Platform, 4, "T9");
    }
    RPltSet = true;
  }
	
	if (userTjmax != 0) {
		for (int i = 0; i < count; i++)
			tjmax[i] = userTjmax;
		
	} else {
		for (int i = 0; i < count; i++) {
			if (!nehalemArch)
				tjmax[i] = tjmax[0];
		}	
	}

	
	for (int i = 0; i < count; i++) {
		key[i] = (char*)IOMalloc(5);
		snprintf(key[i], 5, "TC%XD", i);
	}
//	InfoLog("Platform string %s", Platform);
	return this;
}

bool IntelCPUMonitor::start(IOService * provider)
{
  IORegistryEntry * rootNode;
  OSData *tmpNumber = 0;
	DebugLog("Starting...");
	
	if (!super::start(provider)) return false;
	
    // Join power management so that we can get a notification early during
    // wakeup to re-sample our battery data. We don't actually power manage
    // any devices.
    PMinit();
    registerPowerDriver(this, myTwoStates, 2);
    provider->joinPMtree(this);
    
    if (!(fakeSMC = waitForService(serviceMatching(kFakeSMCDeviceService)))) {
		WarningLog("Can't locate fake SMC device, kext will not load");
		return false;
	}
	
	InfoLog("CPU family 0x%x, model 0x%x, stepping 0x%x, cores %d, threads %d", cpuid_info()->cpuid_family, cpuid_info()->cpuid_model, cpuid_info()->cpuid_stepping, count, cpuid_info()->thread_count);
/*	BusClock = (gPEClockFrequencyInfo.bus_frequency_max_hz >> 2);
	if (BusClock >= (420 * Mega)) {
		BusClock >>=2;
	}
	BusClock = BusClock / Mega;
	FSBClock = gPEClockFrequencyInfo.bus_frequency_max_hz  / Mega;
 */
  rootNode = fromPath("/efi/platform", gIODTPlane);
  if (rootNode) {
    tmpNumber = OSDynamicCast(OSData, rootNode->getProperty("FSBFrequency"));
    BusClock = *((UInt64*) tmpNumber->getBytesNoCopy());
    FSBClock = BusClock << 2;
    InfoLog("Using efi");
  } else {
    FSBClock = gPEClockFrequencyInfo.bus_frequency_max_hz;
    BusClock = FSBClock >> 2;
    InfoLog("Using bus_frequency_max_hz");
  }
    if(!SandyArch)
        BusClock = BusClock / Mega;   // I Don't like this crap - i'll write mine
    else {
    float v = (float)BusClock / (float)Mega;
    BusClock = (int)(v  < 0 ? (v - 0.5) : (v + 0.5));
    }
  FSBClock = FSBClock / Mega;
	InfoLog("BusClock=%dMHz FSB=%dMHz", (int)(BusClock), (int)(FSBClock));
	InfoLog("Platform string %s", Platform);
	
	
	if (!(WorkLoop = getWorkLoop())) 
		return false;
	
	if (!(TimerEventSource = IOTimerEventSource::timerEventSource( this, OSMemberFunctionCast(IOTimerEventSource::Action, this, &IntelCPUMonitor::loopTimerEvent)))) 
		return false;
	
	if (kIOReturnSuccess != WorkLoop->addEventSource(TimerEventSource))
	{
		return false;
	}
	Activate();
	if (!nehalemArch)
		InfoLog("CPU Tjmax %d", tjmax[0]);
	else
		for (int i = 0; i < count; i++)
			InfoLog("CPU%X Tjmax %d", i, tjmax[i]);
	
	for (int i = 0; i < count; i++) {
		if (kIOReturnSuccess != fakeSMC->callPlatformFunction(kFakeSMCAddKeyHandler, false, (void *)key[i], (void *)"sp78", (void *)2, this)) {
			WarningLog("Can't add key to fake SMC device, kext will not load");
			return false;
		}
		
		char keyF[5];
		snprintf(keyF, 5, "FRC%X", i);
		if (kIOReturnSuccess != fakeSMC->callPlatformFunction(kFakeSMCAddKeyHandler, false, (void *)keyF, (void *)"freq", (void *)2, this)) {
			WarningLog("Can't add Frequency key to fake SMC device");
		}	
        
        if (!nehalemArch and !SandyArch){ 
            char keyM[5];
              snprintf(keyM, 5, KEY_FORMAT_NON_APPLE_CPU_MULTIPLIER, i);
                if (kIOReturnSuccess != fakeSMC->callPlatformFunction(kFakeSMCAddKeyHandler, false, (void *)keyM, (void *)TYPE_UI16, (void *)2, this)) {
                    WarningLog("Can't add key to fake SMC device");
                    //return false;
                }
        }
        
		if (!nehalemArch){  // Voltage is impossible for Nehalem
			char keyV[5];
			snprintf(keyV, 5, "VC0C");
			if (kIOReturnSuccess != fakeSMC->callPlatformFunction(kFakeSMCAddKeyHandler, false, (void *)keyV, (void *)"fp2e", (void *)2, this)) {
				WarningLog("Can't add Voltage key to fake SMC device");
			}
		}	
	}
    if (nehalemArch || SandyArch) 
        if (kIOReturnSuccess != fakeSMC->callPlatformFunction(kFakeSMCAddKeyHandler, false, (void *)KEY_NON_APPLE_PACKAGE_MULTIPLIER, (void *)TYPE_UI16, (void *)2, this)) {
                WarningLog("Can't add key to fake SMC device");
                //return false;
            }

 
	if (Platform[0] != 'n') {
		if (kIOReturnSuccess != fakeSMC->callPlatformFunction(kFakeSMCAddKeyHandler, false, (void *)"RPlt", (void *)"ch8*", (void *)6, this)) {
			WarningLog("Can't add Platform key to fake SMC device");
		}			
	}
	
	return true;
}

void IntelCPUMonitor::stop (IOService* provider)
{
	DebugLog("Stoping...");
	Deactivate();
	super::stop(provider);
}

void IntelCPUMonitor::free ()
{
	DebugLog("Freeing...");
	
	super::free ();
}

void IntelCPUMonitor::Activate(void)
{
	if(Active)
		return;
	
	Active = true;
	
	loopTimerEvent();
	
	//	InfoLog("Monitoring started");
}

void IntelCPUMonitor::Deactivate(void)
{
	if(!Active)
		return;
	
	if (TimerEventSource)
		TimerEventSource->cancelTimeout();
	
	Active = false;
	
	//	InfoLog("Monitoring stopped");
}

IOReturn IntelCPUMonitor::callPlatformFunction(const OSSymbol *functionName, bool waitForFunction, void *param1, void *param2, void *param3, void *param4 )
{
	UInt32 magic = 0;	
	if (functionName->isEqualTo(kFakeSMCGetValueCallback)) {
		const char* name = (const char*)param1;
		void * data = param2;
		//UInt32 size = (UInt64)param3;
		UInt16 value=0;
		int index;
		//InfoLog("key %s is called", name);
		if (name && data) {
			
			switch (name[0]) {
				case 'T':
					index = name[2] >= 'A' ? name[2] - 65 : name[2] - 48;
					if (index >= 0 && index < count) {
						if (threads > count) {
							mp_rendezvous_no_intrs(IntelThermal2, &magic);
						} else
							mp_rendezvous_no_intrs(IntelThermal, &magic);
						value = tjmax[index] - GlobalThermalValue[index];
					}
					else {
						//DebugLog("cpu index out of bounds");
						return kIOReturnBadArgument;						
					}
					break;
                case 'M':
                
                    if (strcasecmp(name, KEY_NON_APPLE_PACKAGE_MULTIPLIER) == 0) {
                           value = GlobalState[0].Control;
                        if (SandyArch) 
                           value = (value >> 8) * 10;
                        else if(nehalemArch)
                           value = value * 10;
                        else value=0;
                              
                                
                        bcopy(&value, data, 2);
                        
                        return kIOReturnSuccess;    
                    }
                    else    
                    {
                    index = name[2] >= 'A' ? name[2] - 65 : name[2] - 48;
					if (index >= 0 && index < count) 
                    {
                        
                        value = GlobalState[index].Control;
                   
                        float mult = float(((value >> 8) & 0x1f)) + 0.5f * float((value >> 14) & 1);
                        value = mult * 10.0f;

                     
                    }
                    else return kIOReturnBadArgument;
                    }  
                break;
				case 'F':
					if ((name[1] != 'R') || (name[2] != 'C')) {
						return kIOReturnBadArgument;
					}
					index = name[3] >= 'A' ? name[3] - 65 : name[3] - 48;
					if (index >= 0 && index < count) {
						value = swap_value(Frequency[index]);
						//InfoLog("Frequency = %d", value);
						//InfoLog("GlobalState: FID=%x VID=%x", GlobalState[index].FID, GlobalState[index].FID);
					}
					break;
				case 'V':
					value = encode_fp2e(Voltage);
					break;
				case 'R':
					if ((name[1] != 'P') || (name[2] != 'l') || (name[3] != 't')) {
						return kIOReturnBadArgument;
					}
					bcopy(Platform, data, 4);
					return kIOReturnSuccess;

				default:
					return kIOReturnBadArgument;
			}
				
			bcopy(&value, data, 2);		
			return kIOReturnSuccess;
		}
		
		//DebugLog("bad argument key name or data");
		
		return kIOReturnBadArgument;
	}
	
	return super::callPlatformFunction(functionName, waitForFunction, param1, param2, param3, param4);
}

IOReturn IntelCPUMonitor::loopTimerEvent(void)
{
	//Please, don't remove this timer! If frequency is read in OnKeyRead function, then the CPU is loaded by smcK-Stat-i and
	//goes to a higher P-State in this moment, displays high frequency and switches back to low frequency.
	UInt32 magic = 0;	
	
	if(LoopLock)
		return kIOReturnTimeout;	
	LoopLock = true;
	if(SandyArch){
        mp_rendezvous_no_intrs(UCState, &magic);
    }

	// State Readout
	if (threads > count) {
		mp_rendezvous_no_intrs(IntelState2, &magic);
	} else {
		mp_rendezvous_no_intrs(IntelState, &magic);
	}

	for (UInt32 i = 0; i < count; i++) 
	{
		if (!nehalemArch  || SandyArch) {
			Frequency[i] = IntelGetFrequency(i);
			Voltage = IntelGetVoltage(GlobalState[i].VID);
		} else {
			Frequency[i] = IntelGetFrequency(i);
			Voltage = 1000;
		}
	}
	
	LoopLock = false;
	TimerEventSource->setTimeoutMS(1000);	
	return kIOReturnSuccess;
}

UInt32 IntelCPUMonitor::IntelGetFrequency(UInt8 cpu_id) {
	UInt32 multiplier, frequency=0;
	UInt8 fid = GlobalState[cpu_id].FID;
    if(SandyArch)
    {
        UInt64 deltaUCC = lastUCC[cpu_id] > UCC[cpu_id] ? 0xFFFFFFFFFFFFFFFFll - lastUCC[cpu_id] + UCC[cpu_id] : UCC[cpu_id] - lastUCC[cpu_id];
        UInt64 deltaUCR = lastUCR[cpu_id] > UCR[cpu_id] ? 0xFFFFFFFFFFFFFFFFll - lastUCR[cpu_id] + UCR[cpu_id] : UCR[cpu_id] - lastUCR[cpu_id];
        if(deltaUCR>0)
        {
            float num = (float)deltaUCC*BaseFreqRatio/(float)deltaUCR;
            int n = (int)(num < 0 ? (num - 0.5) : (num + 0.5));
            return BusClock*n;
        }
        
    }
  if (!nehalemArch)
  {
		multiplier = fid & 0x1f;					// = 0x08
		int half = (fid & 0x40)?1:0;							// = 0x01
		int dfsb = (fid & 0x80)?1:0;							// = 0x00
		UInt32 fsb = (UInt32)BusClock >> dfsb;
		UInt32 halffsb = (UInt32)BusClock >> 1;						// = 200
		frequency = (multiplier * fsb);			// = 3200
		return (frequency + (half * halffsb));	// = 3200 + 200 = 3400
        }

	else {
		multiplier = fid & 0x3f;
		frequency = (multiplier * (UInt32)BusClock);
//		int half = gPEClockFrequencyInfo.bus_to_CPUID_rate_num;
//		half = half?half:1;
//		frequency = (multiplier * BusClock) * gPEClockFrequencyInfo.bus_to_CPUID_rate_den / half;
		return (frequency);	
	}
}

UInt32 IntelCPUMonitor::IntelGetVoltage(UInt8 vid) {  //no nehalem
	switch (CpuModel) {
		case CPUID_MODEL_PENTIUM_M:
			return 700 + ((vid & 0x3F) << 4);
			break;      
		case CPUID_MODEL_YONAH:
			return  (1425 + ((vid & 0x3F) * 25)) >> 1;
			break;
		case CPUID_MODEL_MEROM: //Conroe?!
			return (1650 + ((vid & 0x3F) * 25)) >> 1;
			break;
		case CPUID_MODEL_PENRYN:
		case CPUID_MODEL_ATOM:
			//vid=0x22 (~vid& 0x3F)=0x1d=29 ret=1137
			return  (1500 - (((~vid & 0x3F) * 25) >> 1));
			break;
/*		case AMDK7:
		case AMDK8BC:
		case AMDK8D:
		case AMDK8E:
		case AMDK8NPT:
			return 1550 - (vid * 25);
			break;
		case AMDK10:
		case AMDK11:
			return (3100 - (vid * 25)) >> 1;
			break;
 */
		default:
			return 0;
			break;
	}	
	return 0;
}



IOReturn IntelCPUMonitor::setPowerState(unsigned long which,IOService *whom)
{
    if (kMyOnPowerState == which)
 
    {
        // Init PMC Fixed Counters once more
        DebugLog( "awaken, resetting counters");
        bzero(UCC, sizeof(UCC));
        bzero(lastUCC, sizeof(lastUCC));
        bzero(UCR, sizeof(UCR));
        bzero(lastUCR, sizeof(lastUCR));
        bzero(InitFlags, sizeof(InitFlags));
    }
    return IOPMAckImplied;
}
