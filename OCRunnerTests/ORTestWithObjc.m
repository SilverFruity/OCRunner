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
#import <objc/message.h>
@interface ORTestWithObjc : XCTestCase
@property (nonatomic, strong)MFScopeChain *currentScope;
@property (nonatomic, strong)MFScopeChain *topScope;
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
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *currentBundle = [NSBundle bundleForClass:[ORTestWithObjc class]];
        NSString *bundlePath = [currentBundle pathForResource:@"Scripts" ofType:@"bundle"];
        NSBundle *frameworkBundle = [NSBundle bundleWithPath:bundlePath];
        NSString *UIKitPath = [frameworkBundle pathForResource:@"UIKitRefrences" ofType:nil];
        NSString *UIKitData = [NSString stringWithContentsOfFile:UIKitPath encoding:NSUTF8StringEncoding error:nil];
        AST *ast = [OCParser parseSource:UIKitData];
        [ORInterpreter excuteNodes:ast.nodes];
        
        NSString *GCDPath = [frameworkBundle pathForResource:@"GCDRefrences" ofType:nil];
        NSString *CCDData = [NSString stringWithContentsOfFile:GCDPath encoding:NSUTF8StringEncoding error:nil];
        ast = [OCParser parseSource:CCDData];
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
- (void)testStructSetValueNoCopy{
    MFScopeChain *scope = self.currentScope;
    CGRect rect1 = CGRectZero;
    MFValue *value = [MFValue defaultValueWithTypeEncoding:@encode(CGRect)];
    [value setStructPointerWithNoCopy:&rect1];
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
    AST *ast = [OCParser parseSource:source];
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
    [value setStructPointerWithNoCopy:&rect1];
    [[value fieldForKey:@"origin"] setFieldWithValue:[MFValue valueWithDouble:1] forKey:@"x"];
    [[value fieldForKey:@"origin"] setFieldWithValue:[MFValue valueWithDouble:2] forKey:@"y"];
    XCTAssert(rect1.origin.x == 0, @"origin.x %f", rect1.origin.x);
    XCTAssert(rect1.origin.y == 0, @"origin.y %f", rect1.origin.y);

    NSString * source =
    @"CGRect frame = CGRectMake(0,1,2,3);"
    "CGSize size = frame.size;"
    "size.width = 100;"
    "size.height = 100;";
    AST *ast = [OCParser parseSource:source];
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
    AST *ast = [OCParser parseSource:source];
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
    AST *ast = [OCParser parseSource:source];
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
    AST *ast = [OCParser parseSource:source];
    for (id <OCExecute> exp in ast.globalStatements) {
        [exp execute:scope];
    }
    MFValue *d = [scope recursiveGetValueWithIdentifier:@"d"];
    XCTAssert(strcmp(d.typeEncode, "i") == 0);
    XCTAssert(*(int *)d.pointer == 1);
}
- (void)testProtcolConfirm{
    MFScopeChain *scope = self.currentScope;
    NSString * source =
    @"@protocol Protocol1 <NSObject>"
    @"@property (nonatomic,copy)NSString *name;"
    @"-(NSUInteger)getAge;"
    @"-(void)setAge:(NSUInteger)age;"
    @"@end"
    @"@protocol Protocol2 <Protocol1>"
    @"- (void)sleep;"
    @"@end"
    @"@interface TestObject : NSObject <Protocol2>"
    @"@property (nonatomic,copy)NSString *name;"
    @"@end"
    @"@implementation TestObject"
    @"- (NSUInteger)getAge{"
    @"    return 100;"
    @"}"
    @"-(void)setAge:(NSUInteger)age{"
    @"}"
    @"- (void)sleep{"
    @"}"
    @"@end";
    AST *ast = [OCParser parseSource:source];
    for (ORProtocol *protocol in ast.protcolCache.allValues) {
        [protocol execute:scope];
    }
    for (ORClass *clas in ast.classCache.allValues) {
        [clas execute:scope];
    }
    Class testClass = NSClassFromString(@"TestObject");
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
    AST *ast = [OCParser parseSource:source];
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
    AST *ast = [OCParser parseSource:source];
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
    AST *ast = [OCParser parseSource:source];
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
    AST *ast = [OCParser parseSource:source];
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
    AST *ast = [OCParser parseSource:source];
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
    AST *ast = [OCParser parseSource:source];
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
    AST *ast = [OCParser parseSource:source];
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
    @"    return [self run:n - 1] + [self run:n - 2];"
    @"}"
    @"@end"
    @"int a = [[Fibonaccia new] run:20];";
    AST *ast = [OCParser parseSource:source];
    [self measureBlock:^{
        for (id <OCExecute> exp in ast.nodes) {
            [exp execute:scope];
        }
        NSLog(@"%d",[scope getValueWithIdentifier:@"a"].uIntValue);
    }];
}
@end
