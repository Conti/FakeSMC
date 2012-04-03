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
    OSString *              VendorAndModel;

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

inline OSString * vendorID(OSString * smbios_manufacturer)
{
    if (smbios_manufacturer) {
        if (smbios_manufacturer->isEqualTo("Alienware")) return OSString::withCString("Alienware");
        if (smbios_manufacturer->isEqualTo("Apple Inc.")) return OSString::withCString("Apple");
        if (smbios_manufacturer->isEqualTo("ASRock")) return OSString::withCString("ASRock");
        if (smbios_manufacturer->isEqualTo("ASUSTeK Computer INC.")) return OSString::withCString("ASUS");
        if (smbios_manufacturer->isEqualTo("ASUSTeK COMPUTER INC.")) return OSString::withCString("ASUS");
        if (smbios_manufacturer->isEqualTo("Dell Inc.")) return OSString::withCString("Dell");
        if (smbios_manufacturer->isEqualTo("DFI")) return OSString::withCString("DFI");
        if (smbios_manufacturer->isEqualTo("DFI Inc.")) return OSString::withCString("DFI");
        if (smbios_manufacturer->isEqualTo("ECS")) return OSString::withCString("ECS");
        if (smbios_manufacturer->isEqualTo("EPoX COMPUTER CO., LTD")) return OSString::withCString("EPoX");
        if (smbios_manufacturer->isEqualTo("EVGA")) return OSString::withCString("EVGA");
        if (smbios_manufacturer->isEqualTo("First International Computer, Inc.")) return OSString::withCString("FIC");
        if (smbios_manufacturer->isEqualTo("FUJITSU")) return OSString::withCString("FUJITSU");
        if (smbios_manufacturer->isEqualTo("FUJITSU SIEMENS")) return OSString::withCString("FUJITSU");
        if (smbios_manufacturer->isEqualTo("Gigabyte Technology Co., Ltd.")) return OSString::withCString("Gigabyte");
        if (smbios_manufacturer->isEqualTo("Hewlett-Packard")) return OSString::withCString("HP");
        if (smbios_manufacturer->isEqualTo("IBM")) return OSString::withCString("IBM");
        if (smbios_manufacturer->isEqualTo("Intel")) return OSString::withCString("Intel");
        if (smbios_manufacturer->isEqualTo("Intel Corp.")) return OSString::withCString("Intel");
        if (smbios_manufacturer->isEqualTo("Intel Corporation")) return OSString::withCString("Intel");
        if (smbios_manufacturer->isEqualTo("INTEL Corporation")) return OSString::withCString("Intel");
        if (smbios_manufacturer->isEqualTo("Lenovo")) return OSString::withCString("Lenovo");
        if (smbios_manufacturer->isEqualTo("LENOVO")) return OSString::withCString("Lenovo");
        if (smbios_manufacturer->isEqualTo("Micro-Star International")) return OSString::withCString("MSI");
        if (smbios_manufacturer->isEqualTo("MICRO-STAR INTERNATIONAL CO., LTD")) return OSString::withCString("MSI");
        if (smbios_manufacturer->isEqualTo("MICRO-STAR INTERNATIONAL CO.,LTD")) return OSString::withCString("MSI");
        if (smbios_manufacturer->isEqualTo("MSI")) return OSString::withCString("MSI");
        if (smbios_manufacturer->isEqualTo("Shuttle")) return OSString::withCString("Shuttle");
        if (smbios_manufacturer->isEqualTo("TOSHIBA")) return OSString::withCString("TOSHIBA");
        if (smbios_manufacturer->isEqualTo("XFX")) return OSString::withCString("XFX");
        if (smbios_manufacturer->isEqualTo("To be filled by O.E.M.")) return NULL;
    }
    return NULL;  
}

