# 交付清单（RELEASE）

> 记账本 v4.37 · 2026-08-07 · 可上架状态

## 安装包

- **Release APK**：`build/app/outputs/flutter-apk/app-release.apk`（54.5 MB）
- **SHA-256**：`102618D2B380D39D898EA6B3F1FF32B48798DC9954E805004384FFBC6A10422C`
- **签名**：MoneyThings keystore（`android/upload-keystore.jks`，**不入库，请妥善备份**）
  - 证书：CN=MoneyThings, OU=Dev, O=MoneyThings, L=Shanghai, ST=Shanghai, C=CN
  - SHA-256 digest：`a7e997bb7fd9ebd7dd79f927621b9355995916732c9f589c4e08d9be8854e15a`

## 上架素材（均在仓库内）

| 素材 | 路径 |
|---|---|
| 应用图标（全套 mipmap） | `assets/icon/` + `android/app/src/main/res/` |
| 商店截图（1080×1920 ×5） | `screenshots/store/1-home-1080.png` ~ `5-add-1080.png` |
| 宣传横幅（1024×500） | `screenshots/store/banner-1024x500.png` |
| 文案（名称/简介/描述/关键词） | `STORE_TEXT.md` |
| 隐私政策 | `PRIVACY.md` |
| 上架清单 | `CHECKLIST.md` |
| 真机冒烟脚本 | `SMOKE_TEST.md` |

## 质量门禁

- `flutter analyze`：0 问题
- `flutter test`：123/123 通过（v4.37 首页本周最近流水）（含大字体 2.0x 无障碍、JSON 备份恢复、多账本（含明细复制到其他账本）、预算按账本、导入预览等）
- 功能覆盖：首页（含结余走势/总资产下钻）/明细/统计/我的/记一笔（含账户转账/数字键盘/保存撤销）、明细分类筛选/统计下钻/金额区间筛选/账户名搜索/统计柱状图下钻/常用备注/账户月度收支/周期记账（含规则编辑/立即生成本次/跳过下次）/明细多选批量修改/导出选中/批量移动账本/全部时间年份分组/统计页预算对比/自定义账户/统计页年度汇总/账户转账统计/CSV 导入自动建账户/周期规则 CSV 导入/导出、多账本（含明细复制到其他账本）、预算+系统通知、自定义分类、导入导出+JSON 备份、首启引导、图标、release 签名

## 上架步骤（摘要）

1. 注册 Google Play 开发者账号（一次性 $25）
2. Play Console 新建应用，上传 `app-release.apk`
3. 启用 **Play App Signing**（上传密钥后由 Google 管理）
4. 填写商店文案（`STORE_TEXT.md`）、隐私政策 URL（可托管 GitHub/Gitee Pages）
5. 上传截图与图标
6. 内部测试轨道 → 按 `SMOKE_TEST.md` 真机冒烟 → 正式版发布
