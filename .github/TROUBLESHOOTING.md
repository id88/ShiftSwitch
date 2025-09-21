# GitHub Actions 故障排除

## 403 权限错误解决方案

如果您遇到 `⚠️ GitHub release failed with status: 403` 错误，请按以下步骤检查和修复：

### 1. 检查仓库设置

前往 GitHub 仓库设置：

1. 点击仓库页面的 **Settings** 标签
2. 在左侧菜单中选择 **Actions** → **General**
3. 在 **Workflow permissions** 部分，选择：
   - ✅ **Read and write permissions**
   - ✅ **Allow GitHub Actions to create and approve pull requests**

### 2. 检查个人 Token 权限（如果使用自定义Token）

如果您使用自定义的 `GITHUB_TOKEN`：

1. 前往 GitHub Settings → Developer settings → Personal access tokens
2. 确保 Token 具有以下权限：
   - ✅ `repo` (Full control of private repositories)
   - ✅ `write:packages` (Write packages to GitHub Package Registry)
   - ✅ `contents:write` (Contents write permission)

### 3. 验证分支保护规则

1. 前往 **Settings** → **Branches**
2. 检查是否有分支保护规则阻止 Actions
3. 如果有保护规则，确保：
   - ✅ 允许 Actions 推送到保护分支
   - ✅ 不要求管理员进行审查

### 4. 手动测试权限

运行调试工作流来检查权限：

```bash
# 在 GitHub 仓库页面的 Actions 标签中
# 找到 "Debug Permissions" 工作流
# 点击 "Run workflow" 手动运行
```

### 5. 组织仓库的额外设置

如果仓库属于组织：

1. 前往组织的 **Settings** → **Actions**
2. 确保允许仓库使用 Actions
3. 检查 **Third-party Actions** 设置

### 6. 重新创建工作流文件

如果以上都无效，尝试重新创建工作流：

1. 删除 `.github/workflows/build.yml`
2. 重新创建文件
3. 提交并推送

### 7. 使用经典 Token

如果问题持续存在，创建经典 Personal Access Token：

1. GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. 生成新 Token，选择所有 `repo` 权限
3. 在仓库 Settings → Secrets 中添加为 `RELEASE_TOKEN`
4. 修改工作流使用 `RELEASE_TOKEN` 而不是 `GITHUB_TOKEN`

## 常见问题

### Q: 为什么构建成功但发布失败？
A: 这通常是权限问题。检查上述权限设置。

### Q: 可以手动创建 Release 吗？
A: 是的，您可以：
1. 手动运行构建工作流
2. 下载 Artifacts
3. 在 GitHub 手动创建 Release 并上传文件

### Q: 如何调试权限问题？
A: 运行 "Debug Permissions" 工作流查看详细信息。

## 联系支持

如果问题仍然存在，请：
1. 提供完整的错误日志
2. 说明您的仓库设置
3. 创建 Issue 寻求帮助