inline OSString * boardID(OSString * smbios_boardid)
{
    if (smbios_boardid) {
        if (smbios_boardid->isEqualTo("880GMH/USB3")) return OSString::withCString("880GMH_USB3");
        if (smbios_boardid->isEqualTo("ASRock AOD790GX/128M")) return OSString::withCString("AOD790GX_128M");
        if (smbios_boardid->isEqualTo("P55 Deluxe")) return OSString::withCString("P55_Deluxe");
        if (smbios_boardid->isEqualTo("Crosshair III Formula")) return OSString::withCString("Crosshair_III_Formula");
        if (smbios_boardid->isEqualTo("M2N-SLI DELUXE")) return OSString::withCString("M2N-SLI_DELUXE");
        if (smbios_boardid->isEqualTo("M4A79XTD EVO")) return OSString::withCString("M4A79XTD_EVO");
        if (smbios_boardid->isEqualTo("P5W DH Deluxe")) return OSString::withCString("P5W_DH_Deluxe");
        if (smbios_boardid->isEqualTo("P6T")) return OSString::withCString("P6T");
        if (smbios_boardid->isEqualTo("P6X58D-E")) return OSString::withCString("P6X58D-E");
        if (smbios_boardid->isEqualTo("P8P67")) return OSString::withCString("P8P67");
        if (smbios_boardid->isEqualTo("P8P67 EVO")) return OSString::withCString("P8P67_EVO");
        if (smbios_boardid->isEqualTo("P8P67 PRO")) return OSString::withCString("P8P67_PRO");
        if (smbios_boardid->isEqualTo("P8P67-M PRO")) return OSString::withCString("P8P67-M_PRO");
        if (smbios_boardid->isEqualTo("P9X79")) return OSString::withCString("P9X79");
        if (smbios_boardid->isEqualTo("Rampage Extreme")) return OSString::withCString("Rampage_Extreme");
        if (smbios_boardid->isEqualTo("Rampage II GENE")) return OSString::withCString("Rampage_II_GENE");
        if (smbios_boardid->isEqualTo("LP BI P45-T2RS Elite")) return OSString::withCString("LP_BI_P45-T2RS_Elite");
        if (smbios_boardid->isEqualTo("LP DK P55-T3eH9")) return OSString::withCString("LP_DKP_55-T3eH9");
        if (smbios_boardid->isEqualTo("A890GXM-A")) return OSString::withCString("A890GXM-A");
        if (smbios_boardid->isEqualTo("X58 SLI Classified")) return OSString::withCString("X58_SLI_Classified");
        if (smbios_boardid->isEqualTo("965P-S3")) return OSString::withCString("965P-S3");
        if (smbios_boardid->isEqualTo("EP43-UD3L")) return OSString::withCString("EP43-UD3L");
        if (smbios_boardid->isEqualTo("EP45-DS3R")) return OSString::withCString("EP45-DS3R");
        if (smbios_boardid->isEqualTo("EP45-UD3R")) return OSString::withCString("EP45-UD3R");
        if (smbios_boardid->isEqualTo("EX58-EXTREME")) return OSString::withCString("EX58-EXTREME");
        if (smbios_boardid->isEqualTo("GA-MA770T-UD3")) return OSString::withCString("GA-MA770T-UD3");
        if (smbios_boardid->isEqualTo("GA-MA785GMT-UD2H")) return OSString::withCString("GA-MA785GMT-UD2H");
        if (smbios_boardid->isEqualTo("H67A-UD3H-B3")) return OSString::withCString("H67A-UD3H-B3");
        if (smbios_boardid->isEqualTo("P35-DS3")) return OSString::withCString("P35-DS3");
        if (smbios_boardid->isEqualTo("P35-DS3L")) return OSString::withCString("P35-DS3L");
        if (smbios_boardid->isEqualTo("P55-UD4")) return OSString::withCString("P55-UD4");
        if (smbios_boardid->isEqualTo("P55M-UD4")) return OSString::withCString("P55M-UD4");
        if (smbios_boardid->isEqualTo("P67A-UD4-B3")) return OSString::withCString("P67A-UD4-B3");
        if (smbios_boardid->isEqualTo("P8Z68-V PRO")) return OSString::withCString("P8Z68-V_PRO");
        if (smbios_boardid->isEqualTo("X38-DS5")) return OSString::withCString("X38-DS5");
        if (smbios_boardid->isEqualTo("X58A-UD3R")) return OSString::withCString("X58A-UD3R");
        if (smbios_boardid->isEqualTo("Z68X-UD7-B3")) return OSString::withCString("Z68X-UD7-B3");
        if (smbios_boardid->isEqualTo("FH67")) return OSString::withCString("FH67");
        if (smbios_boardid->isEqualTo("Base Board Product Name")) return NULL;
        if (smbios_boardid->isEqualTo("To be filled by O.E.M.")) return NULL;
    }
    return NULL;  
}

#define MAX_STR 512

inline OSString * ComposeVendorAndMbKey(OSString * Vendor, OSString * MainBoard)
{
    char str[MAX_STR];
    if(Vendor && MainBoard)
    {
        snprintf(str , MAX_STR, "%s.%s",Vendor->getCStringNoCopy(),MainBoard->getCStringNoCopy());
        return OSString::withCString(str);
    }
    return NULL;
}

#endif