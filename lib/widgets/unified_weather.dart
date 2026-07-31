import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../config/platform_config.dart';
import '../theme/app_theme.dart';
import 'harmony_glass.dart';

/// 统一天气结果 — 一次搜索全部列出
/// 实时天气 → 每小时天气 → 温度趋势 → 本周天气
class UnifiedWeatherResult extends StatelessWidget {
  const UnifiedWeatherResult({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        if (state.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: isDark
                        ? const Color(0xFF4A90D9)
                        : const Color(0xFF007AFF),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '正在查询天气...',
                  style: TextStyle(
                    color: AppTheme.textSecondary(isDark),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }

        if (state.errorMessage != null) {
          return _buildError(state.errorMessage!, isDark);
        }

        if (state.unifiedData == null) {
          return _buildEmptyState(isDark);
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: PlatformConfig.horizontalPadding,
            vertical: PlatformConfig.spacingSM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNowWeather(state, isDark),
              SizedBox(height: PlatformConfig.spacingSM),
              _buildHourlyWeather(state, isDark),
              SizedBox(height: PlatformConfig.spacingSM),
              _buildChartWeather(state, isDark),
              SizedBox(height: PlatformConfig.spacingSM),
              _buildDailyWeather(state, isDark),
              SizedBox(height: PlatformConfig.spacingXL),
            ],
          ),
        );
      },
    );
  }

  // ── 空状态 ──
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wb_sunny_outlined,
              size: 72,
              color: AppTheme.textSecondary(isDark).withOpacity(0.30)),
          SizedBox(height: PlatformConfig.spacingMD),
          Text(
            '云栖枝',
            style: TextStyle(
              fontSize: PlatformConfig.fontSizeTitle,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary(isDark).withOpacity(0.40),
            ),
          ),
          SizedBox(height: PlatformConfig.spacingSM),
          Text(
            '请在上方输入城市名称，查询天气',
            style: TextStyle(
              color: AppTheme.textSecondary(isDark).withOpacity(0.30),
              fontSize: PlatformConfig.fontSizeMD,
            ),
          ),
        ],
      ),
    );
  }

  // ── 错误状态 ──
  Widget _buildError(String message, bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(PlatformConfig.spacingXL),
      child: Column(
        children: [
          Icon(Icons.error_outline,
              size: PlatformConfig.iconSizeHero, color: const Color(0xFFF87171)),
          SizedBox(height: PlatformConfig.spacingMD),
          Text(message,
              style: TextStyle(
                  fontSize: PlatformConfig.fontSizeLG,
                  color: AppTheme.textPrimary(isDark)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── 实时天气 ──
  Widget _buildNowWeather(AppState state, bool isDark) {
    final now = state.unifiedData?['now'] as Map<String, dynamic>?;
    if (now == null) {
      return _sectionTitle('实时天气', Icons.wb_sunny_outlined, isDark);
    }
    final iconCode = now['icon']?.toString() ?? '';
    final tempUnit = state.settings.temperatureUnit;
    final windUnit = state.settings.windSpeedUnit;
    final rawTemp = _parseNum(now['temp']);
    final displayTemp = rawTemp != null
        ? (tempUnit == '℉' ? (rawTemp * 9 / 5 + 32).toStringAsFixed(1) : rawTemp.toStringAsFixed(1))
        : '-';
    final feelsLike = _parseNum(now['feelsLike']);
    final displayFeelsLike = feelsLike != null
        ? (tempUnit == '℉' ? (feelsLike * 9 / 5 + 32).toStringAsFixed(1) : feelsLike.toStringAsFixed(1))
        : '-';
    final rawWindSpeed = _parseNum(now['windSpeed']);
    final displayWindSpeed = rawWindSpeed != null
        ? (windUnit == 'm/s' ? (rawWindSpeed / 3.6).toStringAsFixed(1) : rawWindSpeed.toStringAsFixed(1))
        : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('实时天气 - ${state.currentCity}', Icons.wb_sunny_outlined, isDark),
        SizedBox(height: PlatformConfig.spacingSM),
        HarmonyGlass(
          isDark: isDark,
          borderRadius: PlatformConfig.radiusLG,
          padding: EdgeInsets.all(PlatformConfig.spacingLG),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$displayTemp°$tempUnit',
                      style: TextStyle(
                        fontSize: PlatformConfig.fontSizeHero,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary(isDark),
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: PlatformConfig.spacingSM),
                    Text(
                      now['text']?.toString() ?? '未知',
                      style: TextStyle(
                        fontSize: PlatformConfig.fontSizeXL,
                        color: AppTheme.textPrimary(isDark),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '体感 $displayFeelsLike°$tempUnit',
                      style: TextStyle(
                        fontSize: PlatformConfig.fontSizeSM,
                        color: AppTheme.textSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              _weatherIcon(iconCode, PlatformConfig.iconSizeHero + 24, isDark),
            ],
          ),
        ),
        SizedBox(height: PlatformConfig.spacingSM),
        Row(
          children: [
            Expanded(child: _detailCard(Icons.air_outlined, '风向风力',
                '${now['windDir'] ?? '-'} ${now['windScale'] ?? '-'}级', const Color(0xFF4A90D9), isDark)),
            SizedBox(width: PlatformConfig.spacingSM),
            Expanded(child: _detailCard(Icons.speed_outlined, '风速',
                '$displayWindSpeed $windUnit', const Color(0xFF22D3EE), isDark)),
          ],
        ),
        SizedBox(height: PlatformConfig.spacingSM),
        Row(
          children: [
            Expanded(child: _detailCard(Icons.water_drop_outlined, '湿度',
                '${now['humidity'] ?? '-'}%', const Color(0xFF38BDF8), isDark)),
            SizedBox(width: PlatformConfig.spacingSM),
            Expanded(child: _detailCard(Icons.compress_outlined, '气压',
                '${now['pressure'] ?? '-'}hPa', const Color(0xFF94A3B8), isDark)),
          ],
        ),
      ],
    );
  }

  // ── 每小时天气 ──
  Widget _buildHourlyWeather(AppState state, bool isDark) {
    final hourlyList = state.unifiedData?['hourly'] as List?;
    if (hourlyList == null || hourlyList.isEmpty) {
      return _sectionTitle('每小时预报', Icons.schedule_outlined, isDark);
    }
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day, now.hour, 0, 0);
    final limitedList = hourlyList.where((item) {
      final fxTime =
          (item as Map<String, dynamic>?)?['fxTime']?.toString() ?? '';
      if (fxTime.isEmpty) return true;
      try {
        final t = fxTime.length >= 13 ? fxTime.substring(0, 13) : fxTime;
        final hourTime = DateTime.tryParse(t) ?? cutoff;
        return !hourTime.isBefore(cutoff);
      } catch (_) {
        return true;
      }
    }).take(24).toList();

    final currentHour = '${now.hour.toString().padLeft(2, '0')}:00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('每小时预报', Icons.schedule_outlined, isDark),
        SizedBox(height: PlatformConfig.spacingSM),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: limitedList.length,
            itemBuilder: (context, index) {
              final hour = limitedList[index] as Map<String, dynamic>?;
              if (hour == null) return const SizedBox.shrink();
              final time = hour['fxTime']?.toString().substring(11, 16) ?? '';
              final isCurrent = time == currentHour;
              final iconCode = hour['icon']?.toString() ?? '';
              final rawTemp = _parseNum(hour['temp']);
              final hourlyTemp = rawTemp != null
                  ? (state.settings.temperatureUnit == '℉'
                      ? (rawTemp * 9 / 5 + 32).round()
                      : rawTemp.round())
                  : 0;

              return Container(
                width: 90,
                margin: EdgeInsets.symmetric(horizontal: PlatformConfig.spacingXS),
                child: HarmonyGlass(
                  isDark: isDark,
                  borderRadius: PlatformConfig.radiusMD,
                  bgOpacity: isCurrent ? 0.95 : 0.70,
                  padding: EdgeInsets.all(PlatformConfig.spacingSM),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? AppTheme.accentBlue
                              : AppTheme.textSecondary(isDark),
                          fontSize: PlatformConfig.fontSizeSM,
                        ),
                      ),
                      SizedBox(height: PlatformConfig.spacingXS),
                      _weatherIcon(iconCode, PlatformConfig.iconSizeLG, isDark),
                      SizedBox(height: PlatformConfig.spacingXS),
                      Text(
                        '$hourlyTemp°',
                        style: TextStyle(
                          fontSize: PlatformConfig.fontSizeLG,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── 温度趋势 ──
  Widget _buildChartWeather(AppState state, bool isDark) {
    final dailyList = state.unifiedData?['daily'] as List?;
    if (dailyList == null || dailyList.isEmpty) {
      return _sectionTitle('温度趋势', Icons.show_chart_outlined, isDark);
    }

    final limitedList = dailyList.take(7).toList();
    final useFahrenheit = state.settings.temperatureUnit == '℉';
    final minSpots = limitedList.asMap().entries.map((entry) {
      final temp = _parseNum(entry.value['tempMin'])?.round() ?? 0;
      final converted = useFahrenheit ? temp * 9 / 5 + 32 : temp.toDouble();
      return FlSpot(entry.key.toDouble(), converted);
    }).toList();
    final maxSpots = limitedList.asMap().entries.map((entry) {
      final temp = _parseNum(entry.value['tempMax'])?.round() ?? 0;
      final converted = useFahrenheit ? temp * 9 / 5 + 32 : temp.toDouble();
      return FlSpot(entry.key.toDouble(), converted);
    }).toList();

    final textColor = isDark
        ? Colors.white.withOpacity(0.40)
        : Colors.black.withOpacity(0.45);
    final gridColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.06);

    final chartData = LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 5,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: gridColor, strokeWidth: 0.5),
        getDrawingVerticalLine: (value) =>
            FlLine(color: gridColor, strokeWidth: 0.5),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= limitedList.length) {
                return const SizedBox();
              }
              final date =
                  limitedList[index]['fxDate']?.toString().substring(5, 10) ?? '';
              return Padding(
                padding: EdgeInsets.only(top: PlatformConfig.spacingSM),
                child: Text(date,
                    style: TextStyle(
                        fontSize: PlatformConfig.fontSizeSM,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (value, meta) {
              return Text('${value.toInt()}°',
                  style: TextStyle(fontSize: 10, color: textColor));
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: gridColor),
      ),
      minX: 0,
      maxX: limitedList.length.toDouble() - 1,
      minY: [...minSpots, ...maxSpots]
              .map((s) => s.y)
              .reduce((a, b) => a < b ? a : b) -
          5,
      maxY: [...minSpots, ...maxSpots]
              .map((s) => s.y)
              .reduce((a, b) => a > b ? a : b) +
          5,
      lineBarsData: [
        LineChartBarData(
          spots: minSpots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: const Color(0xFF38BDF8),
          barWidth: PlatformConfig.chartLineWidth,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: PlatformConfig.chartDotRadius,
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : Colors.black.withOpacity(0.05),
              strokeWidth: 2,
              strokeColor: const Color(0xFF38BDF8),
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF38BDF8).withOpacity(0.15),
                const Color(0xFF38BDF8).withOpacity(0.01),
              ],
            ),
          ),
        ),
        LineChartBarData(
          spots: maxSpots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: const Color(0xFFF87171),
          barWidth: PlatformConfig.chartLineWidth,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: PlatformConfig.chartDotRadius,
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : Colors.black.withOpacity(0.05),
              strokeWidth: 2,
              strokeColor: const Color(0xFFF87171),
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF87171).withOpacity(0.15),
                const Color(0xFFF87171).withOpacity(0.01),
              ],
            ),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('温度趋势', Icons.show_chart_outlined, isDark),
        SizedBox(height: PlatformConfig.spacingSM),
        HarmonyGlass(
          isDark: isDark,
          borderRadius: PlatformConfig.radiusLG,
          padding: EdgeInsets.all(PlatformConfig.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _legend('最高温', const Color(0xFFF87171), isDark),
                  SizedBox(width: PlatformConfig.spacingMD),
                  _legend('最低温', const Color(0xFF38BDF8), isDark),
                ],
              ),
              SizedBox(height: PlatformConfig.spacingMD),
              SizedBox(
                height: 260,
                child: LineChart(chartData),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 本周天气 ──
  Widget _buildDailyWeather(AppState state, bool isDark) {
    final dailyList = state.unifiedData?['daily'] as List?;
    if (dailyList == null || dailyList.isEmpty) {
      return _sectionTitle('本周天气', Icons.calendar_month_outlined, isDark);
    }
    final limitedList = dailyList.take(7).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('本周天气', Icons.calendar_month_outlined, isDark),
        SizedBox(height: PlatformConfig.spacingSM),
        ...limitedList.map((item) {
          final day = item as Map<String, dynamic>?;
          if (day == null) return const SizedBox.shrink();
          final date = day['fxDate']?.toString().substring(5, 10) ?? '';
          final tempMin = _parseNum(day['tempMin'])?.round() ?? 0;
          final tempMax = _parseNum(day['tempMax'])?.round() ?? 0;
          final useF = state.settings.temperatureUnit == '℉';
          final displayMin = useF ? (tempMin * 9 / 5 + 32) : tempMin.toDouble();
          final displayMax = useF ? (tempMax * 9 / 5 + 32) : tempMax.toDouble();
          final iconCode = day['iconDay']?.toString() ?? '';

          return Padding(
            padding: EdgeInsets.symmetric(vertical: PlatformConfig.spacingXS),
            child: HarmonyGlass(
              isDark: isDark,
              borderRadius: PlatformConfig.radiusMD,
              padding: EdgeInsets.symmetric(
                  horizontal: PlatformConfig.spacingMD,
                  vertical: PlatformConfig.spacingMD),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(date,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: PlatformConfig.fontSizeMD,
                            color: AppTheme.textPrimary(isDark))),
                  ),
                  _weatherIcon(iconCode, PlatformConfig.iconSizeLG, isDark),
                  SizedBox(width: PlatformConfig.spacingSM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('白天: ${day['textDay'] ?? '-'}',
                            style: TextStyle(
                                color: _weatherColor(
                                    day['textDay']?.toString() ?? '', isDark),
                                fontSize: PlatformConfig.fontSizeSM,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text('夜间: ${day['textNight'] ?? '-'}',
                            style: TextStyle(
                                color: _weatherColor(
                                    day['textNight']?.toString() ?? '', isDark),
                                fontSize: PlatformConfig.fontSizeXS)),
                      ],
                    ),
                  ),
                  _tempBar(displayMin, displayMax, isDark),
                  SizedBox(width: PlatformConfig.spacingMD),
                  Text(
                    '${day['windDirDay'] ?? '-'} ${day['windScaleDay'] ?? '-'}级',
                    style: TextStyle(
                        fontSize: PlatformConfig.fontSizeXS,
                        color: AppTheme.textSecondary(isDark)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── 辅助组件 ──
  Widget _sectionTitle(String title, IconData icon, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: PlatformConfig.spacingSM),
      child: Row(
        children: [
          Icon(icon, size: PlatformConfig.iconSizeMD, color: AppTheme.accentBlue),
          SizedBox(width: PlatformConfig.spacingSM),
          Text(title,
              style: TextStyle(
                  fontSize: PlatformConfig.fontSizeLG,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(isDark))),
        ],
      ),
    );
  }

  Widget _detailCard(
      IconData icon, String label, String value, Color color, bool isDark) {
    return HarmonyGlass(
      isDark: isDark,
      borderRadius: PlatformConfig.radiusMD,
      padding: EdgeInsets.all(PlatformConfig.spacingMD),
      child: Column(
        children: [
          Icon(icon, color: color, size: PlatformConfig.iconSizeMD),
          SizedBox(height: PlatformConfig.spacingSM),
          Text(label,
              style: TextStyle(
                  fontSize: PlatformConfig.fontSizeSM,
                  color: AppTheme.textSecondary(isDark),
                  fontWeight: FontWeight.w500)),
          SizedBox(height: PlatformConfig.spacingXS),
          Text(value,
              style: TextStyle(
                  fontSize: PlatformConfig.fontSizeLG,
                  color: color,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _tempBar(double min, double max, bool isDark) {
    const range = 40;
    final minRatio = (min + 10).clamp(0, range).toDouble() / range;
    final maxRatio = (max + 10).clamp(0, range).toDouble() / range;
    return Column(
      children: [
        Text('${min.toStringAsFixed(0)}° ~ ${max.toStringAsFixed(0)}°',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: PlatformConfig.fontSizeSM,
                color: AppTheme.textPrimary(isDark))),
        SizedBox(height: PlatformConfig.spacingXS),
        SizedBox(
          width: 60,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              children: [
                Container(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06)),
                Positioned(
                  left: minRatio * 60,
                  width: (maxRatio - minRatio) * 60,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF38BDF8),
                          Color(0xFFFBBF24),
                          Color(0xFFF87171)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _legend(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: PlatformConfig.spacingXS),
        Text(label,
            style: TextStyle(
                fontSize: PlatformConfig.fontSizeSM,
                color: AppTheme.textSecondary(isDark))),
      ],
    );
  }

  Widget _weatherIcon(String iconCode, double size, bool isDark) {
    if (iconCode.isEmpty) {
      return Icon(Icons.wb_sunny_outlined,
          size: size, color: AppTheme.textPrimary(isDark));
    }
    // [Android/Windows Liquid Glass] 深色模式：亮色图标；浅色模式：深色图标
    return SvgPicture.asset(
      'assets/icons/$iconCode.svg',
      width: size,
      height: size,
      colorFilter: isDark
          ? const ColorFilter.mode(Color(0xFFF3F4F6), BlendMode.srcIn)
          : const ColorFilter.mode(Color(0xFF374151), BlendMode.srcIn),
      placeholderBuilder: (_) => Icon(Icons.wb_sunny_outlined,
          size: size, color: AppTheme.textPrimary(isDark)),
    );
  }

  /// 天气文字颜色 — 根据主题调整亮度，浅色模式下加深以保证可读性
  Color _weatherColor(String text, bool isDark) {
    if (text.contains('晴')) return const Color(0xFFFBBF24);
    if (text.contains('云')) return isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280);
    if (text.contains('阴')) return isDark ? const Color(0xFFB0B0B0) : const Color(0xFF78716C);
    if (text.contains('雨')) return isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1);
    if (text.contains('雪')) return isDark ? const Color(0xFFBAE6FD) : const Color(0xFF0C4A6E);
    return isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1);
  }

  /// 安全解析数字，支持 int/double/String
  double? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}