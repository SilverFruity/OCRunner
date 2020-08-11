# OCRunner

[中文介绍](https://github.com/SilverFruity/OCRunner/blob/master/README-CN.md)

[Wiki](https://github.com/SilverFruity/OCRunner/wiki)

Execute Objective-C code Dynamically.

## Run Demo
You should use 'git clone --recursive'.
```shell
git clone --recursive https://github.com/SilverFruity/OCRunner.git
```
or
```shell
git clone https://github.com/SilverFruity/OCRunner.git
cd OCRunner
git submodule update --init --recursive
```

The unit tests of OCRunner.framework has move to OCRunnerDemo。

## Feature

* Execute Objective-C code Dynamically。

* Unit test coverage is 86%。

* Support link system Non-inline C function by using Global C function declaration syntax in script。

* Support structure declaration syntax in script. You can freely use structures in scripts。

* Support enum declaration syntax.

* Support typedef.

* Support call multiple arguments function and method.

* Support pointer operators :  '&' and '*'.

* Support Protocol.

* Optinal libffi.a or build-in customized arm64 abi (modified from libffi)

	Default using libffi.a.

  * Do not use libffi.a:  you should remove the reference of 'libffi' folder from project.
  * Use libffi.a:  add the libffi folder to project.

* Not support  pre-compile, C array declaration syntax.

Recommend:  start eating from the unit test.

## Example

```objective-c
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
[ORInterpreter excute:source];
Class testClass = NSClassFromString(@"TestObject");
NSAssert([testClass conformsToProtocol:NSProtocolFromString(@"Protocol1")]);
NSAssert([testClass conformsToProtocol:NSProtocolFromString(@"Protocol2")]);
id object = [[testClass alloc] init];
NSAssert([object conformsToProtocol:NSProtocolFromString(@"Protocol1")]);
NSAssert([object conformsToProtocol:NSProtocolFromString(@"Protocol2")]);
```


## Cocoapods
```ruby
pod 'OCRunner'      #for all architectures, include libffi.a
pod 'OCRunnerArm64' #only for arm64 or amr64e, no libffi.a
```


## What's the difference of Objective-C

### Not support pre-compile

Such as #define, #if etc.

### The problems of hot fix Class

* Problem 1:if Class1 have five method (a,b,c,d,e) and several properties, if i only want to hot fix 'a' method, how can i do it ?  anwser: you only need to imp the 'a' method in scripts.  

#### Fix Existed Class

The shortest way:

```objective-c
@implementation ORTestReplaceClass
- (int)otherMethod{
    return 10;
}
- (int)test{
    return [self otherMethod];
}
@end
```

If want to add properties (not support add ivars), you should:

```objective-c
@interface ORTestReplaceClass : NSObject
@property (assign, nonatomic) NSInteger num;
@end
@implementation ORTestReplaceClass
- (int)otherMethod{
    return 10;
}
- (int)test{
    return [self otherMethod];
}
@end
```

#### Create new Class

In this situation, ORTestReplaceClass inherit NSObjece. 

```objective-c
@implementation ORTestReplaceClass
- (int)otherMethod{
    return 10;
}
- (int)test{
    return [self otherMethod];
}
@end
```

if you want to add ivar, property or customized superClass，you should imp @interface.

Notice: ivar must be used in new Class.

```objective-c
@interface ORTestReplaceClass : NSObject
{
  int _testValue;
  id _testObject;
}
@property (assign, nonatomic) NSInteger num;
@end
@implementation ORTestReplaceClass
{
  int _impivar;
}
- (int)otherMethod{
    return 10;
}
- (int)test{
    return [self otherMethod];
}
@end
```



#### Support Category Syntax

```objective-c
@implementation Demo
- (instancetype)initWithBaseUrl:(NSURL *)baseUrl{ }
- (NSString *)method2:(void(^)(NSString *name))callback{ }
@end
@implementation Demo (Category)
- (NSString *)method3:(void(^)(NSString *name))callback{ }
@end
```

### About Enum Syntax

Not surpport **NS_ENUM**和**NS_OPTION**.

You should use C syntax.

```objective-c
//typedef NS_OPTIONS(NSUInteger, UIControlEvents) {}
//convert to this
typedef enum: NSUInteger {

}UIControlEvents;
```

### About Struct Syntax

The referenced structure must be declared in advance.

```objective-c
// CGPoint must be in front of CGRect
struct CGPoint { 
    CGFloat x;
    CGFloat y;
};
// CGSize must be in front of CGRect
struct CGSize { 
    CGFloat width;
    CGFloat height;
};
struct CGSize { 
    CGPoint point;
    CGSize size; 
};
```


### constant, type, struct, enum, global function.

#### constant、struct、enum

Way 1:

```objective-c
// Need write those code in Application files
// Struct
ORStructDeclareTable *table = [ORStructDeclareTable shareInstance];
[table addStructDeclare:[ORStructDeclare structDecalre:@encode(CGPoint) keys:@[@"x",@"y"]]];
// Constant
[MFScopeChain.topScope setValue:[MFValue valueWithLongLong:DISPATCH_QUEUE_PRIORITY_HIGH] withIndentifier:@"DISPATCH_QUEUE_PRIORITY_HIGH"];

// Enum is similar to Constant
[MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventTouchDragInside] withIndentifier:@"UIControlEventTouchDragInside"];
```

Way 2:

```objective-c
// Need write those code in Scripts
typedef struct CGPoint { 
    CGFloat x;
    CGFloat y;
} CGPointss;
typedef enum: NSUInteger{
    UIControlEventTouchDown = 1 <<  0,
    UIControlEventTouchDownRepeat = 1 <<  1,
    UIControlEventTouchDragInside = 1 <<  2,
    UIControlEventAllTouchEvents = 0x00000FFF,
}UIControlEvents;
// it will add four types: CGPoint, CGPointss, UIControlEvents
// add four constants: UIControlEventTouchDown UIControlEventTouchDownRepeat UIControlEventTouchDragInside UIControlEventAllTouchEvents
```

#### Add new type

```objective-c
// use it in Scripts
typedef NSInteger dispatch_once_t;
```

```objective-c
// problem code:
typedef long long IntegerType;
typedef IntegerType dispatch_once_t;
```

#### Global Function

1. Pre-compile function:

```objective-c
[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_queue_t queue, void (^block)(void)) {
		dispatch_async(queue, ^{
			block();
		});
	}] withIndentifier:@"dispatch_async"]
```

2. Non-inline function:

```objective-c
// add this in Scripts
void NSLog(NSString *format, ...);
```

3. Inline function

   For example:  dispatch_get_main_queue

   * Way 1

   ```objective-c
   // the code in Application files
   [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^id() {
			return dispatch_get_main_queue();
   }]withIndentifier:@"dispatch_get_main_queue"];
   ```

   
   * Way 2
   
   ```objective-c
   // write in script. OCRunner will auto print it in console on the debug mode.
   dispatch_queue_main_t dispatch_get_main_queue(void);
   // the code in Application files
   [ORSystemFunctionTable reg:@"dispatch_get_main_queue" pointer:&dispatch_get_main_queue];
   ```

4. (CGRectMake etc.) Inline function、Custom function

```objective-c
// write in script
CGRect CGRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height)
{
  CGRect rect;
  rect.origin.x = x; rect.origin.y = y;
  rect.size.width = width; rect.size.height = height;
  return rect;
}
```

### About #import

**#import** can be omitted.

### Not Support 
* int a\[x\]
* typeof
* @optional
* @encode
* @synchronized
* @try
* @catch
* @available
* @protocol
* @autoreleasepool
* @dynamic
* @synthesize
* IBOutlet
* IBAction
* IBInspectable



### Thanks for

* [Mango](https://github.com/YPLiang19/Mango)
* [libffi](https://github.com/libffi/libffi)
* Procedure Call Standard for the ARM 64-bit Architecture. 


