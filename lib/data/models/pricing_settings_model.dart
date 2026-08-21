/// Model representing dynamic hourly rates per player tier
class PricingSettingsModel {
  final double rate2Players;
  final double rate3Players;
  final double rate4Players;

  const PricingSettingsModel({
    this.rate2Players = 3000.0,
    this.rate3Players = 4000.0,
    this.rate4Players = 5000.0,
  });

  /// Get hourly rate for a specific player count
  double getRateForPlayers(int playerCount) {
    switch (playerCount) {
      case 2:
        return rate2Players;
      case 3:
        return rate3Players;
      case 4:
        return rate4Players;
      default:
        if (playerCount <= 2) return rate2Players;
        return rate4Players;
    }
  }

  PricingSettingsModel copyWith({
    double? rate2Players,
    double? rate3Players,
    double? rate4Players,
  }) {
    return PricingSettingsModel(
      rate2Players: rate2Players ?? this.rate2Players,
      rate3Players: rate3Players ?? this.rate3Players,
      rate4Players: rate4Players ?? this.rate4Players,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rate2Players': rate2Players,
      'rate3Players': rate3Players,
      'rate4Players': rate4Players,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory PricingSettingsModel.fromMap(Map<String, dynamic> map) {
    return PricingSettingsModel(
      rate2Players: (map['rate2Players'] as num?)?.toDouble() ?? 3000.0,
      rate3Players: (map['rate3Players'] as num?)?.toDouble() ?? 4000.0,
      rate4Players: (map['rate4Players'] as num?)?.toDouble() ?? 5000.0,
    );
  }

  factory PricingSettingsModel.fromJson(Map<String, dynamic> json) =>
      PricingSettingsModel.fromMap(json);
}
