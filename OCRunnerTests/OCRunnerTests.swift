//
//  OCRunnerTests.swift
//  OCRunnerTests
//
//  Created by Jiang on 2020/5/13.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

import XCTest
import OCRunner
import oc2mangoLib
var hasAddScripts = false
class CRunnerTests: XCTestCase {
    var scope: MFScopeChain!
    let ocparser = ORParserForTest()
    var source = ""
    var inter = ORInterpreter.shared()
    var ctx  = ORThreadContext.current()
    override func setUp() {
//        if !hasAddScripts{
//            let current = Bundle.init(for: CRunnerTests.classForCoder())
//            let bundlePath = current.path(forResource: "Scripts", ofType: "bundle")!
//            let scriptBundle = Bundle.init(path: bundlePath)!
//
//            if let UIKitPath = scriptBundle.path(forResource: "UIKitRefrences", ofType: nil),
//                let UIKitData = try? String.init(contentsOfFile: UIKitPath, encoding: .utf8){
//                let ast = ocparser.parseSource(UIKitData)
//                ORInterpreter.excuteNodes(ast.nodes as! [Any])
//
//            }
//
//            if let GCDPath = scriptBundle.path(forResource: "GCDRefrences", ofType: nil),
//                let CCDData = try? String.init(contentsOfFile: GCDPath, encoding: .utf8){
//                let ast = ocparser.parseSource(CCDData)
//                ORInterpreter.excuteNodes(ast.nodes as! [Any])
//            }
//            hasAddScripts = true
//        }
        scope = MFScopeChain.init(next: MFScopeChain.topScope())
        mf_add_built_in(scope)
    }
    override func tearDown() {
        
    }
    func testDeclareExpression(){
        let source = """
        char a = -1;
        short b = -1;
        int c = -1;
        long d = -1;
        long long e = -1;
        unsigned char f = 1;
        unsigned short g = 1;
        unsigned int h = 1;
        unsigned long i = 1;
        unsigned long long j = 1;
        float k = 0.5;
        double l = 0.5;
        char *str = "123";
        SEL sel = @selector(test);
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        var scopeValue = scope.getValueWithIdentifier("a")
        XCTAssert(scopeValue!.type == OCTypeChar)
        XCTAssert(scopeValue!.charValue == -1)
        scopeValue = scope.getValueWithIdentifier("b")
        XCTAssert(scopeValue!.type == OCTypeShort)
        XCTAssert(scopeValue!.shortValue == -1)
        scopeValue = scope.getValueWithIdentifier("c")
        XCTAssert(scopeValue!.type == OCTypeInt)
        XCTAssert(scopeValue!.intValue == -1)
        scopeValue = scope.getValueWithIdentifier("d")
        XCTAssert(scopeValue!.type == OCTypeLong)
        XCTAssert(scopeValue!.longValue == -1)
        scopeValue = scope.getValueWithIdentifier("e")
        XCTAssert(scopeValue!.type == OCTypeLongLong)
        XCTAssert(scopeValue!.longlongValue == -1)
        scopeValue = scope.getValueWithIdentifier("f")
        XCTAssert(scopeValue!.type == OCTypeUChar)
        XCTAssert(scopeValue!.uCharValue == 1)
        scopeValue = scope.getValueWithIdentifier("g")
        XCTAssert(scopeValue!.type == OCTypeUShort)
        XCTAssert(scopeValue!.uShortValue == 1)
        scopeValue = scope.getValueWithIdentifier("h")
        XCTAssert(scopeValue!.type == OCTypeUInt)
        XCTAssert(scopeValue!.uIntValue == 1)
        scopeValue = scope.getValueWithIdentifier("i")
        XCTAssert(scopeValue!.type == OCTypeULong)
        XCTAssert(scopeValue!.uLongValue == 1)
        scopeValue = scope.getValueWithIdentifier("j")
        XCTAssert(scopeValue!.type == OCTypeULongLong)
        XCTAssert(scopeValue!.uLongLongValue == 1)
        scopeValue = scope.getValueWithIdentifier("k")
        XCTAssert(scopeValue!.type == OCTypeFloat)
        XCTAssert(scopeValue!.floatValue == 0.5)
        scopeValue = scope.getValueWithIdentifier("l")
        XCTAssert(scopeValue!.type == OCTypeDouble)
        XCTAssert(scopeValue!.doubleValue == 0.5)
        scopeValue = scope.getValueWithIdentifier("str")
        XCTAssert(scopeValue!.type == OCTypeCString)
        XCTAssert(String(utf8String: scopeValue!.cStringValue!) == "123", "\(scopeValue!.cStringValue!)")
        scopeValue = scope.getValueWithIdentifier("sel")
        XCTAssert(scopeValue!.selValue == Selector("test"), "\(scopeValue!.selValue)")
    }
    func testeDeclareBlock(){
        let source =
        """
        void (^a)(void) = ^{
            int b = 0;
        };
        """
        
        let ast = ocparser.parseSource(source)
        let exp = ast.globalStatements.firstObject as! ORInitDeclaratorNode;
        eval(self.inter, self.ctx, scope, exp);
        let result = scope.getValueWithIdentifier("a")
        XCTAssert(result!.type == OCTypeObject)
        XCTAssert(result?.objectValue != nil) //__NSMallocBlock__
        let scopeValue = scope.getValueWithIdentifier("a")
        XCTAssert(scopeValue!.type == OCTypeObject)
        XCTAssert(scopeValue?.objectValue != nil) //__NSMallocBlock__
    }
    func testBlockExecute(){
        let source =
        """
        short (^a)(void) = ^short{
            int b = 0;
            return 2;
        };
        int b = a();
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        let scopeValue = scope.getValueWithIdentifier("b")
        XCTAssert(scopeValue!.type == OCTypeInt)
        XCTAssert(scopeValue!.type == OCTypeInt)
        XCTAssert(scopeValue!.shortValue == 2)
    }
    func testBlockCopyValue(){
        let source =
        """
        int x = 2;
        short (^a)(int) = ^short(int y){
            return y + x;
        };
        int b = a(1);
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        let scopeValue = scope.getValueWithIdentifier("b")
        XCTAssert(scopeValue!.type == OCTypeInt)
        XCTAssert(scopeValue!.type == OCTypeInt)
        XCTAssert(scopeValue!.intValue == 3)
    }
    func testUnaryExpresssion() {
        let source =
        """
        int a = 2;
        int c = a++;
        int d = a--;
        a = 2;
        int e = ++a;
        int f = --a;
        BOOL g = !a;
        int h = sizeof(a);
        int i = ~a;
        int j = -a;
        int *k = &a;
        int l = *k;
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 2)
        XCTAssert(scope.getValueWithIdentifier("d")!.intValue == 3)
        XCTAssert(scope.getValueWithIdentifier("e")!.intValue == 3)
        XCTAssert(scope.getValueWithIdentifier("f")!.intValue == 2)
        XCTAssert(scope.getValueWithIdentifier("g")!.boolValue == false)
        XCTAssert(scope.getValueWithIdentifier("h")!.intValue == 8)
        XCTAssert(scope.getValueWithIdentifier("i")!.intValue == -3)
        XCTAssert(scope.getValueWithIdentifier("j")!.intValue == -2)
        XCTAssert(scope.getValueWithIdentifier("l")!.intValue == 2)
    }
    func testBinaryExpresssion() {
        let source =
        """
        int a = 2;
        int b = 1;
        int c = a + b;
        int d = a - b;
        int e = a * b;
        int f = a / b;
        int g = a % b;
        int h = a << b;
        int i = a >> b;
        int j = a & 1;
        int k = a ^ b;
        int l = a | b;
        BOOL m = a < b;
        BOOL n = a > b;
        BOOL o = a <= b;
        BOOL p = a >= b;
        BOOL q = a && b;
        BOOL r = a || b;
        BOOL s = a != b;
        BOOL t = a == b;
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        XCTAssert(scope.getValueWithIdentifier("a")!.intValue == 2)
        XCTAssert(scope.getValueWithIdentifier("b")!.intValue == 1)
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 3)
        XCTAssert(scope.getValueWithIdentifier("d")!.intValue == 1)
        XCTAssert(scope.getValueWithIdentifier("e")!.intValue == 2)
        XCTAssert(scope.getValueWithIdentifier("f")!.intValue == 2)
        XCTAssert(scope.getValueWithIdentifier("g")!.intValue == 0)
        XCTAssert(scope.getValueWithIdentifier("h")!.intValue == 4)
        XCTAssert(scope.getValueWithIdentifier("i")!.intValue == 1)
        XCTAssert(scope.getValueWithIdentifier("j")!.intValue == 0)
        XCTAssert(scope.getValueWithIdentifier("k")!.intValue == 3)
        XCTAssert(scope.getValueWithIdentifier("l")!.intValue == 3)
        XCTAssert(scope.getValueWithIdentifier("m")!.boolValue == false)
        XCTAssert(scope.getValueWithIdentifier("n")!.boolValue == true)
        XCTAssert(scope.getValueWithIdentifier("o")!.boolValue == false)
        XCTAssert(scope.getValueWithIdentifier("p")!.boolValue == true)
        XCTAssert(scope.getValueWithIdentifier("q")!.boolValue == true)
        XCTAssert(scope.getValueWithIdentifier("r")!.boolValue == true)
        XCTAssert(scope.getValueWithIdentifier("s")!.boolValue == true)
        XCTAssert(scope.getValueWithIdentifier("t")!.boolValue == false)
    }
    
    func testTernaryExpression() {
        let source =
        """
        int a = 2;
        int b = a? 1 : 3;
        int c = a == 1 ? 1 : 3;
        int d = a?:3;
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        XCTAssert(scope.getValueWithIdentifier("b")!.intValue == 1)
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 3)
        XCTAssert(scope.getValueWithIdentifier("d")!.intValue == 2)
    }
    func testIfStatement(){
        let source =
        """
        int testIfStatement(int a){
            if (a <= 1){
              return 0;
            }else if (a < 10){
              return 1;
            }else if (a < 20){
              return 2;
            }else{
              return 3;
            }
        }
        int a = testIfStatement(1);
        int b = testIfStatement(3);
        int c = testIfStatement(15);
        int d = testIfStatement(30);
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        XCTAssert(scope.getValueWithIdentifier("a")!.intValue == 0)
        XCTAssert(scope.getValueWithIdentifier("b")!.intValue == 1)
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 2)
        XCTAssert(scope.getValueWithIdentifier("d")!.intValue == 3)
    }
    
    func testWhileStatement(){
        let source =
        """
        int testWhileStatement(int x){
            int a = 1;
            while(a < x){
                if (x < 3){
                    break;
                }
                if (a == 12){
                    return 18;
                }
                if (a == 10){
                    a = 12;
                    continue;
                }
                a++;
            }
            return a;
        }
        int a = testWhileStatement(2);
        int b = testWhileStatement(3);
        int c = testWhileStatement(15);
        int d = testWhileStatement(30);
        """
        let ast = ocparser.parseSource(source)
        let scope = MFScopeChain.topScope()
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        XCTAssert(scope.getValueWithIdentifier("a")!.intValue == 1)
        XCTAssert(scope.getValueWithIdentifier("b")!.intValue == 3)
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 18)
        XCTAssert(scope.getValueWithIdentifier("d")!.intValue == 18)
    }
    func testDoWhileStatement(){
        let source =
        """
        int testDoWhileStatement(int x){
            int a = 1;
            do{
                a++;
                if (x < 3){
                    break;
                }
                if (a == 12){
                    return 18;
                }
                if (a == 10){
                    a = 11;
                    continue;
                }
            }while(a < x)
            return a;
        }
        int a = testDoWhileStatement(2);
        int b = testDoWhileStatement(3);
        int c = testDoWhileStatement(15);
        int d = testDoWhileStatement(30);
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        XCTAssert(scope.getValueWithIdentifier("a")!.intValue == 2)
        XCTAssert(scope.getValueWithIdentifier("b")!.intValue == 3)
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 18)
        XCTAssert(scope.getValueWithIdentifier("d")!.intValue == 18)
    }
    func testSwitchStatement(){
        let source =
        """
        int testSwitchStatement(int x){
            int a = 0;
            switch (x){
                case 0:
                    a = x + 3;
                    break;
                case 1:
                    return 111;
                case 2:
                    break;
                default:
                    a = 222;
                    break;
            }
            return a;
        }
        int a = testSwitchStatement(0);
        int b = testSwitchStatement(1);
        int c = testSwitchStatement(2);
        int d = testSwitchStatement(3);
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        XCTAssert(scope.getValueWithIdentifier("a")!.intValue == 3)
        XCTAssert(scope.getValueWithIdentifier("b")!.intValue == 111)
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 0)
        XCTAssert(scope.getValueWithIdentifier("d")!.intValue == 222)
    }
    
    func testForStatement(){
        let source =
        """
        int testForStatement(int x){
            int a = 1;
            for (a; a < x; a++){
                if (x == 2){
                    a = 10;
                    break;
                }
                if (a == 2){
                    a = 100;
                    continute;
                }
                if (a == 3){
                  return a;
                }
            }
            return a;
        }
        int a = testForStatement(0);
        int b = testForStatement(2);
        int c = testForStatement(3);
        int d = testForStatement(4);
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        XCTAssert(scope.getValueWithIdentifier("a")!.intValue == 1)
        XCTAssert(scope.getValueWithIdentifier("b")!.intValue == 10)
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 101)
        XCTAssert(scope.getValueWithIdentifier("d")!.intValue == 101)
    }
    func testForStatementWithDeclare(){
        let source =
        """
        int testForStatementWithDeclare(int x){
            int b = 0;
            for (int a = 1; a < x; a++){
                if (x == 2){
                    b = 10;
                    break;
                }
                if (a == 2){
                    b = 100;
                    continute;
                }
                if (a == 3){
                  return b;
                }
            }
            return b;
        }
        int a = testForStatementWithDeclare(0);
        int b = testForStatementWithDeclare(2);
        int c = testForStatementWithDeclare(3);
        int d = testForStatementWithDeclare(4);
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        XCTAssert(scope.getValueWithIdentifier("a")!.intValue == 0)
        XCTAssert(scope.getValueWithIdentifier("b")!.intValue == 10)
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 100)
        XCTAssert(scope.getValueWithIdentifier("d")!.intValue == 100)
    }
    
    func testForInStatement(){
        let source =
        """
        int testForInStatement(NSArray *x){
            int b = 0;
            for (NSNumber *value in x){
                if ([value intValue] == 1)
                    b += 1;
                else if([value intValue] == 2)
                    b += 2;
                else
                    b += 3;
            }
            return b;
        }
        int a = testForInStatement(@[@(1),@(2),@(3)]);
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        let value = scope.getValueWithIdentifier("a")!
        XCTAssert(value.intValue == 6, "\(value.intValue)")
    }
    func testClassMethodReplace(){
        let source =
        """
        int globalVar = 1111;
        @interface ORTestReplaceClass : NSObject
        - (int)test;
        - (int)arg1:(NSNumber *)arg1;
        - (int)arg1:(NSNumber *)arg1 arg2:(NSNumber *)arg2;
        @end
        @implementation ORTestReplaceClass
        - (int)test{
            return 1;
        }
        - (int)arg1:(NSNumber *)arg1{
            return [arg1 intValue];
        }
        - (int)arg1:(NSNumber *)arg1 arg2:(NSNumber *)arg2{
            return [arg1 intValue] + [arg2 intValue];
        }
        + (BOOL)testClassMethodReplaceTest{
            return YES;
        }
        - (NSInteger)testOriginalMethod{
            return 1 + [self ORGtestOriginalMethod];
        }
        - (NSInteger)testAddGlobalVar{
            return globalVar;
        }
        - (BOOL)testCallSuperNoArgTestSupser{
            return [super testCallSuperNoArgTestSupser];
        }
        - (NSDictionary* (^)(void))testMethodParameterListAndReturnValueWithString:(NSString *)str block:(NSString *(^)(NSString *))block{
            NSMutableDictionary *dic = [@{} mutableCopy];
            dic[@"param1"] = str;
            dic[@"param2"] = block(@"Mango");
            NSDictionary* (^retBlock)(void)  = ^NSDictionary *{
                return dic;
            };
            return retBlock;
        }
        @end
        """
        scope = MFScopeChain.topScope()
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        let classes = ast.classCache.allValues as! [ORClassNode];
        for classValue in classes {
            eval(self.inter, self.ctx, scope, classValue);
        }
        let test = ORTestReplaceClass.init()
        XCTAssert(test.test() == 1)
        XCTAssert(test.arg1(NSNumber.init(value: 2), arg2: NSNumber.init(value: 3)) == 5)
        XCTAssert(test.arg1(NSNumber.init(value: 10)) == 10)
        XCTAssert(ORTestReplaceClass.testMethodReplaceTest())
        XCTAssert(test.testOriginalMethod() == 2)
        XCTAssert(test.testAddGlobalVar() == 1111)
        if let dict = test.testMethodParameterListAndReturnValue(with: "ggggg", block: { (value) -> String in
            return "hhhh" + value
        })() as? [AnyHashable:String]{
            XCTAssert(dict["param1"] == "ggggg")
            XCTAssert(dict["param2"] == "hhhhMango")
        }
        
    }
    func testMultiArgsFunCall(){
        let source =
        """
        NSString *b = [NSString stringWithFormat:@"%@",@"sss"];
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        if let object = scope.getValueWithIdentifier("b")?.objectValue as? String{
            XCTAssert(object == "sss",object)
        }
    }
    func testClassAddMethod(){
        let source =
        """
        @implementation ORTestReplaceClass
        - (int)otherMethod{
            return 10;
        }
        - (int)test{
            return [self otherMethod];
        }
        @end
        """
        let ast = ocparser.parseSource(source)
        let classes = ast.classCache.allValues as! [ORClassNode];
        for classValue in classes {
            eval(self.inter, self.ctx, scope, classValue);
        }
        let test = ORTestReplaceClass.init()
        let result = test.test()
        XCTAssert(result == 10, "\(result)")
    }
    func testClassProperty(){
        let source =
        """
        @interface ORTestClassProperty:NSObject
        @property (nonatomic,copy)NSString *strTypeProperty;
        @property (assign, nonatomic) NSInteger count;
        @end
        @implementation ORTestClassProperty
        - (void)otherMethod{
            self.strTypeProperty = @"Mango";
        }

        - (NSString *)testObjectPropertyTest{
            [self otherMethod];
            return self.strTypeProperty;
        }
        - (id)testIvarx{
            _strTypeProperty = @"Mango-testIvar";
            return _strTypeProperty;
        }
        - (NSInteger)testProMathAdd{
            self.num += 10;
            return self.num;
        }
        -(NSInteger)testBasePropertyTest{
            self.count = 100000;
            return self.count;
        }
        - (NSInteger)testPropertyIvar{
            _count  = 100001;
            return _count;
        }
        @end
        """
        let ast = ocparser.parseSource(source)
        let classes = ast.classCache.allValues as! [ORClassNode];
        for classValue in classes {
            eval(self.inter, self.ctx, scope, classValue);
        }
        let test = ORTestClassProperty.init()
        XCTAssert(test.testObjectPropertyTest() == "Mango")
        XCTAssert(test.testProMathAdd() == 10)
        XCTAssert(test.testIvarx() == "Mango-testIvar")
        XCTAssert(test.testBasePropertyTest() == 100000)
        XCTAssert(test.testIvar() == 100001)

    }
    func testClassIvar(){
        let source =
        """
        @implementation ORTestClassIvar
        - (id)testObjectIvar{
            _objectIvar = @"test";
            return _objectIvar;
        }
        - (NSInteger)testIntIvar{
            _intIvar = -1;
            return _intIvar;
        }
        - (unsigned int)testUIntIvar{
            return 1000;
        }
        - (double)testDoubleIvar{
            return 0.55;
        }
        @end
        """
        let ast = ocparser.parseSource(source)
        let classes = ast.classCache.allValues as! [ORClassNode];
        for classValue in classes {
            eval(self.inter, self.ctx, scope, classValue);
        }
        let test = ORTestClassIvar.init()
        XCTAssert(test.testObjectIvar() == "test")
        XCTAssert(test.testIntIvar() == -1)
        XCTAssert(test.testUIntIvar() == 1000)
        XCTAssert(test.testDouble() == 0.55)
    }
    func testCallOCReturnBlock(){
        let source =
        """
        @implementation ORCallOCPropertyBlockTest
        - (id)testCallOCReturnBlock{
            id ret = self.returnBlockMethod(@"a",@"b");
            return ret;
        }
        @end
        """
        let ast = ocparser.parseSource(source)
        let classes = ast.classCache.allValues as! [ORClassNode];
        for classValue in classes {
            eval(self.inter, self.ctx, scope, classValue);
        }
        let test = ORCallOCPropertyBlockTest.init()
        XCTAssert(test.testCallOCReturnBlock() == "ab")
        
    }
    func testSuperMethodCall(){
        let source =
        """
        @implementation MFCallSuperNoArgTestSupserTest
        - (BOOL)testCallSuperNoArgTestSupser{
            return YES;
        }
        @end
        """
        let ast = ocparser.parseSource(source)

        let classes = ast.classCache.allValues as! [ORClassNode];
        for classValue in classes {
            eval(self.inter, self.ctx, scope, classValue);
        }
        
        let test = MFCallSuperNoArgTest.init()
        XCTAssert(test.testCallSuperNoArgTestSupser())
    }
    func testSuperNoArgs(){
        let source =
        """
        @implementation MFCallSuperNoArgTest
        - (BOOL)testCallSuperNoArgTestSupser{
            return [super testCallSuperNoArgTestSupser];
        }
        @end
        """
        let ast = ocparser.parseSource(source)
        let classes = ast.classCache.allValues as! [ORClassNode];
        for classValue in classes {
            eval(self.inter, self.ctx, scope, classValue);
        }
        let test = MFCallSuperNoArgTest.init()
        XCTAssert(test.testCallSuperNoArgTestSupser())
    }
    func testSuperClassReplace(){
        let source =
        """
        @implementation BMW
        - (int)run
        {
            return 2;
        }
        @end
        """
        let ast = ocparser.parseSource(source)
        let classes = ast.classCache.allValues as! [ORClassNode];
        for classValue in classes {
            eval(self.inter, self.ctx, scope, classValue);
        }
        let test = MiniBMW.init()
        XCTAssert(test.run() == 2)
    }
    func testGCD(){
        let source =
        """
        @implementation ORGCDTests
        - (void)testGCDWithCompletionBlock:(void (^)(NSString * _Nonnull))completion{
           dispatch_queue_t queue = dispatch_queue_create("com.plliang19.mango", DISPATCH_QUEUE_SERIAL);
           dispatch_async(queue, ^{
               completion(@"success");
           });
        }
        - (void)testGCDAfterWithCompletionBlock:(void (^)(NSString * _Nonnull))completion{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                completion(@"success");
            });
        }
        - (BOOL)testDispatchSemaphore{
            BOOL retValue = NO;
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_global_queue(0, 0), ^{
                retValue = YES;
                dispatch_semaphore_signal(semaphore);
            });
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            return retValue;
        }
        -(NSInteger)testDispatchSource{
            NSInteger count = 0;
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
            dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
            dispatch_source_set_event_handler(timer, ^{
                count++;
                if (count == 10) {
                    dispatch_suspend(timer);
                    dispatch_semaphore_signal(semaphore);
                }
            });
            dispatch_resume(timer);
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            return count;
        }
        @end
        """
        let ast = ocparser.parseSource(source)
        let classes = ast.classCache.allValues as! [ORClassNode];
        for classValue in classes {
            eval(self.inter, self.ctx, scope, classValue);
        }
        let test = ORGCDTests.init()
        XCTAssert(test.testDispatchSemaphore())
        XCTAssert(test.testDispatchSource() == 10)
        let afterException = XCTestExpectation.init(description: "async_after")
        test.testGCDAfter { (text) in
            XCTAssert(text == "success")
            afterException.fulfill()
        }
        let asyncException = XCTestExpectation.init(description: "async")
        test.testGCD(completionBlock: { (text) in
            XCTAssert(text == "success")
            asyncException.fulfill()
        })
        self.wait(for: [afterException,asyncException], timeout: 2.0)
    }
    func testStaticVariable(){
        source =
        """
        int func(){
            static int i = 0; //静态变量只初始化一次
            i++;
            return i;
        }
        int a = func();
        int b = func();
        int c = func();
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        eval(self.inter, self.ctx, scope, exps[0]);
        eval(self.inter, self.ctx, scope, exps[1]);
        XCTAssert(scope.getValueWithIdentifier("a")!.intValue == 1)
        eval(self.inter, self.ctx, scope, exps[2])
        XCTAssert(scope.getValueWithIdentifier("b")!.intValue == 2)
        eval(self.inter, self.ctx, scope, exps[3])
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 3)
    }
    func testDispatchOnce(){
        source =
        """
        typedef NSInteger dispatch_once_t;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [NSObject new];
        });
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
    }
    
    func testEnumDeclare(){
        source =
        """
        typedef enum: NSUInteger{
            UIControlEventTouchDown                                         = 1 <<  0,      // on all touch downs
            UIControlEventTouchDownRepeat                                   = 1 <<  1,      // on multiple touchdowns (tap count > 1)
            UIControlEventTouchDragInside                                   = 1 <<  2,
            UIControlEventTouchDragOutside                                  = 1 <<  3,
            UIControlEventTouchDragEnter                                    = 1 <<  4,
            UIControlEventTouchDragExit                                     = 1 <<  5,
            UIControlEventTouchUpInside                                     = 1 <<  6,
            UIControlEventTouchUpOutside                                    = 1 <<  7,
            UIControlEventTouchCancel                                       = 1 <<  8,

            UIControlEventValueChanged                                      = 1 << 12,     // sliders, etc.
            UIControlEventPrimaryActionTriggered                            = 1 << 13,     // semantic action: for buttons, etc.

            UIControlEventEditingDidBegin                                   = 1 << 16,     // UITextField
            UIControlEventEditingChanged                                    = 1 << 17,
            UIControlEventEditingDidEnd                                     = 1 << 18,
            UIControlEventEditingDidEndOnExit                               = 1 << 19,     // 'return key' ending editing

            UIControlEventAllTouchEvents                                    = 0x00000FFF,  // for touch events
            UIControlEventAllEditingEvents                                  = 0x000F0000,  // for UITextField
            UIControlEventApplicationReserved                               = 0x0F000000,  // range available for application use
            UIControlEventSystemReserved                                    = 0xF0000000,  // range reserved for internal framework use
            UIControlEventAllEvents                                         = 0xFFFFFFFF
        }UIControlEvents;
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        XCTAssert(scope.getValueWithIdentifier("UIControlEventTouchDown")!.uLongLongValue == 1 <<  0)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventTouchDownRepeat")!.uLongLongValue == 1 <<  1)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventTouchDragInside")!.uLongLongValue == 1 <<  2)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventTouchDragOutside")!.uLongLongValue == 1 <<  3)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventTouchDragEnter")!.uLongLongValue == 1 <<  4)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventTouchDragExit")!.uLongLongValue == 1 <<  5)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventTouchUpInside")!.uLongLongValue == 1 <<  6)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventTouchUpOutside")!.uLongLongValue == 1 <<  7)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventTouchCancel")!.uLongLongValue == 1 <<  8)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventValueChanged")!.uLongLongValue == 1 << 12)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventPrimaryActionTriggered")!.uLongLongValue == 1 << 13)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventEditingDidBegin")!.uLongLongValue == 1 << 16)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventEditingChanged")!.uLongLongValue == 1 << 17)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventEditingDidEnd")!.uLongLongValue == 1 << 18)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventEditingDidEndOnExit")!.uLongLongValue == 1 << 19)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventAllTouchEvents")!.uLongLongValue == 0x00000FFF)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventAllEditingEvents")!.uLongLongValue == 0x000F0000)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventApplicationReserved")!.uLongLongValue == 0x0F000000)
        XCTAssert(scope.getValueWithIdentifier("UIControlEventSystemReserved")!.uLongLongValue == UInt64(0xF0000000))
        XCTAssert(scope.getValueWithIdentifier("UIControlEventAllEvents")!.uLongLongValue == UInt64(0xFFFFFFFF))
    }
    
    func testStructDeclare(){
        source =
        """
        struct CGPoint {
            CGFloat x;
            CGFloat y;
        };
        CGPoint CGPointMake(CGFloat x, CGFloat y){
          CGPoint p; p.x = x; p.y = y; return p;
        }
        CGPoint p = CGPointMake(0.1,0.1);
        CGFloat a = p.x;
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        XCTAssert(scope.getValueWithIdentifier("a")!.doubleValue == 0.1)
    }
    
    func testStructDeclares(){
        source =
        """
        struct CGPoint {
            CGFloat x;
            CGFloat y;
        };

        struct CGSize {
            CGFloat width;
            CGFloat height;
        };
        struct CGRect {
            CGPoint origin;
            CGSize size;
        };
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
//        let rect = ORTypeSymbolTable.shareInstance().symbolItem(forTypeName: "CGRect")
//        XCTAssert(NSString.init(utf8String: rect.typeEncode) == "{CGRect={CGPoint=dd}{CGSize=dd}}")
    }
    func testTypedef(){
        source =
        """
        typedef long long IntegerType;
        typedef IntegerType dispatch_once_t;
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
//        let item1 = ORTypeSymbolTable.shareInstance().symbolItem(forTypeName: "IntegerType")
//        let item2 = ORTypeSymbolTable.shareInstance().symbolItem(forTypeName: "dispatch_once_t")
//        XCTAssert(item1.typeEncode == "q", item1.typeEncode)
//        XCTAssert(item2.typeEncode == "q", item2.typeEncode)
        
    }
    
    func testNilCallMethod(){
        source =
        """
        id a = [nil new];
        id b = [XXLabel new];
        id c = [object new];
        id d = [a callMethod];
        """
        let ast = ocparser.parseSource(source)
        let exps = ast.globalStatements as! [ORNode]
        for exp in exps {
            eval(self.inter, self.ctx, scope, exp);
        }
        XCTAssert(scope.getValueWithIdentifier("a")?.objectValue == nil)
        XCTAssert(scope.getValueWithIdentifier("b")?.objectValue == nil)
        XCTAssert(scope.getValueWithIdentifier("c")?.objectValue == nil)
        XCTAssert(scope.getValueWithIdentifier("d")?.objectValue == nil)
    }
    func testMethodReturn(){
        let source =
        """
        @implementation ORMethodReturnTest
        - (NSString *)showLog{
           [self getMsg:@"Hello world!"];
           return @"test";
        }
        - (NSString *)getMsg:(NSString *)msg{
            return [NSString stringWithFormat:@"{OCRunner} %@", msg];
        }
        @end
        NSString *value = [[ORMethodReturnTest new] showLog];
        """
        let ast = ocparser.parseSource(source)
        for classValue in ast.nodes {
            eval(self.inter, self.ctx, scope, (classValue as! ORNode));
        }
        let value = scope.getValueWithIdentifier("value")?.objectValue as? String ?? "failed"
        XCTAssert(value == "test", value)
    }
    func testUnknownSelector(){
        let source =
        """
        [UIColor red];
        """
        let ast = ocparser.parseSource(source)
        for classValue in ast.nodes {
            eval(self.inter, self.ctx, scope, (classValue as! ORNode));
        }
    }
}
