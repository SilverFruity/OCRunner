//
//  ORCoreFunctionTests.m
//  OCRunnerDemoTests
//
//  Created by Jiang on 2020/7/17.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCRunner/OCRunner.h>
#import <OCRunner/ORCoreImp.h>
#import <OCRunner/ORTypeVarPair+TypeEncode.h>

#import <objc/message.h>
@interface ORCoreFunctionTests : XCTestCase

@end

@implementation ORCoreFunctionTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}
int functionCall1(){
    return 100;
}
- (void)testFunctionCallReturn{
    MFValue * result = [MFValue defaultValueWithTypeEncoding:"i"];
    void *funcptr = &functionCall1;
    invoke_functionPointer(funcptr, @[], result);
    int intValue = *(int *)result.pointer;
    XCTAssert(intValue == 100);
}
- (void)testCallStructPointer{
    MFValue *result = [[MFValue alloc] initTypeEncode:@encode(CGAffineTransform)];
    void *funcptr = &CGAffineTransformScale;
    invoke_functionPointer(funcptr, @[[[MFValue alloc] initTypeEncode:@encode(CGAffineTransform) pointer:&CGAffineTransformIdentity],
                                      [MFValue valueWithDouble:0.5],
                                      [MFValue valueWithDouble:0.5]], result);
}
- (void)testCallMultiFunctionPointer{
    MFValue *result = [MFValue voidValue];
    void *funcptr = &NSLog;
    invoke_functionPointer(funcptr, @[[MFValue valueWithObject:@"%@"],[MFValue valueWithObject:@"123"]], result, 1);
}

- (void)testCallFunctionPointer{
    MFValue *result1 = [[MFValue alloc] initTypeEncode:@encode(CGRect)];
    void *funcptr = &CGRectMake;
    invoke_functionPointer(funcptr, @[[MFValue valueWithDouble:1],
                                          [MFValue valueWithDouble:2],
                                          [MFValue valueWithDouble:3],
                                          [MFValue valueWithDouble:4]], result1);
    CGRect rect1 = *(CGRect *)result1.pointer;
    XCTAssert(CGRectEqualToRect(CGRectMake(1, 2, 3, 4), rect1));
    UIView *view = [UIView new];
    CGRect rect = CGRectMake(1, 2, 3, 4);
    MFValue *result = [MFValue voidValue];
    funcptr = &objc_msgSend;
    invoke_functionPointer(funcptr, @[[MFValue valueWithObject:view],
                                            [MFValue valueWithSEL:@selector(setFrame:)],
                                            [[MFValue alloc] initTypeEncode:@encode(CGRect) pointer:&rect]], result);

    XCTAssert(CGRectEqualToRect(view.frame, rect));
}

//void testRegister1(ffi_cif *cif, void* ret, void **args, void *userdata){
//    for (int i = 0; i < cif->nargs; i++) {
//        void *pvalue = args[i];
//        MFValue *value = [[MFValue alloc] initTypeEncode:cif->arg_typeEncodes[i] pointer:pvalue];
//        if (i == 0) {
//            assert(value.intValue == 100);
//        }else{
//            float fvalue = 0.1;
//            assert(value.floatValue == fvalue);
//        }
//    }
//    *(int *)ret = 100;
//}
//- (void)testRegisterFunctionCall{
//    int (*func)(int a, float b) = register_function(&testRegister1, @[[ORTypeVarPair typePairWithTypeKind:TypeInt]
//                                                                      ,[ORTypeVarPair typePairWithTypeKind:TypeFloat]],
//                                                    [ORTypeVarPair typePairWithTypeKind:TypeInt]);
//    int res = func(100, 0.1);
//    XCTAssert(res == 100);
//}

@end
