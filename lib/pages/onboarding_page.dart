/// 首次启动引导（3 页 + 开始使用）
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../main.dart';
import '../theme/app_colors.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    (
      icon: Icons.receipt_long_outlined,
      title: '记录每一笔',
      desc: '支出、收入、自定义分类，随手记录；数据仅保存在本地，绝不上传云端。',
    ),
    (
      icon: Icons.bar_chart_rounded,
      title: '统计一目了然',
      desc: '每日支出、分类排行、结余走势、预算进度，黑灰编辑风排版，一眼看懂钱去哪了。',
    ),
    (
      icon: Icons.ios_share_outlined,
      title: '数据属于你',
      desc: 'CSV 导出分享、导入恢复，换机也不丢账本。',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<AppState>().completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      backgroundColor: kPageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: kSpace4, vertical: kSpace2),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('跳过'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kSpace6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            color: kPaperSurface,
                            border:
                                Border.all(color: kDividerDefault, width: 1),
                            borderRadius: BorderRadius.circular(kRadiusTable),
                          ),
                          child: Icon(p.icon, size: 56, color: kInkPrimary),
                        ),
                        const SizedBox(height: kSpace6),
                        Text(
                          p.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: kInkPrimary,
                          ),
                        ),
                        const SizedBox(height: kSpace3),
                        Text(
                          p.desc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: kInkSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _index ? kAccentBlue : kDividerDefault,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  kPagePadding, kSpace6, kPagePadding, kSpace6),
              child: FilledButton(
                onPressed: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: Text(isLast ? '开始使用' : '下一步'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
