//
//  ORunner.h
//  MangoFix
//
//  Created by Jiang on 2020/4/26.
//  Copyright © 2020 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MFValue;

@protocol OCExecute <NSObject>

- (nullable MFValue *)executeResult;
@end

// MARK: - Base
typedef enum{
    TypeChar,
    TypeUChar,
    TypeShort,
    TypeUShort,
    TypeInt,
    TypeUInt,
    TypeLong,
    TypeULong,
    TypeLongLong,
    TypeULongLong,
    TypeBOOL,
    TypeEnum,
    TypeFloat,
    TypeDouble,
    TypeLongDouble,
    TypeVoid,
    TypeUnion,
    TypeStruct,
    TypeFunction,
    TypeArray,
    TypeNSArray,
    TypeNSDictionary,
    TypeSEL,
    TypeProtocol,
    TypeClass,
    TypeObject,
    TypeBlock,
    TypeId,
    TypeUnKnown
}TypeKind;
enum{
    AttributeConst = 1,
    AttributeStatic = 1 << 1,
    AttributeVolatile = 1 << 2,
    AttributeStrong = 1 << 3,
    AttributeBlock = 1 << 4,
    AttributeWeak = 1 << 5,
    AttributeExtern = 1 << 6,
    AttributeNonnull = 1 << 7,
    AttributeNullable = 1 << 8,
    AttributeBridge = 1 << 9
};


@interface ORTypeSpecial: NSObject
@property (nonatomic, assign) TypeKind type;
@property (nonatomic, nullable, copy) NSString * name;
@end


@interface ORVariable :NSObject
@property (nonatomic, assign) NSInteger ptCount;
@property (nonatomic, nullable, copy) NSString * varname;
@end

@interface ORTypeVarPair: NSObject
@property (nonatomic, strong)ORTypeSpecial *type;
@property (nonatomic, strong)ORVariable *var;
@end

@interface ORFuncVariable: ORVariable
@property(nonatomic,strong) NSMutableArray <ORTypeVarPair *> *pairs;
@end

@interface ORFuncDeclare: NSObject
@property(nonatomic,strong) ORTypeVarPair *returnType;
@property(nonatomic,strong) ORFuncVariable *var;
@end

// MARK: - Expression
typedef enum {
    OCValueVariable,
    OCValueClassType,
    OCValueSelf,
    OCValueSuper,
    OCValueBlock,
    OCValueSelector,
    OCValueProtocol,
    OCValueDictionary, // value -> [[exp,exp]..]
    OCValueArray, // value -> [exp..]
    OCValueNSNumber,
    OCValueString,
    OCValueCString,
    OCValueInt,
    OCValueDouble,
    OCValueConvert,
    OCValueNil,
    OCValueNULL,
    OCValueBOOL,
    OCValuePointValue,
    OCValueVarPoint,
    OCValueMethodCall,
    OCValueFuncCall,
    OCValueCollectionGetValue // array[0] , dict[@"key"]
}OC_VALUE_TYPE;

@interface ORValueExpression: NSObject <OCExecute>
@property (nonatomic, assign)OC_VALUE_TYPE type;
@property (nonatomic,strong)id value;
@end

@interface ORMethodCall: ORValueExpression
@property (nonatomic, strong)ORValueExpression * caller;
@property (nonatomic, assign)BOOL isDot;
@property (nonatomic, strong)NSMutableArray *names;
@property (nonatomic, strong)NSMutableArray <ORValueExpression *> *values;
@end

@interface ORCFuncCall: ORValueExpression
@property (nonatomic, strong)ORValueExpression *caller;
@property (nonatomic, strong)NSMutableArray <ORValueExpression *>*expressions;
@end

@interface ORBlockImp: ORValueExpression
@property(nonatomic,strong) ORFuncDeclare *declare;
@property(nonatomic,strong) NSMutableArray<id <OCExecute>>* statements;
@end

@interface OCCollectionGetValue: ORValueExpression
@property (nonatomic, strong)ORValueExpression * caller;
@property (nonatomic, strong)ORValueExpression * keyExp;
@end

typedef enum {
    AssignOperatorAssign,
    AssignOperatorAssignAnd,
    AssignOperatorAssignOr,
    AssignOperatorAssignXor,
    AssignOperatorAssignAdd,
    AssignOperatorAssignSub,
    AssignOperatorAssignDiv,
    AssignOperatorAssignMuti,
    AssignOperatorAssignMod,
    AssignOperatorAssignShiftLeft,
    AssignOperatorAssignShiftRight,
}AssignOperatorType;

@interface ORAssignExpression:NSObject <OCExecute>
@property (nonatomic,strong)ORValueExpression * value;
@property (nonatomic,assign)AssignOperatorType assignType;
@property (nonatomic,strong)ORValueExpression * expression;
@end

@interface ORDeclareExpression:NSObject <OCExecute>
@property (nonatomic,strong)ORTypeVarPair *pair;
@property (nonatomic,strong, nullable)ORValueExpression * expression;
@end

