# 第三方声明（NOTICE）

## MG Linker（Apache License 2.0）

本项目「上汽云端」数据源参考了 MG Linker 公开的接口信息：

- 接口地址：`https://mp.ebanma.com/app-mp/vp/1.1/getVehicleStatus`
- 请求参数：`timestamp` / `token` / `vin`
- 响应字段结构：车辆位置、车辆数值、车辆状态（胎压、温度、电量、油量、门锁等）

来源仓库：<https://gitee.com/yangyachao-X/mg-linker>
著作权归原作者（yangyachao-X）所有，依据 **Apache License 2.0** 使用。

本项目的实现为 Swift 重新编写，未复制其 Kotlin 源码文件；
Apache License 2.0 全文见 <https://www.apache.org/licenses/LICENSE-2.0>。

## MGControl

仅参考其公开 README 中描述的功能清单（车况卡片覆盖的字段范围），
未使用其任何代码、资源或设计（其源码与设计原稿不公开）。
