// doesn't implement Comparable because Versions don't have a total order (because of arbitrary prereleases & build metadata)
final class Version {
  final int major, minor, patch;
  final String? prerelease, buildMetadata;

  const Version(
    this.major,
    this.minor,
    this.patch, {
    this.prerelease,
    this.buildMetadata,
  });

  // cf https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
  static final semVerRegex = RegExp(
    r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$',
    unicode: true,
  );

  static Version parse(String str) {
    final ver = tryParse(str);
    if (ver == null) {
      throw FormatException(
        "The string '$str' is not a valid semantic version",
      );
    }

    return ver;
  }

  static Version? tryParse(String? str) {
    if (str == null) return null;

    final match = semVerRegex.firstMatch(str);

    // match will be null if we couldn't match
    if (match == null) {
      return null;
    }

    final major = int.parse(match[1]!); // <--| these will never be null, cause
    final minor = int.parse(match[2]!); // <--| they're required for the regex
    final patch = int.parse(match[3]!); // <--| to match (which it did)
    final pre = match[4];
    final metadata = match[5];

    return Version(
      major,
      minor,
      patch,
      prerelease: pre,
      buildMetadata: metadata,
    );
  }

  @override
  String toString() => switch ((prerelease, buildMetadata)) {
        (null, null) => '$major.$minor.$patch',
        (_, null) => '$major.$minor.$patch-$prerelease',
        (null, _) => '$major.$minor.$patch+$buildMetadata',
        (_, _) => '$major.$minor.$patch-$prerelease+$buildMetadata'
      };

  bool operator >(Version other) =>
      _compare(other) == _CompareResult.greaterThan;
  bool operator >=(Version other) {
    final res = _compare(other);
    return res == _CompareResult.greaterThan || res == _CompareResult.equal;
  }

  bool operator <(Version other) => _compare(other) == _CompareResult.lessThan;
  bool operator <=(Version other) {
    final res = _compare(other);
    return res == _CompareResult.lessThan || res == _CompareResult.equal;
  }

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      (other is Version &&
          other.major == major &&
          other.minor == minor &&
          other.patch == patch &&
          other.prerelease == prerelease &&
          other.buildMetadata == buildMetadata);

  _CompareResult _compare(Version other) {
    if (major > other.major) return _CompareResult.greaterThan;
    if (major < other.major) return _CompareResult.lessThan;

    // if major versions are equal
    if (minor > other.minor) return _CompareResult.greaterThan;
    if (minor < other.minor) return _CompareResult.lessThan;

    // if major and minor versions are equal
    if (patch > other.patch) return _CompareResult.greaterThan;
    if (patch < other.patch) return _CompareResult.lessThan;

    // if [other] has prerelease info but not us, then we're more recent
    if (other.prerelease != null && prerelease == null) {
      return _CompareResult.greaterThan;
    }

    if (prerelease != null && other.prerelease == null) {
      return _CompareResult.lessThan;
    }

    // perfectly equal major/minor/patch versions,
    // just need to make sure the extra info is also equal
    return other.prerelease == prerelease &&
            other.buildMetadata == buildMetadata
        ? _CompareResult.equal
        : _CompareResult.unknown;
  }

  @override
  int get hashCode =>
      Object.hash(major, minor, patch, prerelease, buildMetadata);
}

enum _CompareResult { lessThan, greaterThan, equal, unknown }
