//
//  ORTestWithObjc.m
//  OCRunnerTests
//
//  Created by Jiang on 2020/5/19.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCRunner.h>
#import "ORTypeVarPair+TypeEncode.h"
#import <oc2mangoLib/oc2mangoLib.h>
#import "ORRecoverClass.h"
#import <objc/message.h>
#import "ORWeakPropertyAndIvar.h"
#import "ORTestReplaceClass.h"
#import "ORTestClassIvar.h"
#import "ORParserForTest.h"
#import "TestFakeModel.h"
#import "ORTestORGDealloc.h"
#import <MJExtension/MJExtension.h>

@interface SubModel1 : NSObject
@property (nonatomic, assign) CGFloat numberToFloat;
@property (nonatomic, copy) NSString *numberToString;
@property (nonatomic, assign) NSInteger stringToInteger;
@end
@implementation SubModel1
@end
@interface TestModel1 : NSObject
@property (nonatomic, assign) NSInteger numberToInteger;
@property (nonatomic, copy) NSString *numberToString;
@property (nonatomic, strong) SubModel1 *sub;
@end
@implementation TestModel1
@end

@interface ORTestWithObjc : XCTestCase
@property (nonatomic, strong)MFScopeChain *currentScope;
@property (nonatomic, strong)MFScopeChain *topScope;
@property (nonatomic, strong)ORParserForTest *parser;
@end

@interface Fibonaccia: NSObject
@end
@implementation Fibonaccia
-(int)run:(int)n{
    if (n == 1 || n == 2)
        return 1;
    return [self run:n - 1] + [self run:n - 2];
}
@end
int fibonaccia(int n) {
    if (n == 1 || n == 2)
        return 1;
    return fibonaccia(n - 1) + fibonaccia(n - 2);
}

@implementation ORTestWithObjc
- (void)setUp {
    _parser = [ORParserForTest new];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ORParserForTest *parser = [ORParserForTest new];
        NSBundle *currentBundle = [NSBundle bundleForClass:[ORTestWithObjc class]];
        NSString *bundlePath = [currentBundle pathForResource:@"Scripts" ofType:@"bundle"];
        NSBundle *frameworkBundle = [NSBundle bundleWithPath:bundlePath];
        NSString *UIKitPath = [frameworkBundle pathForResource:@"UIKitRefrences" ofType:nil];
        NSString *UIKitData = [NSString stringWithContentsOfFile:UIKitPath encoding:NSUTF8StringEncoding error:nil];
        AST *ast = [parser parseSource:UIKitData];
        [ORInterpreter excuteNodes:ast.nodes];
        
        NSString *GCDPath = [frameworkBundle pathForResource:@"GCDRefrences" ofType:nil];
        NSString *CCDData = [NSString stringWithContentsOfFile:GCDPath encoding:NSUTF8StringEncoding error:nil];
        ast = [parser parseSource:CCDData];
        [ORInterpreter excuteNodes:ast.nodes];
    });
    self.topScope = [MFScopeChain topScope];
    mf_add_built_in(self.topScope);
    XCTAssert(self.topScope.vars.count != 0);
    self.currentScope = [MFScopeChain scopeChainWithNext:self.topScope];
}

