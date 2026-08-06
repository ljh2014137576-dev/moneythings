/// 导出文件的网页端实现：复制到剪贴板
library;

import 'package:flutter/services.dart';

Future<String> exportCsvFile(String csv, String filename) async {
  await Clipboard.setData(ClipboardData(text: csv));
  return '剪贴板';
}
