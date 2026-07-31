import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../config/environment.dart';
import '../config/platform_config.dart';
import '../theme/app_theme.dart';
import '../widgets/favorite_list.dart';
import '../widgets/unified_weather.dart';
import '../widgets/glass_card.dart';
import 'settings_page.dart';
import 'about_page.dart';
import 'changelog_page.dart';
import 'help_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _cityController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController();
  OverlayEntry? _suggestionOverlay;
  List<Map<String, String>> _suggestions = [];
  bool _searching = false;
  int _currentTab = 0;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _textPrimary => AppTheme.textPrimary(_isDark);
  Color get _textSecondary => AppTheme.textSecondary(_isDark);

  void _goToTab(int tab) {
    setState(() => _currentTab = tab);
    if (PlatformConfig.isAndroid && _pageController.hasClients) {
      _pageController.animateToPage(
        tab,
        duration: Duration(milliseconds: PlatformConfig.animationDurationMS * 3),
        curve: Curves.easeInOut,
      );
    }
    if (tab == 2) {
      context.read<AppState>().setSettingsPage(true);
    } else {
      context.read<AppState>().setSettingsPage(false);
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _searchFocusNode.dispose();
    _pageController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _suggestionOverlay?.remove();
    _suggestionOverlay = null;
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      _removeOverlay();
      setState(() => _suggestions = []);
      return;
    }
    _searching = true;
    try {
      final results = await context.read<AppState>().searchCities(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _searching = false;
      });
      _showSuggestionsOverlay();
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();
    if (_suggestions.isEmpty) return;
    final isAndroid = PlatformConfig.isAndroid;
    _suggestionOverlay = OverlayEntry(
      builder: (ctx) => Positioned(
        width: PlatformConfig.searchOverlayWidth,
        left: isAndroid ? 0 : null,
        right: isAndroid ? 0 : null,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, PlatformConfig.searchOverlayOffsetY),
          child: Material(
            color: Colors.transparent,
            elevation: 4,
            borderRadius: BorderRadius.circular(PlatformConfig.radiusMD),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.bgColor(_isDark),
                border: Border.all(
                  color: (_isDark ? Colors.white : Colors.black).withOpacity(0.10),
                ),
                borderRadius: BorderRadius.circular(PlatformConfig.radiusMD),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final s = _suggestions[index];
                    final display =
                        '${s['name']}${s['adm1'] != s['name'] ? ' - ${s['adm1']}' : ''}${s['adm2'] != null && s['adm2']!.isNotEmpty ? ' ${s['adm2']}' : ''}';
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.location_on_outlined,
                          size: PlatformConfig.iconSizeMD,
                          color: _textSecondary),
                      title: Text(display,
                          style: TextStyle(
                              fontSize: PlatformConfig.fontSizeMD,
                              color: _textPrimary)),
                      onTap: () {
                        _removeOverlay();
                        final city = s['name'] ?? '';
                        _cityController.text = city;
                        context.read<AppState>().setCity(city);
                        _searchFocusNode.unfocus();
                        _goToTab(0);
                        _doQuery(context.read<AppState>());
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_suggestionOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        // 启动时直接恢复缓存数据，不弹窗提示
        if (state.hasCachedQuery && !state.restoredCache && state.lastQueryCity != null && state.lastQueryTime != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            state.restoreCachedQuery();
          });
        }

        // 首次启动位置提示
        if (state.isFirstLaunch && !state.locationPromptShown && !state.settings.autoQueryLocation) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await state.markLocationPromptShown();
            if (context.mounted) {
              _showLocationPrompt(context, state);
            }
          });
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (!didPop) {
              if (_suggestionOverlay != null) {
                _removeOverlay();
                setState(() => _suggestions = []);
              } else if (_currentTab != 0) {
                _goToTab(0);
              } else {
                SystemNavigator.pop();
              }
            }
          },
          child: Scaffold(
            key: _scaffoldKey,
            extendBodyBehindAppBar: true,
            drawer: PlatformConfig.useDrawer
                ? _buildDrawer(context, state)
                : null,
            body: Stack(
              children: [
                _buildBackground(),
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(state),
                      _buildSearchBar(state),
                      _buildQueryChips(state),
                      _buildQueryTime(state),
                      Expanded(child: _buildTabContent(state)),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _buildBottomNav(state),
          ),
        );
      },
    );
  }

  Widget _buildBackground() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF0D1117),
                    Color(0xFF151B28),
                    Color(0xFF111827),
                    Color(0xFF0F172A),
                  ]
                : const [
                    Color(0xFFF2F2F7),
                    Color(0xFFE8E8ED),
                    Color(0xFFEDEDF2),
                    Color(0xFFE5E5EA),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppState state) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: PlatformConfig.horizontalPadding,
        vertical: PlatformConfig.spacingSM,
      ),
      child: Row(children: [
        Tooltip(
          message: '菜单',
          child: Material(
            color: _isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
            child: InkWell(
              borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
              onTap: () {
                if (PlatformConfig.useDrawer) {
                  _scaffoldKey.currentState?.openDrawer();
                } else {
                  _showMenuBottomSheet(context);
                }
              },
              child: Container(
                width: PlatformConfig.touchTargetMin,
                height: PlatformConfig.touchTargetMin,
                alignment: Alignment.center,
                child: Icon(Icons.menu,
                    color: _textPrimary,
                    size: PlatformConfig.iconSizeMD),
              ),
            ),
          ),
        ),
        Icon(Icons.wb_sunny_outlined,
            size: PlatformConfig.iconSizeLG,
            color: const Color(0xFFFBBF24)),
        SizedBox(width: PlatformConfig.spacingSM),
        Text(
          '云栖枝',
          style: TextStyle(
            fontSize: PlatformConfig.fontSizeXL,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        if (state.hasUpdate)
          GestureDetector(
            onTap: () => _showUpdateDialog(context),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: PlatformConfig.spacingSM,
                vertical: PlatformConfig.spacingXS,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF87171).withOpacity(0.15),
                borderRadius:
                    BorderRadius.circular(PlatformConfig.radiusSM),
                border: Border.all(
                  color: const Color(0xFFF87171).withOpacity(0.30),
                ),
              ),
              child: Text(
                state.hasMajorUpdate ? '新版本' : '更新',
                style: TextStyle(
                  color: const Color(0xFFF87171),
                  fontSize: PlatformConfig.fontSizeSM,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildSearchBar(AppState state) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: PlatformConfig.horizontalPadding),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: SizedBox(
          height: PlatformConfig.searchBarHeight,
          child: TextField(
            controller: _cityController,
            focusNode: _searchFocusNode,
            style: TextStyle(
              color: _textPrimary,
              fontSize: PlatformConfig.fontSizeMD,
            ),
            onChanged: (city) {
              if (city.isEmpty) {
                _removeOverlay();
                setState(() => _suggestions = []);
              }
              state.setCity(city);
              _onSearchChanged(city);
            },
            onSubmitted: (value) {
              _removeOverlay();
              _searchFocusNode.unfocus();
              setState(() => _currentTab = 0);
              _doQuery(state);
            },
            onTap: () {
              if (_suggestions.isNotEmpty) _showSuggestionsOverlay();
            },
            decoration: InputDecoration(
              hintText: '输入城市名称搜索...',
              hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
              prefixIcon: Icon(Icons.search_outlined,
                  size: PlatformConfig.iconSizeMD,
                  color: _textSecondary),
              suffixIcon: _searching
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _textSecondary,
                        ),
                      ),
                    )
                  : (_cityController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_outlined,
                              size: PlatformConfig.iconSizeSM,
                              color: _textSecondary),
                          onPressed: () {
                            _cityController.clear();
                            _removeOverlay();
                            setState(() => _suggestions = []);
                          },
                        )
                      : null),
              filled: true,
              fillColor: (_isDark ? Colors.white : Colors.black).withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(PlatformConfig.radiusMD),
                borderSide: BorderSide(
                    color: (_isDark ? Colors.white : Colors.black).withOpacity(0.10),
                    width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(PlatformConfig.radiusMD),
                borderSide: BorderSide(
                    color: (_isDark ? Colors.white : Colors.black).withOpacity(0.08),
                    width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(PlatformConfig.radiusMD),
                borderSide: BorderSide(
                    color: (_isDark ? Colors.white : Colors.black).withOpacity(0.20),
                    width: 1),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: PlatformConfig.spacingMD,
                vertical: PlatformConfig.spacingSM,
              ),
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQueryChips(AppState state) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: PlatformConfig.horizontalPadding,
        vertical: PlatformConfig.spacingSM,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _QueryChip(
            label: '刷新',
            isActive: false,
            onTap: () => _doQuery(state),
          ),
        ]),
      ),
    );
  }

  Widget _buildQueryTime(AppState state) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: PlatformConfig.horizontalPadding,
        vertical: PlatformConfig.spacingXS,
      ),
      child: SizedBox(
        height: PlatformConfig.fontSizeSM + 4,
        child: state.queryTime.isNotEmpty
            ? Row(children: [
                Icon(Icons.access_time_outlined,
                    size: PlatformConfig.iconSizeSM,
                    color: _textSecondary),
                SizedBox(width: PlatformConfig.spacingXS),
                Text(
                  '查询时间: ${state.queryTime}',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: PlatformConfig.fontSizeSM,
                  ),
                ),
              ])
            : null,
      ),
    );
  }

  Widget _buildTabContent(AppState state) {
    // Android: PageView 侧向滑动切换，手势跟随动画
    if (PlatformConfig.isAndroid) {
      return PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentTab = index);
          if (index == 2) {
            context.read<AppState>().setSettingsPage(true);
          } else {
            context.read<AppState>().setSettingsPage(false);
          }
        },
        children: [
          state.isSettingsPage ? const SettingsPage() : const UnifiedWeatherResult(),
          const FavoriteList(),
          state.isSettingsPage ? const SettingsPage() : const UnifiedWeatherResult(),
        ],
      );
    }
    // Desktop: 静态切换
    switch (_currentTab) {
      case 0:
        return state.isSettingsPage
            ? const SettingsPage()
            : const UnifiedWeatherResult();
      case 1:
        return const FavoriteList();
      case 2:
        if (!state.isSettingsPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _currentTab = 0);
          });
          return const UnifiedWeatherResult();
        }
        return const SettingsPage();
      default:
        return const UnifiedWeatherResult();
    }
  }

  Widget _buildBottomNav(AppState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgColor(_isDark),
        border: Border(
          top: BorderSide(
            color: (_isDark ? Colors.white : Colors.black).withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: PlatformConfig.navBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.wb_sunny_outlined,
                activeIcon: Icons.wb_sunny,
                label: '天气',
                isActive: _currentTab == 0,
                onTap: () => _goToTab(0),
              ),
              _NavItem(
                icon: Icons.favorite_outline,
                activeIcon: Icons.favorite,
                label: '收藏',
                isActive: _currentTab == 1,
                onTap: () => _goToTab(1),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: '设置',
                isActive: _currentTab == 2,
                onTap: () => _goToTab(2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppState state) {
    return Drawer(
      backgroundColor: AppTheme.bgColor(_isDark),
      width: PlatformConfig.drawerWidth,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: EdgeInsets.all(PlatformConfig.spacingXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.wb_sunny_outlined,
                      size: PlatformConfig.iconSizeXL,
                      color: const Color(0xFFFBBF24)),
                  SizedBox(height: PlatformConfig.spacingMD),
                  Text('云栖枝',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: PlatformConfig.fontSizeTitle,
                        fontWeight: FontWeight.bold,
                      )),
                  SizedBox(height: PlatformConfig.spacingXS),
                  Text('v${Environment.appVersion} - Cloudbranch',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: PlatformConfig.fontSizeSM,
                      )),
                ],
              ),
            ),
            Divider(height: 1, color: (_isDark ? Colors.white : Colors.black).withOpacity(0.06)),
            _buildDrawerItem(
              icon: Icons.info_outline,
              title: '关于软件',
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.history,
              title: '更新日志',
              onTap: () {
                Navigator.pop(context);
                _showChangelogDialog(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.open_in_browser_outlined,
              title: '开发者网站',
              onTap: () {
                Navigator.pop(context);
                _openDeveloperSite(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.system_update_outlined,
              title: '检查更新',
              onTap: () {
                Navigator.pop(context);
                _handleCheckUpdate(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.help_outline,
              title: '帮助',
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon,
          size: PlatformConfig.iconSizeMD,
          color: _textSecondary),
      title: Text(title,
          style: TextStyle(
            fontSize: PlatformConfig.fontSizeMD,
            color: _textPrimary,
          )),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: PlatformConfig.spacingXL,
      ),
    );
  }

  void _doQuery(AppState state) {
    final city = state.currentCity.trim();
    if (city.isEmpty) return;
    // 检查缓存提示：同一城市在设定间隔内重复查询时提示
    if (state.shouldPromptCache(city)) {
      _showCachePrompt(state);
      return;
    }
    state.queryUnifiedWeather();
  }

  void _showCachePrompt(AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => buildGlassDialog(
        context: ctx,
        title: Row(
          children: [
            Icon(Icons.cached_outlined,
                size: PlatformConfig.iconSizeLG, color: const Color(0xFFFBBF24)),
            SizedBox(width: PlatformConfig.spacingSM),
            Text('缓存提示',
                style: TextStyle(
                    fontSize: PlatformConfig.fontSizeLG + 2,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary(_isDark))),
          ],
        ),
        content: Text(
          '您在${state.settings.cachePromptMinutes}分钟内已查询过「${state.currentCity}」的天气，'
          '是否使用缓存数据？',
          style: TextStyle(
              fontSize: PlatformConfig.fontSizeMD,
              color: AppTheme.textPrimary(_isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              state.queryUnifiedWeather();
            },
            child: Text('重新查询',
                style: TextStyle(color: AppTheme.textPrimary(_isDark))),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              state.restoreCachedQuery();
            },
            child: Text('使用缓存',
                style: TextStyle(color: AppTheme.textPrimary(_isDark))),
          ),
        ],
      ),
    );
  }

  void _showLocationPrompt(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => buildGlassDialog(
        context: ctx,
        title: Row(
          children: [
            Icon(Icons.my_location_outlined,
                size: PlatformConfig.iconSizeLG, color: const Color(0xFF34D399)),
            SizedBox(width: PlatformConfig.spacingSM),
            Text('位置服务',
                style: TextStyle(
                    fontSize: PlatformConfig.fontSizeLG + 2,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary(_isDark))),
          ],
        ),
        content: Text(
          '是否允许云栖枝通过IP定位查询您当前位置的天气？\n'
          '您可以在「设置-常规」中随时更改此选项。',
          style: TextStyle(
              fontSize: PlatformConfig.fontSizeMD,
              color: AppTheme.textPrimary(_isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('可在「设置-常规」中开启默认查询当前位置',
                      style: TextStyle(color: _textPrimary)),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  backgroundColor: AppTheme.bgColor(_isDark).withOpacity(0.92),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PlatformConfig.radiusMD),
                    side: BorderSide(
                        color: (_isDark ? Colors.white : Colors.black).withOpacity(0.15),
                        width: 1),
                  ),
                ),
              );
            },
            child: Text('不允许',
                style: TextStyle(color: AppTheme.textSecondary(_isDark))),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final newSettings = state.settings.copyWith(autoQueryLocation: true);
              await state.updateSettings(newSettings);
              final city = await state.detectLocation();
              if (city != null && city.isNotEmpty) {
                state.setCity(city);
                state.queryUnifiedWeather();
              }
            },
            child: Text('允许',
                style: TextStyle(color: AppTheme.textPrimary(_isDark))),
          ),
        ],
      ),
    );
  }

  void _showMenuBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.bgColor(_isDark).withOpacity(0.92),
                  AppTheme.bgColor(_isDark).withOpacity(0.85),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: (_isDark ? Colors.white : Colors.black).withOpacity(0.10),
                  width: 1,
                ),
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: (_isDark ? Colors.white : Colors.black).withOpacity(0.20),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: '关于软件',
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAboutDialog(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.history,
                    title: '更新日志',
                    onTap: () {
                      Navigator.pop(ctx);
                      _showChangelogDialog(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.open_in_browser_outlined,
                    title: '开发者网站',
                    onTap: () {
                      Navigator.pop(ctx);
                      _openDeveloperSite(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.system_update_outlined,
                    title: '检查更新',
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleCheckUpdate(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: '帮助',
                    onTap: () {
                      Navigator.pop(ctx);
                      _showHelpDialog(context);
                    },
                  ),
                  SizedBox(height: PlatformConfig.spacingMD),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon,
          size: PlatformConfig.iconSizeMD,
          color: _textSecondary),
      title: Text(title,
          style: TextStyle(
            fontSize: PlatformConfig.fontSizeMD,
            color: _textPrimary,
          )),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: PlatformConfig.spacingXL,
      ),
    );
  }

  void _handleCheckUpdate(BuildContext context) async {
    final state = context.read<AppState>();
    await state.checkUpdate();
    if (!context.mounted) return;
    if (state.hasUpdate) {
      _showUpdateDialog(context);
    } else {
      _showNoUpdateDialog(context);
    }
  }

  void _showNoUpdateDialog(BuildContext context) {
    final state = context.read<AppState>();
    showDialog(
      context: context,
      builder: (context) => buildGlassDialog(
        context: context,
        title: Text('检查更新',
            style: TextStyle(
                fontSize: PlatformConfig.fontSizeLG + 2,
                fontWeight: FontWeight.bold,
                color: _textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: const Color(0xFF34D399),
                    size: PlatformConfig.iconSizeLG + 8),
                SizedBox(width: PlatformConfig.spacingMD),
                Text('当前已是最新版本',
                    style: TextStyle(
                        fontSize: PlatformConfig.fontSizeLG,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary)),
              ],
            ),
            SizedBox(height: PlatformConfig.spacingMD),
            GlassCard(
              borderRadius: PlatformConfig.radiusMD,
              padding: EdgeInsets.all(PlatformConfig.spacingMD),
              child: Column(
                children: [
                  _buildVersionRow(
                      '当前版本', 'v${Environment.appVersion}', const Color(0xFF4A90D9)),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: PlatformConfig.spacingSM),
                    child: Divider(height: 1, color: (_isDark ? Colors.white : Colors.black).withOpacity(0.06)),
                  ),
                  _buildVersionRow(
                      '云端版本', state.latestVersion, const Color(0xFF34D399)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('确定',
                style: TextStyle(color: _textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionRow(String label, String version, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: _textSecondary,
                fontSize: PlatformConfig.fontSizeMD)),
        Text(version,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: PlatformConfig.fontSizeMD + 1)),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => buildGlassDialog(
        context: context,
        title: Text('关于软件',
            style: TextStyle(
                fontSize: PlatformConfig.fontSizeLG + 2,
                fontWeight: FontWeight.bold,
                color: _textPrimary)),
        content: const AboutPage(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭',
                style: TextStyle(color: _textPrimary)),
          ),
        ],
      ),
    );
  }

  void _showChangelogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => buildGlassDialog(
        context: context,
        title: Text('更新日志',
            style: TextStyle(
                fontSize: PlatformConfig.fontSizeLG + 2,
                fontWeight: FontWeight.bold,
                color: _textPrimary)),
        content: const SizedBox(
            width: double.maxFinite, height: 400, child: ChangelogPage()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭',
                style: TextStyle(color: _textPrimary)),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => buildGlassDialog(
        context: context,
        title: Text('帮助',
            style: TextStyle(
                fontSize: PlatformConfig.fontSizeLG + 2,
                fontWeight: FontWeight.bold,
                color: _textPrimary)),
        content: const SizedBox(
            width: double.maxFinite, height: 300, child: HelpPage()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭',
                style: TextStyle(color: _textPrimary)),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context) {
    final state = context.read<AppState>();
    showDialog(
      context: context,
      builder: (context) => buildGlassDialog(
        context: context,
        title: Row(
          children: [
            Icon(
              state.hasMajorUpdate
                  ? Icons.new_releases_outlined
                  : Icons.system_update_outlined,
              color: state.hasMajorUpdate
                  ? const Color(0xFFF87171)
                  : const Color(0xFFFBBF24),
              size: PlatformConfig.iconSizeLG,
            ),
            SizedBox(width: PlatformConfig.spacingSM),
            Text(
              state.hasMajorUpdate ? '发现新版本' : '发现补丁更新',
              style: TextStyle(
                  fontSize: PlatformConfig.fontSizeLG + 2,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.hasMajorUpdate
                    ? '这是一个大版本更新，包含重要功能和修复。'
                    : '这是一个补丁更新，包含一些修复和优化。',
                style: TextStyle(
                    fontSize: PlatformConfig.fontSizeMD,
                    color: _textPrimary),
              ),
              SizedBox(height: PlatformConfig.spacingMD),
              GlassCard(
                borderRadius: PlatformConfig.radiusMD,
                padding: EdgeInsets.all(PlatformConfig.spacingMD),
                child: Column(
                  children: [
                    _buildVersionRow('当前版本',
                        'v${Environment.appVersion}', const Color(0xFF4A90D9)),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: PlatformConfig.spacingSM),
                      child: Divider(height: 1, color: (_isDark ? Colors.white : Colors.black).withOpacity(0.06)),
                    ),
                    _buildVersionRow('最新版本', state.latestVersion,
                        const Color(0xFFFBBF24)),
                    if (state.hasMajorUpdate) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: PlatformConfig.spacingSM),
                        child: Divider(height: 1, color: (_isDark ? Colors.white : Colors.black).withOpacity(0.06)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('更新类型',
                              style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: PlatformConfig.fontSizeMD)),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: PlatformConfig.spacingSM,
                                vertical: PlatformConfig.spacingXS),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF87171).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
                              border: Border.all(
                                  color: const Color(0xFFF87171).withOpacity(0.30)),
                            ),
                            child: Text('重要更新',
                                style: TextStyle(
                                    color: const Color(0xFFF87171),
                                    fontWeight: FontWeight.bold,
                                    fontSize: PlatformConfig.fontSizeSM)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: PlatformConfig.spacingMD),
              Text('更新内容:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _textPrimary)),
              SizedBox(height: PlatformConfig.spacingXS),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                      state.releaseNotes.isNotEmpty
                          ? state.releaseNotes
                          : '暂无更新日志',
                      style: TextStyle(
                          color: _textSecondary)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('稍后更新',
                style: TextStyle(color: _textPrimary)),
          ),
          FilledButton(
            onPressed: () => _openUpdateUrl(context),
            child: Text('查看详情',
                style: TextStyle(color: _textPrimary)),
          ),
        ],
      ),
    );
  }

  void _openDeveloperSite(BuildContext context) {
    launchUrl(Uri.parse('https://console.qweather.com/home?lang=zh'),
        mode: LaunchMode.externalApplication);
  }

  void _openUpdateUrl(BuildContext context) {
    final state = context.read<AppState>();
    launchUrl(
      Uri.parse(
          'https://github.com/Yuexiuxiu/Weather/releases/tag/${state.latestVersion}'),
      mode: LaunchMode.externalApplication,
    );
  }
}

