**OCRunner QQ群: 860147790**

[相关文章](https://github.com/SilverFruity/OCRunner/issues/11)

## Demo运行

直接下载zip，是无法正常运行的。必须通过git clone --recursive。

```shell
git clone --recursive https://github.com/SilverFruity/OCRunner.git
```

## 简介

### [OCRunner](https://github.com/SilverFruity/OCRunner)开发补丁的工作流

![0](https://silverfruity.github.io/2020/09/04/OCRunner/OCRunner_0.jpeg)

### 初衷

为了能够实现一篇文章的思路：Objective-C源码 -> 二进制补丁文件 ->热更新（具体是哪篇我忘了）。当时刚好开始了[oc2mango](https://github.com/SilverFruity/oc2mango)翻译器的漫漫长路（顺带为了学习编译原理，嘻嘻），等基本完成以后，就开始肝OCRunner：完全兼容struct，enum，系统C函数调用，魔改libffi，生成补丁文件等，尽可能兼容Objective-C，为了做一个直接运行OC的快乐人。

### 各方职责

* [oc2mangoLib](https://github.com/SilverFruity/oc2mango/tree/master/oc2mangoLib)相当于一个简单的编译器，负责生成语法树
* [ORPatchFile](https://github.com/SilverFruity/oc2mango/tree/master/oc2mangoLib/PatchFile)负责将语法树序列化、反序列化和版本判断
* [PatchGenerator](https://github.com/SilverFruity/oc2mango/tree/master/PatchGenerator)负责将oc2mangoLib和ORPatchFile的功能整合（以上工具都在[oc2mango](https://github.com/SilverFruity/oc2mango)项目下）
* [OCRunner](https://github.com/SilverFruity/OCRunner)负责解释执行语法树

### 与其他库的区别

* 下发二进制补丁文件。增加安全性，减小补丁大小，省去词法分析与语法分析，优化启动时间，可在PatchGenerator阶段进行优化

* 自定义的Arm64 ABI （可以不使用libffi）

* 完整的Objective-C语法支持，除去预编译和部分语法

## 本地使用OCRunner运行补丁

[OCRunnerDemo](https://github.com/SilverFruity/OCRunner/tree/master/OCRunnerDemo)可以作为整个流程的参照.

###  Cocoapods导入OCRunner
```ruby
pod 'OCRunner'      #支持所有架构，包含libffi.a
# 或者
pod 'OCRunnerArm64' #仅支持 arm64和arm64e，没有libffi.a
```

### 下载 [PatchGenerator](https://github.com/SilverFruity/oc2mango/releases)

解压PatchGenerato.zip，然后将PatchGenerator保存到/usr/local/bin/或项目目录下.

### 添加PatchGenerator的 `Run Script` 

1. **Project Setting** -> **Build Phases** -> 左上角的 `+` -> `New Run Script Phase`

2. PatchGenerator的路径 **-files** Objective-C源文件列表或者文件夹 **-refs** Objective-C头文件列表或者文件夹 **-output** 输出补丁保存的位置

3. 比如OCRunnerDemo中的`Run Script`

   ```shell
   $SRCROOT/OCRunnerDemo/PatchGenerator -files $SRCROOT/OCRunnerDemo/ViewController1 -refs  $SRCROOT/OCRunnerDemo/Scripts.bundle -output $SRCROOT/OCRunnerDemo/binarypatch
   ```

### 开发环境下: 运行补丁

1. 将生成的补丁文件作为资源文件添加到项目中

2. Appdelegate.m

```objc
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

### 正式环境

1. 将补丁上传到服务器
2. App中下载补丁文件并保存到本地
3. 使用**[ORInterpreter excuteBinaryPatchFile:PatchFilePath]** 执行补丁



## 使用介绍

### 引入结构体、枚举、typedef

可以通过修改**OCRunnerDemo**中的**ViewController1**，运行以下代码.

```objc
// 将添加一个名为dispatch_once_t的新类型
typedef NSInteger dispatch_once_t;
// link NSLog
void NSLog(NSString *format, ...);

typedef enum: NSUInteger{
    UIControlEventTouchDown                                         = 1 <<  0,
    UIControlEventTouchDownRepeat                                   = 1 <<  1,
    UIControlEventTouchDragInside                                   = 1 <<  2,
    UIControlEventTouchDragOutside                                  = 1 <<  3,
    UIControlEventTouchDragEnter                                    = 1 <<  4
}UIControlEvents;

int main(){
    UIControlEvents events = UIControlEventTouchDown | UIControlEventTouchDownRepeat;
    if (events & UIControlEventTouchDown){
        NSLog(@"UIControlEventTouchDown");
    }
    NSLog(@"enum test: %lu",events);
    return events;
}
main();
```

**Tips:** 

推荐新建一个文件来放置以上代码，类似于OCRunnerDemo中的UIKitRefrence和GCDRefrence文件，然后使用**PatchGenerator**以**-links**的形式加入补丁生成。作者想偷偷懒，不想再去CV了，头文件太多了😭.



### 使用系统内置C函数

```objc
//you only need to add the C function declaration in Script.
//link NSLog
void NSLog(NSString *format, ...);

//then you can use it in Scrtips.
NSLog(@"test for link function %@", @"xixi");
```

当你运行以上代码时. OCRunner将会使用`ORSearchedFunction` 搜索函数的指针. 

这个过程的核心实现是 `SymbolSearch` (修改自`fishhook`).

如果搜索到的结果是NULL，OCRunner将会自动在控制台打印如下信息:

```objc
|----------------------------------------------|
|❕you need add ⬇️ code in the application file |
|----------------------------------------------|
[ORSystemFunctionTable reg:@"dispatch_source_set_timer" pointer:&dispatch_source_set_timer];
```



### 修复OC对象（类）方法、添加属性

> 小天才英语学习机，不会哪里点哪里

想修复哪个方法，将改方法实现即可，不用实现其他方法.


```objc
@interface ORTestClassProperty:NSObject
@property (nonatomic,copy)NSString *strTypeProperty;
@property (nonatomic,weak)id weakObjectProperty;
@end
@implementation ORTestClassProperty
- (void)otherMethod{
    self.strTypeProperty = @"Mango";
}
- (NSString *)testObjectPropertyTest{
  	[self ORGtestObjectPropertyTest] //方法名前加'ORG'调用原方法
    [self otherMethod];
    return self.strTypeProperty;
}
@end
```



### Block使用、解决循环引用

```objc
// 用于解决循环引用
__weak id object = [NSObject new];
// 最简block声明
void (^a)(void) = ^{
    int b = 0;
};
a();
```



### 使用GCD

本质就是 **使用系统内置C函数**，通过**GCDRefrences**文件添加，GCD相关的函数声明以及typedef皆在其中.

比如:

```objc
// link dispatch_sync
void dispatch_sync(dispatch_queue_t queue, dispatch_block_t block);
void main(){
  dispatch_queue_t queue = dispatch_queue_create("com.plliang19.mango",DISPATCH_QUEUE_SERIAL);
	dispatch_async(queue, ^{
   	completion(@"success");
	});
}
main();
```



### 使用内联函数、预编译函数

```objc
// 内联函数：在补丁中，添加一个全局函数中即可，比如UIKitRefrences中的CGRectMake
CGRect CGRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height)
{
  CGRect rect;
  rect.origin.x = x; rect.origin.y = y;
  rect.size.width = width; rect.size.height = height;
  return rect;
}
// 预编译函数：需要在App中预埋
[[MFScopeChain top] setValue:[MFValue valueWithBlock:^void(dispatch_once_t *onceTokenPtr,
                                                                  dispatch_block_t _Nullable handler){
        dispatch_once(onceTokenPtr,handler);
    }] withIndentifier:@"dispatch_once"];
```



### 如何确定补丁中是否包含源文件

![1](https://raw.githubusercontent.com/SilverFruity/silverfruity.github.io/server/source/_posts/OCRunner/OCRunner_2.jpeg)

查看Run Script打印的 **InputFiles** 中是否包含源文件.




## 性能测试

### 加载时间

![2](https://silverfruity.github.io/2020/09/04/OCRunner/OCRunner_1.jpeg)

### 执行速度和内存占用

设备：iPhone SE2 , iOS 14.2,  Xcode 12.1.

以经典的斐波那契数列函数作为例子，求第25项的值的测试结果.

#### JSPatch

* 执行时间，平均时间为0.169s

  ![](./ImageSource/JSPatchTimes.png)

* 内存占用，一直稳定在12MB左右


![](./ImageSource/JSPatchMemory.png)

#### OCRunner
* 执行时间，平均时间为1.05s

  ![](./ImageSource/OCRunnerTimes.png)

* 内存占用，峰值为60MB左右


![](./ImageSource/OCRunnerMemory.png)

#### Mango
* 执行时间，平均时间为2.38s。

  ![](./ImageSource/MangoTimes.png)

* 内存占用，持续走高，最高的时候大约为350MB。


![](./ImageSource/MangoMemory.png)

* 目前递归方法调用的速度，大约为JSPatch的1/5倍，为MangoFix的2.5倍左右。
* OCRunner的补丁加载速度是Mango的10倍+，随着补丁大小的不断增加，这个倍数会不断增加，针对JSPatch，目前未知。
* 关于递归方法调用时的内存占用，目前存在占用过大的问题。求斐波那契数列数列第30项的时候，Mango会爆内存，OCRunner内存峰值占用大概在600MB。



## 目前的问题

1. 指针与乘号识别冲突问题，衍生的问题：类型转换等等
2. 不支持static、inline函数声明
3. 不支持C数组声明:  type a[]和type a[2]，以及 value = { 0 , 0 , 0 , 0 } 这种表达式
4. 不支持 ‘->’ 操作符号
5. 不支持C函数替换

## 感谢
* 贡献者：[@jokerwking](https://github.com/jokerwking)
* [Mango](https://github.com/YPLiang19/Mango)
* [libffi](https://github.com/libffi/libffi)
* Procedure Call Standard for the ARM 64-bit Architecture. 


## 支持语法
1. 类声明与实现，支持分类写法
3. Protocol
4. Block语法
4. 结构体、枚举、typedef
5. 使用函数声明，链接系统函数指针
6. 全局函数
7. 多参数调用（方法和函数）
8. **\***、**&**  (指针操作)
9. 变量static关键字
9. NSArray: @[value1, value2]，NSDictionary: @{ key: value },  NSNumer:  @(value)
10. NSArray取值和NSDictionary取值和赋值语法，id value = a[var];  a[var] = value;
11. [运算符，除去'->'皆已实现](https://baike.baidu.com/item/%E8%BF%90%E7%AE%97%E7%AC%A6%E4%BC%98%E5%85%88%E7%BA%A7/4752611?fr=aladdin)

... 等


## 目标

* 完善当前的语法支持
* 更多的单元测试覆盖（尽管目前显示是84%）
* PatchGenerator阶段进行优化：未被调用的函数声明、结构体、枚举等，不会在补丁中，减少包大小以及加载时间等
* 尝试Swift热更新（新建库吧，哈哈）
