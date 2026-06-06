import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:meread/global/global.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BlockSettingPage extends StatefulWidget {
  const BlockSettingPage({Key? key}) : super(key: key);

  @override
  State<BlockSettingPage> createState() => _BlockSettingPageState();
}

class _BlockSettingPageState extends State<BlockSettingPage> {
  // 屏蔽词列表
  final List<String> _blockList = prefs.getStringList('blockList') ?? [];

  // 导出为 TXT 文件
  Future<void> _exportKeywordsToTxt() async {
    if (_blockList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前没有屏蔽关键词')),
      );
      return;
    }

    try {
      final String content = _blockList.join('////');
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/meread_block_keywords.txt';
      final file = File(filePath);
      await file.writeAsString(content);

      await Share.shareXFiles(
        [XFile(filePath, mimeType: 'text/plain')],
        text: 'MeRead 屏蔽关键词列表（使用 //// 分隔）',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  // 从 TXT 文件导入
  Future<void> _importKeywordsFromTxt() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final content = await File(filePath).readAsString();
      final imported = content
          .split('////')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      int addedCount = 0;
      setState(() {
        for (final kw in imported) {
          if (!_blockList.contains(kw)) {
            _blockList.add(kw);
            addedCount++;
          }
        }
      });

      if (addedCount > 0) {
        prefs.setStringList('blockList', _blockList);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.blockRulesImported(addedCount),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.blockRules),
        actions: [
          // 从 TXT 文件导入
          IconButton(
            onPressed: _importKeywordsFromTxt,
            icon: const Icon(Icons.file_download_outlined),
            tooltip: '从 TXT 文件导入',
          ),
          // 导出为 TXT 文件
          IconButton(
            onPressed: _exportKeywordsToTxt,
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: '导出为 TXT 文件',
          ),
          // 添加屏蔽词
          IconButton(
            onPressed: () async {
              final TextEditingController controller = TextEditingController();
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    icon: const Icon(Icons.block_outlined),
                    title: Text(AppLocalizations.of(context)!.addBlockRule),
                    content: TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText:
                            AppLocalizations.of(context)!.enterBlockedWord,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          if (controller.text.isNotEmpty) {
                            setState(() {
                              if (!_blockList.contains(controller.text)) {
                                _blockList.add(controller.text);
                              }
                            });
                            prefs.setStringList('blockList', _blockList);
                          }
                          Navigator.pop(context);
                        },
                        child: Text(AppLocalizations.of(context)!.ok),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.add_circle_outline),
            tooltip: AppLocalizations.of(context)!.addBlockRule,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          itemCount: _blockList.length + 2,
          itemBuilder: (BuildContext context, int index) {
            if (index == _blockList.length) {
              return const Divider();
            }
            if (index == _blockList.length + 1) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(AppLocalizations.of(context)!.blockInfo),
              );
            }
            return ListTile(
              title: Text(_blockList[index]),
              trailing: IconButton(
                onPressed: () {
                  /* 删除屏蔽词 */
                  setState(() {
                    _blockList.removeAt(index);
                  });
                  prefs.setStringList('blockList', _blockList);
                },
                icon: const Icon(Icons.remove_circle_outline),
              ),
            );
          },
        ),
      ),
    );
  }
}