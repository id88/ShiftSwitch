# 🔒 macOS 代码签名指南

## 问题说明

当您下载并尝试运行 ShiftSwitch.app 时，可能会遇到以下错误：
- "App 已被修改或者已损坏"
- "无法打开，因为无法验证开发者"
- "应用已损坏，无法打开"

这是因为 macOS 的 **Gatekeeper** 安全机制要求应用必须经过代码签名才能运行。

## 🚀 立即解决方案（用户端）

### 方法 1: 右键打开（推荐）

1. 在 `应用程序` 文件夹中找到 `ShiftSwitch.app`
2. **右键点击** 应用图标
3. 选择 **"打开"**
4. 在弹出的对话框中点击 **"打开"**

![右键打开示意图](https://support.apple.com/library/content/dam/edam/applecare/images/en_US/macos/Big-Sur/macos-big-sur-gatekeeper-right-click-open.jpg)

### 方法 2: 终端命令

```bash
# 移除应用的隔离属性
sudo xattr -rd com.apple.quarantine /Applications/ShiftSwitch.app

# 或者移除所有扩展属性
sudo xattr -c /Applications/ShiftSwitch.app
```

### 方法 3: 系统设置

1. 尝试双击打开应用（会失败并显示错误）
2. 立即前往 `系统偏好设置` → `隐私与安全性`
3. 在 **"安全性"** 部分找到关于 ShiftSwitch 的提示
4. 点击 **"仍要打开"** 按钮

## 🛠️ 开发者解决方案

### Ad-hoc 签名（当前方案）

我们在 GitHub Actions 中添加了 ad-hoc 签名：

```bash
# 执行 ad-hoc 签名
codesign --force --deep --sign - ShiftSwitch.app
```

**优点：**
- ✅ 免费，无需开发者账户
- ✅ 减少 Gatekeeper 警告
- ✅ 自动化构建

**缺点：**
- ⚠️ 用户仍需手动允许运行
- ⚠️ 无法通过 App Store 分发
- ⚠️ 无法使用系统级权限

### Apple Developer 签名（完整方案）

如果您有 Apple Developer 账户（$99/年），可以进行完整签名：

#### 1. 准备证书

```bash
# 在 Keychain Access 中导出证书
security find-identity -v -p codesigning

# 导出为 .p12 文件
security export -k login.keychain -t identities -f pkcs12 -o cert.p12
```

#### 2. 配置 GitHub Secrets

在 GitHub 仓库设置中添加：
- `MACOS_CERTIFICATE`: Base64 编码的 .p12 证书
- `MACOS_CERTIFICATE_PWD`: 证书密码
- `MACOS_NOTARIZATION_APPLE_ID`: Apple ID
- `MACOS_NOTARIZATION_TEAM_ID`: Team ID
- `MACOS_NOTARIZATION_PWD`: App-specific password

#### 3. 修改 GitHub Actions

```yaml
- name: Import Code-Signing Certificates
  uses: Apple-Actions/import-codesign-certs@v1
  with:
    p12-file-base64: ${{ secrets.MACOS_CERTIFICATE }}
    p12-password: ${{ secrets.MACOS_CERTIFICATE_PWD }}

- name: Sign Application
  run: |
    codesign --force --options runtime --deep --sign "Developer ID Application: Your Name" ShiftSwitch.app

- name: Notarize Application
  uses: Apple-Actions/notarize-app@v1
  with:
    product-path: ShiftSwitch.app
    primary-bundle-id: com.yourcompany.shiftswitch
    apple-id: ${{ secrets.MACOS_NOTARIZATION_APPLE_ID }}
    password: ${{ secrets.MACOS_NOTARIZATION_PWD }}
    team-id: ${{ secrets.MACOS_NOTARIZATION_TEAM_ID }}
```

### 本地签名

如果您在本地构建：

```bash
# 查看可用的签名身份
security find-identity -v -p codesigning

# 使用开发者证书签名
codesign --force --options runtime --deep --sign "Developer ID Application: Your Name" ShiftSwitch.app

# 验证签名
codesign --verify --verbose ShiftSwitch.app

# 检查签名信息
codesign -dv ShiftSwitch.app
```

## 📋 签名状态检查

检查应用的签名状态：

```bash
# 基本签名信息
codesign -dv /Applications/ShiftSwitch.app

# 详细签名信息
codesign -dvvv /Applications/ShiftSwitch.app

# 验证签名有效性
codesign --verify --verbose /Applications/ShiftSwitch.app

# 检查 Gatekeeper 状态
spctl -a -v /Applications/ShiftSwitch.app
```

## 🔍 常见问题

### Q: 为什么需要代码签名？
A: macOS 的 Gatekeeper 要求所有应用都必须签名，以防止恶意软件。

### Q: Ad-hoc 签名安全吗？
A: 是的，ad-hoc 签名确保应用未被篡改，但不验证开发者身份。

### Q: 如何避免每次都需要右键打开？
A: 使用 Apple Developer 账户进行完整签名和公证。

### Q: 可以禁用 Gatekeeper 吗？
A: 不推荐，会降低系统安全性。正确的做法是对应用进行签名。

## 📚 参考链接

- [Apple 代码签名指南](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Gatekeeper 用户指南](https://support.apple.com/en-us/HT202491)
- [代码签名最佳实践](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow)

## 💡 贡献

如果您有 Apple Developer 账户并愿意帮助改进签名流程，欢迎提交 PR！
