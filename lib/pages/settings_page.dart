import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io' show exit;
import '../config/platform_config.dart';
import '../providers/app_state.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../models/settings.dart';
import '../widgets/glass_card.dart';
import '../utils/logger.dart';
import '../services/log_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int _historyLimit;
  String _tempUnit = '℃';
  String _windUnit = 'km/h';
  late List<String> _favoriteCities;
  bool _autoQueryLocation = false;
  int _cachePromptMinutes = 30;
  bool _useHarmonyGlass = false;
  bool _enableLogging = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loaded = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 只在首次加载时从 AppState 读取，防止主题切换或重建时覆盖本地未保存的修改
    if (!_loaded) {
      _loadSettings();
      _loaded = true;
    }
  }

  void _loadSettings() {
    final appState = context.read<AppState>();
    final settings = appState.settings;
    _historyLimit = settings.historyLimit;
    _tempUnit = settings.temperatureUnit;
    _windUnit = settings.windSpeedUnit;
    _favoriteCities = List.from(settings.favoriteCities);
    _autoQueryLocation = settings.autoQueryLocation;
    _cachePromptMinutes = settings.cachePromptMinutes;
    _useHarmonyGlass = settings.useHarmonyGlass;
    _enableLogging = settings.enableLogging;
  }

  void _handleBackPress() {
    _saveSettings();
    context.read<AppState>().setSettingsPage(false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: 4,
      child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PlatformConfig.spacingMD - 4, vertical: PlatformConfig.spacingSM),
              child: GlassCard(
                borderRadius: PlatformConfig.radiusMD - 2,
                bgOpacity: PlatformConfig.glassBgOpacitySecondary,
                padding: EdgeInsets.all(PlatformConfig.spacingXS),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
                    border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.2), width: 1),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppTheme.textPrimary(isDark),
                  unselectedLabelColor: AppTheme.textSecondary(isDark),
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: PlatformConfig.fontSizeSM),
                  unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.w500, fontSize: PlatformConfig.fontSizeSM),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: '主题'),
                    Tab(text: '常规'),
                    Tab(text: '单位'),
                    Tab(text: '收藏'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildThemeTab(),
                  _buildGeneralTab(),
                  _buildUnitTab(),
                  _buildFavoriteTab(),
                ],
              ),
            ),
            GlassCard(
              borderRadius: 0,
              bgOpacity: PlatformConfig.glassBgOpacity,
              padding: EdgeInsets.all(PlatformConfig.spacingMD - 4),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _handleBackPress,
                    child: Text('返回',
                        style: TextStyle(
                            color: AppTheme.textPrimary(isDark))),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildThemeTab() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SingleChildScrollView(
          padding: EdgeInsets.all(PlatformConfig.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                borderRadius: PlatformConfig.radiusMD,
                padding: EdgeInsets.all(PlatformConfig.spacingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_outlined,
                            size: PlatformConfig.iconSizeMD,
                            color: const Color(0xFF7B68EE)),
                        SizedBox(width: PlatformConfig.spacingSM),
                        Text('主题模式',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: PlatformConfig.fontSizeLG,
                                color: AppTheme.textPrimary(isDark))),
                      ],
                    ),
                    SizedBox(height: PlatformConfig.spacingLG),
                    _ThemeOption(
                      icon: Icons.wb_sunny_outlined,
                      label: '浅色模式',
                      description: '明亮清爽的界面风格',
                      isSelected: themeProvider.themeMode == ThemeMode.light,
                      activeColor: const Color(0xFFFBBF24),
                      isDark: isDark,
                      onTap: () {
                        themeProvider.setThemeMode(ThemeMode.light);
                      },
                    ),
                    SizedBox(height: PlatformConfig.spacingSM),
                    _ThemeOption(
                      icon: Icons.nightlight_outlined,
                      label: '深色模式',
                      description: '护眼舒适的暗色界面',
                      isSelected: themeProvider.themeMode == ThemeMode.dark,
                      activeColor: const Color(0xFF4A90D9),
                      isDark: isDark,
                      onTap: () {
                        themeProvider.setThemeMode(ThemeMode.dark);
                      },
                    ),
                    SizedBox(height: PlatformConfig.spacingSM),
                    _ThemeOption(
                      icon: Icons.brightness_auto_outlined,
                      label: '跟随系统',
                      description: '自动匹配系统主题设置',
                      isSelected: themeProvider.themeMode == ThemeMode.system,
                      activeColor: const Color(0xFF34D399),
                      isDark: isDark,
                      onTap: () {
                        themeProvider.setThemeMode(ThemeMode.system);
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: PlatformConfig.spacingMD),
              GlassCard(
                borderRadius: PlatformConfig.radiusMD,
                padding: EdgeInsets.all(PlatformConfig.spacingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_outlined,
                            size: PlatformConfig.iconSizeMD,
                            color: const Color(0xFFC084FC)),
                        SizedBox(width: PlatformConfig.spacingSM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('毛玻璃',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: PlatformConfig.fontSizeLG,
                                      color: AppTheme.textPrimary(isDark))),
                              const SizedBox(height: 4),
                              Text('开启后所有UI采用毛玻璃效果（glass_kit: 这个库专注于在鸿蒙等平台实现高性能的毛玻璃质感，封装了 BackdropFilter，能帮你快速构建出与系统风格一致的玻璃效果。\n\nflutter_liquid_glass 等: 有一些库专门针对"液态玻璃"效果进行了封装，提供了类似 LiquidGlass 的组件，开箱即用。），需重启应用生效',
                                  style: TextStyle(
                                      fontSize: PlatformConfig.fontSizeSM,
                                      color: AppTheme.textSecondary(isDark))),
                            ],
                          ),
                        ),
                        Switch(
                          value: _useHarmonyGlass,
                          onChanged: (value) {
                            setState(() => _useHarmonyGlass = value);
                            _saveSettings();
                            if (value) {
                              _showRestartPrompt(isDark);
                            }
                          },
                          activeColor: const Color(0xFFC084FC),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGeneralTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: EdgeInsets.all(PlatformConfig.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            borderRadius: PlatformConfig.radiusMD,
            padding: EdgeInsets.all(PlatformConfig.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.my_location_outlined,
                        size: PlatformConfig.iconSizeMD, color: const Color(0xFF34D399)),
                    SizedBox(width: PlatformConfig.spacingSM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('默认查询当前位置天气',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: PlatformConfig.fontSizeLG,
                                  color: AppTheme.textPrimary(isDark))),
                          const SizedBox(height: 4),
                          Text('打开应用时自动请求位置权限并查询本地天气',
                              style: TextStyle(
                                  fontSize: PlatformConfig.fontSizeSM,
                                  color: AppTheme.textSecondary(isDark))),
                        ],
                      ),
                    ),
                    Switch(
                      value: _autoQueryLocation,
                      onChanged: (value) {
                        setState(() => _autoQueryLocation = value);
                        _saveSettings();
                      },
                      activeColor: const Color(0xFF34D399),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: PlatformConfig.spacingMD),
          GlassCard(
            borderRadius: PlatformConfig.radiusMD,
            padding: EdgeInsets.all(PlatformConfig.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history_outlined,
                        size: PlatformConfig.iconSizeMD, color: const Color(0xFF4A90D9)),
                    SizedBox(width: PlatformConfig.spacingSM),
                    Text('历史记录设置',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: PlatformConfig.fontSizeLG,
                            color: AppTheme.textPrimary(isDark))),
                  ],
                ),
                SizedBox(height: PlatformConfig.spacingMD),
                Row(
                  children: [
                    Text('历史记录数量:',
                        style:
                            TextStyle(color: AppTheme.textSecondary(isDark))),
                    SizedBox(width: PlatformConfig.spacingMD),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFF4A90D9),
                          inactiveTrackColor: (isDark ? Colors.white : Colors.black).withOpacity(0.10),
                          thumbColor: const Color(0xFF4A90D9),
                          overlayColor:
                              const Color(0xFF4A90D9).withOpacity(0.15),
                          trackHeight: 4,
                          thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: PlatformConfig.spacingSM - 2),
                        ),
                        child: Slider(
                          value: _historyLimit.toDouble(),
                          min: 1,
                          max: 100,
                          divisions: 99,
                          label: '$_historyLimit',
                          onChanged: (value) {
                            setState(() => _historyLimit = value.round());
                          },
                          onChangeEnd: (value) {
                            _saveSettings();
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: PlatformConfig.spacingSM, vertical: PlatformConfig.spacingXS),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
                          border: Border.all(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.10), width: 1),
                        ),
                        child: Text('$_historyLimit',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A90D9))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: PlatformConfig.spacingMD),
          GlassCard(
            borderRadius: PlatformConfig.radiusMD,
            padding: EdgeInsets.all(PlatformConfig.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        size: PlatformConfig.iconSizeMD, color: const Color(0xFFFBBF24)),
                    SizedBox(width: PlatformConfig.spacingSM),
                    Text('缓存提示间隔',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: PlatformConfig.fontSizeLG,
                            color: AppTheme.textPrimary(isDark))),
                  ],
                ),
                SizedBox(height: PlatformConfig.spacingMD),
                Row(
                  children: [
                    Expanded(
                        child: _UnitButton(
                      label: '30分钟',
                      isSelected: _cachePromptMinutes == 30,
                      activeColor: const Color(0xFF4A90D9),
                      onTap: () {
                        setState(() => _cachePromptMinutes = 30);
                        _saveSettings();
                      },
                    )),
                    SizedBox(width: PlatformConfig.spacingSM),
                    Expanded(
                        child: _UnitButton(
                      label: '60分钟',
                      isSelected: _cachePromptMinutes == 60,
                      activeColor: const Color(0xFFC084FC),
                      onTap: () {
                        setState(() => _cachePromptMinutes = 60);
                        _saveSettings();
                      },
                    )),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: PlatformConfig.spacingMD),
          GlassCard(
            borderRadius: PlatformConfig.radiusMD,
            padding: EdgeInsets.all(PlatformConfig.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.article_outlined,
                        size: PlatformConfig.iconSizeMD, color: const Color(0xFFF59E0B)),
                    SizedBox(width: PlatformConfig.spacingSM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('开启日志',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: PlatformConfig.fontSizeLG,
                                  color: AppTheme.textPrimary(isDark))),
                          const SizedBox(height: 4),
                          Text(PlatformConfig.isAndroid
                              ? '记录应用运行日志到内部存储，用于排查问题'
                              : '记录应用运行日志到「文档\\Cloudbranch\\log」文件夹，用于排查问题',
                              style: TextStyle(
                                  fontSize: PlatformConfig.fontSizeSM,
                                  color: AppTheme.textSecondary(isDark))),
                        ],
                      ),
                    ),
                    Switch(
                      value: _enableLogging,
                      onChanged: (value) async {
                        setState(() => _enableLogging = value);
                        await _saveSettings();
                        if (value) {
                          await LogService.enableLogging();
                        } else {
                          await LogService.disableLogging();
                        }
                      },
                      activeColor: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: EdgeInsets.all(PlatformConfig.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            borderRadius: PlatformConfig.radiusMD,
            padding: EdgeInsets.all(PlatformConfig.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.thermostat_outlined,
                        size: PlatformConfig.iconSizeMD, color: const Color(0xFFF87171)),
                    SizedBox(width: PlatformConfig.spacingSM),
                    Text('温度单位',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: PlatformConfig.fontSizeLG,
                            color: AppTheme.textPrimary(isDark))),
                  ],
                ),
                SizedBox(height: PlatformConfig.spacingMD - 4),
                Row(
                  children: [
                    Expanded(
                        child: _UnitButton(
                      label: '摄氏度 (℃)',
                      isSelected: _tempUnit == '℃',
                      activeColor: const Color(0xFF4A90D9),
                      onTap: () {
                        setState(() => _tempUnit = '℃');
                        _saveSettings();
                      },
                    )),
                    SizedBox(width: PlatformConfig.spacingSM),
                    Expanded(
                        child: _UnitButton(
                      label: '华氏度 (℉)',
                      isSelected: _tempUnit == '℉',
                      activeColor: const Color(0xFFFBBF24),
                      onTap: () {
                        setState(() => _tempUnit = '℉');
                        _saveSettings();
                      },
                    )),
                  ],
                ),
                SizedBox(height: PlatformConfig.spacingXL),
                Row(
                  children: [
                    Icon(Icons.air_outlined,
                        size: PlatformConfig.iconSizeMD, color: const Color(0xFF4A90D9)),
                    SizedBox(width: PlatformConfig.spacingSM),
                    Text('风速单位',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: PlatformConfig.fontSizeLG,
                            color: AppTheme.textPrimary(isDark))),
                  ],
                ),
                SizedBox(height: PlatformConfig.spacingMD - 4),
                Row(
                  children: [
                    Expanded(
                        child: _UnitButton(
                      label: '公里/小时 (km/h)',
                      isSelected: _windUnit == 'km/h',
                      activeColor: const Color(0xFF34D399),
                      onTap: () {
                        setState(() => _windUnit = 'km/h');
                        _saveSettings();
                      },
                    )),
                    SizedBox(width: PlatformConfig.spacingSM),
                    Expanded(
                        child: _UnitButton(
                      label: '米/秒 (m/s)',
                      isSelected: _windUnit == 'm/s',
                      activeColor: const Color(0xFFC084FC),
                      onTap: () {
                        setState(() => _windUnit = 'm/s');
                        _saveSettings();
                      },
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(PlatformConfig.spacingMD - 4),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addFavoriteCity(),
                  icon: Icon(Icons.add, size: PlatformConfig.iconSizeMD),
                  label: Text('添加',
                      style: TextStyle(color: AppTheme.textPrimary(isDark))),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A90D9),
                    side: BorderSide(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.20), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(PlatformConfig.radiusSM + 2)),
                    padding: EdgeInsets.symmetric(vertical: PlatformConfig.spacingMD - 4),
                  ),
                ),
              ),
              SizedBox(width: PlatformConfig.spacingSM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _removeFavoriteCity(),
                  icon: Icon(Icons.remove, size: PlatformConfig.iconSizeMD),
                  label: Text('删除',
                      style: TextStyle(color: AppTheme.textPrimary(isDark))),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF87171),
                    side: BorderSide(
                        color: const Color(0xFFF87171).withOpacity(0.4),
                        width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(PlatformConfig.radiusSM + 2)),
                    padding: EdgeInsets.symmetric(vertical: PlatformConfig.spacingMD - 4),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _favoriteCities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border,
                          size: PlatformConfig.iconSizeHero, color: (isDark ? Colors.white : Colors.black).withOpacity(0.40)),
                      SizedBox(height: PlatformConfig.spacingMD - 4),
                      Text('暂无收藏城市',
                          style: TextStyle(color: AppTheme.textSecondary(isDark))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: PlatformConfig.spacingMD - 4),
                  itemCount: _favoriteCities.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: PlatformConfig.spacingXS - 1),
                      child: GlassCard(
                        borderRadius: PlatformConfig.radiusMD - 2,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: PlatformConfig.spacingMD, vertical: PlatformConfig.spacingXS),
                          leading: Container(
                            padding: EdgeInsets.all(PlatformConfig.spacingXS + 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF87171).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
                              border: Border.all(
                                  color: const Color(0xFFF87171)
                                      .withOpacity(0.25),
                                  width: 1),
                            ),
                            child: Icon(Icons.favorite_outlined,
                                color: const Color(0xFFF87171), size: PlatformConfig.iconSizeSM + 2),
                          ),
                          title: Text(_favoriteCities[index],
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary(isDark))),
                          trailing: IconButton(
                            icon: Container(
                              padding: EdgeInsets.all(PlatformConfig.spacingXS),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFF87171).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(PlatformConfig.radiusSM - 4),
                                border: Border.all(
                                    color: const Color(0xFFF87171)
                                        .withOpacity(0.25),
                                    width: 1),
                              ),
                              child: Icon(Icons.close,
                                  size: PlatformConfig.iconSizeSM, color: const Color(0xFFF87171)),
                            ),
                            onPressed: () {
                              setState(
                                  () => _favoriteCities.removeAt(index));
                              _saveSettings();
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _addFavoriteCity() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_favoriteCities.length >= PlatformConfig.maxFavoriteCities) {
      _showSnackBar('最多只能添加${PlatformConfig.maxFavoriteCities}个收藏城市', false, isDark);
      return;
    }
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return buildGlassDialog(
          context: context,
          title: Text('添加收藏城市',
              style: TextStyle(
                  fontSize: PlatformConfig.fontSizeLG + 2,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(isDark))),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: AppTheme.textPrimary(isDark)),
            decoration: InputDecoration(
              hintText: '请输入城市名称',
              hintStyle: TextStyle(color: AppTheme.textSecondary(isDark)),
            ),
            onSubmitted: (value) {
              final city = value.trim();
              if (city.isNotEmpty && !_favoriteCities.contains(city)) {
                setState(() => _favoriteCities.add(city));
                _saveSettings();
              }
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消',
                  style: TextStyle(color: AppTheme.textPrimary(isDark))),
            ),
            FilledButton(
              onPressed: () {
                final city = controller.text.trim();
                if (city.isNotEmpty && !_favoriteCities.contains(city)) {
                  setState(() => _favoriteCities.add(city));
                  _saveSettings();
                }
                Navigator.pop(context);
              },
              child: Text('添加',
                  style: TextStyle(color: AppTheme.textPrimary(isDark))),
            ),
          ],
        );
      },
    );
  }

  void _removeFavoriteCity() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_favoriteCities.isEmpty) {
      _showSnackBar('暂无收藏城市可删除', false, isDark);
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return buildGlassDialog(
          context: context,
          title: Text('删除收藏城市',
              style: TextStyle(
                  fontSize: PlatformConfig.fontSizeLG + 2,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(isDark))),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: _favoriteCities.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.favorite_outlined,
                      color: const Color(0xFFF87171), size: PlatformConfig.iconSizeMD + 2),
                  title: Text(_favoriteCities[index],
                      style: TextStyle(
                          color: AppTheme.textPrimary(isDark))),
                  trailing: const Icon(Icons.delete_outline,
                      color: Color(0xFFF87171)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PlatformConfig.radiusSM)),
                  onTap: () {
                    final removed = _favoriteCities[index];
                    setState(() => _favoriteCities.removeAt(index));
                    _saveSettings();
                    Navigator.pop(context);
                    _showSnackBar('「$removed」已从收藏中删除', true, isDark);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消',
                  style: TextStyle(color: AppTheme.textPrimary(isDark))),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, bool success, bool isDark) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(success ? Icons.check_circle_outline : Icons.info_outline,
                color: AppTheme.textPrimary(isDark), size: PlatformConfig.iconSizeMD),
            SizedBox(width: PlatformConfig.spacingSM),
            Expanded(child: Text(message,
                style: TextStyle(color: AppTheme.textPrimary(isDark)))),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.bgColor(isDark).withOpacity(0.92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlatformConfig.radiusMD),
          side: BorderSide(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.15), width: 1),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    try {
      final appState = context.read<AppState>();
      final newSettings = AppSettings(
        historyLimit: _historyLimit,
        temperatureUnit: _tempUnit,
        windSpeedUnit: _windUnit,
        favoriteCities: List.from(_favoriteCities),
        autoQueryLocation: _autoQueryLocation,
        cachePromptMinutes: _cachePromptMinutes,
        useHarmonyGlass: _useHarmonyGlass,
        enableLogging: _enableLogging,
      );
      await appState.updateSettings(newSettings);
    } catch (e) {
      Logger.e('Failed to save settings: $e');
    }
  }

  void _showRestartPrompt(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => buildGlassDialog(
        context: ctx,
        title: Row(
          children: [
            Icon(Icons.restart_alt,
                size: PlatformConfig.iconSizeLG, color: const Color(0xFFC084FC)),
            SizedBox(width: PlatformConfig.spacingSM),
            Text('需要重启',
                style: TextStyle(
                    fontSize: PlatformConfig.fontSizeLG + 2,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary(isDark))),
          ],
        ),
        content: Text(
          '毛玻璃主题需要重启应用才能生效，是否立即重启？',
          style: TextStyle(
              fontSize: PlatformConfig.fontSizeMD,
              color: AppTheme.textPrimary(isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('稍后',
                style: TextStyle(color: AppTheme.textSecondary(isDark))),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _restartApp();
            },
            child: Text('立即重启',
                style: TextStyle(color: AppTheme.textPrimary(isDark))),
          ),
        ],
      ),
    );
  }

  void _restartApp() async {
    // 确保设置已保存到磁盘再退出
    await _saveSettings();
    // Windows: 退出进程，由启动脚本重新拉起
    // Android: 关闭应用，用户手动重新打开
    if (!PlatformConfig.isAndroid) {
      exit(0);
    } else {
      SystemNavigator.pop();
    }
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;
  final bool isDark;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(PlatformConfig.spacingMD),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
            border: Border.all(
              color: isSelected
                  ? activeColor.withOpacity(0.50)
                  : (isDark ? Colors.white : Colors.black).withOpacity(0.10),
              width: isSelected ? 1.5 : 1,
            ),
            color: isSelected
                ? activeColor.withOpacity(0.10)
                : (isDark ? Colors.white : Colors.black).withOpacity(0.04),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withOpacity(0.15)
                      : (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
                ),
                child: Icon(icon,
                    color: isSelected ? activeColor : AppTheme.textSecondary(isDark),
                    size: PlatformConfig.iconSizeMD),
              ),
              SizedBox(width: PlatformConfig.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: PlatformConfig.fontSizeMD,
                            color: isSelected
                                ? activeColor
                                : AppTheme.textPrimary(isDark))),
                    const SizedBox(height: 2),
                    Text(description,
                        style: TextStyle(
                            fontSize: PlatformConfig.fontSizeSM,
                            color: AppTheme.textSecondary(isDark))),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle,
                    color: activeColor, size: PlatformConfig.iconSizeMD),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const _UnitButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(PlatformConfig.radiusSM + 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PlatformConfig.radiusSM + 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: PlatformConfig.spacingMD - 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PlatformConfig.radiusSM + 2),
            border: Border.all(
              color: isSelected
                  ? activeColor.withOpacity(0.5)
                  : (isDark ? Colors.white : Colors.black).withOpacity(0.15),
              width: 1.5,
            ),
            color: isSelected
                ? activeColor.withOpacity(0.15)
                : (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppTheme.textPrimary(isDark)
                  : AppTheme.textSecondary(isDark),
              fontWeight: FontWeight.w600,
              fontSize: PlatformConfig.fontSizeSM,
            ),
          ),
        ),
      ),
    );
  }
}