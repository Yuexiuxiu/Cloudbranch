import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../config/platform_config.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.textPrimary(isDark);
    final textSecondary = AppTheme.textSecondary(isDark);
    final dividerColor = (isDark ? Colors.white : Colors.black).withOpacity(0.10);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: PlatformConfig.spacingSM),
          GlassCard(
            borderRadius: PlatformConfig.radiusLG,
            bgOpacity: PlatformConfig.glassBgOpacitySecondary,
            padding: EdgeInsets.all(PlatformConfig.spacingLG),
            child: Icon(Icons.wb_sunny_outlined,
                size: PlatformConfig.iconSizeHero, color: textPrimary),
          ),
          SizedBox(height: PlatformConfig.spacingMD),
          Text('云栖枝',
              style: TextStyle(
                  fontSize: PlatformConfig.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: textPrimary)),
          SizedBox(height: PlatformConfig.spacingSM),
          Text('基于和风天气API开发的跨平台天气工具 Cloudbranch',
              style: TextStyle(
                  color: textSecondary, fontSize: PlatformConfig.fontSizeMD)),
          SizedBox(height: PlatformConfig.spacingXS),
          Text('支持实时天气、每小时预报和每日预报查询',
              style: TextStyle(
                  color: textSecondary.withOpacity(0.7), fontSize: PlatformConfig.fontSizeSM)),
          SizedBox(height: PlatformConfig.spacingXS),
          Text('使用Flutter构建的跨平台应用',
              style: TextStyle(
                  color: textSecondary.withOpacity(0.7), fontSize: PlatformConfig.fontSizeSM)),
          SizedBox(height: PlatformConfig.spacingLG),
          Divider(color: dividerColor),
          SizedBox(height: PlatformConfig.spacingMD),
          GlassCard(
            borderRadius: PlatformConfig.radiusMD,
            bgOpacity: PlatformConfig.glassBgOpacitySecondary,
            padding: EdgeInsets.all(PlatformConfig.spacingMD - 2),
            child: Column(
              children: [
                _buildInfoRow('开发者', '月桂', textPrimary, textSecondary),
                SizedBox(height: PlatformConfig.spacingSM + 2),
                _buildInfoRow('版本', 'v${Environment.appVersion}', textPrimary, textSecondary),
                SizedBox(height: PlatformConfig.spacingSM + 2),
                _buildInfoRow('更新日期', Environment.buildDate, textPrimary, textSecondary),
                SizedBox(height: PlatformConfig.spacingSM + 2),
                _buildInfoRow('开发者主页', 'https://space.bilibili.com/505789935', textPrimary, textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$label: ',
            style: TextStyle(
                color: textSecondary, fontSize: PlatformConfig.fontSizeMD)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: PlatformConfig.fontSizeMD,
                color: textPrimary)),
      ],
    );
  }
}