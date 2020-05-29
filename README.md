# OCRunner
OCRunner is a DSL using Objective-C syntax，OCRunner is also an iOS App hotfix SDK. You can use OCRunner method replace any Objective-C method.
## Demo运行: 

提示缺少oc2mongoLib.h: 

```shell
cd OCRunner
git submodule update --init --recursive
```
或者 重新clone 

```shell
git clone --recursive https://github.com/SilverFruity/OCRunner.git
```

## 无法识别

类型转换 不能识别：a = (CFString) a; 。 能识别 a = (CFString *) a;

Tips: 尽量不用使用类型转换。

## 自动忽略

@protocol 声明协议

关键字: static, const, enum, struct, typedef,_Nullable, nullable, @required, @optional, @encode等

预编译指令: #define #if 等
