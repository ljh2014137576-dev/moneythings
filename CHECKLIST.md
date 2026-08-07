# 应用商店上架清单（Checklist）

> 目标商店：Google Play（Android）

## 1. 账号与开发者
- [ ] 注册 Google Play 开发者账号（一次性 $25）
- [ ] 创建应用条目（名称：记账本 - 本地记账 / MoneyThings）
- [ ] 设置开发者邮箱与隐私政策链接

## 2. 素材（已就绪）
- [x] 应用图标：`assets/icon/app_icon.png`（黑底白¥+蓝线，已生成全套 mipmap）
- [x] 宣传横幅：`screenshots/store/banner-1024x500.png`
- [x] 商店截图：`screenshots/store/1-home-1080.png` ~ `5-add-1080.png`（1080×1920，5 张）
- [x] 文案：`STORE_TEXT.md`（名称/简介/详细描述/类别/关键词/宣传语）

## 3. 应用
- [x] Release APK：`build/app/outputs/flutter-apk/app-release.apk`（53.7MB）
  - SHA-256：`46837B78530F53174B96916A1A5DFD0819B59F39C9C07F9CE855BB23F0842F1A`
  - 签名：MoneyThings keystore（`android/upload-keystore.jks`，不入库，请妥善备份！）
- [ ] 使用 Play App Signing（上传密钥，Google 管理签名密钥）
- [ ] 上传 APK 到 Play Console 内部测试轨道 → 内部测试 → 正式版

## 4. 权限与隐私
- [x] 无敏感权限（仅本地存储；分享/导入导出由系统组件按需触发）
- [x] 隐私政策：`PRIVACY.md`（本地存储、不上传、可清除）
- [ ] 在 Play Console 填写隐私政策 URL（可托管在 GitHub Pages / Gitee Pages）

## 5. 上架前自检（自动化）
- [x] `flutter analyze`：0 问题
- [x] `flutter test`：104/104 通过
- [x] 真机冒烟：首页 / 记一笔 / 明细搜索与左滑删除 / 统计 / 多账本切换 / 预算提醒 / 导出导入
- [ ] 弱网与离线：核心功能完全离线可用（无网络依赖）
- [ ] 大字体与无障碍：语义标签已覆盖主要交互（读屏可操作）

## 6. 版本管理
- [ ] 每次发版更新 `pubspec.yaml` version（当前 4.23.0+63）
- [ ] 更新 `worklog.md` 与 `STORE_TEXT.md` 版本号
