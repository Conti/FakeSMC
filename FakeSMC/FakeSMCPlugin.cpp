//
//  FakeSMCPlugin.cpp
//  HWSensors
//
//  Created by mozo on 11/02/12.
//  Copyright (c) 2012 mozodojo. All rights reserved.
//

#include "FakeSMCPlugin.h"

#include <IOKit/IOLib.h>
#include "FakeSMCDefinitions.h"

#define Debug false

#define LogPrefix "FakeSMCPlugin: "
#define DebugLog(string, args...)   do { if (Debug) { IOLog (LogPrefix "[Debug] " string "\n", ## args); } } while(0)
#define WarningLog(string, args...) do { IOLog (LogPrefix "[Warning] " string "\n", ## args); } while(0)
#define InfoLog(string, args...)    do { IOLog (LogPrefix string "\n", ## args); } while(0)


#define super IOService
OSDefineMetaClassAndAbstractStructors(FakeSMCPlugin, IOService)

bool FakeSMCPlugin::init(OSDictionary *properties)
{
    DebugLog("Initialising...");

    isActive = false;

    return super::init(properties);
}

IOService * FakeSMCPlugin::probe(IOService *provider, SInt32 *score)
{
    DebugLog("Probing...");

    if (super::probe(provider, score) != this) 
        return 0;

    return this;
}

bool FakeSMCPlugin::start(IOService *provider)
{
    DebugLog("Starting...");

    if (!super::start(provider))
        return false;

    if (!(fakeSMC = waitForService(serviceMatching(kFakeSMCDeviceService)))) {
        WarningLog("Can't locate fake SMC device!");
        return false;
    }

    return true;
}

void FakeSMCPlugin::stop(IOService* provider)
{
    DebugLog("Stoping...");

    fakeSMC->callPlatformFunction(kFakeSMCRemoveHandler, true, this, NULL, NULL, NULL);

    super::stop(provider);
}

void FakeSMCPlugin::free()
{
    DebugLog("Freeing...");

    super::free();
}

bool FakeSMCPlugin::isKeyHandled(const char *key)
{
 
    UInt16 size = 1;
    UInt16 * data;
        return kIOReturnSuccess == fakeSMC->callPlatformFunction(kFakeSMCGetKeyValue, false, (void *)key, (void *)&size, (void *)&data, 0);

    
    return false;
}

IOReturn FakeSMCPlugin::callPlatformFunction(const OSSymbol *functionName, bool waitForFunction, void *param1, void *param2, void *param3, void *param4 )
{
    return super::callPlatformFunction(functionName, waitForFunction, param1, param2, param3, param4);
}