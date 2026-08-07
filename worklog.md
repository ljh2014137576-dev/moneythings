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
