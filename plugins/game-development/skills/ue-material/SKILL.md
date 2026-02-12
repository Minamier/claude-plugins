---
name: ue-material
description: UE材质系统编程规范技能，包含材质创建、属性设置、表达式连接等方面的最佳实践。提供UE 5.4材质系统的编程规范，包括材质属性设置、材质表达式创建和连接、材质实例化等内容。
---

# UE材质系统编程规范

## 概述

本技能提供UE 5.4材质系统的编程规范，包括材质属性设置、材质表达式创建和连接、材质实例化等内容，帮助开发者正确使用UE材质系统API。

## 核心规范

### 1. 材质属性设置

#### 基本属性

- 使用正确的着色模型：对于水效果，使用`MSM_SingleLayerWater`
- 混合模式设置：对于透明材质，使用`BLEND_Translucent`
- 双面渲染：对于透明材质，设置`TwoSided = true`
- 半透明光照模式：对于水效果，使用`TLM_Surface`

#### 材质物理属性

- 材质的物理属性（如Metallic、Specular、Roughness等）不能直接访问，需要通过连接材质表达式来设置
- 使用`GetExpressionInputForProperty()`方法获取属性输入
- 创建对应的常量表达式节点，并连接到属性输入

### 2. 材质表达式创建和连接

#### 表达式类型

- **常量表达式**：`UMaterialExpressionConstant`（单值）、`UMaterialExpressionConstant3Vector`（RGB颜色）
- **数学运算**：`UMaterialExpressionAdd`、`UMaterialExpressionMultiply`、`UMaterialExpressionLinearInterpolate`（Lerp）
- **纹理采样**：`UMaterialExpressionTextureSample`
- **纹理坐标**：`UMaterialExpressionTextureCoordinate`、`UMaterialExpressionPanner`
- **时间**：`UMaterialExpressionTime`
- **菲涅尔效应**：`UMaterialExpressionFresnel`

#### 表达式连接

- 使用`FExpressionInput`结构体连接表达式
- 确保设置正确的OutputIndex（大多数表达式只有一个输出，索引为0）
- 使用`Material->GetExpressionCollection().AddExpression()`添加表达式到材质
- 使用`GetExpressionInputForProperty()`获取属性输入，然后设置Expression和OutputIndex

### 3. 材质实例化

#### 动态材质实例

- 使用`UMaterialInstanceDynamic::Create()`创建动态材质实例
- 支持在运行时修改材质属性
- 适用于需要频繁更改材质的场景

#### 静态材质实例

- 使用`UMaterialInstanceConstant`在编辑器中创建静态材质实例
- 性能更好，但不支持运行时修改

### 4. 材质函数

#### 函数创建

- 使用`UMaterialFunction`创建可重用的材质函数
- 支持输入输出参数定义
- 可以在多个材质中重用

#### 函数调用

- 使用`UMaterialExpressionMaterialFunctionCall`在材质中调用材质函数
- 支持参数传递和返回值

## 最佳实践

### 1. 材质表达式管理

- 为每个表达式设置适当的编辑器坐标（MaterialExpressionEditorX/Y），以便在材质编辑器中可视化
- 使用有意义的变量名，方便代码维护
- 及时释放不再使用的表达式（UE会自动管理，但建议显式处理）

### 2. 性能优化

- 尽量减少复杂数学运算的使用
- 避免在材质中使用昂贵的操作，如纹理采样多次
- 对于复杂效果，考虑使用材质函数或蓝图材质

### 3. 错误处理

- 在创建和操作材质时，始终检查返回值是否有效
- 使用UE_LOG记录错误信息，方便调试
- 对于可能失败的操作，提供适当的错误处理逻辑

## 代码示例

### 创建简单材质

```cpp
UMaterial* CreateSimpleMaterial()
{
	UMaterialFactoryNew* MaterialFactory = NewObject<UMaterialFactoryNew>();
	UMaterial* Material = Cast<UMaterial>(MaterialFactory->FactoryCreateNew(
		UMaterial::StaticClass(),
		nullptr,
		FName(TEXT("SimpleMaterial")),
		EObjectFlags::RF_Standalone | EObjectFlags::RF_Public,
		nullptr,
		GWarn
	));

	if (!Material)
	{
		UE_LOG(LogTemp, Error, TEXT("Failed to create material"));
		return nullptr;
	}

	// 设置材质属性
	Material->SetShadingModel(MSM_DefaultLit);
	Material->BlendMode = BLEND_Opaque;
	Material->TwoSided = false;

	// 创建并连接BaseColor表达式
	UMaterialExpressionConstant3Vector* BaseColorNode = NewObject<UMaterialExpressionConstant3Vector>(Material);
	BaseColorNode->Constant = FLinearColor(0.5f, 0.5f, 0.5f);
	BaseColorNode->MaterialExpressionEditorX = 100;
	BaseColorNode->MaterialExpressionEditorY = 100;
	Material->GetExpressionCollection().AddExpression(BaseColorNode);

	if (FExpressionInput* BaseColorInput = Material->GetExpressionInputForProperty(MP_BaseColor))
	{
		BaseColorInput->Expression = BaseColorNode;
		BaseColorInput->OutputIndex = 0;
	}

	// 保存材质
	Material->PreEditChange(nullptr);
	Material->PostEditChange();
	Material->MarkPackageDirty();

	return Material;
}
```