- (void)tearDown {
    
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

typedef union TestUnion1{
    int a;
    int b;
    CGFloat c;
    char *d;
    CGRect rect;
}TestUnion1;

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
- (void)testUnionValueGet{
    TestUnion1 value;
    value.a = 1;
    
    ORStructDeclare *rectDecl = [ORStructDeclare structDecalre:@encode(CGRect) keys:@[@"origin",@"size"]];
    ORStructDeclare *pointDecl = [ORStructDeclare structDecalre:@encode(CGPoint) keys:@[@"x",@"y"]];
    ORStructDeclare *sizeDecl = [ORStructDeclare structDecalre:@encode(CGSize) keys:@[@"width",@"height"]];
    ORUnionDeclare *decalre = [ORUnionDeclare unionDecalre:@encode(TestUnion1) keys:@[@"a",@"b",@"c",@"d",@"rect"]];
    
    [[ORTypeSymbolTable shareInstance] addStruct:rectDecl];
    [[ORTypeSymbolTable shareInstance] addStruct:pointDecl];
    [[ORTypeSymbolTable shareInstance] addStruct:sizeDecl];
    [[ORTypeSymbolTable shareInstance] addUnion:decalre];
    
    MFValue *result = [[MFValue alloc] initTypeEncode:decalre.typeEncoding pointer:&value];
    XCTAssert([result unionFieldForKey:@"a"].intValue == 1);
    value.rect = CGRectMake(1, 2, 3, 4);
    result = [[MFValue alloc] initTypeEncode:decalre.typeEncoding pointer:&value];
    MFValue *rectValue = [result unionFieldForKey:@"rect"];
    double height = [[rectValue fieldForKey:@"size"] fieldForKey:@"height"].doubleValue;
    XCTAssert(height == 4);
    double value2 = [result unionFieldForKey:@"c"].doubleValue;
    XCTAssert(value2 == 1);
    ;
}
- (void)testUnionSetValue{
    MFScopeChain *scope = self.currentScope;
    NSString *source =
    @"union TestUnion2{"
    "    int a;"
    "    int b;"
    "    CGFloat c;"
    "    char *d;"
    "    CGRect rect;"
    "};"
    "TestUnion2 value;"
    "value.a = 2;";
    AST *ast = [_parser parseSource:source];
    for (id <OCExecute> exp in ast.nodes) {
        [exp execute:scope];
    }
    MFValue *value = [scope getValueWithIdentifier:@"value"];
    XCTAssert([value unionFieldForKey:@"b"].intValue == 2);
    TestUnion1 result = *(TestUnion1 *)value.pointer;
    XCTAssert(result.a == 2);
    XCTAssert(result.b == 2);
}
- (void)testStructValueGet{
    CGRect rect = CGRectMake(1, 2, 3, 4);
    ORStructDeclare *rectDecl = [ORStructDeclare structDecalre:@encode(CGRect) keys:@[@"origin",@"size"]];
    ORStructDeclare *pointDecl = [ORStructDeclare structDecalre:@encode(CGPoint) keys:@[@"x",@"y"]];
    ORStructDeclare *sizeDecl = [ORStructDeclare structDecalre:@encode(CGSize) keys:@[@"width",@"height"]];
    
    [[ORTypeSymbolTable shareInstance] addStruct:rectDecl];
    [[ORTypeSymbolTable shareInstance] addStruct:pointDecl];
    [[ORTypeSymbolTable shareInstance] addStruct:sizeDecl];
    
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
    
    [[ORTypeSymbolTable shareInstance] addStruct:element1Decl];
    [[ORTypeSymbolTable shareInstance] addStruct:element2Decl];
    [[ORTypeSymbolTable shareInstance] addStruct:containerDecl];
    
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
    NSArray *results = startStructDetect("{CGPointer=dd(Test=idf*)[10i]}");
    XCTAssertEqualObjects(results[0], @"CGPointer");
    XCTAssertEqualObjects(results[1], @"d");
    XCTAssertEqualObjects(results[2], @"d");
    XCTAssertEqualObjects(results[3], @"(Test=idf*)");
    XCTAssertEqualObjects(results[4], @"[10i]");
    NSArray *results1 = startStructDetect("d");
    XCTAssert(results1.count == 0);
}
- (void)testUinonDetect{
    NSArray *results = startUnionDetect("(CGPointer=dd{Test=idf*}[10i])");
    XCTAssertEqualObjects(results[0], @"CGPointer");
    XCTAssertEqualObjects(results[1], @"d");
    XCTAssertEqualObjects(results[2], @"d");
    XCTAssertEqualObjects(results[3], @"{Test=idf*}");
    XCTAssertEqualObjects(results[4], @"[10i]");
    NSArray *results1 = startUnionDetect("d");
    XCTAssert(results1.count == 0);
}
- (void)testArrayDetect{
    NSArray *result = startArrayDetect("[10(Test=idf*)]");
    XCTAssertEqualObjects(result[0], @"10");
    XCTAssertEqualObjects(result[1], @"(Test=idf*)");
    result = startArrayDetect("[0i]");
    XCTAssertEqualObjects(result[0], @"0");
    XCTAssertEqualObjects(result[1], @"i");
    
    result = startArrayDetect("d");
    XCTAssert(result.count == 0);
    
//    NSLog(@"%s",@encode(int[10]));
//    NSLog(@"%s",@encode(int[100][10]));
//    NSLog(@"%s",@encode(CGPoint[10]));
    
    result = startArrayDetect("[10i]");
    XCTAssert(result.count == 2);
    XCTAssertEqualObjects(result[0], @"10");
    XCTAssertEqualObjects(result[1], @"i");
    
    result = startArrayDetect("[100[10i]]");
    XCTAssert(result.count == 2);
    XCTAssertEqualObjects(result[0], @"100");
    XCTAssertEqualObjects(result[1], @"[10i]");
    result = startArrayDetect([result[1] UTF8String]);
    XCTAssertEqualObjects(result[0], @"10");
    XCTAssertEqualObjects(result[1], @"i");
    
    result = startArrayDetect("[10{CGPoint=dd}]");
    XCTAssert(result.count == 2);
    XCTAssertEqualObjects(result[0], @"10");
    XCTAssertEqualObjects(result[1], @"{CGPoint=dd}");
}
- (void)testStructSetValueNoCopy{
    MFScopeChain *scope = self.currentScope;
    CGRect rect1 = CGRectZero;
    MFValue *value = [MFValue defaultValueWithTypeEncoding:@encode(CGRect)];
    [value setValuePointerWithNoCopy:&rect1];
    [[value fieldNoCopyForKey:@"origin"] setFieldWithValue:[MFValue valueWithDouble:1] forKey:@"x"];
    [[value fieldNoCopyForKey:@"origin"] setFieldWithValue:[MFValue valueWithDouble:2] forKey:@"y"];
    XCTAssert(rect1.origin.x == 1, @"origin.x %f", rect1.origin.x);
    XCTAssert(rect1.origin.y == 2, @"origin.y %f", rect1.origin.y);
    
    NSString * source =
    @"CGRect rect;"
    "rect.origin.x = 10;"
    "rect.origin.y = 10;"
    "rect.size.width = 100;"
    "rect.size.height = 100;";
    AST *ast = [_parser parseSource:source];
    for (id <OCExecute> exp in ast.globalStatements) {
        [exp execute:scope];
    }
    MFValue *rectValue = [scope recursiveGetValueWithIdentifier:@"rect"];
    CGRect rect = *(CGRect *) rectValue.pointer;
    XCTAssert(rectValue.type == OCTypeStruct);
    XCTAssert(rect.origin.x == 10);
    XCTAssert(rect.origin.y == 10);
    XCTAssert(rect.size.width == 100);
    XCTAssert(rect.size.height == 100);
}
- (void)testStructSetValueNeedCopy{
    
    MFScopeChain *scope = self.currentScope;
    CGRect rect1 = CGRectZero;
    MFValue *value = [MFValue defaultValueWithTypeEncoding:@encode(CGRect)];
    [value setValuePointerWithNoCopy:&rect1];
    [[value fieldForKey:@"origin"] setFieldWithValue:[MFValue valueWithDouble:1] forKey:@"x"];
    [[value fieldForKey:@"origin"] setFieldWithValue:[MFValue valueWithDouble:2] forKey:@"y"];
    XCTAssert(rect1.origin.x == 0, @"origin.x %f", rect1.origin.x);
    XCTAssert(rect1.origin.y == 0, @"origin.y %f", rect1.origin.y);

    NSString * source =
    @"CGRect frame = CGRectMake(0,1,2,3);"
    "CGSize size = frame.size;"
    "size.width = 100;"
    "size.height = 100;";
    AST *ast = [_parser parseSource:source];
    for (id <OCExecute> exp in ast.globalStatements) {
        [exp execute:scope];
    }
    MFValue *rectValue = [scope recursiveGetValueWithIdentifier:@"frame"];
    CGRect rect = *(CGRect *) rectValue.pointer;
    XCTAssert(rectValue.type == OCTypeStruct);
    XCTAssert(rect.size.width == 2);
    XCTAssert(rect.size.height == 3);
}
- (void)testStructGetValue{
    MFScopeChain *scope = self.currentScope;
    NSString * source =
    @"UIView *view = [UIView new];"
    "view.frame = CGRectMake(0,0,3,4);"
    "CGRect frame = view.frame;"
    "CGFloat a = frame.size.height;";
    AST *ast = [_parser parseSource:source];
    for (id <OCExecute> exp in ast.globalStatements) {
        [exp execute:scope];
    }
    MFValue *frameValue = [scope recursiveGetValueWithIdentifier:@"frame"];
    CGRect rect = *(CGRect *) frameValue.pointer;
    NSLog(@"%@",[NSValue valueWithCGRect:rect]);
    XCTAssert(frameValue.type == OCTypeStruct);
    MFValue * aValue = [scope recursiveGetValueWithIdentifier:@"a"];
    XCTAssert(aValue.type == OCTypeDouble);
    XCTAssert(aValue.doubleValue == 4);
}
- (void)testStructGetValueNoDefine{
    //    NSString *source = @"\
    //    struct NSDirectionalEdgeInsets {\
    //        CGFloat top, leading, bottom, trailing;\
    //    };\
    //    CGFloat top = UIApplication.sharedApplication.keyWindow.directionalLayoutMargins.top;\
    //    ";
    NSString *source = @"CGFloat top = UIApplication.sharedApplication.keyWindow.directionalLayoutMargins.top;";
    MFScopeChain *scope = self.currentScope;
    AST *ast = [_parser parseSource:source];
    for (id <OCExecute> exp in ast.globalStatements) {
        [exp execute:scope];
    }
    if (@available(iOS 11.0, *)) {
        XCTAssert(UIApplication.sharedApplication.keyWindow.directionalLayoutMargins.top == [scope getValueWithIdentifier:@"top"].doubleValue);
    }
}
- (void)testDetectStructMemeryLayoutCode{
    NSString *result = detectStructMemeryLayoutEncodeCode("{CGRect={CGPoint=ff{CGPoint=dd}}{CGSize=dd}}");
    XCTAssert([result isEqualToString:@"ffdddd"]);
    XCTAssert(isHomogeneousFloatingPointAggregate(result.UTF8String));
    XCTAssert(fieldCountInStructMemeryLayoutEncode(result.UTF8String) == 6);
    XCTAssert(fieldCountInStructMemeryLayoutEncode("^^f^fdd^^dd") == 6);
    NSString *result1 = detectStructMemeryLayoutEncodeCode(@encode(ContainerStruct));
    XCTAssert([result1 isEqualToString:@"^^i^id^{Element1Struct}ddd^^i^id^{Element2Struct}"]);
    XCTAssert(fieldCountInStructMemeryLayoutEncode(result1.UTF8String) == 11);
}
- (void)testDetectFieldTypeEncodes{
    NSMutableArray *results = detectFieldTypeEncodes("^^i^id^{Element1Struct}");
    XCTAssert([results[0] isEqualToString:@"^^i"]);
    XCTAssert([results[1] isEqualToString:@"^i"]);
    XCTAssert([results[2] isEqualToString:@"d"]);
    XCTAssert([results[3] isEqualToString:@"^{Element1Struct}"]);
}
typedef struct MyStruct
{
    char a;         // 1 byte
    int b;          // 4 bytes
    short c;        // 2 bytes
    long long d;    // 8 bytes
    char e;         // 1 byte
}MyStruct;
typedef struct MyStruct1 {
    double b;   // size：8
    int c;      // size：4
    char a;     // size：1
    short d;    // size：2
} MyStruct1;
typedef struct MyStruct2 {
    double b;   // size：8
    char a;     // size：1
    int c;      // size：4
    short d;    // size：2
} MyStruct2;
- (void)testStructMemoryAlignment{
    NSUInteger size = 0;
    NSUInteger alig = 0;
    const char *code = detectStructMemeryLayoutEncodeCode(@encode(MyStruct)).UTF8String;
    while (code != NULL && *code != '\0') {
        code = NSGetSizeAndAlignment(code, &size, &alig);
        NSLog(@"%lu %lu %s",size,alig,code);
    }
    ORStructDeclare *declare = [[ORStructDeclare alloc] initWithTypeEncode:@encode(MyStruct) keys:@[@"a",@"b",@"c",@"d",@"e"]];
    XCTAssert([declare.keyOffsets[@"a"] isEqualToNumber:@(0)]);
    XCTAssert([declare.keyOffsets[@"b"] isEqualToNumber:@(4)]);
    XCTAssert([declare.keyOffsets[@"c"] isEqualToNumber:@(8)]);
    XCTAssert([declare.keyOffsets[@"d"] isEqualToNumber:@(16)]);
    XCTAssert([declare.keyOffsets[@"e"] isEqualToNumber:@(24)]);
    
    ORStructDeclare *declare1 = [[ORStructDeclare alloc] initWithTypeEncode:@encode(MyStruct1) keys:@[@"b",@"c",@"a",@"d"]];
    XCTAssert([declare1.keyOffsets[@"b"] isEqualToNumber:@(0)]);
    XCTAssert([declare1.keyOffsets[@"c"] isEqualToNumber:@(8)]);
    XCTAssert([declare1.keyOffsets[@"a"] isEqualToNumber:@(12)]);
    XCTAssert([declare1.keyOffsets[@"d"] isEqualToNumber:@(14)]);
    
    ORStructDeclare *declare2 = [[ORStructDeclare alloc] initWithTypeEncode:@encode(MyStruct2) keys:@[@"b",@"a",@"c",@"d"]];
    XCTAssert([declare2.keyOffsets[@"b"] isEqualToNumber:@(0)]);
    XCTAssert([declare2.keyOffsets[@"a"] isEqualToNumber:@(8)]);
    XCTAssert([declare2.keyOffsets[@"c"] isEqualToNumber:@(12)]);
    XCTAssert([declare2.keyOffsets[@"d"] isEqualToNumber:@(16)]);
}

struct AStruct {
    int a1;
    char a2;
};
struct BStruct {
    char b1;
    struct AStruct b2;
    double b3;
};

- (void)testStructMemoryAlignment2{
    ORStructDeclare *declare = [[ORStructDeclare alloc] initWithTypeEncode:@encode(struct BStruct) keys:@[@"b1",@"b2",@"b3"]];
    XCTAssert([declare.keyOffsets[@"b1"] isEqualToNumber:@(0)]);
    XCTAssert([declare.keyOffsets[@"b2"] isEqualToNumber:@(offsetof(struct BStruct, b2))]);
    XCTAssert(declare.structSize == sizeof(struct BStruct), @"BStruct %lu", declare.structSize);
}

struct CStruct {
    short c1;
    char c2;
};
struct DStruct {
    char d1;
    struct CStruct d2;
    double d3;
};
- (void)testStructMemoryAlignment3{
    ORStructDeclare *declare = [[ORStructDeclare alloc] initWithTypeEncode:@encode(struct DStruct) keys:@[@"d1",@"d2",@"d3"]];
    XCTAssert([declare.keyOffsets[@"d1"] isEqualToNumber:@(0)]);
    XCTAssert([declare.keyOffsets[@"d2"] isEqualToNumber:@(offsetof(struct DStruct, d2))]);
    XCTAssert(declare.structSize == sizeof(struct DStruct), @"BStruct %lu", declare.structSize);
}

struct GStruct {
    double g1;
    int g2;
};
struct FStruct {
    short f1;
    char f2;
    struct GStruct f3;
};
struct EStruct {
    char e1;
    struct FStruct e2;
    double e3;
};

- (void)testStructMemoryAlignment4{
    ORStructDeclare *declare = [[ORStructDeclare alloc] initWithTypeEncode:@encode(struct EStruct) keys:@[@"e1",@"e2",@"e3"]];
    XCTAssert([declare.keyOffsets[@"e1"] isEqualToNumber:@(0)]);
    XCTAssert([declare.keyOffsets[@"e2"] isEqualToNumber:@(offsetof(struct EStruct, e2))]);
    XCTAssert(declare.structSize == sizeof(struct EStruct), @"EStruct %lu", declare.structSize);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        for (int i = 0; i < 100000; i++) {
            NSUInteger size = 0;
            NSUInteger align = 0;
            NSGetSizeAndAlignment("{CGRect={CGPoint=ff{CGPoint=dd}}{CGSize=dd}}", &size, &align);
            NSGetSizeAndAlignment("{ContainerStruct={Element1Struct=^^i^id}^{Element1Struct}{Element2Struct=ddd{Element1Struct=^^i^id}}^{Element2Struct}}", &size, &align);
        }
    }];
}
- (void)testParsePerformance{
    
}
- (void)testGetPointerAddress{
    MFScopeChain *scope = self.currentScope;
    NSString * source =
    @"int a = 1;"
    @"int *b = &a;"
    @"int **c = &b;";
    AST *ast = [_parser parseSource:source];
    for (id <OCExecute> exp in ast.globalStatements) {
        [exp execute:scope];
    }
    MFValue *a = [scope recursiveGetValueWithIdentifier:@"a"];
    XCTAssert(strcmp(a.typeEncode, "i") == 0);
    XCTAssert(*(int *)a.pointer == 1);
    MFValue *b = [scope recursiveGetValueWithIdentifier:@"b"];
    XCTAssert(strcmp(b.typeEncode, "^i") == 0);
    XCTAssert(**(int **)b.pointer == 1);
    MFValue *c = [scope recursiveGetValueWithIdentifier:@"c"];
    XCTAssert(strcmp(c.typeEncode, "^^i") == 0);
    NSLog(@"%s",c.typeEncode);
    XCTAssert(***(int ***)c.pointer == 1);
}
- (void)testGetPointerValue{
    MFScopeChain *scope = self.currentScope;
    NSString * source =
    @"int a = 1;"
    @"int *b = &a;"
    @"int **c = &b;"
    @"int d = **c;";
    AST *ast = [_parser parseSource:source];
    for (id <OCExecute> exp in ast.globalStatements) {
        [exp execute:scope];
    }
    MFValue *d = [scope recursiveGetValueWithIdentifier:@"d"];
    XCTAssert(strcmp(d.typeEncode, "i") == 0);
    XCTAssert(*(int *)d.pointer == 1);
}
- (void)testProtcolConfirm{
    NSString * source =
    @"@protocol Protocol1 <NSObject>"
    @"@property (nonatomic,copy)NSString *name;"
    @"-(NSUInteger)getAge;"
    @"-(void)setAge:(NSUInteger)age;"
    @"@end"
    @"@protocol Protocol2 <Protocol1>"
    @"- (void)sleep;"
    @"@end"
    @"@interface TestProtocol : NSObject <Protocol2>"
    @"@property (nonatomic,copy)NSString *name;"
    @"@end"
    @"@implementation TestProtocol"
    @"- (NSUInteger)getAge{"
    @"    return 100;"
    @"}"
    @"-(void)setAge:(NSUInteger)age{"
    @"}"
    @"- (void)sleep{"
    @"}"
    @"@end";
    AST *ast = [_parser parseSource:source];
    [ORInterpreter excuteNodes:ast.nodes];
    Class testClass = NSClassFromString(@"TestProtocol");
    XCTAssert([testClass conformsToProtocol:NSProtocolFromString(@"Protocol1")]);
    XCTAssert([testClass conformsToProtocol:NSProtocolFromString(@"Protocol2")]);
    id object = [[testClass alloc] init];
    XCTAssert([object conformsToProtocol:NSProtocolFromString(@"Protocol1")]);
    XCTAssert([object conformsToProtocol:NSProtocolFromString(@"Protocol2")]);
    XCTAssert([object respondsToSelector:@selector(name)]);
    XCTAssert([object respondsToSelector:@selector(setName:)]);
    XCTAssert([object respondsToSelector:@selector(getAge)]);
    XCTAssert([object respondsToSelector:@selector(setAge:)]);
    XCTAssert([object respondsToSelector:@selector(sleep)]);
}
- (void)testAtProtcol{
    MFScopeChain *scope = self.currentScope;
    NSString * source =
    @"id object = @protocol(NSObject);";
    AST *ast = [_parser parseSource:source];
    for (id <OCExecute> exp in ast.globalStatements) {
        [exp execute:scope];
    }
    MFValue *d = [scope recursiveGetValueWithIdentifier:@"object"];
    Protocol *protocol = d.objectValue;
    XCTAssert([NSStringFromProtocol(protocol) isEqualToString:@"NSObject"]);
}
- (void)testRecursiveFunction{
    MFScopeChain *scope = self.currentScope;
    NSString * source =
    @"int fibonaccia(int n){"
    @"    if (n == 1 || n == 2)"
    @"        return 1;"
    @"    return fibonaccia(n - 1) + fibonaccia(n - 2);"
    @"}"
    @"int a = fibonaccia(20);";
    AST *ast = [_parser parseSource:source];
    for (id <OCExecute> exp in ast.globalStatements) {
        [exp execute:scope];
    }
    MFValue *c = [scope recursiveGetValueWithIdentifier:@"a"];
    XCTAssert(c.intValue == fibonaccia(20));
}
- (void)testRecursiveMethod{
    MFScopeChain *scope = self.currentScope;
    NSString * source =
    @"@implementation Fibonaccia"
    @"-(int)run:(int)n{"
    @"    if (n == 1 || n == 2)"
    @"        return 1;"
    @"    return [self run:n - 1] + [self run:n - 2];"
    @"}"
    @"@end"
    @"int a = [[Fibonaccia new] run:20];";
    AST *ast = [_parser parseSource:source];
    for (id <OCExecute> exp in ast.nodes) {
        [exp execute:scope];
    }
    MFValue *a = [scope recursiveGetValueWithIdentifier:@"a"];
    XCTAssert(a.intValue == fibonaccia(20));
}
- (void)testFunctionPointerCall{
    MFScopeChain *scope = self.currentScope;
    [ORSystemFunctionPointerTable reg:@"class_getMethodImplementation" pointer:&class_getMethodImplementation];
    NSString * source =
    @"void *class_getMethodImplementation(Class cls, SEL name);"
    @"int (*imp)(id target, SEL sel) = class_getMethodImplementation([ORTestReplaceClass class], @selector(testOriginalMethod));"
    @"id value = [ORTestReplaceClass new];"
    @"int a = imp(value, @selector(testOriginalMethod));";
    AST *ast = [_parser parseSource:source];
    for (id <OCExecute> exp in ast.nodes) {
        [exp execute:scope];
    }
    MFValue *a = [scope recursiveGetValueWithIdentifier:@"a"];
    XCTAssert(a.intValue == 2);
}
- (void)testMutiTypeCalculate{
    MFScopeChain *scope = self.currentScope;
    NSString * source =
    @"int a = 1 * 1.1;"
    "int b = 2 * 10;"
    "double c = 1 + 1.12;"
    "double d = 1 / 2.0;"
    "double e = 1 - 0.25;"
    "BOOL f = 0 < 0.25;"
    "BOOL g = 0.25 <= 0;"
    "double h = 0.25 - 1;"
    ;
    AST *ast = [_parser parseSource:source];
    for (id <OCExecute> exp in ast.nodes) {
        [exp execute:scope];
    }
    MFValue *a = [scope recursiveGetValueWithIdentifier:@"a"];
    MFValue *b = [scope recursiveGetValueWithIdentifier:@"b"];
    MFValue *c = [scope recursiveGetValueWithIdentifier:@"c"];
    MFValue *d = [scope recursiveGetValueWithIdentifier:@"d"];
    MFValue *e = [scope recursiveGetValueWithIdentifier:@"e"];
    MFValue *f = [scope recursiveGetValueWithIdentifier:@"f"];
    MFValue *g = [scope recursiveGetValueWithIdentifier:@"g"];
    MFValue *h = [scope recursiveGetValueWithIdentifier:@"h"];
    XCTAssert(a.intValue == 1);
    XCTAssert(b.intValue == 20);
    XCTAssert(c.doubleValue == 2.12);
    XCTAssert(d.doubleValue == 0.5);
    XCTAssert(e.doubleValue == 0.75);
    XCTAssert(f.boolValue == YES);
    XCTAssert(g.boolValue == NO);
    XCTAssert(h.doubleValue == -0.75);
}
- (void)testCFunctionReturnTypeEncode{
    NSString * source =
    @"CGFloat testFunctionReturnType(int arg);"
    @"CGFloat (***testFunctionReturnType)(int arg);"
    @"CGFloat *testFunctionReturnType(int arg);"
    @"XCTestCase *testFunctionReturnType(int arg);"
    @"XCTestCase *(^testFunctionReturnType)(int arg);"
    ;
    AST *ast = [_parser parseSource:source];
    ORDeclareExpression *declare1 = ast.globalStatements[0];
    ORDeclareExpression *declare2 = ast.globalStatements[1];
    ORDeclareExpression *declare3 = ast.globalStatements[2];
    ORDeclareExpression *declare4 = ast.globalStatements[3];
    ORDeclareExpression *declare5 = ast.globalStatements[4];
    NSString *returnType1 = [NSString stringWithUTF8String:declare1.pair.typeEncode];
    XCTAssert([returnType1 isEqualToString:@"d"], @"%@", returnType1);
    NSString *returnType2 = [NSString stringWithUTF8String:declare2.pair.typeEncode];
    XCTAssert([returnType2 isEqualToString:@"^^^d"], @"%@", returnType2);
    NSString *returnType3 = [NSString stringWithUTF8String:declare3.pair.typeEncode];
    XCTAssert([returnType3 isEqualToString:@"^d"], @"%@", returnType3);
    NSString *returnType4 = [NSString stringWithUTF8String:declare4.pair.typeEncode];
    XCTAssert([returnType4 isEqualToString:@"@"], @"%@", returnType4);
    NSString *returnType5 = [NSString stringWithUTF8String:declare5.pair.typeEncode];
    XCTAssert([returnType5 isEqualToString:@"@?"], @"%@", returnType5);
}
- (void)testWeakPropertyAndIvar{
    MFScopeChain *scope = self.currentScope;
    NSString *source =
    @""
    "@interface ORWeakPropertyAndIvar()"
    "@property(nonatomic, strong)id strongValue;"
    "@property(nonatomic, weak)id weakValue;"
    "@end"
    "@implementation ORWeakPropertyAndIvar"
    "- (void)propertyStrong{"
    "   self.strongValue = self;"
    "}"
    "- (void)propertyWeak{"
    "   self.weakValue = self;"
    "}"
    "- (void)ivarStrong{"
    "   _strongValue = self;"
    "}"
    "- (void)ivarWeak{"
    "   _weakValue = self;"
    "}"
    "@end";
    
    AST *ast = [_parser parseSource:source];
    for (id <OCExecute> exp in ast.nodes) {
        [exp execute:scope];
    }
    NSMutableString *propertyStrong = [NSMutableString string];
    @autoreleasepool {
        ORWeakPropertyAndIvar *test = [[ORWeakPropertyAndIvar alloc] initWithContainer:propertyStrong];
        [test propertyStrong];
    }
    XCTAssert(propertyStrong.length == 0);
    
    NSMutableString *propertyWeak = [NSMutableString string];
    @autoreleasepool {
        ORWeakPropertyAndIvar *test = [[ORWeakPropertyAndIvar alloc] initWithContainer:propertyWeak];
        [test propertyWeak];
    }
    XCTAssert([propertyWeak isEqualToString:@"dealloc"]);
    
    NSMutableString *ivarStrong = [NSMutableString string];
    @autoreleasepool {
        ORWeakPropertyAndIvar *test = [[ORWeakPropertyAndIvar alloc] initWithContainer:ivarStrong];
        [test ivarStrong];
    }
    XCTAssert(ivarStrong.length == 0);
    
    NSMutableString *ivarWeak = [NSMutableString string];
    @autoreleasepool {
        ORWeakPropertyAndIvar *test = [[ORWeakPropertyAndIvar alloc] initWithContainer:ivarWeak];
        [test ivarWeak];
    }
    XCTAssert([ivarWeak isEqualToString:@"dealloc"]);
}
- (void)testRecover{
    NSString *source = @"\
    @interface ORRecoverClass : NSObject\
    @property (nonatomic, assign)int value1;\
    @property (nonatomic, copy)NSString *value2;\
    @end\
    @implementation ORRecoverClass\
    + (int)classMethodTest{ return 0; }\
    - (int)methodTest1{ return 0; }\
    - (int)methodTest2{ return 0; }\
    - (int)value1{ return 1; }\
    - (NSString *)value2{ return @\"123\"; }\
    @end";
    AST *ast = [_parser parseSource:source];
    [ORInterpreter excuteNodes:ast.nodes];
    ORRecoverClass *object = [ORRecoverClass new];
    XCTAssert([object value1] == 1);
    XCTAssert([[object value2] isEqual:@"123"]);
    XCTAssert([object methodTest1] == 0);
    XCTAssert([object methodTest2] == 0);
    XCTAssert([ORRecoverClass classMethodTest] == 0);
    [ORInterpreter recoverWithClearEnvironment:NO];
    XCTAssert([object value1] == 0);
    XCTAssert([object value2] == nil);
    XCTAssert([object methodTest1] == 1);
    XCTAssert([object methodTest2] == 1);
    XCTAssert([ORRecoverClass classMethodTest] == 1);
}
- (void)testArgumentWithTypeDefBlock{
    NSString *source = @"\
    \
    typedef NSString * (^TestBlock)  (NSString *);\
    typedef NSString * (^TestBlock1) (TestBlock);\
    TestBlock1 block = ^NSString *(TestBlock value){\
        return value(@\"123321\");\
    };\
    NSString *result = block(^NSString *(NSString* value){\
        return value;\
    });";
    AST *ast = [_parser parseSource:source];
    [ORInterpreter excuteNodes:ast.nodes];
    MFValue *h = [self.currentScope recursiveGetValueWithIdentifier:@"result"];
    XCTAssert([h.objectValue isEqual:@"123321"]);
}
int signatureBlockPtr(id object, int b){
    return b * 2;
}
- (void)testNoSignatureBlock{
    NSString *source = @"\
    @implementation ORTestReplaceClass\
    - (int)testNoSignatureBlock:(int(^)(int))arg{\
        return arg(10);\
    }\
    @end\
    ";
    AST *ast = [_parser parseSource:source];
    [ORInterpreter excuteNodes:ast.nodes];
    id block = (__bridge id)simulateNSBlock(NULL, &signatureBlockPtr, NULL);
    int result = [[ORTestReplaceClass new] testNoSignatureBlock: block];
    XCTAssert(result == 20);
}
- (void)testBlockCycleRefrence{
    MFScopeChain *scope = self.currentScope;
    NSString * source =
    @"int flag = 0;\
    @implementation TestObject\
    - (void)testNormalBlock{\
        __weak id weakSelf = self;\
        void(^block)(void) = ^{\
            __strong id strongSelf = weakSelf;\
            NSLog(@\"%@\",strongSelf);\
        };\
        block();\
    }\
    -(void)dealloc{ flag = 1; }\
    @end\
    [[TestObject new] testNormalBlock];";
    @autoreleasepool {
        AST *ast = [OCParser parseSource:source];
        [ORInterpreter excuteNodes:ast.nodes];
    }
    MFValue *flag = [scope recursiveGetValueWithIdentifier:@"flag"];
    XCTAssert(flag.intValue == 1);
}
- (void)testPropertyBlockCycleRefrenceWhileWithWeakVar{
    MFScopeChain *scope = self.currentScope;
    NSString * source =
    @"int flag = 0;\
    @interface TestObject: NSObject\
    @property(nonatomic, strong) void(^block)(void);\
    @end\
    @implementation TestObject\
    - (void)testPropertyBlock{\
        __weak id weakSelf = self;\
        self.block = ^{\
            __strong id strongSelf = weakSelf;\
            NSLog(@\"%@\",strongSelf);\
        };\
        self.block();\
    }\
    -(void)dealloc{ NSLog(@\"GG\"); flag = 1; }\
    @end\
    [[TestObject new] testPropertyBlock];";
    @autoreleasepool {
        AST *ast = [OCParser parseSource:source];
        [ORInterpreter excuteNodes:ast.nodes];
    }
    MFValue *flag = [scope recursiveGetValueWithIdentifier:@"flag"];
    XCTAssert(flag.intValue == 1);
}
- (void)testBlockUseWeakVarWhileIsNil {
    MFScopeChain *scope = self.currentScope;
    NSString *source = @"\
    bool assignOther = YES;\
    id value1 = nil;\
    id value2 = nil;\
    id value3 = nil;\
    @interface TestObject:NSObject \
    @property(assign, nonatomoic)BOOL assignOther; \
    @end\
    @implementation TestObject\
    - (instancetype)initWithFlag:(bool)value {\
        self = [super init];\
        _assignOther = value;\
        return self;\
    }\
    - (void)runTest{\
        bool assignOther = _assignOther;\
        __weak id object = [NSObject new];\
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{\
            if (!assignOther) value1 = object;\
        });\
        __weak id weakSelf = self;\
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{\
            if (!assignOther) value2 = weakSelf;\
            else value3 = weakSelf;\
        });\
    }\
    - (void)dealloc{\
        NSLog(@\"TestObject dealloc\");\
        [super dealloc];\
    }\
    @end\
    [[TestObject new] runTest];\
    id object = [[TestObject alloc] initWithFlag:YES];\
    [object runTest];\
    ";
    @autoreleasepool {
        AST *ast = [OCParser parseSource:source];
        [ORInterpreter excuteNodes:ast.nodes];
    }
    [NSThread sleepForTimeInterval:1.5f];
    MFValue *value1 = [scope recursiveGetValueWithIdentifier:@"value1"];
    MFValue *value2 = [scope recursiveGetValueWithIdentifier:@"value2"];
    MFValue *value3 = [scope recursiveGetValueWithIdentifier:@"value3"];
    XCTAssert(value1.objectValue == nil, @"%@",value1.objectValue);
    XCTAssert(value2.objectValue == nil, @"%@",value2.objectValue);
    XCTAssert(value3.objectValue != nil, @"%@",value2.objectValue);
}
- (void)testInputStackBlock{
    NSString *source = @"\
    @implementation ORTestReplaceClass\
    - (void)receiveStackBlock:(void (^)(NSString *str))block{\
        block(@\"receiveStackBlock\");\
    }\
    @end";
    AST *ast = [_parser parseSource:source];
    [ORInterpreter excuteNodes:ast.nodes];
    ORTestReplaceClass *object = [ORTestReplaceClass new];
    XCTAssert([[object testInputStackBlock] isEqualToString:@"receiveStackBlock"]);
}
- (void)testIvarRefrenceCount{
    
    NSString * source =
    @"\
    @implementation ORTestClassIvar\
    - (void)ivarRefrenceCount:(id)object{\
        _object = object;\
    }\
    @end";
    ORTestClassIvar *test = [ORTestClassIvar new];
    @autoreleasepool {
        NSObject *object = [NSObject new];
        AST *ast = [_parser parseSource:source];
        [ORInterpreter excuteNodes:ast.nodes];
        [test ivarRefrenceCount:object];
    }
    XCTAssert(CFGetRetainCount((void *)(test->_object)) == 1);
}

