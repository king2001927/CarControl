# CarControl 构建指南

原创 SwiftUI 演示项目：**短信验证码登录 + 桌面小组件 + 车况卡片**。
从零写给你，与 MGControl 没有任何代码关系（其源码本身也不公开）。

> ⚠️ 说明：这套源码是在你的手机环境里生成的，**我没法替你 push 到 GitHub、
> 也没法替你登录 Apple 开发者账号**。本指南把「仓库传上去 → 一键出 IPA」的
> 每一步都写清楚了，照着做即可。

## 目录结构

```
CarControlApp/                  ← 这就是仓库根目录，整个文件夹传到 GitHub
├── project.yml                     XcodeGen 项目描述（一条命令生成 .xcodeproj）
├── .gitignore
├── .github/workflows/build-ipa.yml ★ GitHub Actions 构建流程
├── CarControl/                 ← 主 App 源码
│   ├── CarControlApp.swift        App 入口
│   ├── AppConstants.swift         ★ App Group / URL Scheme / bundle id 常量
│   ├── Models.swift               数据模型（App 与小组件共享）
│   ├── AuthProvider.swift         登录抽象协议
│   ├── MockAuthProvider.swift     演示登录（验证码 123456）
│   ├── FirebaseAuthProvider.swift 真实短信（加 Firebase SDK 后自动启用）
│   ├── AuthManager.swift          会话管理
│   ├── SharedStore.swift          ★ App ↔ 小组件共享通道
│   ├── VehicleService.swift       车况数据源（演示为模拟数据）
│   ├── AppSettings.swift / Theme.swift
│   ├── LoginView.swift / HomeView.swift / SettingsView.swift
│   └── CarControl.entitlements    App Group 权限
├── CarControlWidget/           ← 小组件扩展源码
│   ├── CarControlWidgetBundle.swift / WidgetProvider.swift / CarStatusWidgetView.swift
│   └── CarControlWidget.entitlements
└── server/                     ← （可选）自建短信后端模板
```

`Info.plist` 文件由 XcodeGen 自动生成，不用手写、不用提交。

## 两条构建路线

| 路线 | 需要什么 | 得到什么 |
| --- | --- | --- |
| **A. GitHub Actions（云端）** | 一个 GitHub 仓库；（可选）付费开发者账号的证书 | 签名 IPA（付费账号）/ 未签名 IPA |
| **B. 本地 Mac + Xcode** | Mac + Xcode 15+，Apple ID（免费即可） | 直接装到自己手机（免费账号 7 天重签一次） |

**关键结论**：IPA 能不能装到普通 iPhone 上，只取决于签名——

- **付费开发者账号（99 美元/年）**：路线 A 可全自动产出可安装 IPA；
- **免费 Apple ID**：CI 无法替免费账号签名（免费签名只在本地 Xcode 有效），
  CI 只能产出**未签名 IPA**（仅 TrollStore / 越狱设备可装）；
  要装普通手机请走路线 B。

---

# 路线 A：GitHub Actions 云端构建

## A1. 把仓库传到 GitHub

**方式一（网页上传，最简单）**

1. 电脑浏览器打开 github.com → 右上角 **+ → New repository**，
   名称填 `CarControl`，选 **Public**（公开仓库 Actions 免费额度充足），
   不勾 README，点 Create。
2. 进仓库主页 → **uploading an existing file**（或 Add file → Upload files）。
3. 把 `CarControlApp` 文件夹里的**所有内容**（包括 `.github`、`project.yml` 等
   隐藏文件）拖进网页，点 Commit changes。

**方式二（git 命令行）**

```bash
cd CarControlApp
git init
git add .
git commit -m "CarControl: SwiftUI app with widget and SMS login"
git branch -M main
git remote add origin https://github.com/你的用户名/CarControl.git
git push -u origin main
```

> 注意：`.gitignore` 已排除 .xcodeproj 和构建产物，只上传源码和配置。
> 推完后如果文件被漏传（比如 .github 没传上去），检查隐藏文件是否被系统过滤。

## A2. 直接构建（未签名，先验证流水线通不通）

1. 仓库页面 → **Actions** 标签 → 左侧 **Build IPA** → 右侧 **Run workflow** → 绿色按钮确认。
2. 等约 10–15 分钟（首次要装 XcodeGen + 编译）。
3. 完成后点进那次 run，底部 **Artifacts** 下载 `CarControl-IPA-unsigned.zip`，
   里面是未签名 IPA。

> 未签名 IPA **普通 iPhone 装不上**（仅 TrollStore / 越狱设备可装）。
> 这一步的价值是：确认流水线、代码、XcodeGen 配置全部正确。

## A3. 配置签名（付费开发者账号，产出可安装 IPA）

需要 6 个 Secrets。先到 Apple 开发者后台准备材料：

### 3.1 注册 App ID 和 App Group

