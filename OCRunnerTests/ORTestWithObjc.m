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
@interface ORStructField: NSObject
@property (nonatomic,assign)void *fieldPointer;
@property (nonatomic,copy)NSString *fieldTypeEncode;
@end
@implementation ORStructField
- (BOOL)isStructField{
    return *self.fieldTypeEncode.UTF8String == '{';
}
@end

@interface ORStructValue: NSObject
@property (nonatomic,assign) void *structPointer;
@property (nonatomic,strong) ORStructDeclare *decalre;
- (ORStructField *)valueForKey:(NSString *)key;
@end
@implementation ORStructValue
- (instancetype)initWithPointer:(void *)pointer declare:(ORStructDeclare *)decl
{
    self = [super init];
    self.structPointer = pointer;
    self.decalre = decl;
    return self;
}
- (ORStructField *)fieldForKey:(NSString *)key{
    ORStructField *field = [ORStructField new];
    NSUInteger offset = self.decalre.keyOffsets[key].unsignedIntegerValue;
    void *fiedPointer = self.structPointer + offset;
    field.fieldPointer = fiedPointer;
    field.fieldTypeEncode = self.decalre.keyTypeEncodes[key];
    return field;
}
@end
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
    MFValue *value = [MFValue valueInstanceWithPointer:&CGRectMake];
    CGRect (*func)(CGFloat,CGFloat,CGFloat,CGFloat);
    func = value.pointerValue;
    CGRect a = (*func)(1,2,3,4);
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
    element->a = &pointer1;
    element->b = pointer1;
    element->c = 101;
    return element;
}
Element2Struct *Element2StructMake(){
    Element2Struct *element = malloc(sizeof(Element2Struct));
    element->x = 1;
    element->y = 2;
    element->z = 3;
    return element;
}
//FIXME: 结构体三级嵌套时，有问题. self.struct.frame.size.x 需要修改startStructDetect
- (void)testStructValueGet{
    ContainerStruct container;
    Element1Struct *element1 = Element1StructMake();
    Element2Struct *element2 = Element2StructMake();
    container.element1 = *element1;
    container.element1Pointer = element1;
    container.element2 = *element2;
    container.element2Pointer = element2;
    [ORStructDeclare structDecalre:@encode(NSRange) keys:@[@"location",@"length"]];
    
    ORStructDeclare *element1Decl = [ORStructDeclare structDecalre:@encode(Element1Struct) keys:@[@"a",@"b",@"c"]];
    ORStructDeclare *element2Decl = [ORStructDeclare structDecalre:@encode(Element2Struct) keys:@[@"x",@"y",@"z"]];
    ORStructDeclare *containerDecl = [ORStructDeclare structDecalre:@encode(ContainerStruct) keys:@[@"element1",@"element1Pointer",@"element2",@"element2Pointer"]];
    ORStructValue *containerValue = [[ORStructValue alloc] initWithPointer:&container declare:containerDecl];
    ORStructField *field = [containerValue fieldForKey:@"element1"];
    Element1Struct test = *(Element1Struct *)field.fieldPointer;
    NSLog(@"%@",field.fieldTypeEncode);
    XCTAssert(test.c == 101);
    ORStructValue *element1Value = [[ORStructValue alloc] initWithPointer:field.fieldPointer declare:element1Decl];
    ORStructField *resultField = [element1Value fieldForKey:@"c"];
    CGFloat result = *(CGFloat *)resultField.fieldPointer;
    XCTAssert(result == 101);
    
    CGRect rect = CGRectMake(1, 2, 3, 4);
    ORStructDeclare *rectDecl = [ORStructDeclare structDecalre:@encode(CGRect) keys:@[@"origin",@"size"]];
    ORStructValue *rectValue = [[ORStructValue alloc] initWithPointer:&rect declare:rectDecl];
    ORStructField *pointField = [rectValue fieldForKey:@"origin"];
    ORStructDeclare *pointDecl = [ORStructDeclare structDecalre:@encode(CGPoint) keys:@[@"x",@"y"]];
    ORStructValue *pointValue = [[ORStructValue alloc] initWithPointer:pointField.fieldPointer declare:pointDecl];
    ORStructField *xField = [pointValue fieldForKey:@"x"];
    ORStructField *yField = [pointValue fieldForKey:@"y"];
    XCTAssert(*(CGFloat *)xField.fieldPointer == 1);
    XCTAssert(*(CGFloat *)yField.fieldPointer == 2);
    ORStructField *sizeField = [rectValue fieldForKey:@"size"];
    ORStructDeclare *sizeDecl = [ORStructDeclare structDecalre:@encode(CGSize) keys:@[@"width",@"height"]];
    ORStructValue *sizeValue = [[ORStructValue alloc] initWithPointer:sizeField.fieldPointer declare:sizeDecl];
    ORStructField *widthField = [sizeValue fieldForKey:@"width"];
    ORStructField *heightField = [sizeValue fieldForKey:@"height"];
    XCTAssert(*(CGFloat *)widthField.fieldPointer == 3);
    XCTAssert(*(CGFloat *)heightField.fieldPointer == 4);
    
}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
