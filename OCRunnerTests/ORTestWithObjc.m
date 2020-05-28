//
//  ORTestWithObjc.m
//  OCRunnerTests
//
//  Created by Jiang on 2020/5/19.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCRunner/OCRunner.h>
#import "ORStructDeclare.h"

@interface ORTestWithObjc : XCTestCase

@end

@implementation ORTestWithObjc

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    MFValue *value = [MFValue valueWithPointer:&CGRectMake];
    CGRect (**func)(CGFloat,CGFloat,CGFloat,CGFloat);
    func = value.pointer;
    CGRect a = (**func)(1,2,3,4);
    XCTAssert(a.origin.x == 1);
    XCTAssert(a.origin.y == 2);
    XCTAssert(a.size.width == 3);
    XCTAssert(a.size.height == 4);
}
typedef struct Element1Struct{
    int **a;
    int *b;
    CGFloat c;
}Element1Struct;
typedef struct Element2Struct{
    CGFloat x;
    CGFloat y;
    CGFloat z;
    Element1Struct t;
}Element2Struct;
typedef struct ContainerStruct{
    Element1Struct element1;
    Element1Struct *element1Pointer;
    Element2Struct element2;
    Element2Struct *element2Pointer;
}ContainerStruct;

Element1Struct *Element1StructMake(){
    Element1Struct *element = malloc(sizeof(Element1Struct));
    int *pointer1 = malloc(sizeof(int));
    *pointer1 = 100;
    element->a = malloc(sizeof(void *));
    *element->a = pointer1;
    element->b = pointer1;
    element->c = 101;
    return element;
}
Element2Struct *Element2StructMake(){
    Element2Struct *element = malloc(sizeof(Element2Struct));
    element->x = 1;
    element->y = 2;
    element->z = 3;
    element->t = *Element1StructMake();
    return element;
}
- (void)testStructTypeEncodePairse{
    ORStructDeclare *decl = [ORStructDeclare structDecalre:@encode(CGPoint) keys:@[@"x",@"y"]];
    XCTAssertEqualObjects(decl.keySizes[@"x"], @(8));
    XCTAssertEqualObjects(decl.keySizes[@"y"], @(8));
    XCTAssertEqualObjects(decl.keyOffsets[@"x"], @(0));
    XCTAssertEqualObjects(decl.keyOffsets[@"y"], @(8));
    XCTAssertEqualObjects(decl.keyTypeEncodes[@"x"], @"d");
    XCTAssertEqualObjects(decl.keyTypeEncodes[@"y"], @"d");
}
- (void)testStructValueGet{
    CGRect rect = CGRectMake(1, 2, 3, 4);
    ORStructDeclare *rectDecl = [ORStructDeclare structDecalre:@encode(CGRect) keys:@[@"origin",@"size"]];
    ORStructDeclare *pointDecl = [ORStructDeclare structDecalre:@encode(CGPoint) keys:@[@"x",@"y"]];
    ORStructDeclare *sizeDecl = [ORStructDeclare structDecalre:@encode(CGSize) keys:@[@"width",@"height"]];
    
    [[ORStructDeclareTable shareInstance] addStructDeclare:rectDecl];
    [[ORStructDeclareTable shareInstance] addStructDeclare:pointDecl];
    [[ORStructDeclareTable shareInstance] addStructDeclare:sizeDecl];
    
    MFValue *rectValue = [[MFValue alloc] initTypeEncode:rectDecl.typeEncoding pointer:&rect];
    CGFloat x = *(CGFloat *)[[rectValue fieldForKey:@"origin"] fieldForKey:@"x"].pointer;
    CGFloat y = *(CGFloat *)[[rectValue fieldForKey:@"origin"] fieldForKey:@"y"].pointer;
    CGFloat width = *(CGFloat *)[[rectValue fieldForKey:@"size"] fieldForKey:@"width"].pointer;
    CGFloat height = *(CGFloat *)[[rectValue fieldForKey:@"size"] fieldForKey:@"height"].pointer;
    XCTAssert(x == 1);
    XCTAssert(y == 2);
    XCTAssert(width == 3);
    XCTAssert(height == 4);
}
- (void)testStructValueMultiLevelGet{
    ContainerStruct container;
    Element1Struct *element1 = Element1StructMake();
    Element2Struct *element2 = Element2StructMake();
    container.element1 = *element1;
    container.element1Pointer = element1;
    container.element2 = *element2;
    container.element2Pointer = element2;

    ORStructDeclare *element1Decl = [ORStructDeclare structDecalre:@encode(Element1Struct) keys:@[@"a",@"b",@"c"]];
    ORStructDeclare *element2Decl = [ORStructDeclare structDecalre:@encode(Element2Struct) keys:@[@"x",@"y",@"z",@"t"]];
    ORStructDeclare *containerDecl = [ORStructDeclare structDecalre:@encode(ContainerStruct) keys:@[@"element1",@"element1Pointer",@"element2",@"element2Pointer"]];
    
    [[ORStructDeclareTable shareInstance] addStructDeclare:element1Decl];
    [[ORStructDeclareTable shareInstance] addStructDeclare:element2Decl];
    [[ORStructDeclareTable shareInstance] addStructDeclare:containerDecl];
    
    MFValue *containerValue = [[MFValue alloc] initTypeEncode:containerDecl.typeEncoding pointer:&container];
    CGFloat c3 = [[[containerValue fieldForKey:@"element2"] fieldForKey:@"t"] fieldForKey:@"c"].doubleValue;
    XCTAssert(c3 == 101);
    CGFloat pC3 = [[[[containerValue fieldForKey:@"element2Pointer"] getResutlInPointer] fieldForKey:@"t"] fieldForKey:@"c"].doubleValue;
    XCTAssert(pC3 == 101);
    int p1b = [[[containerValue fieldForKey:@"element1"] fieldForKey:@"b"] getResutlInPointer].intValue;
    XCTAssert(p1b == 100);
    int p2a = [[[containerValue fieldForKey:@"element1"] fieldForKey:@"a"] getResutlInPointer].intValue;
    XCTAssert(p2a == 100);
}
- (void)testPointerDetect{
    NSUInteger pointerCount = startDetectPointerCount("^^^d");
    XCTAssert(pointerCount == 3);
}
- (void)testStructDetect{
    NSArray *results = startStructDetect("{CGPointer=dd}");
    XCTAssertEqualObjects(results[0], @"CGPointer=");
    XCTAssertEqualObjects(results[1], @"d");
    XCTAssertEqualObjects(results[2], @"d");
    NSArray *results1 = startStructDetect("d");
    XCTAssert(results1.count == 0);
}
- (void)testStructGetValue{
    MFScopeChain *scope = [MFScopeChain topScope];
    or_add_build_in();
    NSString * source =
    @"UIView *view = [UIView new];"
    "view.frame = CGRectMake(1,2,3,4);"
    "CGRect frame = view.frame;"
    "CGFloat a = frame.size.height;";
    [OCParser parseSource:source];
    for (id <OCExecute> exp in OCParser.ast.globalStatements) {
        [exp execute:scope];
    }
    MFValue *frameValue = [scope getValueWithIdentifier:@"frame"];
    XCTAssert(frameValue.type == TypeStruct);
    MFValue * aValue = [scope getValueWithIdentifier:@"a"];
    XCTAssert(aValue.type == TypeDouble);
//    //FIXME: 类型转换问题，aValue.intValue == 4 测试则通过
    XCTAssert(aValue.doubleValue == 4);
    [OCParser clear];
    [scope clear];
}
- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
