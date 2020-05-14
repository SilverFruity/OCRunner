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
}