typedef enum {
    UnaryOperatorIncrementSuffix,
    UnaryOperatorDecrementSuffix,
    UnaryOperatorIncrementPrefix,
    UnaryOperatorDecrementPrefix,
    UnaryOperatorNot,
    UnaryOperatorNegative,
    UnaryOperatorBiteNot,
    UnaryOperatorSizeOf,
    UnaryOperatorAdressPoint,
    UnaryOperatorAdressValue
}UnaryOperatorType;
@interface ORUnaryExpression:NSObject <OCExecute>
@property (nonatomic,strong)ORValueExpression * value;
@property (nonatomic,assign)UnaryOperatorType operatorType;
@end

typedef enum {
    BinaryOperatorAdd,
    BinaryOperatorSub,
    BinaryOperatorDiv,
    BinaryOperatorMulti,
    BinaryOperatorMod,
    BinaryOperatorShiftLeft,
    BinaryOperatorShiftRight,
    BinaryOperatorAnd,
    BinaryOperatorOr,
    BinaryOperatorXor,
    BinaryOperatorLT,
    BinaryOperatorGT,
    BinaryOperatorLE,
    BinaryOperatorGE,
    BinaryOperatorNotEqual,
    BinaryOperatorEqual,
    BinaryOperatorLOGIC_AND,
    BinaryOperatorLOGIC_OR
}BinaryOperatorType;

@interface ORBinaryExpression: ORValueExpression
@property (nonatomic,strong)ORValueExpression * left;
@property (nonatomic,assign)BinaryOperatorType operatorType;
@property (nonatomic,strong)ORValueExpression * right;
@end

@interface ORTernaryExpression: ORValueExpression
@property (nonatomic,strong)ORValueExpression * expression;
@property (nonatomic,strong)NSMutableArray <ORValueExpression *>*values;
@end
// MARK: - Statement
@interface ORStatement:NSObject <OCExecute>
@property (nonatomic, strong)ORBlockImp *funcImp;
@end

@interface ORIfStatement : ORStatement
@property (nonatomic,strong)ORValueExpression * condition;
@property (nonatomic,strong, nullable)ORIfStatement * last;
@end

@interface ORWhileStatement : ORStatement
@property (nonatomic,strong)ORValueExpression * condition;
@end

@interface ORDoWhileStatement : ORStatement
@property (nonatomic,strong)ORValueExpression * condition;
@end

@interface ORCaseStatement : ORStatement
@property (nonatomic,strong)ORValueExpression * value;
@end

@interface ORSwitchStatement : ORStatement
@property (nonatomic,strong)ORValueExpression * value;
@property (nonatomic,strong)NSMutableArray <ORCaseStatement *>*cases;
@end

@interface ORForStatement : ORStatement
@property (nonatomic,strong)NSMutableArray <ORDeclareExpression *>*declareExpressions;
@property (nonatomic,strong)ORValueExpression * condition;
@property (nonatomic,strong)NSMutableArray <ORValueExpression *>* expressions;
@end

@interface ORForInStatement : ORStatement
@property (nonatomic,strong)ORDeclareExpression * expression;
@property (nonatomic,strong)ORValueExpression * value;
@end

@interface ORReturnStatement : ORStatement
@property (nonatomic,strong)ORValueExpression * expression;
@end

@interface ORBreakStatement : ORStatement

@end

@interface ORContinueStatement : ORStatement

@end

// MARK: - Class
typedef NS_ENUM(NSUInteger, MFPropertyModifier) {
    MFPropertyModifierMemStrong = 0x00,
    MFPropertyModifierMemWeak = 0x01,
    MFPropertyModifierMemCopy = 0x2,
    MFPropertyModifierMemAssign = 0x03,
    MFPropertyModifierMemMask = 0x0F,
    
    MFPropertyModifierAtomic = 0x00,
    MFPropertyModifierNonatomic =  0x10,
    MFPropertyModifierAtomicMask = 0xF0,
};
@interface ORPropertyDeclare: NSObject
@property(nonatomic,strong) NSMutableArray *keywords;
@property(nonatomic,strong) ORTypeVarPair * var;
@property(nonatomic,assign) MFPropertyModifier modifier;
@end

@interface ORMethodDeclare: NSObject
@property(nonatomic,assign) BOOL isClassMethod;
@property(nonatomic,strong) ORTypeVarPair * returnType;
@property(nonatomic,strong) NSMutableArray *methodNames;
@property(nonatomic,strong) NSMutableArray <ORTypeVarPair *>*parameterTypes;
@property(nonatomic,strong) NSMutableArray *parameterNames;
@end

@interface ORMethodImplementation: NSObject
@property (nonatomic,strong) ORMethodDeclare * declare;
@property (nonatomic,strong) ORBlockImp *imp;
@end

@interface ORClass: NSObject <OCExecute>
@property (nonatomic,copy)NSString *className;
@property (nonatomic,copy)NSString *superClassName;
@property (nonatomic,strong)NSMutableArray <NSString *>*protocols;
@property (nonatomic,strong)NSMutableArray <ORPropertyDeclare *>*properties;
@property (nonatomic,strong)NSMutableArray <ORTypeVarPair *>*privateVariables;
@property (nonatomic,strong)NSMutableArray <ORMethodImplementation *>*methods;
@end
NS_ASSUME_NONNULL_END
