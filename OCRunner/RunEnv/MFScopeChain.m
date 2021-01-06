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
    
    if ([ivarName characterAtIndex:0] != '_') {
        return nil;
    }
    
    return [ivarName substringFromIndex:1];
}

- (void)assignWithIdentifer:(NSString *)identifier value:(MFValue *)value{
	for (MFScopeChain *pos = self; pos; pos = pos.next) {
		if (pos.instance) {
            id instance = [(MFValue *)pos.instance objectValue];
            Class clazz = object_getClass(instance);
            NSString *propName = [self propNameByIvarName:identifier];
            if (propName != nil) {
                MFPropertyMapTable *table = [MFPropertyMapTable shareInstance];
                ORPropertyDeclare *propDef = [table getPropertyMapTableItemWith:clazz name:propName].property;
                if (propDef) {
                    MFPropertyModifier modifier = propDef.modifier;
                    if ((modifier & MFPropertyModifierMemMask) == MFPropertyModifierMemWeak) {
                        value = [value copy];
                        value.modifier = DeclarationModifierWeak;
                    }
                    objc_AssociationPolicy associationPolicy = mf_AssociationPolicy_with_PropertyModifier(modifier);
                    objc_setAssociatedObject(instance, mf_propKey(propName), value, associationPolicy);
                    return;
                }
            }
            Ivar ivar = class_getInstanceVariable(object_getClass(instance),identifier.UTF8String);
            if(ivar){
                const char *ivarEncoding = ivar_getTypeEncoding(ivar);
                void *ptr = (__bridge void *)(instance) + ivar_getOffset(ivar);
                [value writePointer:ptr typeEncode:ivarEncoding];
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
        if ([identifier characterAtIndex:0] == '_' && pos.instance) {
            id instance = [(MFValue *)pos.instance objectValue];
            Class clazz = object_getClass(instance);
            NSString *propName = [self propNameByIvarName:identifier];
            if (propName != nil) {
                MFPropertyMapTable *table = [MFPropertyMapTable shareInstance];
                ORPropertyDeclare *propDef = [table getPropertyMapTableItemWith:clazz name:propName].property;
                if (propDef) {
                    MFValue *propValue = objc_getAssociatedObject(instance, mf_propKey(propName));
                    if (!propValue) {
                        return [MFValue defaultValueWithTypeEncoding:propDef.var.typeEncode];
                    }
                    if (propValue.modifier & DeclarationModifierWeak) {
                        propValue = [propValue copy];
                    }
                    return propValue;
                }
            }
            Ivar ivar = class_getInstanceVariable(clazz, identifier.UTF8String);
            if(ivar){
                const char *ivarEncoding = ivar_getTypeEncoding(ivar);
                void *ptr = (__bridge void *)(instance) + ivar_getOffset(ivar);
                return [[MFValue alloc] initTypeEncode:ivarEncoding pointer:ptr];
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

