# 工作日志（worklog）

## 2026-08-06 — 创建 AGENTS.md 项目规则

- 任务内容：按用户要求创建工作区 AGENTS.md，包含 4 项强制规则（GitHub 提交、详细更新报告、工作日志、文件修改范围限制），并启用 ADHD 输出风格。
- 修改文件：
  - `G:\moneythings-goal\AGENTS.md`（新建）
  - `G:\moneythings-goal\worklog.md`（新建，本文件）
- commit hash：无（当前目录尚未初始化 git 仓库，无远程仓库）
- 遇到的问题：`G:\moneythings-goal` 还不是 git 仓库，也没有 GitHub 远程地址，因此"每次提交到 GitHub"规则暂无法执行。
- 下一步：初始化 git 仓库并关联 GitHub 远程地址后，开始首个代码任务。

## 2026-08-06 — 初始化 git 仓库并连接 GitHub 远程

- 任务内容：初始化 git 仓库；连接远程 https://github.com/ljh2014137576-dev/moneythings.git；本地提交 AGENTS.md 与 worklog.md。
- 修改文件：
  - `G:\moneythings-goal\.git\`（新建，git 元数据）
  - `G:\moneythings-goal\.git\config`（远程 origin；本地 user.name / user.email）
  - `G:\moneythings-goal\worklog.md`（追加本条）
- commit hash：`853f7fe`（本地提交，尚未 push）
- 遇到的问题：`gh` 尚未登录，无法 push；github.com 直连超时，但本机已有全局 ghfast.top 镜像配置，远程仓库可达且为空仓库。
- 下一步：用户完成 `gh auth login` 后执行 push。

## 2026-08-06 — 切换 SSH 远程并推送到 GitHub

- 任务内容：弃用 gh，改用已配置的 SSH 密钥（id_ed25519）推送；远程由 https(ghfast.top 镜像) 切换为 `git@github.com:ljh2014137576-dev/moneythings.git`。
- 修改文件：
  - `G:\moneythings-goal\.git\config`（remote url 改为 SSH）
  - `G:\moneythings-goal\worklog.md`（追加本条）
- commit hash：`be402cd`（master 已推送；本条提交后追加推送）
- 遇到的问题：gh 未登录且 github.com HTTPS 直连超时；SSH 22/443 经 Clash Verge 可达，认证通过（Hi ljh2014137576-dev!）。
- 下一步：后续每次修改后直接 add → commit → push。

## 2026-08-07 00:40 — Flutter 本地记账 App「记账本」完整开发

- 任务内容：用 Flutter 开发本地记账手机 App「记账本」，遵循「精密编辑财务 UI」规范（暖灰页面、白色纸面数据组、黑色编辑层级、细分隔线、单一蓝色强调、无阴影/无彩虹分类色）；完成首页/明细/统计/我的四大一级页面 + 记一笔/编辑流程；本地持久化（SharedPreferences JSON，金额以「分」存储）；首次启动内置示例数据；通过 web 渲染做视觉验证、Playwright + 语义树做全流程交互验证；构建 Android debug APK 成功。
- 修改文件（主要）：
  - `lib/main.dart`（App 入口、主题、HomeShell 底部导航、offstage 语义隔离）
  - `lib/theme/app_colors.dart` / `app_theme.dart`（设计令牌与 ThemeData）
  - `lib/models/transaction.dart` / `account.dart`（交易/分类/账户模型）
  - `lib/data/transaction_repository.dart` / `app_state.dart`（持久化与状态）
  - `lib/widgets/`（金额、纸面组、流水行、底部导航、月份选择、空状态、分类排行、预算对话框等）
  - `lib/pages/`（home/ledger/stats/profile/add_transaction）
  - `test/widget_test.dart`（7 个单元+组件测试，含完整 CRUD 流程）
  - `android/…`（应用名「记账本」；Gradle 阿里云镜像；禁 Kotlin 增量编译）
  - `ios/Runner/Info.plist`（显示名「记账本」）
  - `screenshots/*.png`（五个页面的设计截图）
- commit hash：`99d43b7`（脚手架）→ `453ef11`（主体功能）→ `e4c26f8`（a11y/语义/测试/截图）→ `60e5dc4`（命名与 Gradle 修复 + APK）；均已 push 到 GitHub。
- 验证：`flutter analyze` 无问题；`flutter test` 7/7 通过；web 渲染语义树逐页核对无溢出、无控制台错误；新增→明细→编辑→删除全流程在浏览器与组件测试中均验证；`flutter build apk --debug` 成功（144MB debug 包）。
- 遇到的问题与解决方案：
  1. GitHub 推送在 Push 时 PowerShell 将 git stderr 当错误（实际已推送成功）。
  2. 首次 Gradle 构建卡死：国内网络下 services.gradle.org 下载慢 → 切换腾讯 Gradle 镜像 + 阿里云 Maven 镜像。
  3. Kotlin 增量编译跨盘报 "different roots"（项目 G: 盘 / 缓存 C: 盘）→ `kotlin.incremental=false`。
  4. PowerShell 字符串替换中 `\n` 与 CRLF 行尾不匹配导致多次补丁失效 → 改用按行编辑。
  5. IndexedStack offstage 页面语义干扰读屏与自动化点击 → `ExcludeSemantics` 隔离。
- 下一步计划：
  - 可选增强：预算预警、数据导出 CSV、多账本、深色模式、桌面端支持。
  - 发布前：签名 release 包、应用图标、隐私说明。
