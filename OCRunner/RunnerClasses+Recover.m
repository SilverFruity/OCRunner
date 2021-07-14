//
//  RunnerClasses+Reverse.m
//  OCRunner
//
//  Created by Jiang on 2021/2/1.
//

#import "RunnerClasses+Recover.h"
#import "MFScopeChain.h"
#import "util.h"
#import "MFMethodMapTable.h"
#import "MFPropertyMapTable.h"
#import "MFVarDeclareChain.h"
#import "MFBlock.h"
#import "MFValue.h"
#import "MFStaticVarTable.h"

#import <objc/message.h>

#import "ORCoreImp.h"
#import "ORSearchedFunction.h"
#import "ORffiResultCache.h"
void recover_method(BOOL isClassMethod, Class clazz, SEL sel){
    NSString *orgSelName = [NSString stringWithFormat:@"ORG%@",NSStringFromSelector(sel)];
    SEL orgsel = NSSelectorFromString(orgSelName);
    Method ocMethod;
    if (isClassMethod) {
        ocMethod = class_getClassMethod(clazz, orgsel);
    }else{
        ocMethod = class_getInstanceMethod(clazz, orgsel);
    }
    if (ocMethod) {
        const char *typeEncoding = method_getTypeEncoding(ocMethod);
        Class c2 = isClassMethod ? objc_getMetaClass(class_getName(clazz)) : clazz;
        IMP orgImp = class_getMethodImplementation(c2, orgsel);
        class_replaceMethod(c2, sel, orgImp, typeEncoding);
    }
}

@implementation ORNode (Reverse)
- (void)recover{
    
}
@end

@implementation ORClassNode (Reverse)
- (void)deallocffiReusltForKey:(NSValue *)key{
    or_ffi_result *result = [[ORffiResultCache shared] ffiResultForKey:key];
    if (result) {
        [[ORffiResultCache shared] removeForKey:key];
        or_ffi_result_free(result);
    }
}
- (void)recover{
    Class clazz = NSClassFromString(self.className);
    // Reverse时，释放ffi_closure和ffi_type
    for (ORMethodNode *imp in self.methods) {
        SEL sel = NSSelectorFromString(imp.declare.selectorName);
        BOOL isClassMethod = imp.declare.isClassMethod;
        recover_method(isClassMethod, clazz, sel);
        [self deallocffiReusltForKey:[NSValue valueWithPointer:(__bridge void *)imp]];
        CFRelease((__bridge CFTypeRef)(imp));
    }
    for (ORPropertyNode *prop in self.properties){
        NSString *name = prop.var.var.varname;
        NSString *str1 = [[name substringWithRange:NSMakeRange(0, 1)] uppercaseString];
        NSString *str2 = name.length > 1 ? [name substringFromIndex:1] : nil;
        SEL getterSEL = NSSelectorFromString(name);
        SEL setterSEL = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",str1,str2]);
        recover_method(NO, clazz, getterSEL);
        recover_method(NO, clazz, setterSEL);
        [self deallocffiReusltForKey:[NSValue valueWithPointer:(__bridge void *)prop]];
        CFRelease((__bridge CFTypeRef)(prop));
    }
    [[MFMethodMapTable shareInstance] removeMethodsForClass:clazz];
    [[MFPropertyMapTable shareInstance] removePropertiesForClass:clazz];
    
//    Class classVar = [[MFScopeChain topScope] recursiveGetValueWithIdentifier:self.className].classValue;
//    if (classVar != nil && classVar == class) {
//        objc_disposeClassPair(classVar);
//    }
}

@end