打开 [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles**：

1. **Identifiers → App IDs → +**：
   - 注册 `com.example.carcontrol`（建议换成你自己的域名格式）；
   - 再注册 `com.example.carcontrol.widget`；
   - 两个 App ID 的 Capabilities 里都勾 **App Groups**。
2. **Identifiers → App Groups → +**：新建 `group.com.example.carcontrol`，
   把上面两个 App ID 加进这个组。
   （这个名字必须和 `CarControl/AppConstants.swift` 里 `appGroupID` 一致。）

### 3.2 注册设备

**Devices → +**：填你手机的 UDID（用电脑打开 Xcode → Window → Devices and
Simulators，连上手机后复制 Identifier；或爱思助手等工具查看）。

### 3.3 导出签名证书 .p12

1. **Certificates → + → Apple Distribution**：按提示在 Mac 钥匙串里生成 CSR，
   上传后下载 .cer，双击安装进钥匙串。
2. 打开**钥匙串访问**，找到那张证书（带私钥），右键 → **导出「Apple Distribution: ...」**，
   格式选 .p12，设置一个密码，保存为 `cert.p12`。

### 3.4 创建两个描述文件

**Profiles → + → Ad Hoc**，共做两个：

| 描述文件 | 关联 App ID | 命名（务必一致） |
| --- | --- | --- |
| 主 App | `com.example.carcontrol` | `CarControl CI` |
| 小组件 | `com.example.carcontrol.widget` | `CarControl CI` |

都勾选你的 Distribution 证书和刚才注册的设备，下载两个 `.mobileprovision`。
（两个文件名字相同没问题，CI 会按 bundle id 自动匹配。）

### 3.5 添加 Secrets

仓库 → **Settings → Secrets and variables → Actions → New repository secret**，
逐条添加：

| Secret 名 | 内容 |
| --- | --- |
| `TEAM_ID` | 10 位团队 ID（开发者后台右上角 Membership 可见） |
| `CERT_P12_BASE64` | `cert.p12` 的 base64（Mac 终端：`base64 -i cert.p12` 后复制整段） |
| `CERT_PASSWORD` | 导出 .p12 时设置的密码 |
| `PROFILE_APP_BASE64` | 主 App `.mobileprovision` 的 base64 |
| `PROFILE_WIDGET_BASE64` | 小组件 `.mobileprovision` 的 base64 |

### 3.6 重新构建

Actions → Build IPA → Run workflow。这次产出 **`CarControl-IPA`**（已签名的
Ad Hoc IPA），下载后可以直接侧载安装（爱思助手 / Sideloadly / AltStore 均可）。

## A4. 改 bundle id 时要同步改的地方

- `project.yml`：两个 `PRODUCT_BUNDLE_IDENTIFIER`
- `.github/workflows/build-ipa.yml`：`APP_BUNDLE_ID` / `WIDGET_BUNDLE_ID`（env 里）
- `CarControl/CarControl.entitlements` 与 `CarControlWidget/CarControlWidget.entitlements`：App Group 名
- `CarControl/AppConstants.swift`：`appGroupID`
- Apple 后台的 App ID / App Group / 描述文件也要对应重建

> 自用建议：bundle id 全换成你自己的前缀，避免和 App Store 上同名应用冲突。

---

# 路线 B：本地 Mac + Xcode

1. **brew install xcodegen**（没有 Homebrew 就先去 brew.sh 装）。
2. 在仓库根目录执行 **`xcodegen generate`**，生成 `CarControl.xcodeproj`。
3. 双击打开工程：两个 target 的 **Signing & Capabilities → Team** 选你的
   Apple ID（免费账号即可，Xcode 会管理 7 天签名）。
4. 插上手机，顶部选你的 iPhone，**Run**。
5. 登录页输手机号 → 获取验证码 → 输入 **123456**（演示模式，页面有提示）。
6. 桌面长按 → 左上角 **+** → 搜 **CarControl** 添加小组件；App 里刷新车况后小组件跟着变。

---

# 演示模式与真实登录

- **演示登录**：验证码固定 `123456`，不联网。默认开启。
- **接 Firebase 真短信**（无需服务器）：
  1. 在 `project.yml` 里给主 App target 加 Firebase 的 SPM 包（FirebaseAuth）；
  2. 加 `GoogleService-Info.plist`；控制台开启 Phone Auth；
  3. `FirebaseAuthProvider` 检测到 SDK 后**自动启用**，无需改业务代码。
  国内访问 Google 服务可能不稳定，收不到短信就换自建后端。
- **自建后端**（`server/server.js` 模板）：接口协议见 server/README.md；
  iOS 侧仿照 FirebaseAuthProvider 写一个实现 `AuthProvider` 协议的类即可。
  国内短信需域名备案 + 阿里云签名/模板审核。

# 常见问题

| 现象 | 处理 |
| --- | --- |
| Actions 里 xcodegen 报错「widget 类型无效」 | 把 `project.yml` 里小组件 `type: extensionkit-extension` 改成 `app-extension` 再试 |
| 签名构建报「profile 不匹配」 | bundle id / App Group 与描述文件不一致；确认两个描述文件都命名为 `CarControl CI`、App ID 都勾了 App Groups |
| 安装时提示「无法验证 App」 | 免费账号 7 天过期要重签；Ad Hoc 包确认手机 UDID 在描述文件里 |
| 小组件一直显示「打开 App 同步车况」 | App Group 名称两端不一致，或 SharedStore 未编译进小组件 target |
| 未签名包想装普通手机 | 不行。要么付费账号配 Secrets 走签名构建，要么本地 Xcode 路线 |
| 私有仓库 Actions 额度告急 | macOS 按 10 倍计费分钟折算；改用 Public 仓库（源码本来就是演示项目）或本地构建 |

# 法律与安全提醒

- 车况为**模拟数据**；接入真实车辆请只用你合法获得的接口（官方开放 API、
  OBD 设备、自建车联网），本项目不包含任何车厂私有协议实现。
- 验证码、令牌、钥匙不进代码仓库；正式项目的登录会话存 Keychain。
- `.p12` 和描述文件是你的签名身份凭证，**绝不能提交进仓库或发给别人**，
  只放 Secrets。
