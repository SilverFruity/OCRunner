//
//  ORCoreFunction.h
//  OCRunner
//
//  Created by Jiang on 2020/7/14.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#ifndef ORCoreFunction_h
#define ORCoreFunction_h
@class NSArray;
@class MFValue;

void invoke_functionPointer(void *funptr, NSArray<MFValue *> *argValues, MFValue *returnValue);

#endif /* ORCoreFunction_h */
