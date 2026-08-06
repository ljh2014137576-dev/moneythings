/// 导出文件的网页端实现：复制到剪贴板
library;

import 'package:flutter/services.dart';

Future<String> exportCsvFile(String csv, String filename) {
  return exportFile(csv, filename, 'text/csv');
}

Future<String> exportFile(
  String content,
  String filename,
  String mimeType,
) async {
  await Clipboard.setData(ClipboardData(text: content));
  return '剪贴板';
}
