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
