---
name: ue-general-norms
description: UE C++编程规范技能，用于在处理UE C++相关任务时遵循特定的编程规范。当用户需要在UE C++下执行某个需求时遵循以下条件：1. 没特殊说明情况下，一律创建符合用户要求的函数，不要在BeginPlay()和tick()里写任何代码，用户要求每帧实现的功能除外；2. 默认情况下不要添加bool参数来控制函数的调用，除非是功能必需；3. 用户没特殊强调时，默认函数均暴露至蓝图里；此外，当需要token调用时优先参考UE官方文档网址：https://dev.epicgames.com/documentation/zh-cn/unreal-engine/unreal-engine-5-4-documentation?application_version=5.4里相关内容；ue的任何代码均不要测试，交给用户自行测试
---

# UE C++ 编程规范技能

## 概述

本技能提供UE C++编程的基础规范和最佳实践，确保代码质量和一致性。

## 核心规范

### 1. 函数设计原则

- 无特殊说明时，所有功能都应封装为独立函数
- 避免在BeginPlay()和Tick()中直接编写业务代码（用户要求每帧实现的功能除外）
- 函数应具有明确的单一职责
- 保持函数简洁，避免过长的函数体

### 2. 参数设计规范

- 默认情况下不要添加bool参数来控制函数的调用
- 除非功能必需（如开关某种行为），否则避免使用bool参数
- 复杂的条件逻辑应通过多态或策略模式实现

### 3. 蓝图暴露规范

- 用户未特殊强调时，所有函数默认暴露至蓝图
- 使用`UFUNCTION(BlueprintCallable)`宏暴露函数
- 使用`UPROPERTY(EditAnywhere, BlueprintReadWrite)`暴露属性
- 为蓝图可见的函数和属性提供清晰的注释

### 4. 文档参考规范
- 优先参考本地源码，具体参考references/engineCode.md
- 其次参考UE 5.4官方文档：https://dev.epicgames.com/documentation/zh-cn/unreal-engine/unreal-engine-5-4-documentation?application_version=5.4
- 遇到不确定的API或功能时，先查阅官方文档
- 官方文档未覆盖的内容，可参考社区最佳实践
- 最后才搜索网上信息

### 5. 代码测试规范

- UE的任何代码均不需要测试，交给用户自行测试，不要编译项目！！！
- 确保代码语法正确，符合UE C++规范即可
- 如果需要示例代码，提供完整的可编译代码片段

## 代码示例

### 正确的函数设计

```cpp
// 正确：将功能封装为独立函数并暴露至蓝图
UFUNCTION(BlueprintCallable, Category = "Custom")
void InitializeGameState();

UFUNCTION(BlueprintCallable, Category = "Custom")
void SpawnPlayer(FVector SpawnLocation, FRotator SpawnRotation);
```

### 避免的做法

```cpp
// 避免：在BeginPlay()中直接写业务代码
void AMyActor::BeginPlay()
{
    Super::BeginPlay();
    // 业务代码...
    InitializeGameState();
    SpawnPlayer(FVector::ZeroVector, FRotator::ZeroRotator);
}

// 避免：添加不必要的bool参数
UFUNCTION(BlueprintCallable, Category = "Custom")
void SpawnPlayer(FVector SpawnLocation, FRotator SpawnRotation, bool bShouldSpawn);
```

## 使用场景

本技能适用于以下场景：

- 创建新的UE C++类和函数
- 重构现有的UE C++代码
- 回答UE C++相关的技术问题
- 提供UE C++代码示例

## 质量检查

- 函数是否有明确的单一职责？
- 是否避免了在BeginPlay()和Tick()中直接写业务代码？
- 是否添加了不必要的bool参数？
- 函数是否正确暴露至蓝图？
- 是否参考了UE官方文档？
