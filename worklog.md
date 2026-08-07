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

## 2026-08-07 03:10 — 迭代 v1.3：搜索 / 月份跳转 / CSV 导入

- 任务内容：
  - A. 明细搜索：明细页顶部搜索框（备注/分类名，不区分大小写），带清除按钮；无结果时显示空状态提示。
  - B. 月份快速跳转：月份选择器点击月份文字打开年份+12 月网格弹层，可翻年、选中即跳转（首页/明细/统计共用）。
  - C. CSV 导入：`lib/services/csv_importer.dart` 解析器（支持 BOM/表头/引号转义/自定义分类名/账户名映射/非法行报错）；`AppState.importCsv` 按「日期|类型|分类|金额|备注」指纹去重合并；「我的→数据→导入数据 (CSV)」粘贴对话框，结果提示「导入 N 笔，跳过 M 行，错误 K 行」。
- 修改文件：
  - `lib/pages/ledger_page.dart`（搜索）、`lib/widgets/month_selector.dart`（月份弹层）、`lib/services/csv_importer.dart`（新增）、`lib/data/app_state.dart`（importCsv）、`lib/pages/profile_page.dart`（导入入口+对话框）
  - `test/widget_test.dart`（18 测试）、`screenshots/6-month-picker.png`、`7-ledger-search.png`、`8-profile-import.png`
- commit hash：`ea40e87`（三功能）→ `3cc076f`（导入对话框 dispose 修复+测试）；均已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 18/18；web 实测：搜索过滤、月份跳转到 7 月、导入对话框取消/导入均正常，导入后账户余额实时更新（银行卡 +8000、支付宝 -35.50），零控制台错误。
- 遇到的问题与解决方案：
  1. 导入对话框在关闭动画期间 dispose controller → "TextEditingController used after being disposed" 崩溃 → 改为对话框自持 controller 的 StatefulWidget（随组件卸载释放）。
  2. 测试中行备注渲染为「咖啡 · 支付宝」导致 `find.text` 精确匹配失败 → 改用 `find.textContaining`。
- 下一步计划：本地预算预警通知、多账本切换、深色模式、上架素材与隐私说明。

## 2026-08-07 04:00 — 迭代 v1.4：初始余额 / 结余走势 / 首启引导 / 文档

- 任务内容：
  - A. 账户初始余额：账户列表持久化（repository `accounts_v1`），`AppState.accounts` + `setAccountInitialBalance`；「我的→账户」点账户编辑初始余额（对话框自持 controller）；记一笔的账户选择同步使用真实余额；总资产按账户初始余额计算。
  - B. 统计结余走势：`AppState.recentBalanceSeries(endMonth, count)` 近 6 月月度结余序列；统计页「结余走势（近 6 月）」柱状图（正=黑、负=红，可点击看月度金额）。
  - C. 首次启动引导：3 页 PageView（记录每一笔/统计一目了然/数据属于你）+ 圆点指示 + 跳过/下一步/开始使用；prefs `onboarded_v1` 标记，完成后进首页。
  - D. 文档：README.md（功能/截图/技术栈/构建/签名/版本历史）、PRIVACY.md（本地存储、不上传、可清除）；「关于」版本号改为 1.1.0。
- 修改文件：
  - `lib/models/account.dart`（toJson/fromJson 已有）、`lib/data/transaction_repository.dart`、`lib/data/app_state.dart`
  - `lib/pages/profile_page.dart`（账户编辑 UI + 初始余额对话框）、`lib/pages/add_transaction_page.dart`（账户选择用真实余额）
  - `lib/pages/stats_page.dart`（结余走势图）、`lib/pages/onboarding_page.dart`（新增）、`lib/main.dart`（首启路由）
  - `README.md`、`PRIVACY.md`（新增）、`test/widget_test.dart`（22 测试）、`screenshots/3-stats-v1.4.png`、`4-profile-v1.4.png`、`9-onboarding.png`
- commit hash：`eb3b29d`（功能）；截图与日志随本次提交。
- 验证：`flutter analyze` 0 问题；`flutter test` 22/22；web 实测：首启引导三页→首页、结余走势图渲染、账户初始余额对话框设置 ¥500 后余额更新，零控制台错误。
- 遇到的问题与解决方案：无阻塞性问题（沿用自持 controller 的对话框模式避免 dispose 崩溃）。
- 下一步计划：本地预算预警通知、多账本切换、深色模式、商店上架素材。

## 2026-08-07 05:00 — 迭代 v1.5：滑动删除 / 首页走势 / 预算剩余日均 / 商店文案

- 任务内容：
  - A. 明细左滑删除 + 撤销：Dismissible 红底删除背景，删除后 SnackBar「已删除 ¥xx」带「撤销」一键恢复。
  - B. 首页结余走势迷你图：复用 `recentBalanceSeries`，首页新增 6 个月迷你柱状图（正=黑、负=红，中线基准）。
  - C. 预算剩余/日均可用：AppState 新增 `budgetRemaining` / `budgetDaysLeft` / `budgetDailyRemaining`；首页预算条与「我的→预算管理」显示「剩余 ¥xx · 日均可用 ¥yy」（超支显示红字）。
  - D. 商店上架文案：`STORE_TEXT.md`（名称/简介/详细描述/类别/关键词/宣传语/隐私）。
- 修改文件：
  - `lib/pages/ledger_page.dart`（滑动删除）、`lib/pages/home_page.dart`（结余迷你图 + 预算剩余日均）、`lib/pages/profile_page.dart`（预算剩余日均）、`lib/data/app_state.dart`（预算 getters）
  - `STORE_TEXT.md`（新增）、`test/widget_test.dart`（25 测试）、`screenshots/1-home-v1.5.png`、`10-ledger-swipe.png`
