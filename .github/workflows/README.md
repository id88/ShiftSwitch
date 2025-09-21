# GitHub Actions 工作流说明

## 工作流文件

### 1. `build.yml` - 主要构建和发布流程

**触发条件：**
- 推送到 `main` 或 `master` 分支
- 创建以 `v` 开头的标签（如 `v1.0.0`）
- Pull Request 到 `main` 或 `master` 分支
- 手动触发（workflow_dispatch）

**功能：**
- ✅ 使用最新稳定版 Xcode 编译应用
- ✅ 创建 DMG 安装包
- ✅ 创建 ZIP 压缩包
- ✅ 上传构建产物作为 Artifacts
- ✅ 自动创建 GitHub Release（当推送标签时）

### 2. `test.yml` - 测试构建流程

**触发条件：**
- 推送到 `develop` 分支或 `feature/*` 分支
- Pull Request 到 `main`、`master` 或 `develop` 分支

**功能：**
- ✅ 快速测试编译
- ✅ 运行单元测试（如果存在）

## 使用方法

### 创建发布版本

1. **提交代码**：
   ```bash
   git add .
   git commit -m "feat: 添加新功能"
   git push origin main
   ```

2. **创建发布标签**：
   ```bash
   # 创建标签
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. **自动构建**：
   - GitHub Actions 将自动触发构建
   - 创建 DMG 和 ZIP 安装包
   - 自动创建 GitHub Release

### 查看构建结果

1. 前往 GitHub 仓库的 **Actions** 标签页
2. 点击最新的工作流运行
3. 下载 **Artifacts** 中的构建产物

### 下载发布版本

1. 前往 GitHub 仓库的 **Releases** 页面
2. 下载最新版本的 `ShiftSwitch.dmg` 或 `ShiftSwitch.zip`

## 配置选项

### 代码签名和公证（可选）

如果您有 Apple 开发者账户，可以配置代码签名和公证：

1. **在 GitHub 仓库设置中添加 Secrets**：
   - `APPLE_ID`: Apple ID
   - `APPLE_PASSWORD`: App-specific password
   - `APPLE_TEAM_ID`: Team ID
   - `DEVELOPER_ID_APPLICATION`: Developer ID Application certificate

2. **修改工作流**：
   - 取消注释 `notarize` job 中的相关步骤
   - 添加代码签名配置

### 自定义构建

可以通过修改 `.github/workflows/build.yml` 来自定义构建过程：

- 更改 Xcode 版本
- 修改构建配置
- 添加自定义构建步骤
- 配置不同的发布渠道

## 故障排除

### 常见问题

1. **构建失败**：
   - 检查 Xcode 项目配置
   - 确保所有依赖项都已正确设置
   - 查看 Actions 日志了解详细错误信息

2. **DMG 创建失败**：
   - `create-dmg` 工具可能需要特定的图标文件
   - 工作流包含了容错处理，会尝试简化的 DMG 创建

3. **权限问题**：
   - 确保 `GITHUB_TOKEN` 有足够的权限
   - 检查仓库设置中的 Actions 权限

### 调试技巧

1. **本地测试**：
   ```bash
   # 模拟 GitHub Actions 环境
   act -j build
   ```

2. **查看详细日志**：
   - 在 GitHub Actions 中启用调试日志
   - 添加 `ACTIONS_STEP_DEBUG: true` 到环境变量

3. **手动触发**：
   - 使用 `workflow_dispatch` 手动触发构建
   - 便于测试和调试

## 版本管理建议

### 语义化版本控制

使用语义化版本号：
- `v1.0.0` - 主要版本
- `v1.1.0` - 次要版本（新功能）
- `v1.1.1` - 补丁版本（bug修复）

### 分支策略

- `main/master` - 稳定版本
- `develop` - 开发版本
- `feature/*` - 功能分支
- `hotfix/*` - 紧急修复

### 发布流程

1. 在 `develop` 分支开发新功能
2. 创建 Pull Request 到 `main`
3. 合并后创建发布标签
4. 自动构建和发布
