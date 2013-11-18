//
//  PTIDSensors.cpp
//  HWSensors
//
//  Created by kozlek on 24.08.12.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2012 Natan Zalkin <natan.zalkin@me.com>. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software
//  and associated documentation files (the "Software"), to deal in the Software without restriction,
//  including without limitation the rights to use, copy, modify, merge, publish, distribute,
//  sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or
//  substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
//  NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//  DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#include "PTIDSensors.h"

#include "FakeSMCDefinitions.h"

#include "timer.h"

//#define kHWSensorsDebug TRUE

#define super FakeSMCPlugin
OSDefineMetaClassAndStructors(PTIDSensors, FakeSMCPlugin)

bool PTIDSensors::updateTemperatures()
{
    OSObject *object;
    
    if (kIOReturnSuccess == acpiDevice->evaluateObject("TSDD", &object) && object) {
        OSSafeRelease(temperatures);
        
        temperatures = OSDynamicCast(OSArray, object);
        
        //setProperty("temperatures", temperatures);
        
        return true;
    }
    
    HWSensorsWarningLog("failed to evaluate TSDD method");
    
    return false;
}

bool PTIDSensors::updateTachometers()
{
    OSObject *object;
    
    if (kIOReturnSuccess == acpiDevice->evaluateObject("OSDD", &object) && object) {
        OSSafeRelease(tachometers);
        
        tachometers = OSDynamicCast(OSArray, object);
        
        //setProperty("tachometers", tachometers);
        
        return true;
    }
    
    HWSensorsWarningLog("failed to evaluate OSDD method");
    
    return false;
}

float PTIDSensors::readTemperature(UInt32 index)
{
    double time = ptimer_read_seconds();
    
    if (time - temperaturesLastUpdated >= 1.0) {
        updateTemperatures();
        temperaturesLastUpdated = time;
    }
    
    if (temperatures) {
        if (OSNumber *number = OSDynamicCast(OSNumber, temperatures->getObject(index))) {
            UInt64 value = number->unsigned32BitValue();
            return (value == 0x80000000) ? 0 : (float)((value - 0xAAC) / 0xA);
        }
    }
    
    return 0;
}

float PTIDSensors::readTachometer(UInt32 index)
{
    double time = ptimer_read_seconds();
    
    if (time - tachometersLastUpdated >= 1.0) {
        updateTachometers();
        tachometersLastUpdated = time;
    }

    if (tachometers) {
        if (OSNumber *number = OSDynamicCast(OSNumber, tachometers->getObject(index))) {
            UInt64 value = number->unsigned32BitValue();
            return (value == 0x80000000) ? 0 : (float)value;
        }
    }
    
    return 0;
}

float PTIDSensors::getSensorValue(FakeSMCSensor *sensor)
{
    switch(sensor->getGroup()) {
        case kFakeSMCTemperatureSensor:
            return readTemperature(sensor->getIndex());
        case kFakeSMCTachometerSensor:
            return readTachometer(sensor->getIndex());
    }
    
    return 0;
}

void PTIDSensors::parseTemperatureName(OSString *name, UInt32 index)
{
    if (name && readTemperature(index)) {
        if (name->isEqualTo("CPU Core Package DTS") || name->isEqualTo("CPU Package Temperature"))
            addSensor("CPU Package", kFakeSMCCategoryTemperature, kFakeSMCTemperatureSensor, index);
        else if (name->isEqualTo("CPU Temperature"))
            addSensor("CPU Proximity", kFakeSMCCategoryTemperature, kFakeSMCTemperatureSensor, index);
        else if (name->isEqualTo("PCH Temperature") || name->isEqualTo("PCH DTS Temperature from PCH"))
            addSensor("PCH Die", kFakeSMCCategoryTemperature, kFakeSMCTemperatureSensor, index);
        else if (name->isEqualTo("MCH DTS Temperature from PCH"))
            addSensor("MCH Die", kFakeSMCCategoryTemperature, kFakeSMCTemperatureSensor, index);
        else if (name->isEqualTo("Ambient Temperature"))
            addSensor("Ambient", kFakeSMCCategoryTemperature, kFakeSMCTemperatureSensor, index);
        else {
            char str[64];
            
            for (UInt8 i = 0; i < 4; i++) {
                
                snprintf(str, 64, "TS-on-DIMM%X Temperature", i);
                if (name->isEqualTo(str)) {
                    addSensor("Memory Module", kFakeSMCCategoryTemperature, kFakeSMCTemperatureSensor, index);
                    break;
                }
                
                snprintf(str, 64, "Channel %X DIMM Temperature", i);
                if (name->isEqualTo(str)) {
                    addSensor("Memory Proximity", kFakeSMCCategoryTemperature, kFakeSMCTemperatureSensor, index);
                    break;
                }
            }
            

            for (UInt8 i = 0; i < 8; i++) {
                
                snprintf(str, 64, "TZ0%X _TMP", i);
                if (name->isEqualTo(str)) {
                    addSensor("Thermal Zone", kFakeSMCCategoryTemperature, kFakeSMCTemperatureSensor, index);
                    break;
                }
                
                snprintf(str, 64, "CPU Core %X DTS", i);
                if (name->isEqualTo(str)) {
                    addSensor("CPU Core", kFakeSMCCategoryTemperature, kFakeSMCTemperatureSensor, index);
                    break;
                }
            }
        }
    }
    
}

