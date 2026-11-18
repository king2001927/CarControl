# CarControl

原创 SwiftUI 演示项目：**短信验证码登录 + 桌面小组件 + 车况卡片**，最低支持 iOS 16。

> 演示项目：车辆数据为本地模拟，登录默认走演示验证码（123456）。
> 接入真实车辆数据请使用你合法获得的接口（官方开放 API、OBD 设备、自建车联网）。

## 一键构建 IPA（GitHub Actions）

1. 仓库 **Actions** → **Build IPA** → **Run workflow**；
2. 等约 10–15 分钟，在运行页面底部 **Artifacts** 下载 IPA。

- 未配置签名 Secrets 时产出**未签名 IPA**（仅 TrollStore / 越狱设备可装）；
- 配置付费开发者账号的证书后自动产出**可安装的签名 IPA**。

完整说明（含签名 Secrets 配置、本地构建、Firebase 真短信、自建短信后端）
见 [README-构建指南.md](README-构建指南.md)。

## 目录

- `CarControl/`：主 App（SwiftUI，登录 / 车况卡片 / 设置）
- `CarControlWidget/`：桌面小组件扩展（小号 / 中号，经 App Group 共享数据）
- `server/`：自建短信验证码后端模板（Node.js + Express）
- `project.yml`：XcodeGen 项目描述（`xcodegen generate` 生成 .xcodeproj）
- `.github/workflows/build-ipa.yml`：云端构建流程

## 本地开发

```bash
brew install xcodegen
xcodegen generate
open CarControl.xcodeproj
```

Xcode 里选你的签名 Team 后直接 Run；演示登录验证码固定 `123456`。

## 许可

本项目代码仅用于个人学习与自用演示；接入车辆服务请遵守相应服务条款。