- (void)test6ArgsMethodCallInScript{
    MFScopeChain *scope = self.currentScope;
    NSString *source = @"\
    int a,b,c,d,e,f;\
    @implementation ORTestMethoCall\
    - (void)test6ArgsMethoCall:(int)arg1 arg2:(int)arg2 arg3:(int)arg3 arg4:(int)arg4 arg5:(int)arg5 arg6:(int)arg6{\
    a = arg1; b = arg2; c = arg3; d = arg4; e = arg5; f = arg6;\
    }\
    @end\
    [[ORTestMethoCall new] test6ArgsMethoCall:1 arg2:2 arg3:3 arg4:4 arg5:5 arg6:6];\
    ";
    AST *ast = [OCParser parseSource:source];
    [ORInterpreter excuteNodes:ast.nodes];
    MFValue *a = [scope recursiveGetValueWithIdentifier:@"a"];
    MFValue *b = [scope recursiveGetValueWithIdentifier:@"b"];
    MFValue *c = [scope recursiveGetValueWithIdentifier:@"c"];
    MFValue *d = [scope recursiveGetValueWithIdentifier:@"d"];
    MFValue *e = [scope recursiveGetValueWithIdentifier:@"e"];
    MFValue *f = [scope recursiveGetValueWithIdentifier:@"f"];
    
    XCTAssert(a.intValue == 1, @"%d", a.intValue);
    XCTAssert(b.intValue == 2, @"%d", b.intValue);
    XCTAssert(c.intValue == 3, @"%d", c.intValue);
    XCTAssert(d.intValue == 4, @"%d", d.intValue);
    XCTAssert(e.intValue == 5, @"%d", e.intValue);
    XCTAssert(f.intValue == 6, @"%d", f.intValue);
    
}
- (void)test6ArgsMethodCallWithOC{
    MFScopeChain *scope = self.currentScope;
    NSString *source = @"\
    int a,b,c,d,e,f;\
    @implementation ORTestReplaceClass\
    - (void)test6ArgsMethoCall:(int)arg1 arg2:(int)arg2 arg3:(int)arg3 arg4:(int)arg4 arg5:(int)arg5 arg6:(int)arg6{\
        a = arg1; b = arg2; c = arg3; d = arg4; e = arg5; f = arg6;\
    }\
    @end\
    ";
    AST *ast = [OCParser parseSource:source];
    [ORInterpreter excuteNodes:ast.nodes];
    [[ORTestReplaceClass new] test6ArgsMethoCall:1 arg2:2 arg3:3 arg4:4 arg5:5 arg6:6];
    MFValue *a = [scope recursiveGetValueWithIdentifier:@"a"];
    MFValue *b = [scope recursiveGetValueWithIdentifier:@"b"];
    MFValue *c = [scope recursiveGetValueWithIdentifier:@"c"];
    MFValue *d = [scope recursiveGetValueWithIdentifier:@"d"];
    MFValue *e = [scope recursiveGetValueWithIdentifier:@"e"];
    MFValue *f = [scope recursiveGetValueWithIdentifier:@"f"];
    
    XCTAssert(a.intValue == 1, @"%d", a.intValue);
    XCTAssert(b.intValue == 2, @"%d", b.intValue);
    XCTAssert(c.intValue == 3, @"%d", c.intValue);
    XCTAssert(d.intValue == 4, @"%d", d.intValue);
    XCTAssert(e.intValue == 5, @"%d", e.intValue);
    XCTAssert(f.intValue == 6, @"%d", f.intValue);
}
- (void)testCArrayGetSet{
    MFScopeChain *scope = self.currentScope;
    NSString *source = @"\
    char c[100][10];\
    c[0][0] = 1;\
    int d = c[0][0];\
    char a[10]; \
    a[0] = 1;\
    int b = a[0];\
    CGPoint x[2][2];\
    x[0][1] = CGPointMake(0,1);\
    CGPoint y = x[0][1];\
    ";
    AST *ast = [_parser parseSource:source];
    [ORInterpreter excuteNodes:ast.nodes];
    MFValue *a = [scope recursiveGetValueWithIdentifier:@"a"];
    XCTAssert(a.memerySize == 10);
    XCTAssert(strcmp(a.typeEncode, @encode(char[10])) == 0);
    MFValue *b = [scope recursiveGetValueWithIdentifier:@"b"];
    XCTAssert(b.intValue == 1);
    MFValue *d = [scope recursiveGetValueWithIdentifier:@"d"];
    XCTAssert(d.intValue == 1);
    MFValue *c = [scope recursiveGetValueWithIdentifier:@"c"];
    XCTAssert(c.memerySize == 1000);
    XCTAssert(strcmp(c.typeEncode, @encode(char[100][10])) == 0, @"%s",c.typeEncode);
    MFValue *y = [scope recursiveGetValueWithIdentifier:@"y"];
    CGPoint point = *(CGPoint *)y.pointer;
    XCTAssert(CGPointEqualToPoint(CGPointMake(0, 1), point));
}
- (void)testCArrayBridge{
    MFScopeChain *scope = self.currentScope;
    NSString *source = @"\
    int len = 10;\
    int carray[len];\
    for (int i = 0; i < len; i++) {\
        carray[i] = i;\
    }\
    id object = [ORTestReplaceClass new];\
    int result = [object receiveCArray:carray len:len];\
    @implementation ORTestReplaceClass\
    - (int)scriptReceiveCArray:(int *)array len:(int)len{\
        int r = 0;\
        for (int i = 0; i < len; i++) {\
            r += array[i];\
        }\
        return r;\
    }\
    @end";
    AST *ast = [_parser parseSource:source];
    [ORInterpreter excuteNodes:ast.nodes];
    MFValue *result = [scope recursiveGetValueWithIdentifier:@"result"];
    XCTAssert(result.intValue == 45, @"%d", result.intValue);
    ORTestReplaceClass *obejct = [ORTestReplaceClass new];
    int input[10];
    for (int i = 0; i < 10; i++) {
        input[i] = i;
    }
    XCTAssert([obejct scriptReceiveCArray:input len:10] == 45);
}
- (void)testSetPointerValue{
    MFScopeChain *scope = self.currentScope;
    NSString *source = @"\
    int *pointerValue = malloc(4);\
    *pointerValue = 10;\
    int result = *pointerValue;";
    AST *ast = [_parser parseSource:source];
    [ORInterpreter excuteNodes:ast.nodes];
    MFValue *a = [scope recursiveGetValueWithIdentifier:@"result"];
    XCTAssert(a.intValue == 10, @"%d", a.intValue);
}
- (void)testNullPointerBinaryOperator {
    MFScopeChain *scope = self.currentScope;
    NSString *source = @"\
    NSString *string = nil;\
    NSString *result = @\"\";\
    if (string.length < 1) result = @\"123\";\
    int a = string.length - 2;\
    double b = string.length + 2.0;\
    ";
    AST *ast = [_parser parseSource:source];
    [ORInterpreter excuteNodes:ast.nodes];
    MFValue *result = [scope recursiveGetValueWithIdentifier:@"result"];
    XCTAssertEqualObjects(result.objectValue, @"123");
    MFValue *a = [scope recursiveGetValueWithIdentifier:@"a"];
    XCTAssert(a.intValue == -2);
    MFValue *b = [scope recursiveGetValueWithIdentifier:@"b"];
    XCTAssert(b.doubleValue == 2.0);
}
- (void)testOCRecursiveFunctionPerformanceExample {
    [self measureBlock:^{
        fibonaccia(20);
    }];
}
- (void)testOCRecursiveMethodPerformanceExample {
    [self measureBlock:^{
        [[Fibonaccia new] run:20];
    }];
}
- (void)testOCRunnerRecursiveFunctionPerformanceExample {
    MFScopeChain *scope = self.currentScope;
    NSString * source =
    @"int fibonaccia(int n){"
    @"    if (n == 1 || n == 2)"
    @"        return 1;"
    @"    return fibonaccia(n - 1) + fibonaccia(n - 2);"
    @"}"
    @"int a = fibonaccia(20);";
    AST *ast = [_parser parseSource:source];
    [self measureBlock:^{
        for (id <OCExecute> exp in ast.globalStatements) {
            [exp execute:scope];
        }
        NSLog(@"%d",[scope getValueWithIdentifier:@"a"].uIntValue);
    }];
}
- (void)testOCRunnerRecursiveMethodPerformanceExample {
    MFScopeChain *scope = self.currentScope;
    NSString * source =
    @"@implementation Fibonaccia"
    @"-(int)run:(int)n{"
    @"    if (n == 1 || n == 2)"
    @"        return 1;"
    @"    int a = [self run:n - 1];"
    @"    int b = [self run:n - 2];"
    @"    return a + b;"
    @"}"
    @"@end"
    @"int a = [[Fibonaccia new] run:20];";
    AST *ast = [_parser parseSource:source];
    [self measureBlock:^{
        for (id <OCExecute> exp in ast.nodes) {
            [exp execute:scope];
        }
        NSLog(@"%d",[scope getValueWithIdentifier:@"a"].uIntValue);
    }];
}
- (void)testMJExtension {
    MFScopeChain *scope = self.currentScope;
    NSString * source =
    @"@interface SubModel : NSObject\
    @property (nonatomic, assign) CGFloat numberToFloat;\
    @property (nonatomic, copy) NSString *numberToString;\
    @property (nonatomic, assign) NSInteger stringToInteger;\
    @end\
    @implementation SubModel\
    @end\
    @interface TestModel : NSObject\
    @property (nonatomic, assign) NSInteger numberToInteger;\
    @property (nonatomic, copy) NSString *numberToString;\
    @property (nonatomic, strong) SubModel *sub;\
    @end\
    @implementation TestModel\
    @end\
    \
    NSDictionary *data = @{@\"numberToInteger\": @(111), @\"numberToString\": @(222), @\"sub\": @{@\"numberToFloat\": @(3.33), @\"numberToString\": @(4.44), @\"stringToInteger\": @\"555\"}};\
    id model = [TestModel mj_objectWithKeyValues:data];"
    ;
    AST *ast = [_parser parseSource:source];
    [ORInterpreter excuteNodes:ast.nodes];
    MFValue *model = [scope recursiveGetValueWithIdentifier:@"model"];
    TestFakeModel *fakeModel = model.objectValue;
    NSDictionary *data = @{@"numberToInteger": @(111), @"numberToString": @(222), @"sub": @{@"numberToFloat": @(3.33), @"numberToString": @(4.44), @"stringToInteger": @"555"}};
    TestModel1 *model1 = [TestModel1 mj_objectWithKeyValues:data];
    XCTAssert(fakeModel.numberToInteger == model1.numberToInteger);
    XCTAssert([fakeModel.numberToString isKindOfClass:model1.numberToString.class]);
    XCTAssert([fakeModel.numberToString isEqual:model1.numberToString]);
    XCTAssert([fakeModel.sub isKindOfClass:NSClassFromString(@"SubModel")]);
    XCTAssert(fakeModel.sub.numberToFloat == model1.sub.numberToFloat);
    XCTAssert([fakeModel.sub.numberToString isKindOfClass:model1.sub.numberToString.class]);
    XCTAssert([fakeModel.sub.numberToString isEqual:model1.sub.numberToString]);
    XCTAssert(fakeModel.sub.stringToInteger == model1.sub.stringToInteger);
    XCTAssert([model1.sub isKindOfClass:[SubModel1 class]], @"%@", model1.sub.class);
}
- (void)testSetterMethodWhenPropertyLengthOne{
    NSString * source =
    @"@interface Test : NSObject"
    @"@property (nonatomic) CGFloat x;"
    @"@end"
    @""
    @"@implementation Test"
    @"@end"
    @"";
    AST *ast = [_parser parseSource:source];
    [ORInterpreter excuteNodes:ast.nodes];
    XCTAssert([[NSClassFromString(@"Test") new] respondsToSelector:@selector(setX:)]);
}

