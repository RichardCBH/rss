import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:meread/global/global.dart';

class BlockSettingPage extends StatefulWidget {
  const BlockSettingPage({Key? key}) : super(key: key);

  @override
  State<BlockSettingPage> createState() => _BlockSettingPageState();
}

class _BlockSettingPageState extends State<BlockSettingPage> {
  // 屏蔽词列表
  final List<String> _blockList = prefs.getStringList('blockList') ?? [];

  // 导出关键词（使用 //// 分隔，复制到剪贴板）
  void _exportKeywords() {
    if (_blockList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.blockRulesExported),
        ),
      );
      return;
    }
    final String exportStr = _blockList.join('////');
    Clipboard.setData(ClipboardData(text: exportStr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.blockRulesExported),
      ),
    );
  }

  // 导入关键词（从文本分割 //// ）
  void _importKeywords() {
    final TextEditingController importController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.download_outlined),
          title: Text(AppLocalizations.of(context)!.importBlockRules),
          content: TextField(
            controller: importController,
            maxLines: 6,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '粘贴用 //// 分隔的关键词列表\n例如：广告////推广////spam',
              border: const OutlineInputBorder(),
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
                if (importController.text.isNotEmpty) {
                  final List<String> imported = importController.text
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
                        AppLocalizations.of(context)!
                            .blockRulesImported
                            .replaceAll('{count}', addedCount.toString()),
                      ),
                    ),
                  );
                }
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.blockRules),
        actions: [
          // 导入关键词
          IconButton(
            onPressed: _importKeywords,
            icon: const Icon(Icons.file_download_outlined),
            tooltip: AppLocalizations.of(context)!.importBlockRules,
          ),
          // 导出关键词
          IconButton(
            onPressed: _exportKeywords,
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: AppLocalizations.of(context)!.exportBlockRules,
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