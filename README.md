# OCRunner
OCRunner is a DSL using Objective-C syntax，OCRunner is also an iOS App hotfix SDK. You can use OCRunner method replace any Objective-C method.
## Demo运行: 

目前无法在模拟上运行，只支持真机。

直接下载zip，是无法正常运行的。必须通过git clone

```shell
git clone --recursive https://github.com/SilverFruity/OCRunner.git
```
或者

```shell
git clone https://github.com/SilverFruity/OCRunner.git
cd OCRunner
git submodule update --init --recursive
```

关于单元测试，必须在arm64下运行。

OCRunner framework的单元测试，当前无法在模拟器上运行，并不支持x86_64。

单元测试已经转移到OCRunnerDemo下。

## 与Objective-C当前存在的语法差异

### 预编译指令

不支持预编译指令 #define #if等

### Protcol协议
当前不支持协议，不支持@protocol，但支持语法如下:
```objective-c
//这里实际创建的Classxxx并不遵循协议protocol1和protocol2
// [[Classxxx new] conformsToProtocol:@protocol(protocol1)] 必定为NO
@interface Classxxx: NSObject <protocol1, protocol2> 
@end
NSArray <NSObject*>*array;
```
### 多参数问题

```objective-c
// 可以直接使用
[NSString stringWithFormat:@"%@",@"a"];
// 函数，现在还在寻找一个最轻松的方案
NSLog(@"%@",@"a")
// 等等
```


### 类修复问题

* 问题1: 我有个类有abcde5个方法以及若干属性，如果我只想对其中的A方法进行重写，我要把其他几个都带上吗？ 答: 只需要重写A方法

#### 已经存在的类

可以这么写，不用声明 `@interface ORTestReplaceClass:  SuperClass @end`

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

#### 新建类

这里新建的ORTestReplaceClass类默认会继承自NSObject，如果你想添加property或者父类，就必须使用@interface

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

#### 支持分类写法

```objective-c
@implementation Demo
- (instancetype)initWithBaseUrl:(NSURL *)baseUrl{ }
- (NSString *)method2:(void(^)(NSString *name))callback{ }
@end
@implementation Demo (Category)
- (NSString *)method3:(void(^)(NSString *name))callback{ }
@end
```

### 关于枚举的一点问题

不支持**NS_ENUM**和**NS_OPTION**，转换为对应的C声明方式即可.

例如：

```objective-c
typedef NS_OPTIONS(NSUInteger, UIControlEvents) {}
typedef NS_ENUM(NSUInteger, UIControlEvents) {}
// 需要转换为以下语法
typedef enum: NSUInteger {

}UIControlEvents;
```

### 关于结构体一点问题

被引用结构，必须提前声明

```objective-c
// CGPoint必须在CGRect之前声明
struct CGPoint { 
    CGFloat x;
    CGFloat y;
};
// CGSize必须在CGRect之前声明
struct CGSize { 
    CGFloat width;
    CGFloat height;
};
struct CGSize { 
    CGPoint point;
    CGSize size; 
};
```


### UIKit中的常量、类型、结构体、枚举、全局函数的应对方法

#### 常量、结构体、枚举

第一种:

```objective-c
// 需要在App中添加
// 结构体
ORStructDeclareTable *table = [ORStructDeclareTable shareInstance];
[table addStructDeclare:[ORStructDeclare structDecalre:@encode(CGPoint) keys:@[@"x",@"y"]]];
// 常量
[MFScopeChain.topScope setValue:[MFValue valueWithLongLong:DISPATCH_QUEUE_PRIORITY_HIGH] withIndentifier:@"DISPATCH_QUEUE_PRIORITY_HIGH"];

// 枚举值和常量相同
[MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventTouchDragInside] withIndentifier:@"UIControlEventTouchDragInside"];
```

第二种:

```objective-c
// 以下代码在脚本中直接添加即可
// 作用等同于上述的方式
typedef struct CGPoint { 
    CGFloat x;
    CGFloat y;
} CGPointss;
// 直接把UIControlEvents的定义复制过来,修改NS_OPTIONS即可
typedef enum: NSUInteger{
    UIControlEventTouchDown = 1 <<  0,
    UIControlEventTouchDownRepeat = 1 <<  1,
    UIControlEventTouchDragInside = 1 <<  2,
    UIControlEventAllTouchEvents = 0x00000FFF,
}UIControlEvents;
// 上述代码会新增了四个类型, dispatch_once_t, CGPoint, CGPointss, UIControlEvents
// 新增四个常量 UIControlEventTouchDown UIControlEventTouchDownRepeat UIControlEventTouchDragInside UIControlEventAllTouchEvents

id GlobalValue = [NSObject new]; //在OCRunner中是可以作为全局变量的
```

#### 新增类型

typedef，目前还有typedef嵌套问题。

```objective-c
// 脚本中使用
typedef NSInteger dispatch_once_t;
```

```objective-c
// 脚本中使用
// 问题代码
typedef long long IntegerType;
typedef IntegerType dispatch_once_t;
```

#### 全局函数

目前只能使用这种方式

```objective-c
// 需要在App中添加
// 全局函数
[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_queue_t queue, void (^block)(void)) {
		dispatch_async(queue, ^{
			block();
		});
	}] withIndentifier:@"dispatch_async"];
```





### 关于#import

**#import** 是可以省略的。支持这个语法，仅仅是为了复制粘贴....

### 不支持的关键词

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

### 自动忽略的关键词:

* const
* _Nullable
* nullable
* @required
* @public
* @private
* @protected
* __unused
* __bridge_retained
* __bridge_transfer
* __bridge
* __block
* __autoreleasing
* IBInspectable
* UI_APPEARANCE_SELECTOR
* NS_ASSUME_NONNULL_BEGIN
* NS_ASSUME_NONNULL_BEGIN

强烈建议看看单元测试中支持的语法。

