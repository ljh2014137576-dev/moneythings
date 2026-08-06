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

## 2026-08-07 01:50 — 迭代 v1.1：导出 / 预算提醒 / 环比 / 应用图标

- 任务内容：继续完善记账本 v1.1。
  - A. CSV 导出：`lib/services/csv_exporter.dart`（纯函数，UTF-8 BOM，Excel 可开）；移动端经 `share_plus` 写文件并调起系统分享，网页端复制剪贴板（条件导入 `export_target.dart`）；「我的→数据」新增「导出数据 (CSV)」入口。
  - B. 预算超额保存提醒：当月支出且已设预算时，保存前弹窗「超出本月预算」，可取消或继续保存；编辑时扣除原金额避免重复计算。
  - C. 统计环比：`AppState.expenseDeltaOf` 计算与上月差额，统计页「总支出」下方显示「较上月 ±¥xx」（增=红、减=绿）。
  - D. 应用图标：System.Drawing 生成 1024 黑底白¥+蓝线图标（`assets/icon/`），flutter_launcher_icons 生成 Android/iOS 全套；版本升至 1.1.0+2。
  - 工程：新增 `.gitattributes` 统一行尾；`*.hprof` 入 .gitignore。
- 修改文件：
  - `lib/services/csv_exporter.dart`、`lib/services/export_io.dart`、`lib/services/export_web.dart`、`lib/services/export_target.dart`（新增）
  - `lib/data/app_state.dart`、`lib/pages/stats_page.dart`、`lib/pages/profile_page.dart`、`lib/pages/add_transaction_page.dart`
  - `pubspec.yaml`（share_plus/path_provider/flutter_launcher_icons、版本、图标配置）、`.gitattributes`（新增）、`.gitignore`
  - `assets/icon/app_icon.png`、`app_icon_foreground.png`（新增）；`android/…/mipmap*` 与 `ios/…/AppIcon*`（图标）
  - `test/widget_test.dart`（11 个测试，含 CSV/环比/预算弹窗/导出入口）
  - `screenshots/*-v1.1.png`
- commit hash：`bf67088`（功能）→ `dd244a3`（环比符号修复 + 截图；曾因误提交 617MB 的 java_pid*.hprof 被 GitHub 拒绝，已 git rm + gitignore + amend 后推送成功）；均已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 11/11 通过；浏览器语义树实测：环比「较上月 -4,911.00」、预算弹窗出现→取消不保存→继续保存成功（支出 ¥1000→¥1200）、导出入口存在；`flutter clean` 后 `flutter build apk --debug` 成功。
- 遇到的问题与解决方案：
  1. Gradle OOM（IncrementalSplitterRunnable）→ 杀掉旧守护进程 + `flutter clean` 后重建成功（干净守护进程读取 -Xmx8G）。
  2. OOM 堆转储 617MB 被 `git add -A` 误提交，push 被 GitHub 拒绝 → `git rm --cached`、删除文件、`*.hprof` 入 .gitignore、`--amend` 修正。
  3. PowerShell 双引号中 `${...}` 被当变量展开导致 Dart 代码被截断（环比符号、预算文案两处）→ 统一用单引号 here-string 写入。
- 下一步计划：
  - 预算预警通知（本地提醒）、多账本、深色模式、分类自定义、release 签名发布。

## 2026-08-07 02:30 — 迭代 v1.2：自定义分类 / 收入排行 / release 签名

- 任务内容：
  - A. 自定义分类：`TxCategory` 支持序列化与自定义标记；`TxCategories` 注册表合并预设+自定义（`setCustom/of/byId`）；仓库与 `AppState` 增加自定义分类持久化（增/改/删，编辑保留 id 不丢历史）；「我的→分类管理」支出/收入两组，自定义项带蓝色角标、点击可编辑/删除；新增/编辑对话框含名称与 40 个线性图标选择；「记一笔」分类网格自动包含自定义分类。
  - B. 统计收入分类排行：`AppState.categoryIncomeRanking` + 统计页「收入分类排行」分组（当月有收入时显示）。
  - C. Release 签名：keytool 生成 `android/upload-keystore.jks`（不入库）；`android/keystore.properties`（不入库，ASCII 避免 BOM 坑）；`app/build.gradle.kts` 读取签名配置，缺失时回退 debug 签名；`flutter build apk --release` 成功（50.8MB），apksigner 验证证书 CN=MoneyThings。
- 修改文件：
  - `lib/models/transaction.dart`（分类注册表+序列化）、`lib/models/category_icons.dart`（新增，40 图标）
  - `lib/widgets/category_dialog.dart`（新增）、`lib/pages/profile_page.dart`（分类管理 UI）、`lib/data/app_state.dart`、`lib/data/transaction_repository.dart`
  - `lib/pages/stats_page.dart`（收入排行）、`test/widget_test.dart`（13 测试）
  - `android/app/build.gradle.kts`（签名配置）、`.gitignore`（keystore、android/**/build）
  - `screenshots/3-stats-v1.2.png`、`4-profile-v1.2.png`
- commit hash：`9d5c4d5`（A+B）→ `353e16d`（C）；均已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 13/13（含自定义分类注册表/持久化、管理 UI→记一笔联动）；web 语义树确认「收入分类排行」「分类管理」渲染正常、无控制台错误；release APK 构建并验证签名。
- 遇到的问题与解决方案：
  1. PowerShell UTF-8 带 BOM 写入 keystore.properties → Java Properties 键名带 BOM 前缀 → 改 ASCII 写入。
  2. storeFile 相对 app 模块解析路径错误 → 改 `rootProject.file()`。
  3. release 构建 Metaspace OOM → 杀旧 Gradle 守护进程重试（读取 -Xmx8G/MaxMetaspace4G）。
- 下一步计划：本地预算预警通知、多账本、深色模式、release 上架准备（图标已就绪）。