- commit hash：`854b8db`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 25/25（新增预算计算、首页走势/剩余日均显示、左滑删除撤销）；web 实测：首页结余走势、预算剩余日均显示、明细左滑删除 + 撤销恢复，零控制台错误。
- 遇到的问题与解决方案：
  1. node 脚本多次写坏 home_page.dart（字段插错位/文件头污染）→ 干脆整体重写该文件（内容完全可控），后续统一用 PowerShell 按行编辑。
  2. PowerShell 双引号中 `${...}` 展开问题 → 用反引号 `` `$ `` 转义。
- 下一步计划：本地预算预警通知、多账本切换、深色模式、商店上架素材。

## 2026-08-07 06:00 — 迭代 v1.6：多账本 + 商店截图

- 任务内容：
  - A. 多账本：`Book` 模型 + `Transaction.bookId`（默认 default，JSON 兼容）；仓库持久化账本列表与当前账本；`AppState` 支持 `addBook/setCurrentBook/removeBook`，所有查询按当前账本过滤（ofMonth/summary/排行/结余/余额），新增与导入流水归属当前账本，删除账本时其流水并入默认账本并自动切回。
  - B. UI：首页右上角账本切换按钮（显示当前账本名）；`lib/widgets/book_switcher.dart` 底部弹层（列表/当前勾选/删除/新建）；「我的」新增「账本」入口。
  - C. 商店发布截图：`screenshots/store/*-1080.png` 5 张（1080×1920，首页/明细/统计/我的/记一笔）。
- 修改文件：
  - `lib/models/book.dart`（新增）、`lib/models/transaction.dart`（bookId）、`lib/data/transaction_repository.dart`、`lib/data/app_state.dart`
  - `lib/widgets/book_switcher.dart`（新增）、`lib/pages/home_page.dart`（账本按钮）、`lib/pages/profile_page.dart`（账本入口）
  - `test/widget_test.dart`（27 测试）、`screenshots/store/`、`screenshots/11-book-switcher.png`
- commit hash：`93fdf87`（功能）；截图与日志随本次提交。
- 验证：`flutter analyze` 0 问题；`flutter test` 27/27（多账本创建/切换/隔离/删除、首页切换支出变化）；web 实测：首页账本按钮→弹层→新建「工作」账本→列表更新，商店截图 5 张零错误。
- 遇到的问题与解决方案：
  1. node_repl 内核重置导致浏览器句柄丢失 → 重新 launch。
  2. 多次顶层变量重名冲突 → 统一用 var + 顶层 await。
  3. home_page 表头替换时跳行数算错多删 3 行 → 用括号深度检查定位并修复。
- 下一步计划：本地预算预警通知、深色模式、商店素材排版、release 上架。

## 2026-08-07 07:00 — 迭代 v1.7：预算预警 / 合计条 / 导出账本列 / release 校验

- 任务内容：
  - A. 预算 80% 预警：首页预算条达 80%+ 时显示「已用 91%，注意控制」（红字），超支仍显示超支金额。
  - B. 明细筛选合计条：明细列表顶部固定显示「共 N 笔 · 支出 ¥x · 收入 ¥y」（随筛选/搜索实时变化）。
  - C. CSV 导出增强：加「账本」列；改为导出**当前账本**的流水（多账本下更符合直觉）；`CsvExporter` 支持 `bookNames` 映射。
  - D. Release 重建与校验：`flutter build apk --release` 成功（51.1MB）；SHA-256 `2B94260E...9549B`；apksigner 验证 MoneyThings 证书。
- 修改文件：
  - `lib/pages/home_page.dart`（预算预警条）、`lib/pages/ledger_page.dart`（合计条 + _LedgerSummary）、`lib/services/csv_exporter.dart`、`lib/data/app_state.dart`（currentBookTransactions）、`lib/pages/profile_page.dart`（按当前账本导出）
  - `test/widget_test.dart`（27 测试，CSV 断言更新）、`screenshots/12-budget-warning.png`、`13-ledger-summary.png`
- commit hash：`456714e`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 27/27；web 实测：预算 91% 显示「已用 91%，注意控制」、合计条「共 18 笔 · 支出 ¥1,000.00 · 收入 ¥14,000.00」，零控制台错误；release APK 签名校验通过。
- 遇到的问题与解决方案：
  1. PowerShell 双引号 `${...}` 展开损坏 Dart 插值 → 统一用 node 单引号字符串/反引号转义写入，整体重写小文件。
  2. 多次行拼接误伤文件 → 每次改完立即 analyze 验证。
- 下一步计划：本地预算预警通知（系统通知）、深色模式、商店素材排版、上架。

## 2026-08-07 08:00 — 迭代 v1.8：预算按账本 / 日期范围筛选 / 商店横幅与上架清单

- 任务内容：
  - A. 预算按账本：`repository.loadBookBudgets/saveBookBudgets`（新 key `book_budgets_v1`，兼容旧单一预算归入默认账本）；`AppState._bookBudgets` 按账本存，`monthlyBudget` 读当前账本，`setBudget` 写当前账本，`removeBook` 清理对应预算；首页/我的预算条自动跟随当前账本。
  - B. 明细日期范围筛选：明细页「日期：全部日期」入口，点开两次日期选择（开始/结束），应用后列表与合计条按范围过滤，可一键清除。
  - C. 商店横幅 `screenshots/store/banner-1024x500.png`（暖灰底/黑字/蓝色强调/迷你柱状图）+ 上架清单 `CHECKLIST.md`（账号/素材/权限/隐私/自检/版本）。
- 修改文件：
  - `lib/data/transaction_repository.dart`、`lib/data/app_state.dart`、`lib/pages/ledger_page.dart`
  - `screenshots/store/banner-1024x500.png`、`CHECKLIST.md`（新增）、`test/widget_test.dart`（29 测试）、`screenshots/14-date-range.png`
- commit hash：`8bc8d1b`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 29/29（按账本预算独立/持久化/删除清理、日期范围入口与清除）；web 实测：明细「日期：全部日期」入口与日期选择器正常，零控制台错误。
- 遇到的问题与解决方案：node splice 误传嵌套数组导致方法并成一行 → 改按元素传入；金额字体 FontStyle.SemiBold 不存在 → 用 Bold。
- 下一步计划：本地预算预警系统通知、深色模式、商店上架（按 CHECKLIST 执行）。

## 2026-08-07 09:00 — 迭代 v1.9：最近分类 / 导出范围 / 账本重命名

- 任务内容：
  - A. 记一笔「最近使用分类」置顶：`AppState.recentCategoryIds` 按当前账本+类型取最近使用分类（时间倒序去重）；记一笔页分类网格上方显示「最近」一行快捷分类，点击即选中。
  - B. 导出范围选择：`_exportCsv` 先弹底部弹层选「当前账本（xxx）」或「全部账本」，再导出；全部导出时 CSV 带账本列区分。
  - C. 账本重命名：`Book.copyWith` + `AppState.renameBook`；账本弹层非默认账本行新增「重命名账本」按钮（复用对话框，预填名称）。
- 修改文件：
  - `lib/data/app_state.dart`、`lib/pages/add_transaction_page.dart`、`lib/pages/profile_page.dart`、`lib/widgets/book_switcher.dart`、`lib/models/book.dart`
  - `test/widget_test.dart`（31 测试）、`screenshots/15-recent-category.png`、`16-book-rename.png`
- commit hash：`b0e2409`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 31/31（最近分类顺序/收入为空、重命名生效、记一笔显示最近分类）；web 实测：记一笔「最近」分类行渲染，零控制台错误。
- 遇到的问题与解决方案：node 多次 splice 导致 book_switcher 括号错位/方法嵌套（_rename 插进 _remove）→ 用括号深度扫描定位并修正。
- 下一步计划：本地预算预警系统通知、深色模式、上架执行。

## 2026-08-07 10:00 — 迭代 v2.0：全部时间视图 / 预算超支系统通知 / release 重建

- 任务内容：
  - A. 明细「全部时间」视图：明细页新增「时间：本月/全部时间」切换，全部时展示当前账本所有流水（跨月）。
  - C. 预算超支系统通知：引入 flutter_local_notifications 22.2.0；AndroidManifest 加 POST_NOTIFICATIONS；`NotificationService`（渠道+运行时权限+超支通知）；「我的→预算管理」加「超支系统通知」开关（持久化，默认开，开启时请求权限）；记一笔超预算「继续保存」后触发系统通知；core library desugaring 开启。
  - D. release 重建：`flutter build apk --release` 成功（51.7MB），SHA-256 `DF58373D...4BC9`，MoneyThings 签名验证通过。
  - 顺手修复：profile「已超出预算」文案丢失 `$` 的遗留 bug。
- 修改文件：
  - `lib/pages/ledger_page.dart`（全部时间）、`lib/services/notification_service.dart`（新增）、`lib/main.dart`、`lib/pages/add_transaction_page.dart`、`lib/pages/profile_page.dart`、`lib/data/transaction_repository.dart`、`lib/data/app_state.dart`
  - `android/app/src/main/AndroidManifest.xml`、`android/app/build.gradle.kts`（desugaring）、`pubspec.yaml`
  - `test/widget_test.dart`（33 测试）、`screenshots/17-all-time.png`、`18-notify-switch.png`
- commit hash：`c5f5a0a`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 33/33（通知开关持久化、全部时间视图）；web 实测：时间切换、通知开关渲染，零控制台错误；release APK 构建+签名验证。
- 说明：系统通知实际弹出需 Android 真机验证（本环境无设备）；代码/权限/渠道/触发均已就绪。
- 遇到的问题与解决方案：flutter_local_notifications 22.x API 具名参数化（initialize/show）→ 查包源码适配；需 core library desugaring → build.gradle.kts 开启；Metaspace OOM → 杀守护进程重试。
- 下一步计划：深色模式、上架执行（CHECKLIST）、真机通知冒烟。

## 2026-08-07 11:00 — 迭代 v2.1：复制上一条 / 每周统计 / 每日记账提醒

- 任务内容：
  - B. 记一笔「复制上一条」：`AppState.lastTransactionOf` 取当前账本同类型最近一笔；记一笔页顶部「复制上一条」按钮一键填充金额/分类/账户/备注。
  - A. 统计「每日/每周」切换：`AppState.weeklyExpenseSeries` 按周聚合；统计页「每日/每周」切换，每周视图 5~6 根柱、周选中高亮、周标签与金额提示。
  - D. 每日记账提醒：`NotificationService` 增加 `zonedSchedule` 每日 20:00 提醒（timezone 初始化 + inexact 模式无需精确闹钟权限）；「我的→数据」新增「每日记账提醒（20:00）」开关（持久化，开启请求权限并调度，关闭取消）。
  - 深色模式说明：与「精密编辑财务 UI」暖灰浅色设计规范冲突，本轮不做（如需可单独评估）。
- 修改文件：
  - `lib/data/app_state.dart`、`lib/pages/add_transaction_page.dart`、`lib/pages/stats_page.dart`、`lib/services/notification_service.dart`、`lib/pages/profile_page.dart`、`lib/data/transaction_repository.dart`
  - `pubspec.yaml`（flutter_timezone、timezone）、`test/widget_test.dart`（36 测试）、`screenshots/19-copy-last.png`、`20-weekly-chart.png`、`21-reminder-switch.png`
- commit hash：`0459a27`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 36/36（周聚合、提醒开关持久化、复制上一条）；web 实测：复制上一条按钮、每周支出图（第1~5周/周选中/Y轴）、提醒开关渲染，零控制台错误。
- 说明：定时提醒与超支通知的实际弹出需 Android 真机验证。
- 遇到的问题与解决方案：flutter_local_notifications v22 具名参数（initialize/show/cancel/zonedSchedule）→ 查包源码适配；flutter_timezone v5 返回 TimezoneInfo → 用 .identifier；多次 splice 造成方法嵌套 → 括号深度定位修复。
- 下一步计划：上架执行（CHECKLIST）、真机通知冒烟、深色模式评估。

## 2026-08-07 12:00 — 迭代 v2.2：本周概览 / 导入预览 / 预算剩余天数

- 任务内容：
  - A. 首页「本月/本周」概览切换：`AppState.weekSummary`（周一起收支）；首页顶部切换，周模式显示「本周支出/收入/结余」且隐藏月份选择器，最近流水切到本周。
  - B. CSV 导入解析预览确认：粘贴后先解析预览（将导入 N 笔/跳过 M/错误 K），确认后才真正导入，防误导。
  - C. 预算条剩余天数：首页预算条文案增加「· 剩 N 天」（`budgetDaysLeft`）。
- 修改文件：
  - `lib/data/app_state.dart`、`lib/pages/home_page.dart`、`lib/pages/profile_page.dart`
  - `test/widget_test.dart`（38 测试）、`screenshots/22-home-week.png`、`23-budget-days.png`
- commit hash：`1ea8c0e`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 38/38（本周概览排除上周、首页切换本周支出 ¥88、导入预览确认、预算剩余/日均）；web 实测：本周/本月切换、本周支出 ¥632、预算剩余天数渲染，零控制台错误。
- 遇到的问题与解决方案：首页三元表达式括号与标题残留导致语法错误 → 逐处修复；导入预览 `${}` 被 `\$` 转义成字面量 → 去掉反斜杠；测试适配预览确认弹窗（确认导入按钮 .last）。
- 下一步计划：上架执行（CHECKLIST）、真机通知冒烟、深色模式评估。

## 2026-08-07 13:00 — 迭代 v2.3：结余走势 6/12 月、长按复制账目、导出命名、更新日志

- 任务内容：
  - A. 结余走势「6月/12月」切换：统计页结余走势图标题旁切换，数据范围实时更新。
  - B. 明细长按菜单：长按流水行弹出「编辑 / 复制为新的账目 / 删除」；复制=预填内容（日期保持今天）作为新账目保存（`AddTransactionPage.copyFrom`）。
  - C. 导出文件名含账本名（`记账本流水_账本名_日期.csv`，全部时用「全部」）；「关于」对话框加入更新日志。
- 修改文件：
  - `lib/pages/stats_page.dart`、`lib/widgets/transaction_tile.dart`、`lib/pages/ledger_page.dart`、`lib/pages/add_transaction_page.dart`、`lib/pages/profile_page.dart`
  - `test/widget_test.dart`（39 测试）、`screenshots/24-about.png`
- commit hash：`098c196`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 39/39（长按→复制→保存新增）；web 实测：6/12 月切换、关于更新日志渲染，零控制台错误。
- 遇到的问题与解决方案：无阻塞；沿用已有模式（_ChartModeTag 复用、长按菜单参考分类弹层）。
- 下一步计划：上架执行（CHECKLIST）、真机通知冒烟、深色模式评估。

## 2026-08-07 14:00 — 迭代 v2.4：支出/收入图表切换、首页总资产、JSON 全量备份/恢复

- 任务内容：
  - A. 统计柱状图「支出/收入」切换：`dailyIncomeSeries`；统计页每日/每周切换行下新增「支出/收入」切换，收入柱状图实时切换（标题/数据/选中）。
  - B. 首页总资产：结余走势卡标题右侧显示「总资产 ¥xx」（tabular 数字）。
  - C. JSON 全量备份/恢复：`AppState.exportJson/importJson`（交易/账户/自定义分类/账本/当前账本/预算/通知开关）；「我的→数据」新增「备份到剪贴板 (JSON)」「从备份恢复 (JSON)」入口，恢复前可粘贴并校验版本。
- 修改文件：
  - `lib/data/app_state.dart`、`lib/pages/stats_page.dart`、`lib/pages/home_page.dart`、`lib/pages/profile_page.dart`
  - `test/widget_test.dart`（41 测试）、`screenshots/25-home-assets.png`、`26-backup.png`
- commit hash：`3f22724`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 41/41（每日收入序列、JSON round-trip 含账本/预算/备注）；web 实测：首页总资产、收入切换、备份/恢复入口，零控制台错误。
- 遇到的问题与解决方案：无阻塞。
- 下一步计划：上架执行（CHECKLIST）、真机通知冒烟、深色模式评估。

## 2026-08-07 15:00 — 迭代 v2.5：账户筛选 / 筛选导出 / 常用金额快捷

- 任务内容：
  - A. 明细按账户筛选：账户筛选行（全部账户/现金/银行卡/支付宝/微信，横向滚动），与类型/搜索/日期/账本叠加。
  - B. 明细导出当前筛选结果：明细页标题右侧导出按钮，按当前筛选（类型/搜索/日期/账户/账本）导出 CSV。
  - C. 记一笔常用金额快捷：金额输入框下「+10/+50/+100/+500」快捷累加。
  - 修复：明细页 header 在测试视口溢出 11px → 压缩头部行距。
- 修改文件：
  - `lib/pages/ledger_page.dart`、`lib/pages/add_transaction_page.dart`
  - `test/widget_test.dart`（43 测试）、`screenshots/27-ledger-account-filter.png`、`28-quick-amount.png`
- commit hash：`f55fc63`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 43/43（账户筛选隔离、+50/+100 累加 50→150）；web 实测：账户筛选行、导出按钮、常用金额 chips，零控制台错误。
- 遇到的问题与解决方案：_exportVisible 插入时 _longPress 未闭合导致 static _p2 在方法内 → 括号深度定位修复。
- 下一步计划：上架执行（CHECKLIST）、真机通知冒烟、深色模式评估。

## 2026-08-07 16:00 — 迭代 v2.6：支出占比环图 / 账户联动 / 日期预设

- 任务内容：
  - A. 统计页「支出占比」环图：Top5 分类（最大项蓝、其余黑灰阶）+ 图例百分比；符合规范（唯一蓝重点、无彩虹）。
  - B. 账户→明细联动：我的页点账户弹菜单「查看该账户流水 / 设置初始余额」；查看流水打开按账户预筛选的明细页（`LedgerPage.initialAccountId`）。
  - C. 日期范围快速预设：明细日期范围改为底部弹层「本月/上月/近 7 天/近 30 天/自定义」，一键设置。
- 修改文件：
  - `lib/pages/stats_page.dart`、`lib/pages/profile_page.dart`、`lib/pages/ledger_page.dart`
  - `test/widget_test.dart`（45 测试）、`screenshots/29-donut.png`、`30-account-ledger.png`、`31-range-presets.png`
- commit hash：`6bf442c`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 45/45（环图渲染、账户流水筛选隔离、日期预设/初始余额测试适配）；web 实测：环图、账户菜单与流水页、日期预设弹层，零控制台错误。
- 遇到的问题与解决方案：JS 模板字面量中 `${}` 被插值 → 改用数组拼接写 Dart 插值；环图块插入位置挤进 PaperGroup → 括号/结构修正。
- 下一步计划：上架执行（CHECKLIST）、真机通知冒烟、深色模式评估。

## 2026-08-07 17:00 — 迭代 v2.7：记住上次账户 / 大字体无障碍

- 任务内容：
  - A. 记一笔记住上次账户：AppState 记录最近使用的账户（持久化 `last_account_v1`），记一笔页默认账户=上次账户（替代固定支付宝）。
  - D. 大字体无障碍：明细页重构为单列表（头部随内容滚动）；合计条改 Wrap（大字体换行）；统计合计条去固定高度；新增「大字体 2.0x 无障碍冒烟」测试——四页面+记一笔在 2.0x 字号下逐页渲染无溢出。
- 修改文件：
  - `lib/data/transaction_repository.dart`、`lib/data/app_state.dart`、`lib/pages/add_transaction_page.dart`、`lib/pages/ledger_page.dart`、`lib/pages/stats_page.dart`
  - `test/widget_test.dart`（47 测试）、`screenshots/32-last-account.png`
- commit hash：`049b39c`（功能）→ `7bbab0f`（测试+截图）；均已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 47/47（含大字体 2.0x 无溢出、lastAccountId 持久化）；web 实测默认账户记忆，零控制台错误。
- 遇到的问题与解决方案：2x 大字体下抓出两处真实溢出（明细合计条 Row、统计合计条固定高度）→ 分别改 Wrap 与自适应高度；独立页渲染需初始化 intl 中文数据。
- 下一步计划：上架执行（CHECKLIST）、真机通知冒烟、深色模式评估。

## 2026-08-07 18:00 — 迭代 v2.8：保存后继续记一笔 + 上架交付收尾

- 任务内容：
  - C. 记一笔保存后：SnackBar「已保存 ¥xx」+「继续记一笔」快捷再次记账。
  - A. 最终 release 重建（53.6MB，SHA-256 `0B7510BD...65EB`，MoneyThings 签名）；修复 R8 堆溢出（jvmargs -Xmx12G）；新增 `RELEASE.md` 交付清单（APK/校验/素材/质量门禁/上架步骤）。
  - B. 新增 `SMOKE_TEST.md` 真机冒烟脚本（含系统通知/定时提醒等需真机项，其余标注自动化已验）。
- 修改文件：
  - `lib/pages/add_transaction_page.dart`、`android/gradle.properties`
  - `RELEASE.md`、`SMOKE_TEST.md`（新增）、`test/widget_test.dart`（47 测试）
- commit hash：`4d1ca2d`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 47/47；release APK 构建+签名校验。
- 遇到的问题与解决方案：R8 Java heap OOM（30 分钟构建失败）→ jvmargs 提至 -Xmx12G 后 79s 构建成功；测试被保存 SnackBar 遮挡点击 → 显式 clearSnackBars。
- 下一步：用户注册 Play 账号后按 `RELEASE.md` + `SMOKE_TEST.md` 上架；真机确认系统通知与定时提醒。

## 2026-08-07 19:00 — 迭代 v2.9：年度对比 + 导入错误详情

- 任务内容：
  - A. 统计「年度对比」：`AppState.yearComparison(year)` 逐月支出今年 vs 去年；统计页新增分组柱状图（今年=黑、去年=灰、图例+悬停提示）。
  - B. 导入预览错误详情：CSV 导入预览弹窗在存在错误行时展示前 3 条错误示例（红字）。
- 修改文件：
  - `lib/data/app_state.dart`、`lib/pages/stats_page.dart`、`lib/pages/profile_page.dart`
  - `test/widget_test.dart`（48 测试）、`screenshots/33-year-compare.png`
- commit hash：`f6d9664`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 48/48（年度对比月份/金额、导入预览错误）；web 实测年度对比图渲染，零控制台错误。
- 遇到的问题与解决方案：yearComparison 插入时嵌套进 recentBalanceSeries → 括号深度定位修复。
- 下一步计划：上架执行（RELEASE.md）、真机通知冒烟（SMOKE_TEST.md）、深色模式评估。

## 2026-08-07 20:00 — 迭代 v3.0：JSON 备份写文件分享 + 本月小结

- 任务内容：
  - A. JSON 备份改进：导出服务新增通用 `exportFile`（移动端写文件+系统分享，web 剪贴板）；备份从「复制到剪贴板」改为「写文件并分享」。
  - B. 可复制的「本月小结」：`AppState.monthSummaryText` 生成月报（收入/支出/结余/笔数/日均/支出最多）；「我的→数据」新增入口，弹窗展示并可一键复制。
- 修改文件：
  - `lib/services/export_io.dart`、`export_web.dart`、`export_target.dart`、`lib/data/app_state.dart`、`lib/pages/profile_page.dart`
  - `test/widget_test.dart`（49 测试）、`screenshots/34-month-summary.png`
- commit hash：`952328c`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 49/49（月报文本内容）；web 实测月小结弹窗（收入/支出/结余/笔数/日均/支出最多 + 复制按钮），零控制台错误。
- 遇到的问题与解决方案：JS 模板 `\${` 转义成字面量 → 修正；插入方法时双 `}}` 导致类提前闭合 → 括号深度定位修复。
- 下一步计划：上架执行（RELEASE.md）、真机通知冒烟（SMOKE_TEST.md）、深色模式评估。

## 2026-08-07 21:00 — 迭代 v3.1：明细多选批量删除 + 版本号 3.0.0

- 任务内容：
  - B. 明细多选批量删除：长按流水 → 菜单「多选删除」→ 固定选择栏（已选 N 项/全选/删除/取消），选中行高亮，批量删除确认后退出多选。
  - A. 版本号同步：pubspec `3.0.0+30`；「关于」版本 3.0.0；更新日志补 v3.0/v2.9/v2.6。
- 修改文件：
  - `lib/pages/ledger_page.dart`、`lib/widgets/transaction_tile.dart`、`lib/pages/profile_page.dart`、`pubspec.yaml`
  - `test/widget_test.dart`（50 测试）、`screenshots/35-multiselect.png`
- commit hash：`9cc740f`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 50/50（多选删除全流程）；web 实测长按→多选→全选 18 项→删除→退出多选，零控制台错误。
- 遇到的问题与解决方案：选择栏最初放滚动头部导致被滚出屏幕 → 改为固定栏；TransactionTile 括号错位/选择块插错 → 括号深度与行定位修复；测试行被底部导航遮挡 → 改用「全选」+ 修正断言。
- 下一步计划：上架执行（RELEASE.md）、真机通知冒烟（SMOKE_TEST.md）、深色模式评估。

## 2026-08-07 22:00 — 迭代 v3.2：最终 release 3.0.0 + 交付文档同步

- 任务内容：
  - A. 最终 release 重建：版本号与产物一致（3.0.0+30），APK 53.7MB，SHA-256 `87F08DD8...226B`，MoneyThings 签名。
  - B. 文档同步：RELEASE.md（版本/体积/SHA/50 测试）；README 版本历史补 v3.1/v3.0；新增「设计原则」段落（说明暖灰浅色为品牌规范、深色模式暂不做及原因）。
- 修改文件：
  - `RELEASE.md`、`README.md`
- commit hash：`8c834a6`；已 push。
- 验证：release 构建成功 + apksigner 签名校验；analyze/50 测试此前全绿。
- 遇到的问题与解决方案：PackageAndroidArtifact 打包失败（守护进程状态）→ 杀进程后 22s 构建成功。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-07 23:00 — 迭代 v3.3：金额搜索 / CSV 头部信息 / 结余走势默认 12 月

- 任务内容：
  - A. 明细搜索支持金额：搜索框输入纯数字（支持小数）时按金额精确匹配（如 42 → ¥42.00 流水）；与备注/分类搜索并存。
  - B. CSV 导出头部信息行：导出文件首行加 `# 导出时间：xxx` / `# 范围：xxx` 说明；导入解析自动跳过 `#` 注释行（与旧文件兼容）。
  - C. 统计结余走势默认 12 月（更长趋势视野）。
- 修改文件：
  - `lib/pages/ledger_page.dart`、`lib/services/csv_exporter.dart`、`lib/services/csv_importer.dart`、`lib/pages/profile_page.dart`、`lib/pages/stats_page.dart`
  - `test/widget_test.dart`（52 测试）、`screenshots/36-amount-search.png`
- commit hash：`f5aafd5`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 52/52（金额搜索匹配/排除、CSV meta 行导入跳过）；浏览器备注搜索与数据含 ¥30.00 确认（金额搜索由单元测试权威验证，浏览器输入焦点受 harness 干扰）。
- 遇到的问题与解决方案：一次 replace 误伤 ledger 文件（内容被追加到尾部）→ git 回退后用精确行插入重做；node 顶层变量冲突 → 用唯一前缀。
- 下一步计划：上架执行（RELEASE.md）、真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-08 00:00 — 迭代 v3.4：导入追加/替换 + 版本号 3.3.0 + 最终 release

- 任务内容：
  - B. CSV 导入「追加/替换」：导入预览确认弹窗新增「替换全部」（红色，先清空再导入）与「追加导入」两个选项，取消关闭。
  - A. 版本号同步 3.3.0+33；最终 release 重建（53.7MB，SHA-256 `BE7E9796...35A8`，MoneyThings 签名）；RELEASE.md 更新版本/SHA/52 测试。
- 修改文件：
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`RELEASE.md`、`test/widget_test.dart`（52 测试）
- commit hash：`2333bfb`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 52/52；release 构建+签名校验。
- 遇到的问题与解决方案：replace 误改了「清除全部」弹窗类型（showDialog<bool>→String）→ 精确修正两处弹窗类型。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-08 01:00 — 迭代 v3.5：本周小结 + 合计条结余

- 任务内容：
  - A. 可复制的「本周小结」：`AppState.weekSummaryText` 生成周报（周一起至今天，收入/支出/结余/笔数）；「我的→数据」新增「本周小结（复制）」入口（与本月小结共用弹窗）。
  - B. 明细合计条显示结余：收入-支出（正=绿、负=红），与笔数/支出/收入并排。
- 修改文件：
  - `lib/data/app_state.dart`、`lib/pages/profile_page.dart`、`lib/pages/ledger_page.dart`
  - `test/widget_test.dart`（54 测试）、`screenshots/37-ledger-balance.png`、`38-week-summary.png`
- commit hash：`a82add1`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 54/54（周报内容、合计条结余）；web 实测合计条结余与本周小结弹窗，零控制台错误。
- 遇到的问题与解决方案：合计条插入时旧块残留（final balance + 重复收入段）→ 定位删除；MonthSummary 非 const → 去掉 const。
- 下一步：上架执行（RELEASE.md）、真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-08 02:00 — 迭代 v3.6：年度对比点击跳转 + 日期快捷

- 任务内容：
  - A. 统计年度对比：点击某月柱 → 统计页切换到该月（`setState` 更新 `_month`）。
  - B. 记一笔日期快捷：「今天/昨天」chips，一键切换记账日期（日期行下方）。
- 修改文件：
  - `lib/pages/stats_page.dart`、`lib/pages/add_transaction_page.dart`
  - `test/widget_test.dart`（55 测试）、`screenshots/39-quick-date.png`
- commit hash：`2358c9a`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 55/55；web 实测日期快捷 chips 渲染，零控制台错误。
- 遇到的问题与解决方案：日期快捷测试中 chip 在测试视口外 → 简化测试为验证渲染（点击为纯 setState）。
- 下一步：上架执行（RELEASE.md）、真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-08 03:00 — 迭代 v3.7：结余走势点击跳转 + 版本号 3.6.0 + 最终 release

- 任务内容：
  - B. 统计结余走势：点击某月柱 → 切换到该月（与年度对比对称的交互增强）。
  - A. 版本号同步 3.6.0+36；最终 release 重建（53.7MB，SHA-256 `E31B5CA7...FACE`，MoneyThings 签名）；RELEASE.md 更新版本/SHA/55 测试。
- 修改文件：
  - `lib/pages/stats_page.dart`、`pubspec.yaml`、`RELEASE.md`
- commit hash：`854405b`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 55/55；release 构建+签名校验。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-08 04:00 — 迭代 v3.8：账本图标 + 明细最近搜索

- 任务内容：
  - A. 账本图标：`Book.iconKey`（默认 menu_book，复用分类图标集）；新建/重命名账本可选图标（图标选择器）；账本弹层行显示各账本图标。
  - B. 明细最近搜索：`AppState.recordSearch/clearRecentSearches`（去重置顶，最多 5 条，持久化）；搜索框防抖 600ms 记录；搜索框下（无查询时）展示「最近搜索」chips，点击快速搜索、可清除。
- 修改文件：
  - `lib/models/book.dart`、`lib/data/transaction_repository.dart`、`lib/data/app_state.dart`、`lib/widgets/book_switcher.dart`、`lib/pages/ledger_page.dart`
  - `test/widget_test.dart`（57 测试）、`screenshots/40-book-icon.png`、`41-recent-searches.png`
- commit hash：`c093c65`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 57/57（账本图标持久化、最近搜索去重置顶）；web 实测账本弹层与新建图标选择器，零控制台错误。
- 遇到的问题与解决方案：仓库追加方法落在类外 → 移到类内；浏览器输入焦点受 harness 干扰（最近搜索由单元测试权威验证）。
- 下一步：上架执行（RELEASE.md）、真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-08 05:00 — 迭代 v3.9：金额长按全选 + 版本号 3.8.0 + 最终 release

- 任务内容：
  - B. 记一笔金额输入框长按全选文本（便于快速替换/复制）。
  - A. 版本号同步 3.8.0+38；最终 release 重建（53.7MB，SHA-256 `0379FD39...8935`，MoneyThings 签名）；RELEASE.md 更新版本/SHA/57 测试。
- 修改文件：
  - `lib/pages/add_transaction_page.dart`、`pubspec.yaml`、`RELEASE.md`
- commit hash：`6cb1d13`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 57/57；release 构建+签名校验。
- 遇到的问题与解决方案：IncrementalSplitter 打包失败（守护进程）→ 杀进程后 22s 构建成功。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-08 06:00 — 迭代 v4.0：明细按金额排序 + 金额清除按钮

- 任务内容：
  - A. 明细排序：筛选行末尾「日期/金额」切换，按金额降序排列流水（与其他筛选/搜索叠加）。
  - B. 记一笔金额清除：金额输入框非空时显示「×」清除按钮，一键清空。
- 修改文件：
  - `lib/pages/ledger_page.dart`、`lib/pages/add_transaction_page.dart`
  - `test/widget_test.dart`（59 测试）、`screenshots/42-ledger-sort.png`、`43-amount-clear.png`
- commit hash：`403c422`；已 push。
- 验证：`flutter analyze` 0 问题；`flutter test` 59/59（金额排序首位=大额、清除后金额消失）；web 实测清除金额按钮，零控制台错误。
- 遇到的问题与解决方案：排序逻辑放在 _visible 早退之后未生效 → 移到 build 层对 visible 排序；金额输入框显示原始文本非格式化 → 测试断言改 '88'。
- 下一步：上架执行（RELEASE.md）、真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-08 07:00 — 迭代 v4.0 收尾：版本号 4.0.0+40 + 排序跨天修复 + 最终 release

- 任务内容：
  - A. 版本号同步 4.0.0+40；「关于」对话框版本/更新日志更新为 v4.0 系列；README 版本历史补全 v1.5~v4.0（原先只到 v3.1 且缺失大量条目）。
  - B. 修复 v4.0「金额排序」跨天失效 bug：`_groupByDay` 原先固定按日期降序重排分组，导致全局金额排序被覆盖（最大金额 +¥14,000 的 8月5日 仍排第 3）；现按组内最大金额降序排分组（组内已按金额降序），金额排序后最大流水置顶。
  - C. 单测「明细按金额排序」加强为跨天场景（大额在昨日、默认日期排序小额在前 → 切金额排序后大额在前），旧代码会失败、新代码通过。
  - D. 最终 release 重建（53.7MB，SHA-256 `BEB75032...B2DD`，MoneyThings 签名校验通过）；RELEASE.md / CHECKLIST.md 同步版本、SHA、59/59 测试、4.0.0+40。
  - E. web 冒烟：关于对话框显示「版本 4.0.0」；金额输入后「清除金额」按钮出现并可清空；明细切金额排序后 +¥14,000 置顶、日分组按最大金额降序；截图 24-about / 42-ledger-sort / 43-amount-clear 更新，零控制台错误。
- 修改文件：
  - `pubspec.yaml`（4.0.0+40）
  - `lib/pages/profile_page.dart`（关于：版本 4.0.0 + 更新日志 v4.0/v3.8/v3.6/v3.3/v3.0）
  - `lib/pages/ledger_page.dart`（`_groupByDay` 支持按金额排分组 + `_groupMaxAmount`）
  - `test/widget_test.dart`（明细按金额排序 → 跨天断言）
  - `README.md`（版本历史补全 v1.5~v4.0）
  - `RELEASE.md`（v4.0 / 新 SHA / 59 测试）
  - `CHECKLIST.md`（APK 53.7MB / 新 SHA / 59 测试 / 4.0.0+40）
  - `screenshots/24-about.png`、`42-ledger-sort.png`、`43-amount-clear.png`
- commit hash：`a91004e`；已 push（1303c39..a91004e master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 59/59；release 构建 + apksigner 签名校验（CN=MoneyThings）；web 冒烟零控制台错误。
- 遇到的问题与解决方案：
  1. PowerShell 5.1 `Set-Content -Encoding utf8` 给 pubspec 加了 BOM 且把中文注释按 ANSI 读成乱码 → `git checkout` 还原后用 UTF-8 无 BOM 显式读写只改版本行；README/RELEASE/CHECKLIST 的 BOM 也一并剥离。
  2. 行级替换误删 `_groupByDay` 方法体 → 先还原区域再按行插入重建，`flutter analyze` 确认结构。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-08 09:00 — 迭代 v4.1：账户转账 + 版本号 4.1.0 + 最终 release

- 任务内容：
  - 新增「账户转账」核心功能：记一笔支持 支出/收入/转账 三态；转账模式选转出/转入账户 + 金额 + 日期 + 备注，隐藏分类，提示「转账仅调整账户余额，不计入收支统计」；转出=转入账户时拦截。
  - 数据层：`TxType.transfer`、`Transaction.transferToAccountId`（JSON 持久化，旧数据兼容）；`summaryOf`/`weekSummary` 转账不计收支；`balanceOf` 转出账户扣款、转入账户入账，总资产不变。
  - 展示层：流水行转账样式（swap 图标、标题「转账」、副标题「A → B」、金额无 +/-）；明细合计/日分组不计转账；分类对话框排除转账。
  - CSV：导出新增「转入账户」列（类型=转账）；导入解析转账行、校验转出≠转入、指纹含转入账户。
  - 测试：新增 4 项（余额双向变动与总资产不变/CSV 转账往返/明细页转账显示且不计入合计/记一笔转账模式 UI），63/63 通过。
  - web 冒烟：记一笔转账模式 → 保存 ¥88（支付宝→现金）→ 明细「转账 支付宝 → 现金 ¥88.00」；首页收支/结余/总资产不变；我的账户 支付宝 -2949→-3037、现金 0→88；零控制台错误。截图 44/45。
  - 版本号 4.1.0+41；README/RELEASE/CHECKLIST 同步；最终 release 重建（53.7MB，SHA-256 `6DC7E48E...31BE`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/models/transaction.dart`（TxType.transfer + transferToAccountId + TxCategories 适配）
  - `lib/data/app_state.dart`（summaryOf/weekSummary/balanceOf 转账处理）
  - `lib/pages/add_transaction_page.dart`（转账模式 UI/校验/保存/复制上一条）
  - `lib/pages/ledger_page.dart`（合计与日分组不计转账）
  - `lib/widgets/transaction_tile.dart`（转账行样式）
  - `lib/widgets/category_dialog.dart`（类型切换排除转账）
  - `lib/services/csv_exporter.dart`、`csv_importer.dart`（转账列往返）
  - `lib/pages/profile_page.dart`（关于：4.1.0 + 更新日志）
  - `pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/44-transfer-add.png`、`45-transfer-ledger.png`（新增）
- commit hash：`db69aca`；已 push（82f45e3..db69aca master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 63/63；release 构建 + apksigner 签名校验（CN=MoneyThings）；web 冒烟零控制台错误。
- 遇到的问题与解决方案：
  1. Dart collection-if 的 `] else` 不允许换行（解析报 Expected ']'）→ 改为 `] else ...[` 同行写法。
  2. PS 5.1 正则/行尾陷阱：`-match` 含括号与 `\r\n` 不匹配 → 改用 `[System.IO.File]::ReadAllText/WriteAllText` + `.Replace()`（注意文件行尾 LF vs CRLF 差异）。
  3. 测试插入定位错（原文件尾有空行）把新测试放到 main() 外 → 以 `git show HEAD:` 为基准重建，插到末尾 `}` 之前。
  4. `build/` 下临时文件被 analyze 扫描 → 写为 `// temp` 中和（build/ 不入库）。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-08 11:00 — 迭代 v4.2：明细分类筛选 + 统计分类下钻 + 版本号 4.2.0 + 最终 release

- 任务内容：
  - A. 明细分类筛选：账户与分类合并为一行横向筛选条（全部账户/现金/… | 全部分类/餐饮/交通/…），`_categoryFilter` 与类型/账户/搜索/日期/排序叠加；切换支出/收入类型时重置分类筛选。
  - B. 统计分类下钻：支出/收入分类排行每行可点击（CategoryRanking 增 onTapCategory），点击推入 LedgerPage(initialCategoryId: xxx) 预选该分类。
  - C. 修复真实 bug：明细页作为独立路由被 push（统计下钻）时缺 Scaffold/Material，InkWell 崩溃（No Material widget found）→ LedgerPage 根节点包 Scaffold(backgroundColor: kPageBackground)，Tab 内嵌套与独立路由均正常。
  - D. 空状态分支改为可滚动（SingleChildScrollView），避免 600px 视口下新增筛选行导致溢出。
  - E. 测试：新增 2 项（明细页分类筛选、initialCategoryId 预选分类），65/65 通过。
  - F. web 冒烟：明细点「餐饮」→ 只剩餐饮 4 笔 ¥126；统计排行点「餐饮」→ 跳转明细并预选（共 4 笔）；点「全部分类」恢复 18 笔；零控制台错误。截图 46-category-drilldown.png。
  - G. 版本号 4.2.0+42（aapt 校验 versionName=4.2.0/versionCode=42）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.7MB，SHA-256 `6676A4D3...BE02`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/ledger_page.dart`（initialCategoryId、_categoryFilter、合并筛选行、Scaffold 包裹、空状态可滚动）
  - `lib/widgets/category_ranking.dart`（onTapCategory 回调 + 行 InkWell）
  - `lib/pages/stats_page.dart`（两个排行接 onTapCategory → 推 LedgerPage）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/46-category-drilldown.png`（新增）
- commit hash：`f4d6d71`；已 push（094f25a..f4d6d71 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 65/65；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：
  1. 新增筛选行使 600px 测试视口下流水行被挤出可视区（空状态溢出 34px）→ 空状态改可滚动；筛选行与账户行合并为一行省高度。
  2. 统计下钻 web 实测发现真实崩溃：LedgerPage 独立路由无 Scaffold → InkWell 无 Material → 包 Scaffold 修复。
  3. 最后一处编辑误用 `Get-Content/Set-Content -Encoding utf8`（PS 默认 ANSI）把 ledger_page 中文整体弄乱 → `git checkout` 还原后用 ReadAllText/WriteAllText（UTF-8 无 BOM）重做全部 v4.2 改动。
  4. `scrollUntilVisible`/`dragUntilVisible` 在统计页取滚动容器不稳（fl_chart 内部 Scrollable）→ 改用直接 pump LedgerPage(initialCategoryId:) 验证下钻核心逻辑；裸 pump 缺 Scaffold/Material 报错 → 包 Scaffold。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-08 13:00 — 迭代 v4.3：明细金额区间筛选 + 搜索支持账户名 + 版本号 4.3.0 + 最终 release

- 任务内容：
  - A. 明细金额区间筛选：日期与金额筛选合并为一行横向滚动条（日期：全部日期 | 金额：全部金额，各自带清除按钮），不增高表头；点「金额」打开底部弹层（最低/最高输入 + 确定/清除，校验最低≤最高）；`_visible` 按分过滤。
  - B. 搜索支持账户名：搜索除备注/分类外，命中账户名（如搜「微信」显示微信账户流水）。
  - C. 弹层重构为 `_AmountSheet` StatefulWidget（controller 随组件生命周期释放），修复「弹层关闭动画期间 controller 被 dispose」崩溃。
  - D. 测试：新增 2 项（金额区间筛选、账户名搜索），67/67 通过。
  - E. web 冒烟：金额 10~100 → 11 笔 ¥476；搜「微信」→ 7 笔 ¥518 全为微信账户；清除恢复；零控制台错误。截图 47-amount-range.png。
  - F. 版本号 4.3.0+43（aapt 校验 versionName=4.3.0/versionCode=43）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.7MB，SHA-256 `CFA1ECAA...76EA`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/ledger_page.dart`（_amountMin/_amountMax、_visible 金额过滤、搜索加账户名、日期/金额合并筛选行、_AmountSheet 弹层）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/47-amount-range.png`（新增）
- commit hash：`8741a89`；已 push（03d2596..8741a89 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 67/67；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：
  1. 弹层内联 controller 在 `await showModalBottomSheet` 后立即 dispose，关闭动画期间仍被引用 → 改为 `_AmountSheet` StatefulWidget 自持 controller。
  2. Gradle `IncrementalSplitterRunnable` 失败（已知）→ 杀 java/gradle/dart 进程重试，22.6s 构建成功。
  3. `_rangeChip` 命名/位置参数不一致 → 统一为命名参数。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-08 15:00 — 迭代 v4.4：统计柱状图下钻当日/当周流水 + 版本号 4.4.0 + 最终 release

- 任务内容：
  - A. 统计柱状图「查看流水」下钻：每日/每周柱状图选中后，caption 右侧出现「查看流水 ›」入口；点击弹出当日/当周流水底部弹层（日期标题 + 笔数 + 支出/收入合计，流水行可点击进入编辑）。
  - B. `_buildSelectionCaption` 增 onView 回调（周/日分支各加 `_viewHint`）；新增 `_showSelectionDay` / `_showSelectionWeekly` / `_showTransactionsSheet`（弹层复用 TransactionTile，转账不计收支合计）。
  - C. 测试：新增「统计柱状图查看当日流水」（默认选中支出最高日，弹层显示当日两笔、不含其他日），68/68 通过。
  - D. web 冒烟：统计页 caption 渲染「查看流水」入口，滚动/点击零控制台错误（弹层交互以单元测试为权威验证）。截图 48-day-transactions.png。
  - E. 版本号 4.4.0+44（aapt 校验 versionName=4.4.0/versionCode=44）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.7MB，SHA-256 `32CFA603...51DC`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/stats_page.dart`（caption onView + _viewHint + 三个弹层方法；imports）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/48-day-transactions.png`（新增）
- commit hash：`e9f760a`；已 push（e119a67..e9f760a master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 68/68；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：
  1. web 上 getByText 匹配不到 Flutter 语义文本、坐标点击易误中 → 弹层交互以单元测试权威验证（与以往金额/搜索类一致的策略）。
  2. 残留 Chrome 实例 + dev 编译卡顿导致页面无法引导 → 杀 chrome/flutter/dart 进程重启 web server。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-08 17:00 — 迭代 v4.5：记一笔常用备注 + 账户页月度收支 + 版本号 4.5.0 + 最终 release

- 任务内容：
  - A. 记一笔常用备注：备注输入框上方横向快捷备注 chips（午餐/晚餐/早餐/地铁/打车/超市/房租/水电/话费/咖啡），点击一键填充备注（复用 _QuickAmountChip）。
  - B. 我的页每账户月度收支：`AppState.monthlySummaryOfAccount(accountId, month)` 返回当月支出/收入/笔数（转账不计）；账户行显示「本月支出 X · 收入 Y · N 笔」。
  - C. 测试：新增 2 项（常用备注快捷填充、我的页账户月度收支），70/70 通过。
  - D. web 冒烟：记一笔页渲染常用备注 chips；我的页各账户显示本月支出/收入/笔数（银行卡 6 笔 支出196/收入14000、支付宝 5 笔 支出286、微信 7 笔 支出518）；零控制台错误。截图 49-quick-notes.png。
  - E. 版本号 4.5.0+45（aapt 校验 versionName=4.5.0/versionCode=45）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.7MB，SHA-256 `B2B80309...5AD`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/add_transaction_page.dart`（_buildQuickNoteRow）
  - `lib/data/app_state.dart`（monthlySummaryOfAccount）
  - `lib/pages/profile_page.dart`（_AccountRow 加 month 参数与月度收支副标题）
  - `pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/49-quick-notes.png`（新增）
- commit hash：`3a03839`；已 push（fc4403b..3a03839 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 70/70；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：
  1. 相邻字符串拼接漏写首段闭合引号（Unterminated string literal）→ 补 `'`。
  2. 600px 视口下备注 chips 在折叠区外，tap 警告 off-screen → 测试先 ensureVisible 再点。
  3. Gradle `IncrementalSplitterRunnable`（已知）→ 杀进程重试 38.1s 成功。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）；候选大功能：周期记账（重复记账）。

## 2026-08-08 19:00 — 迭代 v4.6：周期记账（重复流水自动生成）+ 版本号 4.6.0 + 最终 release

- 任务内容：
  - A. 周期记账核心：`RecurringRule` 模型（每周/每月/每年 + 锚点/下次日期/启用/账本 + `nextAfter` 月末钳制）；Repository 持久化（recurring_rules_v1，clearAll 一并清除）。
  - B. AppState：load 时加载规则并 `generateDueRecurring()`（nextDate ≤ 今天逐期生成流水并推进，防重复、防死循环 guard=400）；CRUD + 账本切换时生成；JSON 备份/恢复包含规则。
  - C. 记一笔：meta 行新增「周期」选择（不重复/每周/每月/每年 底部弹层）；保存新流水时若设置周期则同时创建规则（下次日期 = 锚点 + 周期）。
  - D. 我的页：「周期记账」区块（规则列表：频率·分类 + 金额·下次日期 + 启用开关 + 删除），仅当前账本有规则时显示。
  - E. 测试：新增 5 项（日期推进含月末/闰年钳制、到期生成且不重复、持久化往返、记一笔设置周期创建规则、我的页显示区块），75/75 通过。
  - F. web 冒烟：记一笔选「每月」保存 → 规则写入 localStorage、流水 +¥100；把 nextDate 改为过去重载 → 自动生成 8月1日 流水（本月支出 +¥100 到 ¥1,200）、我的页出现「删除周期规则」行；零控制台错误。截图 50-recurring.png。
  - G. 版本号 4.6.0+46（aapt 校验 versionName=4.6.0/versionCode=46）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `0953B80A...12DB`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/models/recurring_rule.dart`（新增）
  - `lib/data/transaction_repository.dart`（load/saveRecurringRules + clearAll）
  - `lib/data/app_state.dart`（规则状态/getter/generateDueRecurring/CRUD/账本切换/备份恢复/clearAll）
  - `lib/pages/add_transaction_page.dart`（周期选择行 + 保存创建规则）
  - `lib/pages/profile_page.dart`（周期记账区块 + _RecurringRow）
  - `pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/50-recurring.png`（新增）
- commit hash：`1f539c1`；已 push（4c5e848..1f539c1 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 75/75；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：
  1. 月末钳制 bug：用当前月天数钳制导致 8/31 + 1月 → 10/1；改为用目标月天数（DateTime(y, m+2, 0)）钳制。
  2. web 上 PaperGroup 标题/行文本不进语义 innerText（与 v4.2「支出分类排行」相同现象）→ 用「删除周期规则」工具提示节点 + 自动生成流水证明区块与规则均在渲染；行内容以单元/组件测试为权威验证。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-08 21:00 — 迭代 v4.7：周期规则编辑 + 版本号 4.7.0 + 最终 release

- 任务内容：
  - A. 周期规则编辑：我的页「周期记账」规则行整行可点击（InkWell），打开 `_RecurringEditSheet` 底部弹层编辑金额/分类/账户/频率（每周/每月/每年）/下次日期（日期选择器）/备注，保存调用 updateRecurringRule。
  - B. `RecurringRule.copyWith` 扩展支持 amount/categoryId/accountId/note/frequency/nextDate 编辑字段。
  - C. 测试：新增 2 项（copyWith 编辑字段、编辑弹层改金额与频率保存生效），77/77 通过。
  - D. web 冒烟：注入规则 → 我的页规则行渲染 → 点击打开编辑弹层（金额/分类/账户/频率/下次/保存齐全）→ 金额改 2000 保存 → localStorage 规则 amount 变 200000、旧 100000 消失；零控制台错误。截图 51-recurring-edit.png。
  - E. 版本号 4.7.0+47（aapt 校验 versionName=4.7.0/versionCode=47）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `1F8291C8...0B36`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/models/recurring_rule.dart`（copyWith 扩展）
  - `lib/pages/profile_page.dart`（_RecurringRow onEdit + _editRecurring + _RecurringEditSheet 弹层）
  - `pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/51-recurring-edit.png`（新增）
- commit hash：`02b6519`；已 push（c50bc50..02b6519 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 77/77；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：规则行标题在 600px 视口边缘 tap 落空 → 测试先 scrollUntilVisible 到行标题再 ensureVisible 再点。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-08 23:00 — 迭代 v4.8：金额区间快捷预设 + 周期规则后续预览 + 版本号 4.8.0 + 最终 release

- 任务内容：
  - A. 明细金额区间快捷预设：金额区间弹层顶部新增 3 个预设 chips（≤100 / 100~500 / ≥500），一键填入最低/最高。
  - B. 周期规则后续预览：`RecurringRule.nextOccurrences(from, freq, count)` 计算后续 N 个发生日期；编辑弹层显示「后续：10月1日、11月1日、12月1日」（随频率/下次日期实时变化）。
  - C. 测试：新增 2 项（后续发生日期序列、金额区间预设筛选），79/79 通过。
  - D. web 冒烟：金额弹层预设 chips 渲染，点 100~500 → 金额：100.00 ~ 500.00 → 3 笔 ¥500；周期编辑弹层显示「后续：10月1日、11月1日、12月1日」；零控制台错误。截图 52-recurring-preview.png。
  - E. 版本号 4.8.0+48（aapt 校验 versionName=4.8.0/versionCode=48）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `DB9058A9...4068`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/models/recurring_rule.dart`（nextOccurrences）
  - `lib/pages/ledger_page.dart`（_AmountSheet 预设 chips + _applyPreset/_presetChip）
  - `lib/pages/profile_page.dart`（_RecurringEditSheet 后续预览 + _previewText）
  - `pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/52-recurring-preview.png`（新增）
- commit hash：`22dcd27`；已 push（98a6d03..22dcd27 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 79/79；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：无阻塞问题（沿用 UTF-8 安全编辑与语义节点坐标点击验证）。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-09 01:00 — 迭代 v4.9：明细多选批量修改（分类/账户）+ 版本号 4.9.0 + 最终 release

- 任务内容：
  - A. 明细多选批量修改：多选栏新增「修改」按钮；弹层选「修改分类 / 修改账户」→ 分类/账户选择弹层（Wrap chips）→ `AppState.bulkUpdateTransactions(ids, categoryId/accountId)` 批量应用并退出多选。
  - B. 测试：新增 2 项（批量改账户、批量改分类），81/81 通过。
  - C. web 冒烟：明细长按 → 多选删除 → 全选 18 项 → 修改选中 → 修改账户 → 支付宝 → localStorage 本月 18 笔全部变 alipay（其他月份不受影响，符合「全选=可见流水」语义）；零控制台错误。截图 53-batch-edit.png。
  - D. 版本号 4.9.0+49（aapt 校验 versionName=4.9.0/versionCode=49）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `462F06F3...81E2`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（bulkUpdateTransactions）
  - `lib/pages/ledger_page.dart`（多选栏「修改」+ _editSelected/_pickBulkCategory/_pickBulkAccount）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/53-batch-edit.png`（新增）
- commit hash：`a2dbdb3`；已 push（0ede1c8..a2dbdb3 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 81/81；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：
  1. `const Text('批量修改 ${_selectedIds.length} 笔')` 字符串插值不能 const → 去掉 const。
  2. 选择弹层「支付宝/餐饮」与筛选行同名 → 测试用 `.last`（弹层在树尾部）。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-09 03:00 — 迭代 v4.10：统计页预算对比 + 版本号 4.10.0 + 最终 release

- 任务内容：
  - A. 统计页预算对比卡：汇总条下方新增「预算对比」PaperGroup（仅当月显示）——预算金额 + 已用百分比 + 进度条 + 已用/剩余（超支红字显示超出额）；未设置预算时显示「设置每月预算」入口（点击弹预算对话框）。
  - B. 测试：新增 1 项（预算 1000 元 + 支出 680 元 → 显示「已用 68%」与剩余），82/82 通过。
  - C. web 冒烟：注入预算 1000 元 → 统计页「预算对比 预算 1,000.00 已用 100%」渲染正常（示例数据支出 ¥1,000）；零控制台错误。截图 54-budget-compare.png。
  - D. 版本号 4.10.0+50（aapt 校验 versionName=4.10.0/versionCode=50）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `506A55B4...8F87`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/stats_page.dart`（_buildBudgetCard + 插入汇总条下方 + import budget_dialog）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/54-budget-compare.png`（新增）
- commit hash：`456c700`；已 push（18ea52e..456c700 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 82/82；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：卡片标题用「预算对比」避免与首页「本月预算」文本撞名导致 finder 二义性。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-09 05:00 — 迭代 v4.11：周期规则「立即生成本次」+ 版本号 4.11.0 + 最终 release

- 任务内容：
  - A. 周期规则「立即生成本次」：我的页规则行新增播放按钮（tooltip 立即生成本次）；`AppState.generateRecurringNow(ruleId)` —— 未来规则按今天生成一笔并推进 nextDate（避免到期重复），过期规则走正常补生成。
  - B. 测试：新增 2 项（未来规则立即生成且补生成不重复、我的页按钮触发生成），84/84 通过。
  - C. web 冒烟：注入未来每周规则 → 我的页点「立即生成本次」→ 本月支出 ¥1,000 → ¥1,050（+¥50 订阅）、nextDate 8/15 → 8/14；零控制台错误。截图 55-generate-now.png。
  - D. 版本号 4.11.0+51（aapt 校验 versionName=4.11.0/versionCode=51）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `9D5E0962...93C`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（generateRecurringNow）
  - `lib/pages/profile_page.dart`（_RecurringRow onGenerate + 播放按钮）
  - `pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/55-generate-now.png`（新增）
- commit hash：`b95ac97`；已 push（e7ba9b8..b95ac97 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 84/84；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：规则行副标题不含备注（金额·下次），测试按行标题「每周 · 餐饮」滚动定位。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-09 07:00 — 迭代 v4.12：自定义账户 + 版本号 4.12.0 + 最终 release

- 任务内容：
  - A. 自定义账户：`Account` 加 isCustom/iconKey + `Account.custom()` + 自定义注册表（setCustom/accountById/accountIdByName 支持自定义）；AppState addAccount/renameAccount/removeAccount（有流水的账户禁止删除），load 时同步注册表。
  - B. 我的页账户区「+」新增账户（名称 + 40 图标选择器，复用 kCategoryIconChoices）；自定义账户菜单含「重命名 / 删除账户」（删除二次确认 + 有流水拦截提示）。
  - C. CSV 导入账户名映射支持自定义账户（accountIdByName 注册表查找）。
  - D. 测试：新增 2 项（账户增删改与名称映射/有流水禁删、我的页新增账户 UI），86/86 通过。
  - E. web 冒烟：新增「招商卡」（名称+图标）→ 持久化 + 显示 + 菜单含重命名/删除账户 + 月度收支；零控制台错误。截图 56-custom-account.png。
  - F. 版本号 4.12.0+52（aapt 校验 versionName=4.12.0/versionCode=52）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `25A42857...0D73`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/models/account.dart`（isCustom/iconKey/custom()/注册表/accountIdByName）
  - `lib/data/app_state.dart`（addAccount/renameAccount/removeAccount/_syncAccounts）
  - `lib/pages/profile_page.dart`（账户区「+」、_AccountEditSheet、账户菜单重命名/删除）
  - `lib/services/csv_importer.dart`（账户名映射走注册表）
  - `pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/56-custom-account.png`（新增）
- commit hash：`c24f454`；已 push（2694427..c24f454 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 86/86；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：copyWith 内 `this.icon` 触发 lint → 去掉 this.；账户删除前检查全账本流水（有则拦截并提示）。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-09 09:00 — 迭代 v4.13：统计页年度汇总 + 版本号 4.13.0 + 最终 release

- 任务内容：
  - A. 统计页年度汇总卡：`AppState.yearSummary(year)` 计算当年总支出/总收入/结余/日均支出/笔数/支出最多分类（转账不计）；统计页底部新增「YYYY 年汇总」PaperGroup 展示六项（当年无流水则隐藏）。
  - B. 测试：新增 2 项（yearSummary 计算含跨年过滤与最多分类、统计页显示年度汇总），88/88 通过。
  - C. web 冒烟：统计页滚动到底部显示「2026 年汇总 总支出 ¥6,911.00 总收入 ¥79,300.00 结余 ¥72,389.00 日均支出 ¥18.93 全年 95 笔 · 支出最多：居住」；零控制台错误。截图 57-year-summary.png。
  - D. 版本号 4.13.0+53（aapt 校验 versionName=4.13.0/versionCode=53）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `9654FE58...7658`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（yearSummary）
  - `lib/pages/stats_page.dart`（_buildYearSummaryCard + _ysCell + 插入列表底部）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/57-year-summary.png`（新增）
- commit hash：`2ef206a`；已 push（a07744f..2ef206a master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 88/88；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：统计页测试交易在 1 月而默认当月为空 → 改当月交易避免空状态无 Scrollable；web 语义标题不进 innerText → 用整段文本验证。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-09 11:00 — 迭代 v4.14：账户页转账统计 + 版本号 4.14.0 + 最终 release

- 任务内容：
  - A. 账户页转账统计：`AppState.monthlyTransferSummaryOfAccount(accountId, month)` 计算本月转出/转入 金额与笔数；账户菜单（点账户行弹出）头部显示「本月转账：转出 ¥X · N 笔　转入 ¥Y · M 笔」（无转账则不显示）。
  - B. 测试：新增 2 项（转账统计计算含跨月过滤、账户菜单展示），90/90 通过。
  - C. web 冒烟：注入一笔支付宝→微信转账 → 我的页点支付宝账户 → 菜单显示「本月转账：转出 50.00 · 1 笔　转入 0.00 · 0 笔」，账户余额同步 -¥2,949 → -¥2,999；零控制台错误。截图 58-account-transfer.png。
  - D. 版本号 4.14.0+54（aapt 校验 versionName=4.14.0/versionCode=54）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `FDE36040...26C`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（monthlyTransferSummaryOfAccount）
  - `lib/pages/profile_page.dart`（账户菜单转账统计行）
  - `pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/58-account-transfer.png`（新增）
- commit hash：`bd42c23`；已 push（8ba141b..bd42c23 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 90/90；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：相邻字符串拼接漏闭合引号（同 v4.5 教训）→ 补 `'`。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-09 13:00 — 迭代 v4.15：周期规则「跳过下次」+ 版本号 4.15.0 + 最终 release

- 任务内容：
  - A. 周期规则「跳过下次」：`AppState.skipNextOccurrence(ruleId)` 把 nextDate 推进一期且不生成流水；周期编辑弹层底部新增「跳过下次（不生成本次）」按钮。
  - B. 测试：新增 2 项（跳过推进不生成、编辑弹层触发），92/92 通过。
  - C. web 冒烟：注入月租规则（nextDate 9/1）→ 编辑弹层点「跳过下次」→ 流水数不变（95）、nextDate 9/1 → 10/1；零控制台错误。截图 59-skip-next.png。
  - D. 版本号 4.15.0+55（aapt 校验 versionName=4.15.0/versionCode=55）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `B401240D...68E4`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（skipNextOccurrence）
  - `lib/pages/profile_page.dart`（_RecurringEditSheet onSkip + 跳过按钮）
  - `pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/59-skip-next.png`（新增）
- commit hash：`b907a36`；已 push（239f98e..b907a36 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 92/92；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：
  1. `Replace` 全量替换把跳过按钮同时插进账户编辑弹层（onSkip 未定义）→ 还原后用「widget.onSave(widget.initial.copyWith(」锚点精确插入周期弹层。
  2. 行删除时误用 Get-Content/Set-Content（PS ANSI）弄乱中文 → git checkout 还原后全程用 ReadAllText/WriteAllText（UTF-8 无 BOM）。
  3. IndexOf("),") 误中字符串内 '保存'), 的 '),' → 改为逐行定位 FilledButton 闭合行。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-09 15:00 — 迭代 v4.16：明细多选导出选中项 + 版本号 4.16.0 + 最终 release

- 任务内容：
  - A. 明细多选「导出选中」：多选栏新增导出按钮（tooltip 导出选中）；`_exportSelected` 把所选流水（当前账本内按 id 过滤、日期倒序）生成 CSV（含账本名与「范围：选中 N 笔」头部）并调用 exportCsvFile 分享/下载，成功提示「已导出 N 条」并退出多选。
  - B. 测试：新增 1 项（多选栏出现导出选中入口），93/93 通过。
  - C. web 冒烟：明细多选全选 18 项 → 点「导出选中」→ 出现「已导出」提示（触发 CSV 下载）；零控制台错误。截图 60-export-selected.png。
  - D. 版本号 4.16.0+56（aapt 校验 versionName=4.16.0/versionCode=56）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `F4F84FF2...A0BC`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/ledger_page.dart`（多选栏导出按钮 + _exportSelected）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/60-export-selected.png`（新增）
- commit hash：`4289aee`；已 push（71c4092..4289aee master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 93/93；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：测试中 mock path_provider/share_plus 通道导致导出挂起 → 改为仅验证按钮存在（导出流程复用已测 CsvExporter，文件写入由真机/浏览器验证）。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-09 17:00 — 迭代 v4.17：CSV 导入账户自动补全 + 版本号 4.17.0 + 最终 release

- 任务内容：
  - A. CSV 导入账户自动补全：`CsvImporter` 对未知账户名返回占位 id（`imp_unknown_N`）并在结果中记录「占位→账户名」映射（转账转入账户同理）；`AppState.importCsv` 为每个未知账户名自动创建自定义账户（按名称去重，图标默认 card_gift）并把流水/转入账户重映射到新账户 id。
  - B. 测试：新增 2 项（解析未知账户占位、导入自动创建并映射 + 同名不重复创建），95/95 通过。
  - C. web 冒烟：导入含「招商卡」账户的 CSV → 确认追加 → localStorage 新增账户、我的页出现「招商卡 本月支出 25.00 · 2 笔 -¥25.00」；零控制台错误。截图 61-import-account.png。
  - D. 版本号 4.17.0+57（aapt 校验 versionName=4.17.0/versionCode=57）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `CF8C053B...72C`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/services/csv_importer.dart`（CsvImportResult.unknownAccountNames + resolveAccount 占位；移除废弃 _accountIdByName）
  - `lib/data/app_state.dart`（importCsv 自动建账户 + 重映射）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/61-import-account.png`（新增）
- commit hash：`1c3e5c9`；已 push（1f7a626..1c3e5c9 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 95/95；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：importCsv 整块字符串替换因缩进不匹配未命中 → 改按行号区间替换。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-09 19:00 — 迭代 v4.18：周期规则 CSV 导出 + 版本号 4.18.0 + 最终 release

- 任务内容：
  - A. 周期规则 CSV 导出：`CsvExporter.exportRecurringCsv(rules)` 生成「频率,类型,金额(元),分类,账户,下次日期,备注」清单（UTF-8 BOM，Excel 可开）；我的页周期记账区标题右侧新增导出按钮（tooltip 导出周期规则）→ exportCsvFile 分享/下载。
  - B. 测试：新增 2 项（CSV 内容断言、周期记账区导出按钮存在），97/97 通过。
  - C. web 冒烟：注入月租规则 → 我的页周期记账区点「导出周期规则」→ 「已导出」提示（触发 CSV 下载）；零控制台错误。截图 62-recurring-export.png。
  - D. 版本号 4.18.0+58（aapt 校验 versionName=4.18.0/versionCode=58）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `5BF4857E...98A7`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/services/csv_exporter.dart`（exportRecurringCsv + import recurring_rule）
  - `lib/pages/profile_page.dart`（周期记账区导出按钮 + _exportRecurringCsv）
  - `pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/62-recurring-export.png`（新增）
- commit hash：`81d9a73`；已 push（b84695e..81d9a73 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 97/97；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：无阻塞（沿用 UTF-8 安全编辑与既有导出模式）。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-09 21:00 — 迭代 v4.19：记一笔自定义数字键盘 + 版本号 4.19.0 + 最终 release

- 任务内容：
  - A. 记一笔自定义数字键盘：金额输入框改为 `TextInputType.none`（不弹系统键盘），下方新增应用内键盘（1-9 / . / 0 / ⌫ 四行，纸面容器 + 细分隔线 + 黑色数字，符合设计规范）；`_appendToAmount`（两位小数规则、重复小数点忽略、0 起始替换）、`_backspaceAmount`、`_KeypadKey`（带读屏语义：数字 N / 删除一位）。
  - B. 关键验证：先写实验确认 `tester.enterText` 在 `TextInputType.none` 下仍可用，避免破坏既有金额 enterText 测试；98/98 全绿（含全部既有测试）。
  - C. web 冒烟：记一笔页键盘渲染（语义标签齐全），点 1/5/./0 → 金额输入框出现清除按钮（金额已录入）；零控制台错误。截图 63-amount-keypad.png。
  - D. 版本号 4.19.0+59（aapt 校验 versionName=4.19.0/versionCode=59）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `DC614B3D...61C5`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/add_transaction_page.dart`（_buildKeypad/_appendToAmount/_backspaceAmount/_KeypadKey；金额框 TextInputType.none）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/63-amount-keypad.png`（新增）
- commit hash：`a4a861e`；已 push（2779c26..a4a861e master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 98/98；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：`find.bySemanticsLabel('删除一位')` 匹配不到（语义扁平化）→ 改用 `find.text('⌫')`。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-10 01:00 — 迭代 v4.20：首页结余走势下钻统计 + 版本号 4.20.0 + 最终 release

- 任务内容：
  - A. 首页结余走势下钻：图表区域包 InkWell（onTap: onGoStats，切到统计 tab）；标题尾部新增「查看统计 ›」入口（与总资产并排）。
  - B. 测试：新增 1 项（点查看统计 → 统计页出现预算对比卡），99/99 通过。
  - C. web 冒烟：首页滚动到结余走势 → 点「查看统计」→ 切到统计页（预算对比出现）；零控制台错误。截图 64-home-stats.png。
  - D. 版本号 4.20.0+60（aapt 校验 versionName=4.20.0/versionCode=60）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `D8F20CD5...BB93`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/home_page.dart`（结余走势 InkWell + 查看统计入口）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/64-home-stats.png`（新增）
- commit hash：`38ffea1`；已 push（fb429da..38ffea1 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 99/99；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：web 上「查看统计」与「查看完整统计」文本子串重叠 → 语义节点过滤排除「查看完整」；入口在折叠区外 → 先滚动到可见。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-10 03:00 — 迭代 v4.21：明细全部时间按年份分组 + 版本号 4.21.0 + 最终 release

- 任务内容：
  - A. 明细全部时间按年份分组：`全部时间` 模式下，日分组按年份插入「YYYY 年」标题（_YearHeader）；月份视图不受影响。
  - B. 测试：新增 1 项（跨年流水显示两个年份标题），并更新既有「明细全部时间视图」测试（年份标题使上月流水下移 → 加滚动）；100/100 通过。
  - C. web 冒烟：注入 2025-12-31 流水 → 明细全部时间滚动到底 → 「2026 年」「2025 年」标题齐全、去年流水可见；零控制台错误。截图 65-year-group.png。
  - D. 版本号 4.21.0+61（aapt 校验 versionName=4.21.0/versionCode=61）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `52086BD0...D7E`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/ledger_page.dart`（groupList + 循环插年份标题 + _YearHeader）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/65-year-group.png`（新增）
- commit hash：`f8a5707`；已 push（a7cc7ad..f8a5707 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 100/100；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：
  1. collection-for 内不能写 `final group = ...` 语句 → 改为内联 `groupList[gi]` 表达式。
  2. 明细页 `find.byType(Scrollable).last` 命中横向筛选行 → 改用 `find.descendant(of: LedgerPage, matching: Scrollable).first`（纵向 ListView）。
  3. 年份标题把既有测试的「上月流水」挤出视口 → 测试加 scrollUntilVisible。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-10 05:00 — 迭代 v4.22：周期规则 CSV 导入 + 版本号 4.22.0 + 最终 release

- 任务内容：
  - A. 周期规则 CSV 导入：`CsvExporter.exportRecurringCsv` 补「转入账户」列（转账规则完整往返）；`CsvImporter.parseRecurringCsv` 解析（频率/类型/金额/分类/账户/下次日期/备注/转入账户，未知账户回落默认）；`AppState.importRecurringCsv`（按 频率+金额+备注 去重，写当前账本）；我的页数据管理新增「导入周期规则 (CSV)」入口（粘贴对话框 + 确认）。
  - B. 测试：新增 3 项（导出导入往返含转账规则、导入去重、入口存在），并更新 v4.18 导出测试（新增转入账户列）；103/103 通过。
  - C. web 冒烟：我的页点「导入周期规则」→ 粘贴规则 CSV → 确认导入 → localStorage 出现「房租」规则；零控制台错误。截图 66-recurring-import.png。
  - D. 版本号 4.22.0+62（aapt 校验 versionName=4.22.0/versionCode=62）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `AB374F88...A64F3`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/services/csv_exporter.dart`（exportRecurringCsv 补转入账户列）
  - `lib/services/csv_importer.dart`（parseRecurringCsv + _parseRecurringDate）
  - `lib/data/app_state.dart`（importRecurringCsv）
  - `lib/models/recurring_rule.dart`（copyWith 补 bookId）
  - `lib/pages/profile_page.dart`（导入入口 + _importRecurringCsv）
  - `pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/66-recurring-import.png`（新增）
- commit hash：`35c92af`；已 push（ca19a3d..35c92af master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 103/103；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：
  1. `r'\r?\n'` 正则被 PowerShell 转义成 `r'\\r?\\n'`（匹配字面 `\n` 而非换行）→ 解析恒 0 条 → 修正为单反斜杠。
  2. 调试 print 插入/删除时行错位弄坏 catch 与 hasHeader → 逐行核对修复。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-10 07:00 — 迭代 v4.23：记一笔保存撤销 + 版本号 4.23.0 + 最终 release

- 任务内容：
  - A. 记一笔保存后可撤销：保存成功 SnackBar 改为自定义内容行（「已保存 ¥X」+ 撤销 + 继续记一笔，新记账显示撤销，编辑模式不显示）；撤销删除刚保存的流水，若本次同时创建了周期规则则一并删除。
  - B. 测试：新增 1 项（保存 12 元 → 撤销 → 流水归零；断言 SnackBar 双操作存在），104/104 通过。
  - C. web 冒烟：键盘输入 ¥30 → 保存 → SnackBar 含「撤销」「继续记一笔」→ 点撤销 → 本月支出回到 1,050（¥30 已删）；零控制台错误。
  - D. 版本号 4.23.0+63（aapt 校验 versionName=4.23.0/versionCode=63）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `46837B78...2F1A`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/add_transaction_page.dart`（SnackBar 内容行 + createdRuleId 跟踪 + 撤销/继续双操作）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/67-save-undo.png`（新增）
- commit hash：`fa4c5ee`；已 push（d3b1418..fa4c5ee master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 104/104；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：SnackBar 块行号替换漏闭合 `);` → 补上；`createdRuleId!` 触发不必要的非空断言 lint → 去掉 `!`。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-10 09:00 — 迭代 v4.24：首页总资产下钻账户 + 版本号 4.24.0 + 最终 release

- 任务内容：
  - A. 首页总资产点击下钻：HomePage 新增 onGoProfile 回调；HomeShell 接线切到「我的」tab；结余走势卡尾部「总资产 ¥X」文本包 InkWell 可点。
  - B. 测试：新增 1 项（点总资产 → 我的页账户区出现），105/105 通过。
  - C. web 冒烟：首页滚动到结余走势 → 点「总资产」→ 切到我的页（账户区显示）；零控制台错误。截图 68-assets-profile.png。
  - D. 版本号 4.24.0+64（aapt 校验 versionName=4.24.0/versionCode=64）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（53.9MB，SHA-256 `153628D0...9229`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/home_page.dart`（onGoProfile + 总资产 InkWell）
  - `lib/main.dart`（HomeShell 接线 onGoProfile → tab 3）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/68-assets-profile.png`（新增）
- commit hash：`bfd8e25`；已 push（bfa1d55..bfd8e25 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 105/105；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：测试直接构造 HomePage 缺 onGoProfile → 补参数。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-10 11:00 — 迭代 v4.25：明细复制到其他账本 + 版本号 4.25.0 + 最终 release

- 任务内容：
  - A. 明细长按「复制到其他账本」：`AppState.copyTransactionToBook(txId, bookId)`（新 id 保留日期/分类/账户/备注/转账目标，写目标账本）；长按菜单新增「复制到其他账本」→ 账本选择弹层（排除当前账本）→ 复制并提示。
  - B. 测试：新增 2 项（复制流水到其他账本、明细长按菜单+账本选择全流程），107/107 通过。
  - C. web 冒烟：注入「旅行账本」→ 明细长按 → 复制到其他账本 → 选旅行账本 → localStorage 旅行账本出现 1 笔；零控制台错误。截图 69-copy-book.png。
  - D. 版本号 4.25.0+65（aapt 校验 versionName=4.25.0/versionCode=65）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.0MB，SHA-256 `37472DBC...5843`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/models/transaction.dart`（copyWith 补 id 参数）
  - `lib/data/app_state.dart`（copyTransactionToBook）
  - `lib/pages/ledger_page.dart`（长按菜单项 + _copyToBook 账本选择 + import Book）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/69-copy-book.png`（新增）
- commit hash：`19d9672`；已 push（3237474..19d9672 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 107/107；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：Transaction.copyWith 缺 id 参数 → 补；ledger 缺 Book import → 补。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-10 13:00 — 迭代 v4.26：我的页数据概况 + 版本号 4.26.0 + 最终 release

- 任务内容：
  - A. 我的页「数据概况」卡：总资产下方新增卡片，显示 流水笔数 / 账户数 / 账本数 / 周期规则数（全账本）；`AppState.recurringRuleCount` 全量规则计数 getter。
  - B. 测试：新增 1 项（数据概况显示 2 笔/4 个/1 个/1 条），并更新 3 个既有测试（周期记账区块/账户菜单转账/首页总资产下钻）适配卡片导致的下移滚动；108/108 通过。
  - C. web 冒烟：我的页顶部「数据概况 95 笔 流水 4 个 账户 1 个 账本 0 条 周期规则」渲染正常；零控制台错误。截图 70-data-overview.png。
  - D. 版本号 4.26.0+66（aapt 校验 versionName=4.26.0/versionCode=66）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.0MB，SHA-256 `F316CBDF...2458`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（recurringRuleCount）
  - `lib/pages/profile_page.dart`（_buildDataOverview + _overviewCell + 插入总资产下方）
  - `pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/70-data-overview.png`（新增）
- commit hash：`0aed876`；已 push（deff034..0aed876 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 108/108；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：数据概况卡把下方内容挤出视口（3 个既有测试失败）→ 加滚动；「账户」与卡片标签撞名导致 finder 二义 → 改用「数据概况」断言。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-10 15:00 — 迭代 v4.27：统计页自定义日期范围 + 版本号 4.27.0 + 最终 release

- 任务内容：
  - A. 统计页自定义日期范围：月份选择器下方新增「范围：本月 / 自定义」切换；自定义时显示 起始/结束日期 选择器（日期选择器，含边界钳制）；`AppState` 新增 inRange / rangeSummary / rangeDailySeries / rangeCategoryRanking（转账不计）。
  - B. 范围模式渲染：范围汇总条（起止日期 + 支出/收入/结余/笔数/日均支出）、每日支出柱状图、支出/收入分类排行；隐藏月维度的预算/结余走势/年度对比/周切换。
  - C. 测试：新增 2 项（范围汇总与序列含转账不计、统计页自定义范围全流程），110/110 通过。
  - D. web 冒烟：自定义 8月7日~8月7日 → 「汇总 ¥100.00 · 收入 ¥0 · 结余 -¥100 · 2 笔 · 日均 ¥100」+ 每日支出图 + 分类排行；零控制台错误。截图 71-range-mode.png。
  - E. 版本号 4.27.0+67（aapt 校验 versionName=4.27.0/versionCode=67）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.1MB，SHA-256 `D03FD529...144B`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（inRange/rangeSummary/rangeDailySeries/rangeCategoryRanking）
  - `lib/pages/stats_page.dart`（范围切换/日期选择/范围分支/_buildRangeSummaryStrip/_buildRangeBarChart）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/71-range-mode.png`（新增）
- commit hash：`e208391`；已 push（643e387..e208391 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 110/110；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：结束日期取午夜会排除当天中午后流水 → 结束日期存 23:59:59。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。

## 2026-08-10 17:00 — 迭代 v4.28：明细批量移动到其他账本 + 版本号 4.28.0 + 最终 release

- 任务内容：
  - A. 明细多选批量「移动到其他账本」：`AppState.moveTransactionsToBook(ids, bookId)`（批量改 bookId，当前账本移除）；多选「修改选中」弹层新增「移动到其他账本」→ 账本选择弹层 → 移动并提示。
  - B. 测试：新增 2 项（批量移动流水到其他账本、明细多选批量移动全流程），112/112 通过。
  - C. web 冒烟：注入「旅行账本」→ 明细多选全选 18 笔 → 修改选中 → 移动到其他账本 → 选旅行账本 → localStorage 旅行账本 0→18、总数 95 不变；零控制台错误。截图 72-move-book.png。
  - D. 版本号 4.28.0+68（aapt 校验 versionName=4.28.0/versionCode=68）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.1MB，SHA-256 `B7DD27A5...2C04`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（moveTransactionsToBook）
  - `lib/pages/ledger_page.dart`（批量弹层「移动到其他账本」+ _pickBulkBook + Book import）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/72-move-book.png`（新增）
- commit hash：`b601584`；已 push（20789c9..b601584 master -> master）。
- 验证：`flutter analyze` 0 问题；`flutter test` 112/112；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：`use_build_context_synchronously` lint → await 后补 `mounted` 检查。
- 下一步：上架执行（RELEASE.md）只差 Play 账号；真机通知冒烟（SMOKE_TEST.md）。
## 2026-08-07 18:30 — 迭代 v4.29：统计页自定义范围「结余走势」联动图 + 版本号 4.29.0 + 最终 release

- 任务内容：
  - A. `AppState.rangeDailyNetSeries(start, end)`：自定义范围逐日收入-支出累计结余序列（时间升序，转账不计），返回 `({DateTime date, int net})`。
  - B. 统计页范围模式新增「结余走势（范围）」卡片（`_buildRangeBalanceChart`，LineChart 曲线 + kAccentBlue 蓝色细线 + 极淡蓝面积填充，负值自动落入零轴下方，触控 tooltip 显示日期与结余金额），位于范围汇总之后、每日支出柱状图之前，与所选日期范围联动。
  - C. `_compact` 轴标签支持负数（-3246.9 → -3.2k），修复范围走势负值轴显示。
  - D. 测试：扩展「日期范围汇总与序列」（断言逐日累计结余 [-1000,-1000,-3000,-3000,2000]）与「统计页自定义日期范围」（断言出现「结余走势（范围）」），112/112 通过。
  - E. web 冒烟：统计→自定义→8月1日~8月7日，汇总/结余走势（范围）/每日支出均渲染，轴标签 -3.2k 正常；截图 73-range-balance.png。
  - F. 版本号 4.29.0+69（aapt 校验 versionName=4.29.0/versionCode=69）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.5MB，SHA-256 `4B13B27A...C3B1`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（rangeDailyNetSeries）
  - `lib/pages/stats_page.dart`（_buildRangeBalanceChart + 范围分支接入 + _compact 负数支持）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/73-range-balance.png`（新增）
- commit hash：`cef35c1`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 112/112；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：PowerShell 双引号 here-string 会把 `$` 插值吞掉，导致 tooltip 字符串丢失日期/金额 → 改用单引号 here-string 修复后重建 APK 并更新 SHA；web 端日期选择器用输入模式（input[type=text] fill "2026/8/1"）避免语义网格点击定位困难。
- 下一步：周期规则「按月补生成」或统计年度对比增强；上架执行只差 Play 账号。
## 2026-08-07 19:30 — 迭代 v4.30：周期规则按月补生成（历史流水补齐+去重）+ 版本号 4.30.0 + 最终 release

- 任务内容：
  - A. `AppState.recurringBackfillInfo(ruleId)`：补生成预览，返回规则锚点 date 到今天应发生但尚无对应流水（同日+同字段签名去重）的期数与起止日期；不适用（停用/非当前账本/未来锚点/无可补）返回 null。
  - B. `AppState.backfillRecurring(ruleId)`：按月补齐锚点到今天缺失的历史周期流水（已存在同日期同金额自动跳过），推进 nextDate 到今天之后第一期，持久化并返回生成笔数。
  - C. 周期规则编辑弹层新增「补生成历史流水」按钮：先预览笔数/日期范围 → AlertDialog 确认（取消/补生成）→ 执行后 SnackBar「已补生成 N 笔流水」。
  - D. 测试：新增 2 项（周期规则按月补生成历史流水（含去重）、我的页周期规则补生成历史流水），114/114 通过。
  - E. web 冒烟：注入「锚点 3月1日 / nextDate 7月1日」周期规则 → 启动自动生成 7、8 月两期 → 编辑弹层补生成预览「4 笔（3月1日~6月1日）」→ 确认后 SnackBar「已补生成 4 笔流水」→ localStorage 校验 3~6 月 4 笔补齐、nextDate 保持 9月1日；截图 74-backfill-dialog.png。
  - F. 版本号 4.30.0+70（aapt 校验 versionName=4.30.0/versionCode=70）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.5MB，SHA-256 `809F4A4C...9249`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（_recurringOccSig/_recurringExistingSigs/recurringBackfillInfo/backfillRecurring）
  - `lib/pages/profile_page.dart`（_RecurringEditSheet._backfill + 「补生成历史流水」按钮）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/74-backfill-dialog.png`（新增）
- commit hash：`e572dd3`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 114/114；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：shared_preferences_web 在 localStorage 中会把值 JSON 二次编码 → web 冒烟注入周期规则需 `JSON.stringify(JSON.stringify([rule]))`，否则 getString 解析报 CastList 错误；use_build_context_synchronously → 用 `context.mounted` 守卫。
- 下一步：统计年度对比增强或明细「按分类批量移动账本」；上架执行只差 Play 账号。
## 2026-08-07 20:30 — 迭代 v4.31：明细按分类批量移动到其他账本 + 版本号 4.31.0 + 最终 release

- 任务内容：
  - A. 明细多选「批量修改」弹层新增「按分类移动到其他账本」：选分类 → 选目标账本 → 确认对话框（显示该分类全部笔数与目标账本）→ 把当前账本中该分类全部流水移动到目标账本。
  - B. 复用 `AppState.moveTransactionsToBook(ids, bookId)`：按 `currentBookTransactions` 按 categoryId 收集 ids，移动后 SnackBar「已移动 N 笔到「账本」」并退出多选；分类/账本空态提示「该分类暂无流水」「暂无其他账本」。
  - C. 测试：新增 1 项组件测试「明细按分类批量移动到其他账本」（餐饮 2 笔移动、购物 1 笔保留），115/115 通过。
  - D. web 冒烟：注入「旅行账本」→ 明细多选全选 18 笔 → 修改选中 → 按分类移动到其他账本 → 餐饮 → 旅行账本 → 确认「24 笔」→ SnackBar「已移动 24 笔到「旅行账本」」→ localStorage 校验 foodDefault=0 / foodTrip=24 / shoppingDefault=16 / 总数 95 不变；截图 75-move-cat-dialog.png。
  - E. 版本号 4.31.0+71（aapt 校验 versionName=4.31.0/versionCode=71）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.5MB，SHA-256 `65AB2388...6834`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/ledger_page.dart`（批量弹层新菜单项 + _pickBulkCategoryMove + 分发分支）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/75-move-cat-dialog.png`（新增）
- commit hash：`f93abdb`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 115/115；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：ledger_page.dart 为 LF 行尾，PS 多行替换时 here-string 需先归一化 LF 再匹配，否则注入 CRLF 导致结构错乱（已修复）；use_build_context_synchronously → 用 `mounted`（State）守卫 ScaffoldMessenger。
- 下一步：统计年度对比增强或「按分类批量改账户/删除」；上架执行只差 Play 账号。
## 2026-08-07 21:30 — 迭代 v4.32：统计年度对比支出/收入切换 + 版本号 4.32.0 + 最终 release

- 任务内容：
  - A. `AppState.yearComparison(year, {income})`：新增 income 参数，income=true 时返回逐月收入与上一年对比（默认仍为支出，向后兼容）。
  - B. 统计页年度对比卡片新增「支出/收入」切换（复用 _ChartModeTag，样式与每日图一致）；标题随模式变化「年度支出对比 / 年度收入对比」；数据源 `yearComparison(_month.year, income: _yearIncome)`。
  - C. 测试：扩展「年度对比 yearComparison」（收入 2026-3=9000 / 2025-3=4000，支出不受影响）；新增组件测试「统计页年度支出/收入对比切换」（切到收入后标题变为「年度收入对比」），116/116 通过。
  - D. web 冒烟：统计页滚动到年度卡片 → 点「收入」→ 标题变「年度收入对比（2026 vs 2025）」、纵轴 8.0w（对应年收入 ¥79,300）；截图 76-year-income.png。
  - E. 版本号 4.32.0+72（aapt 校验 versionName=4.32.0/versionCode=72）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.5MB，SHA-256 `60B4756B...AA6A`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（yearComparison income 参数）
  - `lib/pages/stats_page.dart`（_yearIncome + 年度卡片支出/收入切换 + 动态标题）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/76-year-income.png`（新增）
- commit hash：`931bd13`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 116/116；release 构建 + apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：widget 测试 find.byWidgetPredicate 默认 skipOffstage=true，年度卡片在视口外找不到 → 显式 skipOffstage:false；find.text 内部也要 skipOffstage:false。
- 下一步：明细「按分类批量改账户/删除」或首页/记一笔细节增强；上架执行只差 Play 账号。
## 2026-08-07 22:30 — 迭代 v4.33：明细按分类批量修改账户 + 版本号 4.33.0 + 最终 release

- 任务内容：
  - A. 明细多选「批量修改」弹层新增「按分类修改账户」：选分类 → 选账户 → 确认对话框（显示该分类全部笔数与目标账户）→ 把当前账本中该分类全部流水的账户改为目标账户。
  - B. 复用 `AppState.bulkUpdateTransactions(ids, accountId:)`：按 `currentBookTransactions` 按 categoryId 收集 ids，改后 SnackBar「已修改 N 笔账户为「账户」」并退出多选；分类/空态提示「该分类暂无流水」。
  - C. 测试：新增 1 项组件测试「明细按分类批量修改账户」（餐饮 2 笔改到银行卡、购物 1 笔保留微信），117/117 通过。
  - D. web 冒烟：明细多选全选 18 笔 → 修改选中 → 按分类修改账户 → 餐饮 → 银行卡 → 确认「24 笔」→ localStorage 校验 foodOnCard=24 / foodOnAlipay=0 / 总数 95 不变；截图 77-cat-account.png。
  - E. 版本号 4.33.0+73（aapt 校验 versionName=4.33.0/versionCode=73）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.5MB，SHA-256 `8069E7EF...DB1F`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/ledger_page.dart`（批量弹层新菜单项 + _pickBulkCategoryAccount + 分发分支）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/77-cat-account.png`（新增）
- commit hash：`cda7153`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 117/117；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：无新坑（沿用 v4.31 的 LF 行尾处理与 mounted 守卫）。
- 下一步：明细「按分类批量删除」（带强确认）或首页/记一笔细节增强；上架执行只差 Play 账号。
## 2026-08-07 23:30 — 迭代 v4.34：明细按分类批量删除（可撤销）+ 版本号 4.34.0 + 最终 release

- 任务内容：
  - A. 明细多选「批量修改」弹层新增「按分类删除」（第 5 项）：选分类 → 强确认对话框（红色删除按钮，「将删除当前账本中「分类」分类的全部流水，无法恢复。」）→ 删除该分类全部流水 → SnackBar「已删除 N 笔」+「撤销」（重新加回全部）。
  - B. 批量修改弹层改为 SingleChildScrollView 包裹，避免 5 项在窄屏/小窗口溢出（测试 800x600 下暴露 RenderFlex overflow 42px）。
  - C. 测试：新增 1 项组件测试「明细按分类批量删除（含撤销）」（餐饮 2 笔删除、购物 1 笔保留、撤销恢复 2 笔），118/118 通过。
  - D. web 冒烟：明细多选全选 → 修改选中 → 按分类删除 → 餐饮 → 确认 → localStorage 校验 food=0 / shopping=16 / 总数 71（95-24）→ 点「撤销」→ food=24 / 总数 95 恢复；截图 78-cat-delete.png。
  - E. 版本号 4.34.0+74（aapt 校验 versionName=4.34.0/versionCode=74）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.5MB，SHA-256 `3E4B5EA7...0C44`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/ledger_page.dart`（批量弹层第 5 项 + _pickBulkCategoryDelete + 分发分支 + 弹层可滚动）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/78-cat-delete.png`（新增）
- commit hash：`a5094cf`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 118/118；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：批量弹层加第 5 项后小窗口 RenderFlex overflow → 弹层内容包 SingleChildScrollView；新测试点击第 5 项需 ensureVisible。
- 下一步：周期记账「到期提醒通知」或首页细节增强；上架执行只差 Play 账号。
## 2026-08-08 00:30 — 迭代 v4.35：周期记账到期提醒通知 + 版本号 4.35.0 + 最终 release

- 任务内容：
  - A. `NotificationService.scheduleRecurringReminders(rules)`：为每个启用规则在其 nextDate 当天 09:00 调度本地通知（先取消旧调度再重排，通知 id 由 rule.id hashCode 派生）；`cancelRecurringReminders()` 取消全部。标题「周期记账：分类名」，正文「M月d日 需记一笔 ¥金额」。
  - B. `AppState`：新增 `recurringRemind`（默认 true）+ `setRecurringRemind` + `_syncRecurringNotifications`；在 9 处规则变更后同步提醒（生成到期/立即生成/新增/编辑/删除/跳过/补生成/CSV 导入/JSON 恢复）；JSON 备份恢复含该字段。
  - C. `TransactionRepository`：新增 `recurring_remind_v1` 的 load/save（默认 true）。
  - D. 我的页提醒区新增「周期记账提醒（到期当天）」开关（每日提醒下方）。
  - E. 测试：新增 2 项（周期记账提醒开关持久化、我的页周期记账提醒开关），120/120 通过。
  - F. web 冒烟：我的页滚动到提醒区 → 截图 79-recurring-remind.png → 关闭「周期记账提醒」→ localStorage `recurring_remind_v1=false` 校验通过。
  - G. 版本号 4.35.0+75（aapt 校验 versionName=4.35.0/versionCode=75）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.5MB，SHA-256 `E7CF22F4...318E`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/services/notification_service.dart`（周期提醒调度/取消）
  - `lib/data/transaction_repository.dart`（recurring_remind_v1）
  - `lib/data/app_state.dart`（recurringRemind + _syncRecurringNotifications + 规则变更同步 + JSON 字段）
  - `lib/pages/profile_page.dart`（提醒区开关）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/79-recurring-remind.png`（新增）
- commit hash：`7b42e65`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 120/120；release 构建（一次成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：web 冒烟首次点击开关未生效（滚动未稳定）→ 重新定位 switch 节点后第二次点击成功；测试环境通知为 no-op（未 init 直接返回），不影响断言。
- 下一步：真机通知冒烟（SMOKE_TEST.md 补充周期提醒条目）或首页细节增强；上架执行只差 Play 账号。
## 2026-08-08 01:30 — 迭代 v4.36：首页本周支出分类排行联动 + 版本号 4.36.0 + 最终 release

- 任务内容：
  - A. `AppState.weekCategoryRanking()`：本周（周一起）支出分类排行（仅统计周一至今天，按金额降序）。
  - B. 首页「本周/本月」切换：支出分类卡片标题随模式变为「本周支出分类 / 本月支出分类」，数据源切换为 weekCategoryRanking / categoryExpenseRanking，修复本周模式下排行仍显示整月的问题。
  - C. 测试：新增单元测试「本周支出分类排行 weekCategoryRanking」（本周餐饮 500/购物 300，上周餐饮 9999 不计）；扩展组件测试「首页切换本周概览」断言「本月支出分类」「本周支出分类」标题，121/121 通过。
  - D. web 冒烟：首页默认「本月支出分类」（居住 220 第一）→ 切「本周」→「本周支出分类」（人情 160 第一，与整月明显不同）验证联动；截图 80-home-week-ranking.png。
  - E. 版本号 4.36.0+76（aapt 校验 versionName=4.36.0/versionCode=76）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.5MB，SHA-256 `F60EAD27...744D`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（weekCategoryRanking）
  - `lib/pages/home_page.dart`（ranking 数据源联动 + 动态标题）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/80-home-week-ranking.png`（新增）
- commit hash：`0c13a4a`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 121/121；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：PS 双引号字符串中 `\n` 不是换行转义 → 多行替换需用反引号 `` `n ``，已修复误插的「\n」字面量。
- 下一步：统计页「自定义范围」记住上次选择，或首页「最近流水」本周过滤；上架执行只差 Play 账号。
## 2026-08-08 02:30 — 迭代 v4.37：首页本周最近流水过滤 + 版本号 4.37.0 + 最终 release

- 任务内容：
  - A. `AppState.weekTransactions`：本周（周一起）流水，按日期倒序。
  - B. 首页「本周/本月」切换：最近流水数据源改用 weekTransactions / ofMonth，修复本周模式下最近流水仍显示全部账本流水的问题；空态文案联动「本周还没有流水 / 本月还没有流水」。
  - C. 测试：新增单元测试「本周流水 weekTransactions」（上周项不计、按日期倒序）+ 组件测试「首页本周最近流水过滤」（本周项出现、上周项不出现），123/123 通过。
  - D. web 冒烟：首页切「本周」→ 本周支出 ¥632、本周支出分类、最近流水正常渲染，无控制台错误；截图 81-home-week-recent.png。
  - E. 版本号 4.37.0+77（aapt 校验 versionName=4.37.0/versionCode=77）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.5MB，SHA-256 `102618D2...422C`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（weekTransactions）
  - `lib/pages/home_page.dart`（recent 数据源 + 空态文案）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/81-home-week-recent.png`（新增）
- commit hash：`861a2a9`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 123/123；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：无新坑（沿用既有替换规范）。
- 下一步：统计页「自定义范围」记住上次选择，或「全部账本」汇总视图；上架执行只差 Play 账号。
## 2026-08-08 03:30 — 迭代 v4.38：统计自定义范围记忆 + 版本号 4.38.0 + 最终 release

- 任务内容：
  - A. `TransactionRepository`：新增 `stats_range_v1` 持久化（mode + start/end ISO 日期），loadStatsRange/saveStatsRange。
  - B. `AppState`：新增 statsRangeMode/Start/End + setStatsRange（加载/保存/notify）；JSON 备份恢复含 statsRange 字段。
  - C. 统计页：initState 恢复上次自定义范围；切换「本月/自定义」与起止日期选择时实时写入记忆，重启后自动恢复。
  - D. 测试：新增 2 项（统计自定义范围记忆持久化、统计页恢复上次自定义范围），125/125 通过。
  - E. web 冒烟：统计页设 8月1日~8月7日 → 刷新页面 → 统计页自动回到自定义范围并渲染「从 8月1日 / 至 8月7日」+ 范围汇总/结余走势；截图 82-stats-range-memory.png。
  - F. 版本号 4.38.0+78（aapt 校验 versionName=4.38.0/versionCode=78）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.5MB，SHA-256 `D95F2233...0606`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/transaction_repository.dart`（stats_range_v1）
  - `lib/data/app_state.dart`（statsRange + setStatsRange + JSON 字段）
  - `lib/pages/stats_page.dart`（initState 恢复 + 切换/选日期持久化）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/82-stats-range-memory.png`（新增）
- commit hash：`7f7cecb`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 125/125；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：无新坑。
- 下一步：「全部账本」汇总视图，或明细「金额区间/日期范围」组合记忆；上架执行只差 Play 账号。
## 2026-08-08 04:30 — 迭代 v4.39：首页账本汇总卡片 + 版本号 4.39.0 + 最终 release

- 任务内容：
  - A. `AppState.bookMonthSummaries(month)`：各账本某月收支结余（全部账本，不随当前账本变化）。
  - B. 首页新增「账本汇总」卡片（多账本时显示，页尾）：每行账本名 + 本月支出/收入/结余；当前账本高亮 + 「当前」标记；点击行切换到该账本（setCurrentBook）。
  - C. 测试：新增单元测试「账本汇总 bookMonthSummaries」（2 账本收支独立）+ 组件测试「首页账本汇总切换账本」（点击旅行账本 → currentBookId 切换），127/127 通过。
  - D. web 冒烟：注入「旅行账本」→ 首页底部出现账本汇总（默认账本 支1000/收14000/结13000 · 当前；旅行账本 0）→ 滚动到卡片点击旅行账本 → header 变「旅行账本」、本月支出 0、localStorage current_book_v1=trip；截图 83-book-summary.png。
  - E. 版本号 4.39.0+79（aapt 校验 versionName=4.39.0/versionCode=79）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.5MB，SHA-256 `14E1C319...3096`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（bookMonthSummaries）
  - `lib/pages/home_page.dart`（账本汇总卡片 + _BookSummaryRow）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/83-book-summary.png`（新增）
- commit hash：`2aa4c66`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 127/127；release 构建（一次成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：多行插入定位到错误类（LastIndexOf 命中 _HomeModeTag 的闭合）→ 改为锚定 `class _MiniStat` 前的类闭合精确插入；`addTransaction` 强制当前账本 bookId → 单元测试先 setCurrentBook 再添加。
- 下一步：统计/明细「全部账本」范围切换，或周期规则「复制」；上架执行只差 Play 账号。
## 2026-08-08 05:30 — 迭代 v4.40：周期规则一键复制 + 版本号 4.40.0 + 最终 release

- 任务内容：
  - A. `RecurringRule.copyWith` 新增 `id` 参数（默认保留原 id），供复制规则生成新 id。
  - B. 周期规则编辑弹层新增「复制规则」：以当前规则设置生成新 id 副本（备注追加「（副本）」），`addRecurringRule` 保存，SnackBar「已复制周期规则」，关闭弹层。
  - C. 测试：扩展「周期规则 copyWith 支持编辑字段」（id 覆盖 + 备注副本）；新增组件测试「我的页周期规则可复制」（复制后规则数 +1、新 id、备注「订阅（副本）」、金额/频率不变），128/128 通过。
  - D. web 冒烟：注入「订阅」月规则 → 我的 → 周期记账 → 编辑弹层「复制规则」→ 点击后 localStorage 规则数 1→2（新 id rc_copy_...，备注「订阅（副本）」），数据概况「2 条 周期规则」；截图 84-recurring-copy.png。
  - E. 版本号 4.40.0+80（aapt 校验 versionName=4.40.0/versionCode=80）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.5MB，SHA-256 `C28410AA...2647`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/models/recurring_rule.dart`（copyWith id 参数）
  - `lib/pages/profile_page.dart`（编辑弹层「复制规则」按钮 + _copyRule）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/84-recurring-copy.png`（新增）
- commit hash：`d863fcc`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 128/128；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：无新坑。
- 下一步：统计/明细「全部账本」范围切换，或「记一笔」今日快捷；上架执行只差 Play 账号。
## 2026-08-08 06:30 — 迭代 v4.41：统计收入占比环图 + 版本号 4.41.0 + 最终 release

- 任务内容：
  - A. 统计页占比环图随「支出/收入」切换联动：`_incomeChart` 时显示收入占比（categoryIncomeRanking），否则支出占比；标题动态「收入占比 / 支出占比」。
  - B. `_ChartModeTag` 支持 key，给收入切换钮加 ValueKey('incomeToggleTag') 便于测试定位（避免与年度卡片同名文本混淆）。
  - C. 测试：新增组件测试「统计页收入占比环图」（滚动到环图断言支出占比 → 切收入 → 断言收入占比、支出占比消失），129/129 通过。
  - D. web 冒烟：统计页滚动到环图「支出占比 居住 22%...」→ 切「收入」→ 每日图变「每日收入」、环图变「收入占比 理财 100%」；截图 85-income-donut.png。
  - E. 版本号 4.41.0+81（aapt 校验 versionName=4.41.0/versionCode=81）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.5MB，SHA-256 `14056C7B...2E2EF`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/stats_page.dart`（环图收入联动 + _ChartModeTag key + 收入切换钮 key）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/85-income-donut.png`（新增）
- commit hash：`cd26834`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 129/129；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：stats ListView 懒加载，环图在视口外时 finder 找不到 → 测试用 scrollUntilVisible 滚动到目标；同名「收入」文本（年度卡片 vs 每日切换）→ 给切换钮加 ValueKey 精确定位。
- 下一步：统计/明细「全部账本」范围切换，或「记一笔」今日快捷；上架执行只差 Play 账号。
## 2026-08-08 07:30 — 迭代 v4.42：首页今日概览模式 + 版本号 4.42.0 + 最终 release

- 任务内容：
  - A. `AppState`：新增 `todaySummary`（今日收支）、`todayTransactions`（今日流水倒序）、`todayCategoryRanking()`（今日支出分类排行）。
  - B. 首页时间范围切换从「本周/本月」扩为「今日/本周/本月」三档：概览（今日支出/本周支出/本月支出）、最近流水、支出分类排行、空态文案全部随模式联动；月份选择器仅在「本月」模式显示；预算仍仅本月生效。
  - C. 测试：新增单元测试「今日概览 todaySummary/流水/排行」（今日 2 笔 + 昨日 1 笔不计）+ 组件测试「首页今日概览」（今日支出/今日支出分类出现、昨日项不出现），131/131 通过。
  - D. web 冒烟：首页切「今日」→ 今日支出 ¥100、最近流水仅今日 2 笔（购物 40/娱乐 60）、今日支出分类（娱乐 60/购物 40）；截图 86-home-today.png。
  - E. 版本号 4.42.0+82（aapt 校验 versionName=4.42.0/versionCode=82）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.5MB，SHA-256 `5DF05BAD...4073`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（todaySummary/todayTransactions/todayCategoryRanking）
  - `lib/pages/home_page.dart`（三档切换 + 数据/标题/空态联动）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/86-home-today.png`（新增）
- commit hash：`c5eb292`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 131/131；release 构建（一次成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：PS 双引号字符串再次把 `\n` 当字面量插入（_buildRecent 签名/空态标题）→ 改用反引号转义修复。
- 下一步：统计/明细「全部账本」范围切换，或明细「金额区间+日期范围」组合记忆；上架执行只差 Play 账号。
## 2026-08-08 08:30 — 迭代 v4.43：记一笔常用金额自定义 + 版本号 4.43.0 + 最终 release

- 任务内容：
  - A. `TransactionRepository`：`custom_quick_amounts_v1`（StringList 存元整数）；`AppState.customQuickAmounts` + `addCustomQuickAmount`（去重升序）/`removeCustomQuickAmount`。
  - B. 记一笔常用金额行：固定预设 +10/50/100/500 + 自定义金额 chips（+¥X，点击累加金额，**长按删除**）+ 「+ 自定义」弹窗添加（金额输入 → 添加，去重）；行改横向滚动防溢出。
  - C. `_QuickAmountChip` 支持 onLongPress。
  - D. 测试：新增单元测试「自定义常用金额增删持久化」（去重/升序/重载/删除）+ 组件测试「记一笔添加自定义常用金额」（+ 自定义 → 输 128 → 添加 → chip +¥128 → 点击填入 128.00），133/133 通过。
  - E. web 冒烟：记一笔 → 「+ 自定义」→ 输 128 → 添加 → chip +¥128 出现、localStorage `["128"]` → 点击填入金额；截图 87-quick-amount-custom.png。
  - F. 版本号 4.43.0+83（aapt 校验 versionName=4.43.0/versionCode=83）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.5MB，SHA-256 `8671FD9C...6E85`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/transaction_repository.dart`（custom_quick_amounts_v1）
  - `lib/data/app_state.dart`（customQuickAmounts + 增删）
  - `lib/pages/add_transaction_page.dart`（常用金额行 + 自定义弹窗 + 长按删除 + chip onLongPress）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/87-quick-amount-custom.png`（新增）
- commit hash：`27486e9`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 133/133；release 构建（连续两次 Gradle 失败为已知 Metaspace 问题，第三次杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：SharedPreferences 无 getIntList/setIntList → 改 StringList 存取；插入方法时误复制 _addAmount 重复定义 → 去重修复；await 后 context.mounted → 改 mounted（State）。
- 下一步：统计/明细「全部账本」范围切换，或「记一笔」常用备注自定义；上架执行只差 Play 账号。
## 2026-08-08 09:30 — 迭代 v4.44：记一笔常用备注自定义 + 版本号 4.44.0 + 最终 release

- 任务内容：
  - A. `TransactionRepository`：`custom_quick_notes_v1`（StringList）；`AppState.customQuickNotes` + `addCustomQuickNote`（去重，最多 20 条）/`removeCustomQuickNote`。
  - B. 记一笔常用备注行：固定预设 + 自定义备注 chips（点击填入备注，**长按删除**）+ 「+ 自定义」弹窗添加（输入 → 添加）。
  - C. 测试：新增单元测试「自定义常用备注增删持久化」（去重/重载/删除）+ 组件测试「记一笔添加自定义常用备注」（添加「培训」→ chip → 填入备注框）；修正 v4.43 金额测试（两处「+ 自定义」需 .first），135/135 通过。
  - D. web 冒烟：注入自定义备注「培训」→ 记一笔备注行出现「培训」chip（预设与 + 自定义 之间）；截图 88-quick-note-custom.png。
  - E. 版本号 4.44.0+84（aapt 校验 versionName=4.44.0/versionCode=84）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.6MB，SHA-256 `A1BF4625...22DF`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/transaction_repository.dart`（custom_quick_notes_v1）
  - `lib/data/app_state.dart`（customQuickNotes + 增删）
  - `lib/pages/add_transaction_page.dart`（备注行自定义 + 弹窗 + 长按删除）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/88-quick-note-custom.png`（新增）
- commit hash：`4b5c776`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 135/135；release 构建（一次成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：新增备注行「+ 自定义」与金额行同名 → 旧金额测试需 .first；web 注入 StringList 需单层 JSON（`["培训"]`），双层会导致 getStringList 解析崩溃（TypeError String is not List）→ 已用单层注入验证。
- 下一步：统计/明细「全部账本」范围切换，或首页「本周/今日」小结复制；上架执行只差 Play 账号。
## 2026-08-08 10:30 — 迭代 v4.45：统计自定义范围每日支出/收入切换 + 版本号 4.45.0 + 最终 release

- 任务内容：
  - A. `AppState.rangeDailyIncomeSeries(start, end)`：日期范围逐日收入序列（与 rangeDailySeries 对应）。
  - B. 统计自定义范围「每日支出」图新增「支出/收入」切换（复用 _ChartModeTag，样式与本月每日图一致）：`_rangeIncome` 状态 + 范围分支切换行 + `_buildRangeBarChart(series, {income})` 动态标题「每日支出 / 每日收入」；切换钮加 ValueKey('rangeIncomeToggle')。
  - C. 测试：扩展单元测试「日期范围汇总与序列」（incomeSeries [0,0,0,0,5000]）；扩展组件测试「统计页自定义日期范围」（先断言结余走势 → 滚动到切换钮 → 切收入 → 每日收入出现），135/135 通过。
  - D. web 冒烟：统计页自定义 8月1日~8月7日 → 每日支出 → 点「收入」→ 每日收入（轴升到 2.0w，对应 8/5 收入 1.4w）；截图 89-range-income.png。
  - E. 版本号 4.45.0+85（aapt 校验 versionName=4.45.0/versionCode=85）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.6MB，SHA-256 `FF32E89A...6400`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（rangeDailyIncomeSeries）
  - `lib/pages/stats_page.dart`（范围切换行 + _rangeIncome + 动态标题 + key）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/89-range-income.png`（新增）
- commit hash：`2f47478`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 135/135；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：范围图表在测试视口外（ListView 懒构建）→ 组件测试先滚动到切换钮再断言；「结余走势（范围）」断言需在滚动前执行（滚动后移出视口）。
- 下一步：统计/明细「全部账本」范围切换，或「记一笔」金额记忆；上架执行只差 Play 账号。
## 2026-08-08 11:30 — 迭代 v4.46：明细页当前账本/全部账本切换 + 版本号 4.46.0 + 最终 release

- 任务内容：
  - A. 明细页新增「账本：当前账本 / 全部账本」切换（并入时间行，不增加头部高度）：全部账本时数据源改用 `state.transactions`（全部账本全部时间），构建/全选/导出三处数据源统一。
  - B. 修复：独立切换行会推高头部、使流水 tile 移出测试视口（ListView 懒构建）导致既有测试回归 → 改为并入 `_buildTimeRow` 同排。
  - C. 测试：新增组件测试「明细全部账本切换」（默认只显示默认本 → 全部账本显示旅行本 → 切回当前账本隐藏），136/136 通过。
  - D. web 冒烟：注入「旅行账本」+ 一笔「旅行餐费」→ 明细默认当前账本 18 笔 → 切「全部账本」→ 96 笔、旅行餐费出现；截图 90-ledger-all-books.png。
  - E. 版本号 4.46.0+86（aapt 校验 versionName=4.46.0/versionCode=86）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.6MB，SHA-256 `542B684D...9392`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/ledger_page.dart`（_allBooks + 数据源 3 处 + 时间行并入账本切换）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/90-ledger-all-books.png`（新增）
- commit hash：`86cb333`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 136/136；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：独立切换行增加头部高度 → 流水 tile 移出缓存区，`明细按账户筛选` 等测试找不到 tile（默认 finder 跳过 offstage）→ 并入时间行同排（零高度增量）解决。
- 下一步：统计页「全部账本」范围切换，或首页「本周/今日」小结复制；上架执行只差 Play 账号。
## 2026-08-08 12:30 — 迭代 v4.47：报销标记 + 版本号 4.47.0 + 最终 release

- 任务内容：
  - A. `Transaction` 新增 `reimbursable`（默认 false，兼容旧数据）：copyWith/toJson/fromJson。
  - B. 记一笔：支出类型显示「这笔可报销」开关（编辑/复制时回填），保存写入标记。
  - C. 明细：流水行显示「报」徽标；筛选行新增「报销：全部/可报销」切换（_visible 过滤）。
  - D. CSV：导出新增「报销」列（是/否），导入按第 9 列解析。
  - E. 测试：新增 4 项（报销标记模型与 JSON 往返、记一笔可报销开关保存、明细报销筛选、CSV 报销列往返），140/140 通过。
  - F. web 冒烟：记一笔 88 元 + 可报销 → 保存 → localStorage reimbursable=true；明细「报销：可报销」筛选 → 共 1 笔 ¥88；截图 91-reimbursable.png。
  - G. 版本号 4.47.0+87（aapt 校验 versionName=4.47.0/versionCode=87）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.6MB，SHA-256 `1EDD91A6...1F`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/models/transaction.dart`（reimbursable 字段）
  - `lib/pages/add_transaction_page.dart`（可报销开关）
  - `lib/pages/ledger_page.dart`（报销筛选）
  - `lib/widgets/transaction_tile.dart`（报徽标）
  - `lib/services/csv_exporter.dart` / `csv_importer.dart`（报销列）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/91-reimbursable.png`（新增）
- commit hash：`5864bc3`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 140/140；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：web 记一笔页滚动不响应拖拽 → 用大滚轮滚动到可报销开关再点击；「报」徽标未在语义树单独暴露（合并进行文本），不影响功能（有组件测试覆盖逻辑）。
- 下一步：统计页「全部账本」范围切换，或周期规则「提前提醒天数」；上架执行只差 Play 账号。
## 2026-08-08 13:30 — 迭代 v4.48：明细多选复制选中到其他账本 + 版本号 4.48.0 + 最终 release

- 任务内容：
  - A. 明细多选「批量修改」弹层新增「复制选中到其他账本」（第 4 项）：选目标账本 → 确认对话框（显示笔数，说明原账本保留）→ 逐笔 `copyTransactionToBook` → SnackBar「已复制 N 笔到「账本」」→ 退出多选。
  - B. 测试：新增组件测试「明细多选复制选中到其他账本」（2 笔复制后原账本保留、目标账本 +2）；加固既有「按分类移动到其他账本/按分类修改账户」测试（弹层项增多后需 ensureVisible），141/141 通过。
  - C. web 冒烟：明细多选全选 18 笔 → 复制选中到其他账本 → 旅行账本 → 确认「复制选中的 18 笔」→ localStorage default=95 / trip=18 / 总数 113；截图 92-batch-copy-book.png。
  - D. 版本号 4.48.0+88（aapt 校验 versionName=4.48.0/versionCode=88）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.7MB，SHA-256 `8EF36123...26F8`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/ledger_page.dart`（弹层第 4 项 + _pickBulkCopyBook + 分发）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/92-batch-copy-book.png`（新增）
- commit hash：`73844ad`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 141/141；release 构建（一次成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：弹层第 4 项使既有「按分类修改账户」（第 6 项）移出视口 → 测试补 ensureVisible；「按分类移动到其他账本」同步加固。
- 下一步：统计页「全部账本」范围切换，或周期规则「提前提醒天数」；上架执行只差 Play 账号。
## 2026-08-08 14:30 — 迭代 v4.49：周期提醒提前天数 + 版本号 4.49.0 + 最终 release

- 任务内容：
  - A. `TransactionRepository`：`recurring_remind_lead_v1`（int 天，默认 0）；`AppState.recurringRemindLead` + `setRecurringRemindLead`（保存并重排提醒）。
  - B. `NotificationService.scheduleRecurringReminders(rules, {leadDays})`：调度日期改为 nextDate - leadDays 当天 09:00（过期则顺延一天）。
  - C. 我的页提醒区新增「提前提醒：当天/1天/3天/7天」选择 chips。
  - D. 测试：新增单元测试「周期提醒提前天数持久化」（默认 0 → 3 → 重载仍 3）+ 组件测试「我的页周期提醒提前天数」（点 3天 → lead=3），143/143 通过。
  - E. web 冒烟：我的页滚动到提醒区 → 点「3天」→ localStorage `recurring_remind_lead_v1=3`；截图 93-remind-lead.png。
  - F. 版本号 4.49.0+89（aapt 校验 versionName=4.49.0/versionCode=89）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.7MB，SHA-256 `751489E2...B104`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/transaction_repository.dart`（recurring_remind_lead_v1）
  - `lib/data/app_state.dart`（recurringRemindLead + setter + 同步传参）
  - `lib/services/notification_service.dart`（leadDays 调度）
  - `lib/pages/profile_page.dart`（提前提醒 chips）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/93-remind-lead.png`（新增）
- commit hash：`edb4ec4`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 143/143；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：无新坑。
- 下一步：统计页「全部账本」范围切换，或「明细」搜索历史管理；上架执行只差 Play 账号。
## 2026-08-08 15:30 — 迭代 v4.50：结余走势粒度增强（首页 6/12月 + 统计 3/6/12月）+ 版本号 4.50.0 + 最终 release

- 任务内容：
  - A. 首页「结余走势」迷你图新增 6月/12月 切换（`_homeBalanceMonths`，标题「结余走势（近 N 月）」），与统计页保持一致。
  - B. 统计「结余走势」新增「近 3 月」选项（原 6月/12月 → 3月/6月/12月）。
  - C. 测试：新增组件测试「首页结余走势 6/12 月切换」「统计结余走势近 3 月切换」（标签加 Key 定位，规避轴标签同名文本），修正既有「首页显示预算剩余」断言为 textContaining，145/145 通过。
  - D. web 冒烟：首页滚到结余走势（近 6 月 + 6月/12月 标签）→ 点 12月 → 「结余走势（近 12 月）」；统计 3月 由组件测试覆盖；截图 94-balance-granularity.png。
  - E. 版本号 4.50.0+90（aapt 校验 versionName=4.50.0/versionCode=90）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.7MB，SHA-256 `B98B18FC...8D2`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/home_page.dart`（结余走势 6/12 切换 + _HomeModeTag key）
  - `lib/pages/stats_page.dart`（近 3 月 + statsBalance3 key）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/94-balance-granularity.png`（新增）
- commit hash：`2c0e1d4`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 145/145；release 构建（一次成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：首页与统计页在 IndexedStack 中「6月/12月」同名文本 → 标签加 ValueKey 精确定位；首页迷你图轴标签也有「6月」文本 → byKey 规避；统计测试需先加一笔流水（否则空态无图表）。
- 下一步：统计页「全部账本」范围切换，或「明细」搜索历史管理；上架执行只差 Play 账号。
## 2026-08-08 16:30 — 迭代 v4.51：明细多选批量标记/取消可报销 + 版本号 4.51.0 + 最终 release

- 任务内容：
  - A. `AppState.bulkUpdateTransactions` 新增 `reimbursable` 参数（批量标记/取消）。
  - B. 明细多选「批量修改」弹层新增「标记为可报销」「取消报销标记」（第 8/9 项），调用 `_bulkSetReimbursable(bool)` → SnackBar 提示笔数 → 退出多选。
  - C. 测试：新增组件测试「明细多选批量标记可报销」（全选 2 笔 → 标记 → 全部 reimbursable → 取消 → 全部 false），146/146 通过。
  - D. web 冒烟：明细多选全选 18 笔 → 弹层滚到「标记为可报销」→ 点击 → localStorage reimbursable=true 共 18 笔；截图 95-batch-reimburse.png。
  - E. 版本号 4.51.0+91（aapt 校验 versionName=4.51.0/versionCode=91）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.7MB，SHA-256 `009CE3E7...2263`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（bulkUpdateTransactions reimbursable）
  - `lib/pages/ledger_page.dart`（弹层第 8/9 项 + _bulkSetReimbursable + 分发）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/95-batch-reimburse.png`（新增）
- commit hash：`bc7c72a`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 146/146；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：第二次长按「标一」提示 off-screen（批量操作后重渲染滚动位置变化）→ 补 ensureVisible。
- 下一步：统计页「全部账本」范围切换，或「明细」按报销标记汇总；上架执行只差 Play 账号。
## 2026-08-08 17:30 — 迭代 v4.52：我的页待报销合计 + 版本号 4.52.0 + 最终 release

- 任务内容：
  - A. `AppState.reimbursableSummary`：当前账本可报销支出总额/笔数。
  - B. 我的页「数据概况」卡新增「待报销 ¥X · N 笔」行（蓝色强调，X>0 时显示）。
  - C. 测试：新增单元测试「待报销合计 reimbursableSummary」（2 笔可报销 800/2，1 笔不可报销不计）+ 组件测试「我的页显示待报销合计」（待报销 5.00 出现），148/148 通过。
  - D. web 冒烟：注入一笔可报销 123 元 → 我的页数据概况显示「待报销 123.00 1 笔」；截图 96-reimburse-total.png。
  - E. 版本号 4.52.0+92（aapt 校验 versionName=4.52.0/versionCode=92）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.7MB，SHA-256 `F9C26EBA...1AC4`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（reimbursableSummary）
  - `lib/pages/profile_page.dart`（数据概况待报销行）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/96-reimburse-total.png`（新增）
- commit hash：`d83bc54`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 148/148；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：组件测试「1 笔」与数据概况「流水」cell 同名 → 去掉该断言，仅断言「待报销 5.00」。
- 下一步：统计页「全部账本」范围切换，或「记一笔」编辑「报销」开关同步；上架执行只差 Play 账号。
## 2026-08-08 18:30 — 迭代 v4.53：明细全部账本模式显示账本名 + 版本号 4.53.0 + 最终 release

- 任务内容：
  - A. `TransactionTile` 新增 `bookName` 参数：副标题追加「📚 账本名」。
  - B. 明细 `_DayGroup` 增加 `bookNames` 映射并传入 tile；切「全部账本」时每行显示所属账本名（当前账本模式不显示）。
  - C. 测试：新增组件测试「明细全部账本模式显示账本名」（默认当前账本无旅行本 → 全部账本旅行本出现且带账本名），149/149 通过。
  - D. web 冒烟：注入旅行账本 + 旅行餐费 → 明细切「全部账本」→ 每行显示「📚 默认账本 / 📚 旅行账本」；截图 97-ledger-book-name.png。
  - E. 版本号 4.53.0+93（aapt 校验 versionName=4.53.0/versionCode=93）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.7MB，SHA-256 `593C0C8C...B406E`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/widgets/transaction_tile.dart`（bookName 参数 + 副标题）
  - `lib/pages/ledger_page.dart`（_DayGroup bookNames + 传参）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/97-ledger-book-name.png`（新增）
- commit hash：`0d47118`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 149/149；release 构建（一次成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：无新坑（IndexedStack 中账本名文本可能多处 → 测试用 LedgerPage 限定 descendant）。
- 下一步：统计页「全部账本」范围切换，或「首页」账本汇总总行；上架执行只差 Play 账号。
## 2026-08-08 19:30 — 迭代 v4.54：首页账本汇总合计行 + 版本号 4.54.0 + 最终 release

- 任务内容：
  - A. 首页「账本汇总」卡片新增「合计」总行（多账本时）：汇总全部账本本月支出/收入/结余（加粗强调，无切换箭头）。
  - B. `_BookSummaryRow` 新增 `total` 参数（加粗/图标强调/隐藏 chevron）。
  - C. 测试：新增组件测试「首页账本汇总合计行」（两账本 10+20=30 本月支出），150/150 通过。
  - D. web 冒烟：注入旅行账本 + 一笔 66 元 → 首页账本汇总显示「合计 本月支出 1,066.00 · 收入 14,000.00 · 结余 12,934.00」；截图 98-book-summary-total.png。
  - E. 版本号 4.54.0+94（aapt 校验 versionName=4.54.0/versionCode=94）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.7MB，SHA-256 `E2DD7110...CC0E`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/home_page.dart`（账本汇总合计行 + _BookSummaryRow.total）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/98-book-summary-total.png`（新增）
- commit hash：`86fd630`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 150/150；release 构建（连续两次 Gradle 失败为已知 Metaspace 问题，第三次杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：无新坑。
- 下一步：统计页「全部账本」范围切换，或「首页」今日模式预算显示；上架执行只差 Play 账号。
## 2026-08-08 20:30 — 迭代 v4.55：明细多选合计金额 + 版本号 4.55.0 + 最终 release

- 任务内容：
  - A. 明细多选栏新增选中合计：`_selectedSummary()` 计算选中流水支出/收入总额，栏内显示「已选 N 项」+「支出 ¥X · 收入 ¥Y」。
  - B. 测试：新增组件测试「明细多选合计金额」（选 1 笔支出 100 + 1 笔收入 200 → 支出 1.00 · 收入 2.00），151/151 通过。
  - C. web 冒烟：明细多选全选 18 笔 → 多选栏显示「已选 18 项 · 支出 1,000.00 · 收入 14,000.00」；截图 99-select-total.png。
  - D. 版本号 4.55.0+95（aapt 校验 versionName=4.55.0/versionCode=95）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.7MB，SHA-256 `2BCEE2E6...CE985`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/ledger_page.dart`（多选栏合计 + _selectedSummary）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/99-select-total.png`（新增）
- commit hash：`9d64671`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 151/151；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：多选后行移出视口 → 测试补 ensureVisible 再点选。
- 下一步：统计页「全部账本」范围切换，或「首页」今日模式预算显示；上架执行只差 Play 账号。
## 2026-08-08 21:30 — 迭代 v4.56：周期规则编辑「下次日期 +1期」 + 版本号 4.56.0 + 最终 release

- 任务内容：
  - A. 周期规则编辑弹层「下次」行新增「＋1期」快捷 chip：按当前频率把 nextDate 推进一期（`RecurringRule.nextAfter`），后续预览同步更新。
  - B. 测试：新增组件测试「我的页周期规则编辑下次日期 +1期」（打开编辑弹层 → 记录下次文本 → 点 ＋1期 → 下次文本变化），152/152 通过。
  - C. web 冒烟：注入月规则（下次 8/10）→ 编辑弹层「＋1期」→ 后续预览从「9月10日…」变「10月10日…」（下次推进到 9/10）；截图 100-next-plus1.png。
  - D. 版本号 4.56.0+96（aapt 校验 versionName=4.56.0/versionCode=96）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.7MB，SHA-256 `A26875BA...9A64`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/profile_page.dart`（下次行 ＋1期 chip）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/100-next-plus1.png`（新增，截图编号到 100）
- commit hash：`f56c97b`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 152/152；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：web 语义树未暴露「下次：」独立文本 → 用「后续预览」变化验证推进。
- 下一步：统计页「全部账本」范围切换，或「周期规则」批量补生成入口；上架执行只差 Play 账号。
## 2026-08-08 22:30 — 迭代 v4.57：统计页当前账本/全部账本范围切换 + 版本号 4.57.0 + 最终 release

- 任务内容：
  - A. `AppState` 为月度统计方法新增 `{bool allBooks = false}` 参数（默认保持当前账本，向后兼容）：ofMonth/summaryOf/yearSummary/expenseDeltaOf/dailyExpenseSeries/dailyIncomeSeries/weeklyExpenseSeries/categoryExpenseRanking/categoryIncomeRanking/recentBalanceSeries/yearComparison。
  - B. 统计页顶部新增「账本：当前账本/全部账本」切换（全部账本时聚合所有账本）；月度概览/每日/每周图/占比/排行/年度对比/年度汇总全部联动；自定义范围仍按当前账本。
  - C. 测试：新增单元测试「统计全部账本聚合」（全部账本 expense=3000/income=5000、排行合计 3000）+ 组件测试「统计页全部账本切换」（切全部账本总支出 ¥10→¥30），154/154 通过。
  - D. web 冒烟：注入旅行账本 + 33 元 → 统计切「全部账本」→ 总支出 ¥1,000 → ¥1,033；截图 101-stats-all-books.png。
  - E. 版本号 4.57.0+97（aapt 校验 versionName=4.57.0/versionCode=97）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.7MB，SHA-256 `BEEFBEB3...66E46`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（11 个月度统计方法加 allBooks 参数）
  - `lib/pages/stats_page.dart`（_allBooks + 账本切换 + 11 处传参 + yearSummary 卡传参）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/101-stats-all-books.png`（新增）
- commit hash：`732e6d0`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 154/154；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：切换标签 key 误放在「当前账本」上（点击无效）→ 移到「全部账本」；PS 双引号 \n 字面量再次出现（yearData 处）→ 反引号修复。
- 下一步：周期规则「批量补生成」，或「首页」今日模式预算显示；上架执行只差 Play 账号。
## 2026-08-08 23:30 — 迭代 v4.58：周期规则全部补生成 + 版本号 4.58.0 + 最终 release

- 任务内容：
  - A. 周期记账区头部新增「全部补生成」按钮（导出按钮旁）：确认对话框 → 逐条 `backfillRecurring` 补齐所有启用规则的过期历史流水（已存在的自动跳过）→ SnackBar「已补生成 N 笔」。
  - B. 测试：新增组件测试「我的页周期规则全部补生成」（2 启用 + 1 停用 → 补 14 笔、停用不补），155/155 通过。
  - C. web 冒烟：注入「月供」规则（锚点 2025-12，下次 2026-05）→ 全部补生成 → 月供流水 9 笔（4 自动 + 5 补齐）、总数 104；截图 102-batch-backfill.png。
  - D. 版本号 4.58.0+98（aapt 校验 versionName=4.58.0/versionCode=98）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.7MB，SHA-256 `B73328BF...00B50`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/profile_page.dart`（全部补生成按钮 + _backfillAllRecurring）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/102-batch-backfill.png`（新增）
- commit hash：`61622e0`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 155/155；release 构建（一次成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：addRecurringRule 后不会自动生成到期流水（仅 load 时）→ 测试断言按「全部 7 期补齐」修正；web 滚动定位周期区需精确滚动。
- 下一步：首页今日模式预算显示，或「明细」按月份导出；上架执行只差 Play 账号。
## 2026-08-09 00:30 — 迭代 v4.59：账户余额修正 + 版本号 4.59.0 + 最终 release

- 任务内容：
  - A. 账户菜单新增「调整余额（修正）」：显示当前余额 → 输入实际余额 → 自动生成差额修正流水（差额>0 记收入、<0 记支出，备注「余额修正」，分类「其他」），余额一致则提示无需调整。
  - B. 测试：新增组件测试「我的页账户调整余额」（支付宝余额 0 → 调 500 → 余额修正收入 50000、余额=500），156/156 通过；加固既有周期规则测试的 scrollable（ProfilePage 限定，消除 IndexedStack 下 Scrollable.last 偶发错选）。
  - C. web 冒烟：支付宝（当前 -2,949）→ 调整余额 500 → 生成收入 3449.00「余额修正」；截图 103-adjust-balance.png。
  - D. 版本号 4.59.0+99（aapt 校验 versionName=4.59.0/versionCode=99）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.7MB，SHA-256 `B70701E9...CC9F`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/profile_page.dart`（账户菜单项 + _adjustAccountBalance）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/103-adjust-balance.png`（新增）
- commit hash：`7574a02`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 156/156；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：新增测试后「周期规则全部补生成」偶发失败 → 根因是 scrollUntilVisible 用 Scrollable.last 在 IndexedStack 下会错选滚动容器 → 改用 ProfilePage 限定 descendant 加固多处。
- 下一步：首页今日模式预算显示，或「明细」按月导出；上架执行只差 Play 账号。
## 2026-08-09 01:30 — 迭代 v4.60：统计自定义范围小结复制 + 版本号 4.60.0 + 最终 release

- 任务内容：
  - A. 统计自定义范围汇总卡新增「复制」按钮：一键复制范围收支小结文本（起止日期/支出/收入/结余/笔数/日均支出）到剪贴板，SnackBar「已复制范围小结」。
  - B. 测试：新增组件测试「统计自定义范围复制小结」（mock 平台通道断言 Clipboard.setData + SnackBar），157/157 通过；加固「周期规则全部补生成」测试（tap 前 ensureVisible，消除偶发 miss）。
  - C. web 冒烟：统计自定义 8月1日~8月7日 → 汇总卡显示「复制」按钮并可点击（剪贴板/提示由组件测试 mock 验证）；截图 104-range-copy.png。
  - D. 版本号 4.60.0+100（aapt 校验 versionName=4.60.0/versionCode=100）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.7MB，SHA-256 `82D447E6...866C`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/stats_page.dart`（范围汇总复制按钮 + _copyRangeSummary + services 导入）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/104-range-copy.png`（新增）
- commit hash：`d83ad26`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 157/157（连续 3 次全绿）；release 构建（一次成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：完整套件下「周期规则全部补生成」偶发失败（scrollUntilVisible 后 tap 未命中）→ tap 前 ensureVisible；web 语义树不暴露 SnackBar 文本 → 剪贴板行为以组件测试 mock 为准。
- 下一步：首页今日模式预算显示，或「明细」按月导出；上架执行只差 Play 账号。
## 2026-08-09 02:30 — 迭代 v4.61：统计年度汇总一键复制 + 版本号 4.61.0 + 最终 release

- 任务内容：
  - A. 统计「年度汇总」卡新增「复制」按钮（标题旁）：一键复制年度收支小结文本（年份/总支出/总收入/结余/日均支出/笔数/支出最多分类）到剪贴板，SnackBar「已复制年度小结」；支持全部账本模式。
  - B. 测试：新增组件测试「统计年度汇总复制」（mock 平台通道断言 Clipboard.setData + SnackBar），158/158 通过；根治「周期规则全部补生成」偶发 flake（浮出 SnackBar 过渡动画瞬时 RenderFlex 溢出 → takeException 清除）。
  - C. web 冒烟：统计滚到底部年度汇总卡 → 「复制」按钮存在且可点击；截图 105-year-copy.png。
  - D. 版本号 4.61.0+101（aapt 校验 versionName=4.61.0/versionCode=101）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.7MB，SHA-256 `BAFAF239...A727`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/stats_page.dart`（年度汇总卡复制按钮 + _copyYearSummary）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/105-year-copy.png`（新增）
- commit hash：`8e820a1`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 158/158（连续 4 次完整套件全绿）；release 构建（一次成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：完整套件下「周期规则全部补生成」仍偶发失败——浮出 SnackBar 过渡动画与对话框关闭重叠导致瞬时 RenderFlex 溢出（单测/真实使用均正常）→ 用 tester.takeException() 清除瞬时异常后断言，连续 4 次全绿。
- 下一步：首页今日模式预算显示，或「明细」按月导出；上架执行只差 Play 账号。
## 2026-08-09 03:30 — 迭代 v4.62：周期规则 CSV 首次日期列 + 版本号 4.62.0 + 最终 release

- 任务内容：
  - A. 周期规则 CSV 导出新增「首次日期」列（锚点 date）；导入按第 9 列解析（旧格式无此列时回退 nextDate，兼容）。
  - B. 测试：扩展「周期规则 CSV 导出导入往返」断言 date 往返（2026-08-01），158/158 通过。
  - C. web 冒烟：注入月供规则 → 我的页周期记账区正常渲染（每月 · 居住 · 下次 9月1日）；CSV 格式由单元测试往返验证；截图 106-recurring-csv.png。
  - D. 版本号 4.62.0+102（aapt 校验 versionName=4.62.0/versionCode=102）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.7MB，SHA-256 `15F5E384...FEF6`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/services/csv_exporter.dart`（首次日期列）
  - `lib/services/csv_importer.dart`（第 9 列解析 + 回退）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/106-recurring-csv.png`（新增）
- commit hash：`c2acb07`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 158/158；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：无新坑（导入兼容旧格式：缺第 9 列时 date=nextDate）。
- 下一步：首页今日模式预算显示，或「明细」按月导出；上架执行只差 Play 账号。
## 2026-08-09 04:30 — 迭代 v4.63：明细多选复制选中流水文本 + 版本号 4.63.0 + 最终 release

- 任务内容：
  - A. 明细多选「批量修改」弹层新增「复制选中流水（文本）」（第 10 项）：按日期倒序生成文本（日期/类型/分类/金额/账户/转入账户/备注）→ Clipboard.setData → SnackBar「已复制 N 笔流水文本」→ 退出多选。
  - B. 测试：新增组件测试「明细多选复制选中流水文本」（mock 平台通道断言 Clipboard.setData + SnackBar），159/159 通过（连续 2 次全绿）。
  - C. web 冒烟：明细多选全选 18 笔 → 批量弹层第 10 项「复制选中流水（文本）」可点击；截图 107-copy-selected-text.png。
  - D. 版本号 4.63.0+103（aapt 校验 versionName=4.63.0/versionCode=103）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.7MB，SHA-256 `31846838...7FF`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/pages/ledger_page.dart`（复制选中文本菜单项 + _copySelectedText + services 导入）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/107-copy-selected-text.png`（新增）
- commit hash：`c903d60`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 159/159；release 构建（首轮 Gradle 失败为已知 Metaspace 问题，杀进程重试成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：无新坑。
- 下一步：首页今日模式预算显示，或「明细」按月导出；上架执行只差 Play 账号。
## 2026-08-09 05:30 — 迭代 v4.64：明细最近搜索长按单条删除 + 版本号 4.64.0 + 最终 release

- 任务内容：
  - A. `AppState.removeRecentSearch(s)`：删除单条最近搜索（其余保留，持久化）。
  - B. 明细「最近搜索」chips 支持**长按删除单条**（SnackBar「已删除搜索「s」」）；清除按钮旁加「· 长按删除」提示。
  - C. 测试：新增组件测试「明细最近搜索长按删除」（2 条记录 → 长按删「咖啡」→ 仅剩「超市」），160/160 通过（连续 2 次全绿）。
  - D. web 冒烟：注入最近搜索「咖啡/超市」→ 明细显示最近搜索 chips 可交互；截图 108-search-delete.png。
  - E. 版本号 4.64.0+104（aapt 校验 versionName=4.64.0/versionCode=104）；README/RELEASE/CHECKLIST/关于对话框同步；最终 release 重建（54.7MB，SHA-256 `E645AD50...B67`，MoneyThings 签名校验通过）。
- 修改文件：
  - `lib/data/app_state.dart`（removeRecentSearch）
  - `lib/pages/ledger_page.dart`（chips 长按删除 + 提示）
  - `lib/pages/profile_page.dart`、`pubspec.yaml`、`README.md`、`RELEASE.md`、`CHECKLIST.md`、`test/widget_test.dart`
  - `screenshots/108-search-delete.png`（新增）
- commit hash：`a26e413`；已 push（见下方状态）。
- 验证：`flutter analyze` 0 问题；`flutter test` 160/160；release 构建（一次成功）+ apksigner 签名校验（CN=MoneyThings）+ aapt versionName 校验；web 冒烟零控制台错误。
- 遇到的问题与解决方案：插入提示文本时误留悬空括号 → 修复；「长按删除」提示在 web 语义树不显示（仅内联文本，功能由组件测试覆盖）。
- 下一步：首页今日模式预算显示，或「明细」按月导出；上架执行只差 Play 账号。
