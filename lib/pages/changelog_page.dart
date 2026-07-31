import 'package:flutter/material.dart';
import '../config/platform_config.dart';
import '../theme/app_theme.dart';
import '../services/changelog_service.dart';
import '../utils/logger.dart';

class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  List<ChangelogItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChangelog();
  }

  Future<void> _loadChangelog() async {
    try {
      _items = await ChangelogService().loadChangelog();
      _errorMessage = null;
    } catch (e) {
      Logger.e('Failed to load changelog: $e');
      _errorMessage = '加载更新日志失败';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.textPrimary(isDark);
    final textSecondary = AppTheme.textSecondary(isDark);
    final isAndroid = PlatformConfig.isAndroid;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: textPrimary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: textSecondary),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: TextStyle(color: textPrimary)),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 48, color: textSecondary.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text('暂无更新日志', style: TextStyle(color: textSecondary)),
                        ],
                      ),
                    )
                  : isAndroid
                      ? _buildAndroidLayout(textPrimary, textSecondary, isDark)
                      : _buildDesktopLayout(textPrimary, textSecondary, isDark),
    );
  }

  // ── Android 卡片式布局 ──
  Widget _buildAndroidLayout(Color textPrimary, Color textSecondary, bool isDark) {
    final cardBg = (isDark ? Colors.white : Colors.black).withOpacity(0.06);
    final cardBorder = (isDark ? Colors.white : Colors.black).withOpacity(0.08);

    // 按版本分组
    final groups = _groupByVersion();

    return ListView.builder(
      padding: EdgeInsets.all(PlatformConfig.spacingMD),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _buildVersionCard(group, textPrimary, textSecondary, cardBg, cardBorder, isDark);
      },
    );
  }

  // ── Desktop 简洁布局 ──
  Widget _buildDesktopLayout(Color textPrimary, Color textSecondary, bool isDark) {
    final cardBg = (isDark ? Colors.white : Colors.black).withOpacity(0.06);
    final cardBorder = (isDark ? Colors.white : Colors.black).withOpacity(0.08);

    return ListView(
      padding: EdgeInsets.all(PlatformConfig.spacingMD),
      children: [
        Text('更新日志',
            style: TextStyle(
                fontSize: PlatformConfig.fontSizeTitle,
                fontWeight: FontWeight.bold,
                color: textPrimary)),
        SizedBox(height: PlatformConfig.spacingMD - 4),
        ..._items.map((item) => _buildItem(item, textPrimary, textSecondary, cardBg, cardBorder)),
      ],
    );
  }

  // ── 版本分组 ──
  List<_VersionGroup> _groupByVersion() {
    final groups = <_VersionGroup>[];
    _VersionGroup? currentGroup;

    for (final item in _items) {
      if (item is ChangelogHeaderItem) {
        if (currentGroup != null) groups.add(currentGroup);
        currentGroup = _VersionGroup(
          version: item.version,
          date: item.date,
          versionName: item.versionName,
        );
      } else if (currentGroup != null) {
        currentGroup.items.add(item);
      }
    }
    if (currentGroup != null) groups.add(currentGroup);
    return groups;
  }

  // ── Android 版本卡片 ──
  Widget _buildVersionCard(_VersionGroup group, Color textPrimary,
      Color textSecondary, Color cardBg, Color cardBorder, bool isDark) {
    // 版本颜色
    final versionColor = _versionColor(group.items.length);
    final isLatest = _items.isNotEmpty &&
        _items.first is ChangelogHeaderItem &&
        (_items.first as ChangelogHeaderItem).version == group.version;

    return Padding(
      padding: EdgeInsets.only(bottom: PlatformConfig.spacingMD),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(PlatformConfig.radiusLG),
          border: Border.all(
            color: isLatest
                ? versionColor.withOpacity(0.4)
                : cardBorder,
            width: isLatest ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 版本头部
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(PlatformConfig.spacingMD),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    versionColor.withOpacity(0.15),
                    versionColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(color: cardBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // 版本徽章
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: PlatformConfig.spacingSM,
                      vertical: PlatformConfig.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: versionColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
                      border: Border.all(
                        color: versionColor.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'v${group.version}',
                      style: TextStyle(
                        color: versionColor,
                        fontWeight: FontWeight.bold,
                        fontSize: PlatformConfig.fontSizeSM + 1,
                      ),
                    ),
                  ),
                  if (group.versionName.isNotEmpty) ...[
                    SizedBox(width: PlatformConfig.spacingSM),
                    Expanded(
                      child: Text(
                        group.versionName,
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: PlatformConfig.fontSizeMD,
                        ),
                      ),
                    ),
                  ],
                  if (group.date.isNotEmpty) ...[
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: PlatformConfig.spacingSM,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(PlatformConfig.radiusSM - 4),
                      ),
                      child: Text(
                        group.date,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: PlatformConfig.fontSizeXS,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 内容区
            Padding(
              padding: EdgeInsets.all(PlatformConfig.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: group.items.map((item) {
                  return _buildAndroidItem(item, textPrimary, textSecondary, isDark);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Android 条目渲染 ──
  Widget _buildAndroidItem(
      ChangelogItem item, Color textPrimary, Color textSecondary, bool isDark) {
    if (item is ChangelogWarningItem) {
      return _buildAndroidWarning(item, isDark);
    }
    if (item is ChangelogEntry) {
      return _buildAndroidEntry(item, textPrimary, textSecondary);
    }
    return const SizedBox.shrink();
  }

  Widget _buildAndroidWarning(ChangelogWarningItem item, bool isDark) {
    final text = item.text.replaceAll('**', '').replaceAll('═', '').trim();
    if (text.isEmpty) return const SizedBox.shrink();
    final isImportant = item.text.contains('⚠️') || item.text.contains('🔥');

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: PlatformConfig.spacingSM),
      padding: EdgeInsets.all(PlatformConfig.spacingMD - 4),
      decoration: BoxDecoration(
        color: (isImportant ? const Color(0xFFF97316) : const Color(0xFFFBBF24))
            .withOpacity(0.12),
        borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
        border: Border.all(
          color: (isImportant ? const Color(0xFFF97316) : const Color(0xFFFBBF24))
              .withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isImportant ? Icons.warning_amber_rounded : Icons.info_outline,
            size: PlatformConfig.iconSizeSM + 2,
            color: (isImportant ? const Color(0xFFF97316) : const Color(0xFFFBBF24))
                .withOpacity(0.8),
          ),
          SizedBox(width: PlatformConfig.spacingSM),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: item.isBold || isImportant ? FontWeight.w600 : FontWeight.w500,
                fontSize: PlatformConfig.fontSizeSM,
                color: (isImportant ? const Color(0xFFF97316) : const Color(0xFFFBBF24))
                    .withOpacity(0.85),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidEntry(
      ChangelogEntry entry, Color textPrimary, Color textSecondary) {
    final iconData = _entryIcon(entry.title);
    final iconColor = _entryColor(entry.title);

    return Padding(
      padding: EdgeInsets.only(bottom: PlatformConfig.spacingSM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类标题
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(PlatformConfig.radiusSM - 4),
                ),
                alignment: Alignment.center,
                child: Icon(iconData, size: PlatformConfig.iconSizeSM, color: iconColor),
              ),
              SizedBox(width: PlatformConfig.spacingSM),
              Text(
                entry.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: PlatformConfig.fontSizeMD,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: PlatformConfig.spacingXS),
          // 条目列表
          ...entry.items.map((item) => Padding(
                padding: EdgeInsets.only(
                  left: PlatformConfig.spacingXL + 2,
                  top: PlatformConfig.spacingXS - 2,
                  bottom: PlatformConfig.spacingXS - 2,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 7),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: PlatformConfig.spacingSM),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: PlatformConfig.fontSizeSM,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Desktop 条目渲染 (保持原有简洁风格) ──
  Widget _buildItem(ChangelogItem item, Color textPrimary, Color textSecondary,
      Color cardBg, Color cardBorder) {
    switch (item.type) {
      case ChangelogItemType.header:
        return _buildHeader(
            item as ChangelogHeaderItem, textPrimary, textSecondary, cardBg, cardBorder);
      case ChangelogItemType.warning:
        return _buildWarning(item as ChangelogWarningItem);
      case ChangelogItemType.entry:
        return _buildEntry(item as ChangelogEntry, textPrimary, textSecondary);
    }
  }

  Widget _buildHeader(ChangelogHeaderItem item, Color textPrimary,
      Color textSecondary, Color cardBg, Color cardBorder) {
    final title = item.versionName.isNotEmpty
        ? '=== v${item.version} — ${item.versionName} ==='
        : '=== v${item.version} ===';
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: PlatformConfig.spacingXS + 2),
      padding: EdgeInsets.all(PlatformConfig.spacingSM + 2),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: PlatformConfig.fontSizeMD + 1,
                  color: textPrimary)),
          if (item.date.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: PlatformConfig.spacingXS),
              child: Text(item.date,
                  style: TextStyle(
                      color: textSecondary, fontSize: PlatformConfig.fontSizeSM - 1)),
            ),
        ],
      ),
    );
  }

  Widget _buildWarning(ChangelogWarningItem item) {
    final text = item.text.replaceAll('**', '').replaceAll('═', '').trim();
    if (text.isEmpty) return const SizedBox.shrink();
    final isImportant = item.text.contains('⚠️') || item.text.contains('🔥');

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: PlatformConfig.spacingXS + 2),
      padding: EdgeInsets.all(PlatformConfig.spacingMD - 4),
      decoration: BoxDecoration(
        color: (isImportant ? const Color(0xFFF97316) : const Color(0xFFFBBF24))
            .withOpacity(0.15),
        borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
        border: Border.all(
          color: (isImportant ? const Color(0xFFF97316) : const Color(0xFFFBBF24))
              .withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: item.isBold || isImportant ? FontWeight.bold : FontWeight.normal,
          fontSize: PlatformConfig.fontSizeSM,
          color: (isImportant ? const Color(0xFFF97316) : const Color(0xFFFBBF24))
              .withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildEntry(ChangelogEntry entry, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(entry.title, textPrimary),
        _BulletList(entry.items, textSecondary),
      ],
    );
  }

  // ── 辅助方法 ──

  /// 版本颜色 — 根据内容数量分配不同颜色
  Color _versionColor(int itemCount) {
    const colors = [
      Color(0xFF4A90D9),
      Color(0xFF7B68EE),
      Color(0xFF34D399),
      Color(0xFFFBBF24),
      Color(0xFFF87171),
      Color(0xFFC084FC),
    ];
    return colors[itemCount % colors.length];
  }

  /// 分类图标
  IconData _entryIcon(String title) {
    if (title.contains('功能') || title.contains('新增') || title.contains('Feature')) {
      return Icons.add_circle_outline;
    }
    if (title.contains('修复') || title.contains('Fix') || title.contains('Bug')) {
      return Icons.bug_report_outlined;
    }
    if (title.contains('优化') || title.contains('改进') || title.contains('Improve')) {
      return Icons.tune;
    }
    if (title.contains('UI') || title.contains('界面') || title.contains('设计')) {
      return Icons.palette_outlined;
    }
    if (title.contains('性能') || title.contains('Performance')) {
      return Icons.speed;
    }
    if (title.contains('重构') || title.contains('Refactor')) {
      return Icons.architecture;
    }
    return Icons.fiber_manual_record;
  }

  /// 分类颜色
  Color _entryColor(String title) {
    if (title.contains('功能') || title.contains('新增') || title.contains('Feature')) {
      return const Color(0xFF34D399);
    }
    if (title.contains('修复') || title.contains('Fix') || title.contains('Bug')) {
      return const Color(0xFFF87171);
    }
    if (title.contains('优化') || title.contains('改进') || title.contains('Improve')) {
      return const Color(0xFF4A90D9);
    }
    if (title.contains('UI') || title.contains('界面') || title.contains('设计')) {
      return const Color(0xFFC084FC);
    }
    if (title.contains('性能') || title.contains('Performance')) {
      return const Color(0xFFFBBF24);
    }
    if (title.contains('重构') || title.contains('Refactor')) {
      return const Color(0xFF7B68EE);
    }
    return const Color(0xFF94A3B8);
  }
}

/// 版本分组数据
class _VersionGroup {
  final String version;
  final String date;
  final String versionName;
  final List<ChangelogItem> items;

  _VersionGroup({
    required this.version,
    required this.date,
    this.versionName = '',
    List<ChangelogItem>? items,
  }) : items = items ?? [];
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionTitle(this.title, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: PlatformConfig.spacingSM, top: PlatformConfig.spacingSM),
      child: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: PlatformConfig.fontSizeMD,
              color: color)),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  final Color color;
  const _BulletList(this.items, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((item) => Padding(
                padding: EdgeInsets.only(
                    left: PlatformConfig.spacingXL,
                    top: PlatformConfig.spacingXS - 2,
                    bottom: PlatformConfig.spacingXS - 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: TextStyle(
                            fontSize: PlatformConfig.fontSizeSM,
                            color: color.withOpacity(0.7))),
                    Expanded(
                        child: Text(item,
                            style: TextStyle(
                                fontSize: PlatformConfig.fontSizeSM,
                                color: color.withOpacity(0.8)))),
                  ],
                ),
              ))
          .toList(),
    );
  }
}