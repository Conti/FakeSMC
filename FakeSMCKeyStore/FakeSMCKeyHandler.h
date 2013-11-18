//
//  FakeSMCKeyHandler.h
//  HWSensors
//
//  Created by Kozlek on 06/11/13.
//
//

//  The MIT License (MIT)
//
//  Copyright (c) 2013 Natan Zalkin <natan.zalkin@me.com>. All rights reserved.
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

#ifndef __HWSensors__FakeSMCKeyHandler__
#define __HWSensors__FakeSMCKeyHandler__

#include <IOKit/IOService.h>

class FakeSMCKeyHandler : public IOService {

	OSDeclareAbstractStructors(FakeSMCKeyHandler)

public:
    UInt32              getProbeScore();
    virtual IOReturn    getValueCallback(const char *key, const char *type, const UInt8 size, void *buffer);
    virtual IOReturn    setValueForKey(const char *key, const char *type, const UInt8 size, const void *value);

};

#endif /* defined(__HWSensors__FakeSMCKeyHandler__) */
