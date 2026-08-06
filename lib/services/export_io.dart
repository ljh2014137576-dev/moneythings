/// 导出文件的目标实现（移动端写文件 + 系统分享）
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 将 CSV 写入应用文档目录并调起系统分享，返回文件名
Future<String> exportCsvFile(String csv, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$filename');
  await file.writeAsString(csv, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      text: '记账本导出',
      subject: '记账本导出',
      title: '记账本导出',
    ),
  );
  return file.path;
}
