/*
 *  IntelCPUMonitor.h
 *  HWSensors
 *
 *  Created by Slice on 20.12.10.
 *  Copyright 2010 mozodojo. All rights reserved.
 *
 */

#include <IOKit/IOTimerEventSource.h>
#include <IOKit/IOService.h>
#include <IOKit/IOLib.h>
#include <IOKit/IORegistryEntry.h>
#include <IOKit/IOPlatformExpert.h>
#include <IOKit/IODeviceTreeSupport.h>
#include <IOKit/IOKitKeys.h>


#include "cpuid.h"

#include "FakeSMCPlugin.h"

#define MSR_IA32_THERM_STATUS		0x019C
#define MSR_IA32_PERF_STATUS		0x0198;
#define MSR_IA32_TEMPERATURE_TARGET	0x01A2
//#define MSR_PLATFORM_INFO			0xCE;

#define MaxCpuCount 128
#define MaxPStateCount	32

extern "C" void mp_rendezvous_no_intrs(void (*action_func)(void *), void * arg);
extern "C" int cpu_number(void);

struct PState 
{
	union 
	{
		UInt16 Control;
		struct 
		{
			UInt8 VID;	// Voltage ID
			UInt8 FID;	// Frequency ID
		};
	};
	
	UInt8	DID;		// DID
	UInt8	CID;		// Compare ID
};

static UInt8				GlobalThermalValue[MaxCpuCount];
static bool					GlobalThermalValueIsObsolete[MaxCpuCount];
static PState				GlobalState[MaxCpuCount];

const UInt32 Kilo = 1000; //Slice
const UInt32 Mega = Kilo * 1000;
const UInt32 Giga = Mega * 1000;

inline void IntelWaitForSts(void) {
	UInt32 inline_timeout = 100000;
	while (rdmsr64(MSR_IA32_PERF_STS) & (1 << 21)) { if (!inline_timeout--) break; }
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

class IntelCPUMonitor : public FakeSMCPlugin
{
    OSDeclareDefaultStructors(IntelCPUMonitor)   
public:
	UInt32					Frequency[MaxCpuCount];
	UInt32					Voltage;

private:
	bool					Active;	
	bool					LoopLock;
	UInt32					BusClock;
	UInt32					FSBClock;
	UInt32					CpuFamily;
	UInt32					CpuModel; 
	UInt32					CpuStepping;
	bool					CpuMobile;
	UInt8					count;
	UInt8					threads;
	UInt8					tjmax[MaxCpuCount];
	UInt32					userTjmax;
	char*					key[MaxCpuCount];
	char					Platform[4];
	bool					nehalemArch;
  bool          SandyArch;
	IOService*				fakeSMC;
	IOWorkLoop *			WorkLoop;
	IOTimerEventSource *	TimerEventSource;
	void					Activate(void);
	void					Deactivate(void);
	UInt32					IntelGetFrequency(UInt8 fid);
	UInt32					IntelGetVoltage(UInt8 vid);
	
public:
	virtual bool		init(OSDictionary *properties=0);
	virtual IOService*	probe(IOService *provider, SInt32 *score);
    virtual bool		start(IOService *provider);
	virtual void		stop(IOService *provider);
	virtual void		free(void);
	
	virtual IOReturn	callPlatformFunction(const OSSymbol *functionName, bool waitForFunction, void *param1, void *param2, void *param3, void *param4 ); 
	virtual IOReturn	loopTimerEvent(void);
};