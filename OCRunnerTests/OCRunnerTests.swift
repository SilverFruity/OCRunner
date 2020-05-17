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
        let result = exp.execute(scope)
        XCTAssert(result!.typePair.type.type == TypeInt)
        XCTAssert(result!.intValue == 1)
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
        let result = exp.execute(scope)
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
    func testSequentia(){
        
    }
}
