class AppSettings {
  final int targetSquats; // 목표 스쿼트 횟수
  final bool useSound; // 음성 피드백 사용 여부
  final bool showGuide; // 자세 가이드 표시 여부

  const AppSettings({
    this.targetSquats = 20,
    this.useSound = true,
    this.showGuide = true,
  });

  AppSettings copyWith({
    int? targetSquats,
    bool? useSound,
    bool? showGuide,
  }) {
    return AppSettings(
      targetSquats: targetSquats ?? this.targetSquats,
      useSound: useSound ?? this.useSound,
      showGuide: showGuide ?? this.showGuide,
    );
  }
}
