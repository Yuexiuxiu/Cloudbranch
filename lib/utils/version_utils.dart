String getMajorVersion(String version) {
  String cleaned = version;
  if (cleaned.startsWith('v') || cleaned.startsWith('V')) {
    cleaned = cleaned.substring(1);
  }
  if (cleaned.contains('+')) {
    cleaned = cleaned.split('+')[0];
  }
  if (cleaned.contains('-')) {
    cleaned = cleaned.split('-')[0];
  }
  return cleaned;
}

String formatVersionForDisplay(String version) {
  if (version.contains('+')) {
    final parts = version.split('+');
    return 'v${parts[0]} build ${parts[1]}';
  }
  return 'v$version';
}

/// 解析版本号各部件: [main, build, prerelease]
List<String> _parseVersion(String raw) {
  String v = raw;
  if (v.startsWith('v') || v.startsWith('V')) v = v.substring(1);

  String main = v;
  String build = '0';
  String prerelease = '';

  if (v.contains('+')) {
    final plusIdx = v.indexOf('+');
    main = v.substring(0, plusIdx);
    final afterPlus = v.substring(plusIdx + 1);
    final dashIdx = afterPlus.indexOf('-');
    if (dashIdx >= 0) {
      build = afterPlus.substring(0, dashIdx);
      prerelease = afterPlus.substring(dashIdx + 1);
    } else {
      build = afterPlus;
    }
  } else if (v.contains('-')) {
    final dashIdx = v.indexOf('-');
    main = v.substring(0, dashIdx);
    prerelease = v.substring(dashIdx + 1);
  }

  return [main, build, prerelease];
}

/// 比较两个版本号
/// - 先比主版本号，不同则直接返回比较结果
/// - 主版本号相同：本地 beta → 远程稳定 = 有更新，本地稳定 → 远程 beta = 无更新
/// - 同预发布状态时比较构建号
/// 返回: <0 如果 v1 < v2, >0 如果 v1 > v2, 0 如果相等
int compareVersions(String localVersion, String remoteVersion) {
  final local = _parseVersion(localVersion);
  final remote = _parseVersion(remoteVersion);

  final localMain = local[0];
  final remoteMain = remote[0];
  final localBuild = int.tryParse(local[1]) ?? 0;
  final remoteBuild = int.tryParse(remote[1]) ?? 0;
  final localPrerelease = local[2];
  final remotePrerelease = remote[2];
  final localIsBeta = localPrerelease.isNotEmpty;
  final remoteIsBeta = remotePrerelease.isNotEmpty;

  final mainCmp = _compareNumeric(localMain, remoteMain);
  if (mainCmp != 0) return mainCmp;

  if (localIsBeta && !remoteIsBeta) return -1;
  if (!localIsBeta && remoteIsBeta) return 1;

  return localBuild.compareTo(remoteBuild);
}

/// 比较以.分隔的数字版本号
int _compareNumeric(String a, String b) {
  final aParts = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final bParts = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final maxLength = aParts.length > bParts.length ? aParts.length : bParts.length;
  for (int i = 0; i < maxLength; i++) {
    final pa = i < aParts.length ? aParts[i] : 0;
    final pb = i < bParts.length ? bParts[i] : 0;
    if (pa != pb) return pa.compareTo(pb);
  }
  return 0;
}

bool isMajorUpdate(String currentVersion, String newVersion) {
  return getMajorVersion(currentVersion) != getMajorVersion(newVersion);
}

String formatCurrentTime() {
  final now = DateTime.now();
  return '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)} '
      '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}:${_twoDigits(now.second)}';
}

String _twoDigits(int n) => n.toString().padLeft(2, '0');