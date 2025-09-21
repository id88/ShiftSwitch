# ShiftSwitch

[![Build Status](https://github.com/id88/ShiftSwitch/workflows/Build%20and%20Release%20ShiftSwitch/badge.svg)](https://github.com/id88/ShiftSwitch/actions)
[![Release](https://img.shields.io/github/v/release/id88/ShiftSwitch)](https://github.com/id88/ShiftSwitch/releases)
[![License](https://img.shields.io/github/license/id88/ShiftSwitch)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-15.3%2B-blue)](https://www.apple.com/macos/)

一个高效的macOS键盘输入法切换工具，让您通过单独按下Shift键来切换中英文输入法，同时修正Caps Lock键的行为。

> **🎯 核心功能**：Shift键切换输入法 + Caps Lock纯大小写控制

## 功能特点

### 🔄 智能输入法切换
- **单独按下Shift键**：快速切换中英文输入法
- **组合键保持不变**：`Shift + 字母` 仍然正常输出大写字母
- **动态识别输入法**：自动检测系统已启用的中文和英文输入法

### 🔐 Caps Lock行为修正
- **纯粹大小写切换**：Caps Lock键仅控制英文字母的大小写
- **阻止输入法切换**：移除Caps Lock键的默认输入法切换功能
- **指示灯同步**：Caps Lock指示灯状态与系统大小写状态同步

### 🎯 后台运行
- **状态栏菜单**：简洁的状态栏控制界面
- **低资源占用**：内存占用少于10MB
- **快速响应**：按键响应延迟小于5ms

## 📥 快速安装

### 下载发布版本（推荐）

1. 前往 [Releases](https://github.com/id88/ShiftSwitch/releases) 页面
2. 下载最新版本的 `ShiftSwitch.dmg`
3. 双击打开，将应用拖拽到应用程序文件夹

> ⚠️ **重要提示**: 由于应用未经过 Apple 官方签名，首次运行时 macOS 可能显示"应用已损坏"警告。
> 
> **解决方法**: 右键点击应用选择"打开"，或查看 [代码签名指南](.github/CODE_SIGNING.md) 了解详细解决方案。
4. 首次运行时授予辅助功能权限

### 自动构建版本

我们的 GitHub Actions 会自动构建每个版本，确保代码质量和兼容性。

## 系统要求

- **操作系统**：macOS 15.3 (Sequoia) 或更高版本
- **处理器**：Apple Silicon 或 Intel 处理器
- **权限**：辅助功能权限

## 📦 编译安装

### 方法一：使用发布脚本（推荐）
```bash
# 克隆项目
git clone https://github.com/id88/ShiftSwitch.git
cd ShiftSwitch

# 使用发布脚本编译
./scripts/release.sh v1.0.0
```

### 方法二：手动编译
```bash
# 克隆项目
git clone https://github.com/id88/ShiftSwitch.git
cd ShiftSwitch

# 编译应用
xcodebuild -scheme ShiftSwitch -configuration Release -derivedDataPath ./build clean build

# 安装应用
sudo cp -R ./build/Build/Products/Release/ShiftSwitch.app /Applications/
```

## ⚙️ 权限设置

首次运行时，应用会自动提示您授予必要权限：

### 辅助功能权限（必需）
1. 前往 `系统偏好设置` → `隐私与安全性` → `辅助功能`
2. 点击 `🔒` 解锁（需要管理员密码）
3. 点击 `+` 按钮添加 ShiftSwitch 应用
4. 确保 ShiftSwitch 开关处于 `✅ 开启` 状态

### 设置开机启动（可选）
1. 前往 `系统偏好设置` → `用户与群组` → `登录项`
2. 点击 `+` 添加 ShiftSwitch.app
3. 选择 `隐藏` 选项，应用将在后台启动

## 🚀 开始使用

启动 ShiftSwitch 后：
- 应用将以后台模式运行
- 状态栏显示 ⌨️ 图标
- 点击图标查看菜单选项
- 开始享受高效的输入法切换体验！

## 使用方法

### Shift键切换输入法
1. **单独按下左Shift或右Shift键**
2. **在0.05-0.5秒内释放**
3. **期间不按下其他任何键**
4. 输入法将自动在中英文之间切换

### Caps Lock键控制大小写
- **按下Caps Lock键**：切换英文字母大小写状态
- **不会触发输入法切换**：保持当前输入法不变
- **指示灯反馈**：键盘指示灯显示当前大小写状态

### 状态栏菜单
- **ShiftSwitch 正在运行**：显示应用状态
- **检查权限**：验证辅助功能权限状态
- **退出**：安全退出应用

## 技术实现

### 核心技术
- **IOKit框架**：创建全局键盘事件钩子
- **Carbon TIS API**：实现输入法管理和切换
- **Cocoa NSStatusBar**：状态栏界面
- **Swift 5语法**：现代Swift开发

### 权限管理
- **AXIsProcessTrustedWithOptions**：检查辅助功能权限
- **自动权限提示**：引导用户授予必要权限
- **优雅降级**：权限不足时给出明确提示

### 性能优化
- **事件过滤**：只处理必要的键盘事件
- **异步处理**：输入法切换在主队列异步执行
- **内存管理**：正确的CFObject内存管理
- **资源释放**：应用退出时清理所有资源

## 故障排除

### 应用提示"已损坏"无法打开
这是因为应用未经过Apple官方签名导致的macOS安全限制。

**解决方法**:
1. **右键打开**: 右键点击应用选择"打开"（推荐）
2. **自动修复脚本**: 下载并运行 `scripts/fix-codesign.sh`
3. **手动命令**: `sudo xattr -rd com.apple.quarantine /Applications/ShiftSwitch.app`
4. **详细指南**: 查看 [代码签名指南](.github/CODE_SIGNING.md)

### 应用无法启动
1. 检查macOS版本是否符合要求
2. 确保已授予辅助功能权限
3. 重启应用或重新授权

### Shift键切换不工作
1. 确认权限设置正确
2. 检查按键时间（0.05-0.5秒）
3. 确保期间未按下其他键
4. 查看状态栏菜单检查权限状态

### Caps Lock键仍然切换输入法
1. 确认应用正在运行（状态栏有图标）
2. 重启应用
3. 检查系统键盘设置

### 输入法识别错误
- 应用动态识别系统已启用的输入法
- 支持常见的中文输入法：SCIM、拼音、五笔等
- 支持英文布局：ABC、US等

## 🔧 开发信息

### 项目结构
```
ShiftSwitch/
├── .github/workflows/           # GitHub Actions 工作流
│   ├── build.yml               # 主要构建和发布流程
│   ├── test.yml                # 测试构建流程
│   └── README.md               # 工作流说明
├── scripts/
│   └── release.sh              # 发布脚本
├── ShiftSwitch/
│   ├── ShiftSwitchApp.swift    # 主应用文件
│   ├── ShiftSwitch.entitlements # 权限配置
│   └── Assets.xcassets/        # 应用资源
├── ShiftSwitch.xcodeproj/      # Xcode项目文件
├── exportOptions.plist         # 导出配置
└── README.md                   # 项目说明
```

### 核心组件
- **DebugLogger**：调试日志管理，支持不同级别的日志输出
- **InputSourceManager**：输入法管理和切换，支持动态识别系统输入法
- **KeyboardMonitor**：键盘事件监听和处理，包含权限检查和自动恢复
- **AppDelegate**：应用生命周期和状态栏管理

### GitHub Actions 自动化

我们使用 GitHub Actions 提供：
- ✅ **自动构建**：每次推送代码时自动编译
- ✅ **自动测试**：运行测试确保代码质量
- ✅ **自动发布**：创建标签时自动生成 DMG 和 ZIP 包
- ✅ **持续集成**：确保每个版本都能正常编译运行

### 发布流程

1. **开发**：在功能分支开发新功能
2. **测试**：创建 Pull Request，自动运行测试
3. **合并**：合并到主分支
4. **发布**：创建版本标签，自动构建发布包
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

### 本地开发

```bash
# 克隆项目
git clone https://github.com/id88/ShiftSwitch.git
cd ShiftSwitch

# 在 Xcode 中打开
open ShiftSwitch.xcodeproj

# 或使用命令行编译
xcodebuild -scheme ShiftSwitch -configuration Debug build
```

### 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 📄 许可证

本项目遵循 [MIT 许可证](LICENSE)。

## 🙋‍♂️ 支持与反馈

### 问题报告
- 🐛 [报告 Bug](https://github.com/id88/ShiftSwitch/issues/new?template=bug_report.md)
- 💡 [功能建议](https://github.com/id88/ShiftSwitch/issues/new?template=feature_request.md)

### 联系方式
- 📧 Email: 
- 💬 Discussions: [GitHub Discussions](https://github.com/id88/ShiftSwitch/discussions)

---

**⭐ 如果这个项目对您有帮助，请给我们一个星标！**
