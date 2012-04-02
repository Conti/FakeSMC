/*
 *  SuperIOFamily.h
 *  HWSensors
 *
 *  Created by mozo on 08/10/10.
 *  Copyright 2010 mozodojo. All rights reserved.
 *
 */

#ifndef _SUPERIOMONITOR_H
#define _SUPERIOMONITOR_H

#include <IOKit/IOLib.h>
#include <IOKit/IOService.h>

// Ports
const UInt8 SUPERIO_STANDART_PORT[]                 = { 0x2e, 0x4e };

// Registers
const UInt8 SUPERIO_CONFIGURATION_CONTROL_REGISTER  = 0x02;
const UInt8 SUPERIO_DEVICE_SELECT_REGISTER          = 0x07;
const UInt8 SUPERIO_CHIP_ID_REGISTER                = 0x20;
const UInt8 SUPERIO_CHIP_REVISION_REGISTER          = 0x21;
const UInt8 SUPERIO_BASE_ADDRESS_REGISTER           = 0x60;

enum SuperIOSensorGroup {
    kSuperIOTemperatureSensor,
    kSuperIOTachometerSensor,
    kSuperIOVoltageSensor
};

class SuperIOMonitor;

class SuperIOSensor : public OSObject {
     OSDeclareDefaultStructors(SuperIOSensor)

protected:
    SuperIOMonitor *    owner;
    char *              name;
    char *              type;
    unsigned char       size;
    SuperIOSensorGroup  group;
    unsigned long       index;
    long                Ri;
    long                Rf;
    long                Vf;

public:
    static SuperIOSensor *withOwner(SuperIOMonitor *aOwner, const char* aKey, const char* aType, unsigned char aSize, SuperIOSensorGroup aGroup, unsigned long aIndex, long aRi=0, long aRf=1, long aVf=0);

    const char *        getName();
    const char *        getType();
    unsigned char       getSize();
    SuperIOSensorGroup  getGroup();
    unsigned long       getIndex();

    virtual bool        initWithOwner(SuperIOMonitor *aOwner, const char* aKey, const char* aType, unsigned char aSize, SuperIOSensorGroup aGroup, unsigned long aIndex, long aRi, long aRf, long aVf);
    virtual long        getValue();
    virtual void        free();
};

class SuperIOMonitor : public IOService {
    OSDeclareAbstractStructors(SuperIOMonitor)

protected:
    IOService *             fakeSMC;

    bool                    isActive;

    UInt16                  address;
    UInt8                   registerPort;
    UInt8                   valuePort;

    UInt32                  model;

    OSArray *               sensors;

    UInt8                   listenPortByte(UInt16 reg);
    UInt16                  listenPortWord(UInt16 reg);
//    UInt8                 listenPortByte16(UInt16 reg);
//  UInt16                  listenPortWord16(UInt16 reg);
    void                    selectLogicalDevice(UInt8 num);
    bool                    getLogicalDeviceAddress(UInt8 reg = SUPERIO_BASE_ADDRESS_REGISTER);

    virtual int             getPortsCount();
    virtual void            selectPort(unsigned char index);
    virtual void            enter();
    virtual void            exit();
    virtual bool            probePort();
    virtual bool            startPlugin();

    virtual const char *    getModelName();

    SuperIOSensor *         addSensor(const char* key, const char* type, unsigned char size, SuperIOSensorGroup group, unsigned long index, long aRi=0, long aRf=1, long aV=0);
    SuperIOSensor *         addTachometer(unsigned long index, const char* id = 0);
    SuperIOSensor *         getSensor(const char* key);
//    virtual bool            updateSensor(const char *key, const char *type, unsigned char size, SuperIOSensorGroup group, unsigned long index);

public:
    virtual long            readTemperature(unsigned long index);
    virtual long            readVoltage(unsigned long index);
    virtual long            readTachometer(unsigned long index);

    virtual bool            init(OSDictionary *properties=0);
    virtual IOService*      probe(IOService *provider, SInt32 *score);
    virtual bool            start(IOService *provider);
    virtual void            stop(IOService *provider);
    virtual void            free(void);

    virtual IOReturn        callPlatformFunction(const OSSymbol *functionName, bool waitForFunction, void *param1, void *param2, void *param3, void *param4 ); 

};

inline bool process_sensor_entry(OSObject *object, OSString **name, long *Ri, long *Rf, long *Vf)
{
    *Rf=1;
    *Ri=0;
    *Vf=0;
    if ((*name = OSDynamicCast(OSString, object))) {
        return true;
    }
    else if (OSDictionary *dictionary = OSDynamicCast(OSDictionary, object))
        if ((*name = OSDynamicCast(OSString, dictionary->getObject("Name")))) {
            if (OSNumber *number = OSDynamicCast(OSNumber, dictionary->getObject("VRef")))
                *Vf = number->unsigned64BitValue() ;
            
            if (OSNumber *number = OSDynamicCast(OSNumber, dictionary->getObject("Ri")))
                *Ri = number->unsigned64BitValue();
            
            if (OSNumber *number = OSDynamicCast(OSNumber, dictionary->getObject("Rf")))
                *Rf = number->unsigned64BitValue() ;
            
            return true;
        }
    
    return false;
}

inline OSString * ComposeVendorAndMbKey(OSString * vendor, OSString * MainBoard)
{
    return NULL;
}

#endif