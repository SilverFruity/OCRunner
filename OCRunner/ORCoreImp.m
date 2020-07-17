//
//  ORImp.m
//  OCRunner
//
//  Created by Jiang on 2020/6/8.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORCoreImp.h"
#import "MFValue.h"
#import <objc/message.h>
#import "RunnerClasses+Execute.h"
#import "MFWeakPropertyBox.h"
#import "MFMethodMapTable.h"
#import "MFPropertyMapTable.h"
#import "ORTypeVarPair+TypeEncode.h"
#import "util.h"
#import "ORStructDeclare.h"
#import "ORCoreFunctionCall.h"
void methodIMP(ffi_cif *cfi,void *ret,void **args, void*userdata){
    NSMutableArray<MFValue *> *argValues = [NSMutableArray array];
    for (NSUInteger i = 0; i < cfi->nargs; i++) {
        MFValue *argValue = [[MFValue alloc] initTypeEncode:cfi->arg_typeEncodes[i] pointer:args[i]];
        [argValues addObject:argValue];
    }
    MFScopeChain *scope = [MFScopeChain topScope];
    id target = argValues[0].objectValue;
    SEL sel = argValues[1].selValue;
    BOOL classMethod = object_isClass(target);
    Class class;
    if (classMethod) {
        [scope setValue:[MFValue valueWithClass:target] withIndentifier:@"self"];
        class = objc_getMetaClass(NSStringFromClass(target).UTF8String);
    }else{
        [scope setValue:[MFValue valueWithObject:target] withIndentifier:@"self"];
        class = [target class];
    }
    [[MFStack argsStack] push:argValues];
    MFMethodMapTableItem *map = [[MFMethodMapTable shareInstance] getMethodMapTableItemWith:class classMethod:classMethod sel:sel];
    MFValue *value = [map.methodImp execute:scope];
    MFValue *retValue = [MFValue defaultValueWithTypeEncoding:cfi->r_typeEncode];
    if (retValue.type != TypeVoid){
        retValue.pointer = value.pointer;
        *(void **)ret = *(void **)retValue.pointer;
    }
}

void blockInter(ffi_cif *cfi,void *ret,void **args, void*userdata){
    struct MFSimulateBlock *block = args[0];
    MFBlock *mangoBlock =  (__bridge MFBlock *)(block->wrapper);
    NSMutableArray<MFValue *> *argValues = [NSMutableArray array];
    for (NSUInteger i = 1; i < cfi->nargs; i++) {
        MFValue *argValue = [[MFValue alloc] initTypeEncode:cfi->arg_typeEncodes[i] pointer:args[i]];
        [argValues addObject:argValue];
    }
    [[MFStack argsStack] push:argValues];
    MFValue *value = [mangoBlock.func execute:mangoBlock.outScope];
    MFValue *retValue = [MFValue defaultValueWithTypeEncoding:cfi->r_typeEncode];
    if (retValue.type != TypeVoid){
        retValue.pointer = value.pointer;
        *(void **)ret = *(void **)retValue.pointer;
    }
}


void getterImp(id target, SEL sel){
    NSString *propName = NSStringFromSelector(sel);
    ORPropertyDeclare *propDef = [[MFPropertyMapTable shareInstance] getPropertyMapTableItemWith:[target class] name:propName].property;
    const char *type = propDef.var.typeEncode;
    __autoreleasing MFValue *propValue = objc_getAssociatedObject(target, mf_propKey(propName));
    if (!propValue) {
        propValue = [MFValue defaultValueWithTypeEncoding:type];
    }
    if (propValue.type == TypeVoid){
        return;
    }
    void *result = *(void **)propValue.pointer;
    __asm__ volatile
    (
     "mov x0, %[ret]\n"
     :
     : [ret]"r"(result)
     );
}

void setterImp(id target, SEL sel, void *newValue){
    NSMethodSignature *sign = [target methodSignatureForSelector:sel];
    const char *type = [sign getArgumentTypeAtIndex:2];
    MFValue *value = [MFValue defaultValueWithTypeEncoding:type];
    value.pointer = &newValue;
    NSString *setter = NSStringFromSelector(sel);
    NSString *name = [setter substringWithRange:NSMakeRange(3, setter.length - 4)];
    NSString *first = [name substringWithRange:NSMakeRange(0, 1)].lowercaseString;
    NSString *propName = [NSString stringWithFormat:@"%@%@",first,[name substringFromIndex:1]];
    ORPropertyDeclare *propDef = [[MFPropertyMapTable shareInstance] getPropertyMapTableItemWith:[target class] name:propName].property;
    MFPropertyModifier modifier = propDef.modifier;
    if (modifier & MFPropertyModifierMemWeak) {
        value.modifier = ORDeclarationModifierWeak;
    }
    objc_AssociationPolicy associationPolicy = mf_AssociationPolicy_with_PropertyModifier(modifier);
    objc_setAssociatedObject(target, mf_propKey(propName), value, associationPolicy);
}


MFValue *invoke_sueper_values(id instance, SEL sel, NSArray<MFValue *> *argValues){
    BOOL isClassMethod = object_isClass(instance);
    Class superClass;
    if (isClassMethod) {
        superClass = class_getSuperclass(instance);
    }else{
        superClass = class_getSuperclass([instance class]);
    }
    struct objc_super *superPtr = &(struct objc_super){instance,superClass};
    NSMutableArray *args = [@[[MFValue valueWithPointer:(void *)superPtr],[MFValue valueWithSEL:sel]] mutableCopy];
    [args addObjectsFromArray:argValues];
    NSMethodSignature *sig = [instance methodSignatureForSelector:sel];
    MFValue *retValue = [MFValue defaultValueWithTypeEncoding:sig.methodReturnType];
    void *funcptr = &objc_msgSendSuper;
    invoke_functionPointer(funcptr, args, retValue);
    return retValue;
}