- (void)testHotfixPropertyWhenIvarExist {
    NSString * source =
    @"@interface TestFakeSubModel : NSObject \
    @property (nonatomic, strong) NSString *numberToString; \
    // raw \
    // @property (nonatomic, copy) NSString *numberToString; \
    @end \
    ";
    IMP before = class_getMethodImplementation(TestFakeSubModel.class, @selector(numberToString));
    AST *ast = [_parser parseSource:source];
    [ORInterpreter excuteNodes:ast.nodes];
    objc_property_t prop3 = class_getProperty(TestFakeSubModel.class, "numberToString");
    XCTAssert(strcmp(property_getAttributes(prop3), "T@\"NSString\",C,N,V_numberToString") == 0);
    IMP result = class_getMethodImplementation(TestFakeSubModel.class, @selector(numberToString));
    XCTAssert(before == result);
}

- (void)testHotfixPropertyWhenIvarNotExist {
    NSString * source =
    @"@interface TestFakeModel: NSObject\
    @property(nonatomic, assign)int categoryProperty;\
    @end\
    @implementation TestFakeModel\
    @end\
    ";
    TestFakeModel *model = [TestFakeModel new];
    XCTAssert(![model respondsToSelector:@selector(categoryProperty)]);
    XCTAssert(![model respondsToSelector:@selector(setCategoryProperty:)]);
    AST *ast = [_parser parseSource:source];
    [ORInterpreter excuteNodes:ast.nodes];
    [model setCategoryProperty:1000];
    XCTAssert(model.categoryProperty == 1000);
}

