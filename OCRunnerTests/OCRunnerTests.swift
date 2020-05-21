//
//  OCRunnerTests.swift
//  OCRunnerTests
//
//  Created by Jiang on 2020/5/13.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

import XCTest
import OCRunner

class CRunnerTests: XCTestCase {
    let scope = MFScopeChain.topScope()
    let ocparser = Parser.shared()
    var source = ""
    override func setUp() {
        
    }
    override func tearDown() {
        ocparser.clear()
        scope.clear()
    }
    func testDeclareExpression(){
        let source = "int a = 1;"
        ocparser.parseSource(source)
        let exp = ocparser.ast.globalStatements.firstObject as! ORExpression;
        exp.execute(scope)
        let scopeValue = scope.getValueWithIdentifier("a")
        XCTAssert(scopeValue!.typePair.type.type == TypeInt)
        XCTAssert(scopeValue!.intValue == 1)
    }
    func testeDeclareBlock(){
        let source =
        """
        void (^a)(void) = ^{
            int b = 0;
        };
        """
        ocparser.parseSource(source)
        let exp = ocparser.ast.globalStatements.firstObject as! ORDeclareExpression;
        exp.execute(scope)
        let result = scope.getValueWithIdentifier("a")
        XCTAssert(result!.typePair.type.type == TypeBlock)
        XCTAssert(result?.objectValue != nil) //__NSMallocBlock__
        let scopeValue = scope.getValueWithIdentifier("a")
        XCTAssert(scopeValue!.typePair.type.type == TypeBlock)
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
        ocparser.parseSource(source)
        let exps = ocparser.ast.globalStatements as! [ORExpression]
        for exp in exps {
            exp.execute(scope);
        }
        let scopeValue = scope.getValueWithIdentifier("b")
        XCTAssert(scopeValue!.typePair.type.type == TypeInt)
        XCTAssert(scopeValue!.typePair.type.type == TypeInt)
        XCTAssert(scopeValue!.intValue == 2)
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
        ocparser.parseSource(source)
        let exps = ocparser.ast.globalStatements as! [ORExpression]
        for exp in exps {
            exp.execute(scope);
        }
        let scopeValue = scope.getValueWithIdentifier("b")
        XCTAssert(scope.vars.count == 3)
        XCTAssert(scopeValue!.typePair.type.type == TypeInt)
        XCTAssert(scopeValue!.typePair.type.type == TypeInt)
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
        ocparser.parseSource(source)
        let exps = ocparser.ast.globalStatements as! [ORExpression]
        for exp in exps {
            exp.execute(scope);
        }
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 2)
        XCTAssert(scope.getValueWithIdentifier("d")!.intValue == 3)
        XCTAssert(scope.getValueWithIdentifier("e")!.intValue == 3)
        XCTAssert(scope.getValueWithIdentifier("f")!.intValue == 2)
        XCTAssert(scope.getValueWithIdentifier("g")!.boolValue == false)
        XCTAssert(scope.getValueWithIdentifier("h")!.intValue == 4)
        XCTAssert(scope.getValueWithIdentifier("i")!.intValue == -3)
        XCTAssert(scope.getValueWithIdentifier("j")!.intValue == -2)
//        let k = scope.getValueWithIdentifier("k")!
//        let pointer = k.pointerValue!
//        let intPointer = pointer.assumingMemoryBound(to: Int.self)
//        print(intPointer.pointee)
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
        Bool m = a < b;
        Bool n = a > b;
        Bool o = a <= b;
        Bool p = a >= b;
        Bool q = a && b;
        Bool r = a || b;
        Bool s = a != b;
        Bool t = a == b;
        """
        ocparser.parseSource(source)
        let exps = ocparser.ast.globalStatements as! [ORExpression]
        for exp in exps {
            exp.execute(scope);
        }
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
        ocparser.parseSource(source)
        let exps = ocparser.ast.globalStatements as! [ORExpression]
        for exp in exps {
            exp.execute(scope);
        }
        XCTAssert(scope.getValueWithIdentifier("b")!.intValue == 1)
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 3)
        XCTAssert(scope.getValueWithIdentifier("d")!.intValue == 2)
    }
    func testIfStatement(){
        let source =
        """
        int func(int a){
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
        int a = func(1);
        int b = func(3);
        int c = func(15);
        int d = func(30);
        """
        ocparser.parseSource(source)
        let exps = ocparser.ast.globalStatements as! [ORExpression]
        for exp in exps {
            exp.execute(scope);
        }
        XCTAssert(scope.getValueWithIdentifier("a")!.intValue == 0)
        XCTAssert(scope.getValueWithIdentifier("b")!.intValue == 1)
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 2)
        XCTAssert(scope.getValueWithIdentifier("d")!.intValue == 3)
    }
    
    func testWhileStatement(){
        let source =
        """
        int func(int x){
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
        int a = func(2);
        int b = func(3);
        int c = func(15);
        int d = func(30);
        """
        ocparser.parseSource(source)
        let exps = ocparser.ast.globalStatements as! [ORExpression]
        for exp in exps {
            exp.execute(scope);
        }
        XCTAssert(scope.getValueWithIdentifier("a")!.intValue == 1)
        XCTAssert(scope.getValueWithIdentifier("b")!.intValue == 3)
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 18)
        XCTAssert(scope.getValueWithIdentifier("d")!.intValue == 18)
    }
    func testDoWhileStatement(){
        let source =
        """
        int func(int x){
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
        int a = func(2);
        int b = func(3);
        int c = func(15);
        int d = func(30);
        """
        ocparser.parseSource(source)
        let exps = ocparser.ast.globalStatements as! [ORExpression]
        for exp in exps {
            exp.execute(scope);
        }
        XCTAssert(scope.getValueWithIdentifier("a")!.intValue == 2)
        XCTAssert(scope.getValueWithIdentifier("b")!.intValue == 3)
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 18)
        XCTAssert(scope.getValueWithIdentifier("d")!.intValue == 18)
    }
    func testSwitchStatement(){
        let source =
        """
        int func(int x){
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
        int a = func(0);
        int b = func(1);
        int c = func(2);
        int d = func(3);
        """
        ocparser.parseSource(source)
        let exps = ocparser.ast.globalStatements as! [ORExpression]
        for exp in exps {
            exp.execute(scope);
        }
        XCTAssert(scope.getValueWithIdentifier("a")!.intValue == 3)
        XCTAssert(scope.getValueWithIdentifier("b")!.intValue == 111)
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 0)
        XCTAssert(scope.getValueWithIdentifier("d")!.intValue == 222)
    }
    
    func testForStatement(){
        let source =
        """
        int func(int x){
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
        int a = func(0);
        int b = func(2);
        int c = func(3);
        int d = func(4);
        """
        ocparser.parseSource(source)
        let exps = ocparser.ast.globalStatements as! [ORExpression]
        for exp in exps {
            exp.execute(scope);
        }
        XCTAssert(scope.getValueWithIdentifier("a")!.intValue == 1)
        XCTAssert(scope.getValueWithIdentifier("b")!.intValue == 10)
        print(scope.getValueWithIdentifier("c")!.intValue)
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 101)
        XCTAssert(scope.getValueWithIdentifier("d")!.intValue == 101)
    }
    func testForStatementWithDeclare(){
        let source =
        """
        int func(int x){
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
        int a = func(0);
        int b = func(2);
        int c = func(3);
        int d = func(4);
        """
        ocparser.parseSource(source)
        let exps = ocparser.ast.globalStatements as! [ORExpression]
        for exp in exps {
            exp.execute(scope);
        }
        XCTAssert(scope.getValueWithIdentifier("a")!.intValue == 0)
        XCTAssert(scope.getValueWithIdentifier("b")!.intValue == 10)
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 100)
        XCTAssert(scope.getValueWithIdentifier("d")!.intValue == 100)
    }
    
    func testForInStatement(){
        let source =
        """
        int func(NSArray *x){
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
        int a = func(@[@(1),@(2),@(3)]);
        """
        ocparser.parseSource(source)
        let exps = ocparser.ast.globalStatements as! [ORExpression]
        for exp in exps {
            exp.execute(scope);
        }
        print(scope.getValueWithIdentifier("a")!.intValue)
        XCTAssert(scope.getValueWithIdentifier("a")!.intValue == 6)
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
        - (NSString *)testOriginalMethod{
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
        ocparser.parseSource(source)
        let exps = ocparser.ast.globalStatements as! [ORExpression]
        for exp in exps {
            exp.execute(scope);
        }
        let classes = ocparser.ast.classCache.allValues as! [ORClass];
        for classValue in classes {
            classValue.execute(scope);
        }
        let test = ORTestReplaceClass.init()
        XCTAssert(test.test() == 1)
        XCTAssert(test.arg1(NSNumber.init(value: 2), arg2: NSNumber.init(value: 3)) == 5)
        XCTAssert(test.arg1(NSNumber.init(value: 10)) == 10)
        XCTAssert(ORTestReplaceClass.testMethodReplaceTest())
        XCTAssert(test.testOriginalMethod() == 2)
        XCTAssert(test.testAddGlobalVar() == 1111)
        if let dict = test.testMethodParameterListAndReturnValue(with: "ggggg") { (value) -> String in
            return "hhhh" + value
        }() as? [AnyHashable:String]{
            XCTAssert(dict["param1"] == "ggggg")
            XCTAssert(dict["param2"] == "hhhhMango")
        }
        
    }
    func testSuperMethodCall(){
        let source =
        """
        @implementation MFCallSuperNoArgTest
        - (BOOL)testCallSuperNoArgTestSupser{
            return [super testCallSuperNoArgTestSupser];
        }
        @end
        """
        ocparser.parseSource(source)

        let classes = ocparser.ast.classCache.allValues as! [ORClass];
        for classValue in classes {
            classValue.execute(scope);
        }
        
        let test = MFCallSuperNoArgTest.init()
        XCTAssert(test.testCallSuperNoArgTestSupser())
    }
    func testMultiArgsFunCall(){
        let source =
        """
        NSString *b = [NSString stringWithFormat:@"%@",@"sss"];
        """
        ocparser.parseSource(source)
        let exps = ocparser.ast.globalStatements as! [ORExpression]
        for exp in exps {
            exp.execute(scope);
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
        ocparser.parseSource(source)
        let classes = ocparser.ast.classCache.allValues as! [ORClass];
        for classValue in classes {
            classValue.execute(scope);
        }
        let test = ORTestReplaceClass.init()
        XCTAssert(test.test() == 10)
    }
    func testClassProperty(){
        let source =
        """
        @interface ORTestClassProperty:NSObject
        @property(nonatomic,copy)NSString *strTypeProperty;
        @property(nonatomic,weak)id weakObjectProperty;
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

        - (id)testWeakObjectProperty{
            self.weakObjectProperty = [NSObject new];//下一个运行时释放
            return self.weakObjectProperty;
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
        ocparser.parseSource(source)
        let classes = ocparser.ast.classCache.allValues as! [ORClass];
        for classValue in classes {
            classValue.execute(scope);
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
            _objectIvar = [[NSObject alloc] init];
            return _objectIvar;
        }

        - (NSInteger)testIntIvar{
            _intIvar = 10000001;
            return _intIvar;
        }
        @end
        """
        ocparser.parseSource(source)
        let classes = ocparser.ast.classCache.allValues as! [ORClass];
        for classValue in classes {
            classValue.execute(scope);
        }
        let test = ORTestClassIvar.init()
        XCTAssert(test.testObjectIvar() != nil)
        XCTAssert(test.testIntIvar() == 10000001)
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
        ocparser.parseSource(source)
        let classes = ocparser.ast.classCache.allValues as! [ORClass];
        for classValue in classes {
            classValue.execute(scope);
        }
        let test = ORCallOCPropertyBlockTest.init()
        XCTAssert(test.testCallOCReturnBlock() == "ab")
        
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
        ocparser.parseSource(source)
        let classes = ocparser.ast.classCache.allValues as! [ORClass];
        for classValue in classes {
            classValue.execute(scope);
        }
        let test = MFCallSuperNoArgTest.init()
        XCTAssert(test.testCallSuperNoArgTestSupser())
    }
    func testGCD(){
        mf_add_built_in()
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
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_global_queue(0, 0), ^int{
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
        ocparser.parseSource(source)
        let classes = ocparser.ast.classCache.allValues as! [ORClass];
        for classValue in classes {
            classValue.execute(scope);
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
        ocparser.parseSource(source)
        let exps = ocparser.ast.globalStatements as! [ORExpression]
        exps[0].execute(scope);
        exps[1].execute(scope);
        XCTAssert(scope.getValueWithIdentifier("a")!.intValue == 1)
        exps[2].execute(scope)
        XCTAssert(scope.getValueWithIdentifier("b")!.intValue == 2)
        exps[3].execute(scope)
        XCTAssert(scope.getValueWithIdentifier("c")!.intValue == 3)
    }
    func testStructGetValue(){
        source =
        """
        UIView *view = [UIView new];
        CGRect frame = view.frame;
        """
        ocparser.parseSource(source)
        let exps = ocparser.ast.globalStatements as! [ORExpression]
        for exp in exps {
            exp.execute(scope);
        }
        print(scope.getValueWithIdentifier("frame"))
    }
}
