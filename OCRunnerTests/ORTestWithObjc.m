//
//  ORTestWithObjc.m
//  OCRunnerTests
//
//  Created by Jiang on 2020/5/19.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCRunner/OCRunner.h>
#import "MFStructDeclare.h"
@interface ORStructField: NSObject
@property (nonatomic,assign)void *fieldPointer;
@property (nonatomic,copy)NSString *fieldTypeEncode;
@end
@implementation ORStructField

@end

@interface ORStructValue: NSObject
@property (nonatomic,assign) void *structPointer;
@property (nonatomic,strong) MFStructDeclare *decalre;
- (ORStructField *)valueForKey:(NSString *)key;
@end
@implementation ORStructValue
- (instancetype)initWithPointer:(void *)pointer declare:(MFStructDeclare *)decl
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

NSMutableArray * startStructDetect(const char *typeEncode){
    NSMutableString *buffer = [NSMutableString string];
    NSString *content = [NSString stringWithUTF8String:typeEncode];
    NSMutableArray *results = [NSMutableArray array];
    structDetect(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer, 0, results);
    return results;
}
void structDetect(char chr, NSString *content, NSMutableString *buffer, NSUInteger lf, NSMutableArray *results){
    [buffer appendFormat:@"%c",chr];
    if (chr == '{'){
        lf++;
        if (lf == 2) {
            buffer = [buffer substringWithRange:NSMakeRange(0, buffer.length - 1)].mutableCopy;
            [results addObject:buffer];
            buffer = [NSMutableString string];
            [buffer appendFormat:@"%c",chr];
            lf = 1;
        }
        structDetect(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer, lf, results);
        return;
    }
    if (content.length == 0) {
        [results addObject:buffer];
        return;
    }
    if (chr == '}'){
        [results addObject:buffer];
        buffer = [NSMutableString string];
        lf--;
    }
    structDetect(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer, lf, results);
}
NSMutableArray * startDetectTypeEncode(NSString *content){
    NSMutableString *buffer = [NSMutableString string];
    NSMutableArray *results = [NSMutableArray array];
    detectTypeEncode(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer, results);
    return results;
}
void detectTypeEncode(char chr, NSString *content, NSMutableString *buffer, NSMutableArray *types){
    [buffer appendFormat:@"%c",chr];
    if (chr != '^') {
        [types addObject:buffer];
        buffer = [NSMutableString string];
    }
    if (content.length != 0) {
        detectTypeEncode(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer,types);
    }
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
- (void)testStructEncodeParse{
    ContainerStruct container;
    Element1Struct *element1 = Element1StructMake();
    Element2Struct *element2 = Element2StructMake();
    container.element1 = *element1;
    container.element1Pointer = element1;
    container.element2 = *element2;
    container.element2Pointer = element2;
    [self structDecalre:@encode(NSRange) keys:@[@"location",@"length"]];
    [self structDecalre:@encode(CGRect) keys:@[@"origin",@"size"]];
    MFStructDeclare *element1Decl = [self structDecalre:@encode(Element1Struct) keys:@[@"a",@"b",@"c"]];
    MFStructDeclare *element2Decl = [self structDecalre:@encode(Element2Struct) keys:@[@"x",@"y",@"z"]];
    MFStructDeclare *containerDecl = [self structDecalre:@encode(ContainerStruct) keys:@[@"element1",@"element1Pointer",@"element2",@"element2Pointer"]];
    ORStructValue *containerValue = [[ORStructValue alloc] initWithPointer:&container declare:containerDecl];
    ORStructField *field = [containerValue fieldForKey:@"element1"];
    Element1Struct test = *(Element1Struct *)field.fieldPointer;
    NSLog(@"%@",field.fieldTypeEncode);
    XCTAssert(test.c == 101);
    ORStructValue *element1Value = [[ORStructValue alloc] initWithPointer:field.fieldPointer declare:element1Decl];
    ORStructField *resultField = [element1Value fieldForKey:@"c"];
    CGFloat result = *(CGFloat *)resultField.fieldPointer;
    XCTAssert(result == 101);
}

- (MFStructDeclare *)structDecalre:(const char *)encode keys:(NSArray *)keys{
    NSMutableArray *results = startStructDetect(encode);
    if (results.count > 1) {
        NSString *nameElement = results[0];
        NSString *structName = [nameElement substringWithRange:NSMakeRange(1, nameElement.length - 2)];
        if ([structName hasPrefix:@"_"]) {
            structName = [structName substringWithRange:NSMakeRange(1, structName.length - 1)];
        }
        [results removeObjectAtIndex:0];
        [results removeLastObject]; //remove "}"
        MFStructDeclare *declare = [MFStructDeclare new];
        declare.name = structName;
        declare.keys = keys;
        NSMutableDictionary *keySizes = [NSMutableDictionary dictionary];
        NSMutableDictionary *keyTyeps = [NSMutableDictionary dictionary];
        XCTAssert(declare.keys.count == results.count);
        [results enumerateObjectsUsingBlock:^(NSString *elementEncode, NSUInteger idx, BOOL * _Nonnull stop) {
            NSUInteger size;
            NSGetSizeAndAlignment(elementEncode.UTF8String, &size, NULL);
            keySizes[declare.keys[idx]] = @(size);
            keyTyeps[declare.keys[idx]] = elementEncode;
        }];
        declare.keySizes = keySizes;
        declare.keyTypeEncodes = keyTyeps;
        NSMutableDictionary *keyOffsets = [NSMutableDictionary dictionary];
        for (NSString *key in declare.keys){
            NSUInteger offset = 0;
            for (NSString *current in declare.keys) {
                if ([current isEqualToString:key]){
                    break;
                }
                offset += declare.keySizes[current].unsignedIntegerValue;
            }
            keyOffsets[key] = @(offset);
        }
        declare.keyOffsets = keyOffsets;
        NSLog(@"%@",structName);
        NSLog(@"%@",declare.keySizes);
        return declare;
    }else{
        NSString *structEncode = results[0];
        structEncode = [structEncode substringWithRange:NSMakeRange(1, structEncode.length - 2)];
        NSArray *comps = [structEncode componentsSeparatedByString:@"="];
        NSString *structName = comps.firstObject;
        if ([structName hasPrefix:@"_"]) {
            structName = [structName substringWithRange:NSMakeRange(1, structName.length - 1)];
        }
        NSArray *elementEncodes = startDetectTypeEncode(comps.lastObject);
        MFStructDeclare *declare = [MFStructDeclare new];
        declare.name = structName;
        declare.keys = keys;
        declare.keyTypeEncodes = [elementEncodes mutableCopy];
        NSMutableDictionary *keySizes = [NSMutableDictionary dictionary];
        NSMutableDictionary *keyTyeps = [NSMutableDictionary dictionary];
        XCTAssert(declare.keys.count == elementEncodes.count);
        [elementEncodes enumerateObjectsUsingBlock:^(NSString *elementEncode, NSUInteger idx, BOOL * _Nonnull stop) {
            NSUInteger size;
            NSGetSizeAndAlignment(elementEncode.UTF8String, &size, NULL);
            keySizes[declare.keys[idx]] = @(size);
            keyTyeps[declare.keys[idx]] = elementEncode;
        }];
        declare.keySizes = keySizes;
        declare.keyTypeEncodes = keyTyeps;
        
        NSMutableDictionary *keyOffsets = [NSMutableDictionary dictionary];
        for (NSString *key in declare.keys){
            NSUInteger offset = 0;
            for (NSString *current in declare.keys) {
                if ([current isEqualToString:key]){
                    break;
                }
                offset += declare.keySizes[current].unsignedIntegerValue;
            }
            keyOffsets[key] = @(offset);
        }
        declare.keyOffsets = keyOffsets;
        
        NSLog(@"%@",structName);
        NSLog(@"%@",elementEncodes);
        NSLog(@"%@",declare.keySizes);
        return declare;
    }
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
