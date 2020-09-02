# OCRunner

## Demo运行

直接下载zip，是无法正常运行的。必须通过git clone --recursive。

```shell
git clone --recursive https://github.com/SilverFruity/OCRunner.git
```
## 主要功能

* 执行PatchGenerator生成的二进制补丁，进行热更新。

* 可选libffi或者内置自定义实现的arm64 libff(基于TypeEncode不再是ffi_type)。

  默认使用libffi.a实现。

  * 不使用libffi.a:  项目中移除的libffi文件夹的引用即可。
  * 使用libffi.a:  导入libffi文件夹即可。

* 86%的单元测试覆盖。

## 支持的Objective-C语法

* 除去预编译、C数组声明和赋值，其他语法皆已支持。

* 支持方法替换以及新建类。

* 支持全局C函数声明，直接获取非内联函数指针。

* 支持结构体。内置结构体内存布局，结构体取值与赋值等。

* 支持枚举声明。

* 支持可变参数函数和方法调用。

* 支持指针操作: '&'、'*'。

* 支持Protocol。

  等.....

## 如何使用

###  1. Cocoapods导入
```ruby
pod 'OCRunner'      #支持所有架构，包含libffi.a
# 或者
pod 'OCRunnerArm64' #仅支持 arm64和arm64e，没有libffi.a
```

### 2. 下载 [PatchGenerator](https://github.com/SilverFruity/oc2mango/releases)

解压PatchGenerato.zip，然后将PatchGenerator保存到/usr/bin/或项目目录下.

### 3.  添加PatchGenerator的 `Run Script` 

1. Project Setting -> Build Phases -> 左上角的 `+` -> `New Run Script Phase`

2. PatchGenerator的路径 **-files** Objective-C源文件列表或者文件夹 **-refs** Objective-C头文件列表或者文件夹 **-output** 输出补丁保存的位置

3. 比如OCRunnerDemo中的`Run Script`

   ```shell
   $SRCROOT/OCRunnerDemo/PatchGenerator -files $SRCROOT/OCRunnerDemo/ViewController1 -refs  $SRCROOT/OCRunnerDemo/Scripts.bundle -output $SRCROOT/OCRunnerDemo/binarypatch
   ```

### 4.  开发环境下: 测试脚本

1. 将生成的补丁文件作为资源文件添加到项目中

2. Appdelegate.m

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#if DEBUG
    NSString *patchFilePath = [[NSBundle mainBundle] pathForResource:@"PatchFileName" ofType:nil];
#else
   // download from server
#endif
    [ORInterpreter excuteBinaryPatchFile:patchFilePath];
    return YES;
}
```

3. 每次修改文件，记得Command+B，调用Run Scrip，重新生成补丁文件.

### 5. 正式环境

1. 将补丁上传到服务器
2. App中下载补丁文件并保存到本地
3. 使用**[ORInterpreter excuteBinaryPatchFile:PatchFilePath]** 执行补丁

## 与Objective-C当前存在的语法差异

### 预编译指令

不支持预编译指令 #define #if等

### 类修复问题

* 问题1: 我有个类有abcde5个方法以及若干属性，如果我只想对其中的A方法进行重写，我要把其他几个都带上吗？ 答: 只需要重写A方法

#### 已经存在的类

支持的最简方式：

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

如果需要添加properties:

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



#### 新建类

这里新建的ORTestReplaceClass类默认会继承自NSObject.

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

如果你想添加 ivar, property或者父类，就必须使用@interface。

提示：只有在新建类的时候，才能添加成员变量。

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

### 枚举

不支持**NS_ENUM**和**NS_OPTION**，转换为对应的C声明方式即可.

例如：

```objective-c
typedef NS_OPTIONS(NSUInteger, UIControlEvents) {}
typedef NS_ENUM(NSUInteger, UIControlEvents) {}
// 需要转换为以下语法
typedef enum: NSUInteger {

}UIControlEvents;
```

### 关于结构体

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

1. 预编译函数

```objective-c
[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_queue_t queue, void (^block)(void)) {
		dispatch_async(queue, ^{
			block();
		});
	}] withIndentifier:@"dispatch_async"]
```

2. 可通过ORSearchedFunction找的函数

```objective-c
// 直接在脚本中添加函数声明即可
void NSLog(NSString *format, ...);
```

3. 不可通过ORSearchedFunction找的函数

   例如dispatch_get_main_queue

   * 方式一

   ```objective-c
   	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^id() {
   		return dispatch_get_main_queue();
	}]withIndentifier:@"dispatch_get_main_queue"];
   ```

   * 方式二
   
   ```objective-c
	 //脚本中添加声明: DEBUG模式下会自动在控制台打印App中需要添加的代码
   dispatch_queue_main_t dispatch_get_main_queue(void);
   //App中添加: 
   [ORSystemFunctionTable reg:@"dispatch_get_main_queue" pointer:&dispatch_get_main_queue];
   ```
   
4. OC中的inline函数、自定义函数

```objective-c
//脚本中直接添加
CGRect CGRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height)
{
  CGRect rect;
  rect.origin.x = x; rect.origin.y = y;
  rect.size.width = width; rect.size.height = height;
  return rect;
}
```

### 不支持的语法
* C数组声明：int a\[x\]等;
* typeof

* @optional
* @encode
* @synchronized
* @try
* @catch
* @available
* @autoreleasepool
* @dynamic
* @synthesize
* IBOutlet
* IBAction
* IBInspectable

强烈建议看看单元测试中支持的语法。



### Thanks for

* [Mango](https://github.com/YPLiang19/Mango)
* [libffi](https://github.com/libffi/libffi)
* Procedure Call Standard for the ARM 64-bit Architecture. 