void PTIDSensors::parseTachometerName(OSString *name, OSString *title, UInt32 index)
{
    if (name && name->isEqualTo("RPM"))
        this->addTachometer(index, title ? title->getCStringNoCopy() : NULL);
}

bool PTIDSensors::start(IOService * provider)
{
	if (!super::start(provider))
        return false;
    
	acpiDevice = (IOACPIPlatformDevice *)provider;
	
	if (!acpiDevice) {
        HWSensorsFatalLog("ACPI device not ready");
        return false;
    }
    
    // Update timers
    temperaturesLastUpdated = ptimer_read() - NSEC_PER_SEC;
    tachometersLastUpdated = temperaturesLastUpdated;
    
    acpiDevice->evaluateInteger("IVER", &version);
    
    if (version == 0) {
        OSString *name = OSDynamicCast(OSString, provider->getProperty("name"));
        
        if (name && name->isEqualTo("INT3F0D"))
            version = 0x30000;
        else
            return false;
    }
    
    setProperty("version", version, 64);
    
    enableExclusiveAccessMode();
    
    // Parse sensors
    switch (version) {
        case 0x30000: {
            OSObject *object = NULL;
            
            // Temperatures
            if(kIOReturnSuccess == acpiDevice->evaluateObject("TSDL", &object) && object) {
                if (OSArray *description = OSDynamicCast(OSArray, object)) {
                    HWSensorsDebugLog("Parsing temperatures...");
                    
                    for (UInt32 index = 1; index < description->getCount(); index += 2) {
                        parseTemperatureName(OSDynamicCast(OSString, description->getObject(index)), (index - 1) / 2);
                    }
                }
                else HWSensorsErrorLog("failed to parse TSDL table");
            }
            else HWSensorsErrorLog("failed to evaluate TSDL table");
            
            // Tachometers
            if(kIOReturnSuccess == acpiDevice->evaluateObject("OSDL", &object) && object) {
                
                if (OSArray *description = OSDynamicCast(OSArray, object)) {
                    HWSensorsDebugLog("Parsing tachometers...");
                    
                    for (UInt32 index = 2; index < description->getCount(); index += 3) {
                        parseTachometerName(OSDynamicCast(OSString, description->getObject(index)), OSDynamicCast(OSString, description->getObject(index - 1)), (index - 2) / 3);
                    }
                }
                else HWSensorsErrorLog("failed to parse OSDL table");
            }
            else HWSensorsErrorLog("failed to evaluate OSDL table");
            
            break;
        }
            
        case 0x20001: {
            OSObject *object = NULL;
            
            // Temperatures
            if(kIOReturnSuccess == acpiDevice->evaluateObject("TMPV", &object) && object) {
                if (OSArray *description = OSDynamicCast(OSArray, object)) {
                    for (UInt32 index = 1; index < description->getCount(); index += 3) {
                        parseTemperatureName(OSDynamicCast(OSString, description->getObject(index)), index + 1);
                    }
                }
                else HWSensorsErrorLog("failed to parse TMPV table");
            }
            else HWSensorsErrorLog("failed to evaluate TMPV table");
            
            // Tachometers
            if(kIOReturnSuccess == acpiDevice->evaluateObject("OSDV", &object) && object) {
                if (OSArray *description = OSDynamicCast(OSArray, object)) {
                    for (UInt32 index = 2; index < description->getCount(); index += 4) {
                        parseTachometerName(OSDynamicCast(OSString, description->getObject(index)), OSDynamicCast(OSString, description->getObject(index - 1)), index + 1);
                    }
                }
                else HWSensorsErrorLog("failed to parse OSDV table");
            }
            else HWSensorsErrorLog("failed to evaluate OSDV table");
            
            break;
        }
            
        default:
            HWSensorsFatalLog("usupported interface version: 0x%x", (unsigned int)version);
            break;
    }
    
    disableExclusiveAccessMode();
    
    registerService();
    
    HWSensorsInfoLog("started");
    
	return true;
}