void testCallORGDeallocHelper(int *counter) {
    [[ORTestORGDealloc alloc] initWithCounter:counter];
}

- (void)testCallORGDealloc {
    NSString *source = @"\
    @implementation ORTestORGDealloc\
    - (void)dealloc {\
        *_counter = *_counter + 100;\
        [self ORGdealloc];\
    }\
    @end\
    ";
    AST *ast = [_parser parseSource:source];
    [ORInterpreter excuteNodes:ast.nodes];
    int counter = 0;
    testCallORGDeallocHelper(&counter);
    XCTAssert(counter == 110);
}


- (void)testCallSuperDealloc {
    MFScopeChain *scope = self.currentScope;
    NSString *source = @"\
    __weak id a = nil;\
    __weak id b = nil;\
    __weak id c = nil;\
    int count = 0;\
    @implementation ORTestDeallocBase\
    /* by default, at the end of dealloc, we will call [super dealloc] */ \
    - (void)dealloc {\
        count++;\
    }\
    @end\
    @interface ORTestSuperDealloc1: ORTestDeallocBase\
    @end\
    @implementation ORTestSuperDealloc1\
    - (void)dealloc { }\
    @end\
    \
    @interface ORTestSuperDealloc2: ORTestDeallocBase\
    @end\
    @implementation ORTestSuperDealloc2\
    - (void)dealloc { }\
    @end\
    @interface ORTestSuperDealloc3: ORTestDeallocBase\
    @end\
    @implementation ORTestSuperDealloc3\
    - (void)dealloc {\
        [self ORGdealloc];\
    }\
    @end\
    a = [ORTestSuperDealloc1 new];\
    b = [ORTestSuperDealloc2 new];\
    c = [ORTestSuperDealloc3 new];\
    ";
    AST *ast = [_parser parseSource:source];
    [ORInterpreter excuteNodes:ast.nodes];
    MFValue *a = [scope recursiveGetValueWithIdentifier:@"a"];
    MFValue *b = [scope recursiveGetValueWithIdentifier:@"b"];
    MFValue *c = [scope recursiveGetValueWithIdentifier:@"c"];
    MFValue *count = [scope recursiveGetValueWithIdentifier:@"count"];
    XCTAssert(a.objectValue == nil);
    XCTAssert(b.objectValue == nil);
    XCTAssert(c.objectValue == nil);
    // disassemblly arm64 of [xx dealloc], you can found the 'super_msgSend' is added by compiler.
    // so ORTestSuperDealloc3's [self ORGdealloc] will call [NSObject dealloc] directly. so the count is 2.
    XCTAssert(count.intValue == 2, @"count.intValue: %d", count.intValue);
}

@end
