//
//  ANEScopeChain.m
//  MangoFix
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <objc/runtime.h>
#import "MFScopeChain.h"
#import "MFValue.h"
#import "MFBlock.h"
#import "MFPropertyMapTable.h"
#import "MFWeakPropertyBox.h"
#import "util.h"
#import "RunnerClasses+Execute.h"
#import "ORTypeVarPair+TypeEncode.h"
@interface MFScopeChain()
@end
static MFScopeChain *instance = nil;
@implementation MFScopeChain
+ (instancetype)topScope{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [MFScopeChain new];
    });
    return instance;
}
+ (instancetype)scopeChainWithNext:(MFScopeChain *)next{
	MFScopeChain *scope = [MFScopeChain new];
	scope.next = next;
    scope.instance = next.instance;
	return scope;
}

- (instancetype)init{
	if (self = [super init]) {
		_vars = [NSMutableDictionary dictionary];
	}
	return self;
}
- (void)setValue:(MFValue *)value withIndentifier:(NSString *)identier{
    self.vars[identier] = value;
}

- (MFValue *)getValueWithIdentifier:(NSString *)identifer{
    MFValue *value = self.vars[identifer];
	return value;
}


const void *mf_propKey(NSString *propName) {
    static NSMutableDictionary *_propKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _propKeys = [[NSMutableDictionary alloc] init];
    });
    id key = _propKeys[propName];
    if (!key) {
        key = [propName copy];
        [_propKeys setObject:key forKey:propName];
    }
    return (__bridge const void *)(key);
}
- (NSString *)propNameByIvarName:(NSString *)ivarName{
    if (ivarName.length < 2) {
        return nil;
    }
    
    if (*ivarName.UTF8String != '_') {
        return nil;
    }
    
    return [ivarName substringFromIndex:1];
}

- (void)assignWithIdentifer:(NSString *)identifier value:(MFValue *)value{
	for (MFScopeChain *pos = self; pos; pos = pos.next) {
		if (pos.instance) {
            id instance = [(MFValue *)pos.instance objectValue];
            NSString *propName = [self propNameByIvarName:identifier];
            MFPropertyMapTable *table = [MFPropertyMapTable shareInstance];
            Class clazz = object_getClass(instance);
            ORPropertyDeclare *propDef = [table getPropertyMapTableItemWith:clazz name:propName].property;
            Ivar ivar;
            if (propDef) {
                id associationValue = value;
                const char *type = propDef.var.typeEncode;
                if (*type == '@') {
                    associationValue = value.objectValue;
                }
                MFPropertyModifier modifier = propDef.modifier;
                if ((modifier & MFPropertyModifierMemMask) == MFPropertyModifierMemWeak) {
                    associationValue = [[MFWeakPropertyBox alloc] initWithTarget:value];
                }
                objc_AssociationPolicy associationPolicy = mf_AssociationPolicy_with_PropertyModifier(modifier);
                objc_setAssociatedObject(instance, mf_propKey(propName), associationValue, associationPolicy);
                return;
            }else if((ivar = class_getInstanceVariable(object_getClass(instance),identifier.UTF8String))){
                const char *ivarEncoding = ivar_getTypeEncoding(ivar);
                if (*ivarEncoding == '@') {
                    object_setIvar(instance, ivar, value.objectValue);
                }else{
                    ptrdiff_t offset = ivar_getOffset(ivar);
                    void *ptr = (__bridge void *)(instance) + offset;
                    [value writePointer:ptr typeEncode:ivarEncoding];
                }
                return;
            }
		}
        MFValue *srcValue = [pos getValueWithIdentifier:identifier];
        if (srcValue) {
            [srcValue assignFrom:value];
            return;
        }
	}
}

- (MFValue *)getValueWithIdentifier:(NSString *)identifier endScope:(MFScopeChain *)endScope{
    MFScopeChain *pos = self;
    // FIX: while self == endScope, will ignore self
    do {
        if (pos.instance) {
            id instance = [(MFValue *)pos.instance objectValue];
            NSString *propName = [self propNameByIvarName:identifier];
            MFPropertyMapTable *table = [MFPropertyMapTable shareInstance];
            Class clazz = object_getClass(instance);
            ORPropertyDeclare *propDef = [table getPropertyMapTableItemWith:clazz name:propName].property;
            Ivar ivar;
            if (propDef) {
                id propValue = objc_getAssociatedObject(instance, mf_propKey(propName));
                const char *type = propDef.var.typeEncode;
                MFValue *value = propValue;
                if (!propValue) {
                    value = [MFValue defaultValueWithTypeEncoding:type];
                }else if(*type == '@'){
                    if ([propValue isKindOfClass:[MFWeakPropertyBox class]]) {
                        MFWeakPropertyBox *box = propValue;
                        MFValue *weakValue = box.target;
                        value = [MFValue valueWithObject:weakValue];
                    }else{
                        value = [MFValue valueWithObject:propValue];
                    }
                }
                return value;
                
            }else if((ivar = class_getInstanceVariable(object_getClass(instance),identifier.UTF8String))){
                MFValue *value;
                const char *ivarEncoding = ivar_getTypeEncoding(ivar);
                if (*ivarEncoding == '@') {
                    id ivarValue = object_getIvar(instance, ivar);
                    value = [MFValue valueWithObject:ivarValue];
                }else{
                    void *ptr = (__bridge void *)(instance) +  ivar_getOffset(ivar);
                    value = [[MFValue alloc] initTypeEncode:ivarEncoding pointer:ptr];
                }
                return value;
            }
        }
        MFValue *value = [pos getValueWithIdentifier:identifier];
        if (value) {
            return value;
        }
        pos = pos.next;
    } while ((pos != endScope) && (self != endScope));
    return nil;
}

- (MFValue *)recursiveGetValueWithIdentifier:(NSString *)identifier{
    return [self getValueWithIdentifier:identifier endScope:nil];
}

- (void)clear{
    _vars = [NSMutableDictionary dictionary];
}
@end