class _QueryChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _QueryChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
        child: AnimatedContainer(
          duration: Duration(milliseconds: PlatformConfig.animationDurationMS),
          padding: EdgeInsets.symmetric(
            horizontal: PlatformConfig.queryChipPaddingH,
            vertical: PlatformConfig.spacingSM,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF4A90D9).withOpacity(0.40)
                  : (isDark ? Colors.white : Colors.black).withOpacity(0.08),
              width: 1,
            ),
            color: isActive
                ? const Color(0xFF4A90D9).withOpacity(0.12)
                : (isDark ? Colors.white : Colors.black).withOpacity(0.04),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF4A90D9)
                  : AppTheme.textSecondary(isDark),
              fontWeight: FontWeight.w600,
              fontSize: PlatformConfig.queryChipFontSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = (isDark ? Colors.white : Colors.black).withOpacity(0.35);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: PlatformConfig.touchTargetMin + 24,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: PlatformConfig.navBarIconSize,
              color: isActive
                  ? const Color(0xFF4A90D9)
                  : inactiveColor,
            ),
            if (PlatformConfig.showNavLabels) ...[
              SizedBox(height: PlatformConfig.spacingXS),
              Text(
                label,
                style: TextStyle(
                  fontSize: PlatformConfig.navBarFontSize,
                  color: isActive
                      ? const Color(0xFF4A90D9)
                      : inactiveColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}