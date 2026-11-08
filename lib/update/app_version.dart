/// Release tags use major.minor.patch+build. Unlike SemVer precedence, the
/// numeric build suffix participates in update comparison.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch, {this.build});

  factory AppVersion.parse(String value) {
    final match = RegExp(r'^[vV]?(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$')
        .firstMatch(value.trim());
    if (match == null) throw FormatException('无效的版本号', value);
    return AppVersion(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
      build: match[4] == null ? null : int.parse(match[4]!),
    );
  }

  final int major;
  final int minor;
  final int patch;
  final int? build;

  String get label => '$major.$minor.$patch${build == null ? '' : '+$build'}';

  @override
  int compareTo(AppVersion other) {
    for (final (a, b) in [
      (major, other.major),
      (minor, other.minor),
      (patch, other.patch),
      (build ?? 0, other.build ?? 0),
    ]) {
      final result = a.compareTo(b);
      if (result != 0) return result;
    }
    return 0;
  }
}