### 创建水材质

```cpp
UMaterial* CreateWaterMaterial()
{
	UMaterialFactoryNew* MaterialFactory = NewObject<UMaterialFactoryNew>();
	UMaterial* Material = Cast<UMaterial>(MaterialFactory->FactoryCreateNew(
		UMaterial::StaticClass(),
		nullptr,
		FName(TEXT("WaterMaterial")),
		EObjectFlags::RF_Standalone | EObjectFlags::RF_Public,
		nullptr,
		GWarn
	));

	if (!Material)
	{
		UE_LOG(LogTemp, Error, TEXT("Failed to create material"));
		return nullptr;
	}

	// 设置材质属性
	Material->SetShadingModel(MSM_SingleLayerWater);
	Material->BlendMode = BLEND_Translucent;
	Material->TwoSided = true;
	Material->TranslucencyLightingMode = TLM_Surface;

	// 创建常量节点来设置材质属性
	UMaterialExpressionConstant* MetallicNode = NewObject<UMaterialExpressionConstant>(Material);
	MetallicNode->R = 0.8f;
	MetallicNode->MaterialExpressionEditorX = 500;
	MetallicNode->MaterialExpressionEditorY = 200;
	Material->GetExpressionCollection().AddExpression(MetallicNode);

	UMaterialExpressionConstant* SpecularNode = NewObject<UMaterialExpressionConstant>(Material);
	SpecularNode->R = 0.9f;
	SpecularNode->MaterialExpressionEditorX = 500;
	SpecularNode->MaterialExpressionEditorY = 300;
	Material->GetExpressionCollection().AddExpression(SpecularNode);

	UMaterialExpressionConstant* RoughnessNode = NewObject<UMaterialExpressionConstant>(Material);
	RoughnessNode->R = 0.1f;
	RoughnessNode->MaterialExpressionEditorX = 500;
	RoughnessNode->MaterialExpressionEditorY = 400;
	Material->GetExpressionCollection().AddExpression(RoughnessNode);

	UMaterialExpressionConstant3Vector* EmissiveNode = NewObject<UMaterialExpressionConstant3Vector>(Material);
	EmissiveNode->Constant = FLinearColor(0.0f, 0.05f, 0.1f);
	EmissiveNode->MaterialExpressionEditorX = 500;
	EmissiveNode->MaterialExpressionEditorY = 100;
	Material->GetExpressionCollection().AddExpression(EmissiveNode);

	UMaterialExpressionConstant3Vector* BaseColorNode = NewObject<UMaterialExpressionConstant3Vector>(Material);
	BaseColorNode->Constant = FLinearColor(0.0f, 0.1f, 0.2f);
	BaseColorNode->MaterialExpressionEditorX = 500;
	BaseColorNode->MaterialExpressionEditorY = 500;
	Material->GetExpressionCollection().AddExpression(BaseColorNode);

	// 连接材质属性
	if (FExpressionInput* MetallicInput = Material->GetExpressionInputForProperty(MP_Metallic))
	{
		MetallicInput->Expression = MetallicNode;
		MetallicInput->OutputIndex = 0;
	}

	if (FExpressionInput* SpecularInput = Material->GetExpressionInputForProperty(MP_Specular))
	{
		SpecularInput->Expression = SpecularNode;
		SpecularInput->OutputIndex = 0;
	}

	if (FExpressionInput* RoughnessInput = Material->GetExpressionInputForProperty(MP_Roughness))
	{
		RoughnessInput->Expression = RoughnessNode;
		RoughnessInput->OutputIndex = 0;
	}

	if (FExpressionInput* EmissiveInput = Material->GetExpressionInputForProperty(MP_EmissiveColor))
	{
		EmissiveInput->Expression = EmissiveNode;
		EmissiveInput->OutputIndex = 0;
	}

	if (FExpressionInput* BaseColorInput = Material->GetExpressionInputForProperty(MP_BaseColor))
	{
		BaseColorInput->Expression = BaseColorNode;
		BaseColorInput->OutputIndex = 0;
	}

	// 保存材质
	Material->PreEditChange(nullptr);
	Material->PostEditChange();
	Material->MarkPackageDirty();

	return Material;
}
```

## 参考资料

- UE 5.4官方文档：[材质系统](https://dev.epicgames.com/documentation/zh-cn/unreal-engine/unreal-engine-5-4-documentation?application_version=5.4)
- 本地源码路径：F:\UE5.4\UE54\UnrealEngine-5.4.3-release\Engine\Source\Runtime\Engine\Classes\Materials
