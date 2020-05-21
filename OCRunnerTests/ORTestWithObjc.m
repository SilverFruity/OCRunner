//
//  ORTestWithObjc.m
//  OCRunnerTests
//
//  Created by Jiang on 2020/5/19.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCRunner/OCRunner.h>
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
void startStructDetect(const char *typeEncode){
    NSMutableString *buffer = [NSMutableString string];
    NSString *content = [NSString stringWithUTF8String:typeEncode];
    structDetect(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer, 0);
}
void structDetect(char chr, NSString *content, NSMutableString *buffer, NSUInteger lf){
    [buffer appendFormat:@"%c",chr];
    if (chr == '=') {
        structDetect(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer, lf);
        return;
    }
    if (chr == '{'){
        lf++;
        if (lf == 2) {
            buffer = [buffer substringWithRange:NSMakeRange(0, buffer.length - 1)].mutableCopy;
            NSLog(@"%@",buffer);
            buffer = [NSMutableString string];
            [buffer appendFormat:@"%c",chr];
            lf = 1;
        }
        structDetect(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer, lf);
        return;
    }
    if (chr == '}'){
        if (![buffer isEqualToString:@"}"]) {
            NSLog(@"%@",buffer);
        }
        if (content.length > 0) {
            buffer = [NSMutableString string];
            lf--;
            structDetect(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer, lf);
        }
        return;
    }
    structDetect(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer, lf);
}
- (void)testStructEncodeParse{
    ContainerStruct container;
    Element1Struct *element1 = Element1StructMake();
    Element2Struct *element2 = Element2StructMake();
    container.element1 = *element1;
    container.element1Pointer = element1;
    container.element2 = *element2;
    container.element2Pointer = element2;
    startStructDetect(@encode(ContainerStruct));
    startStructDetect(@encode(CGRect));
    startStructDetect(@encode(CGSize));
    startStructDetect(@encode(UIEdgeInsets));
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
