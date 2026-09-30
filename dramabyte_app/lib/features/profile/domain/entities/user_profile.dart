import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    this.displayName = '',
    this.email,
    this.avatarUrl,
    this.country,
    this.language = 'en',
    this.coins = 0,
    this.bonusCoins = 0,
    this.isVip = false,
    this.vipExpiresAt,
    this.isOnboarded = false,
  });

  final String id;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final String? country;
  final String language;
  final int coins;
  final int bonusCoins;
  final bool isVip;
  final DateTime? vipExpiresAt;
  final bool isOnboarded;

  int? get vipDaysLeft {
    final expires = vipExpiresAt;
    if (expires == null) return null;
    final days = expires.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  UserProfile copyWith({int? coins, int? bonusCoins}) => UserProfile(
    id: id,
    displayName: displayName,
    email: email,
    avatarUrl: avatarUrl,
    country: country,
    language: language,
    coins: coins ?? this.coins,
    bonusCoins: bonusCoins ?? this.bonusCoins,
    isVip: isVip,
    vipExpiresAt: vipExpiresAt,
    isOnboarded: isOnboarded,
  );

  int get totalCoins => coins + bonusCoins;

  String get name => displayName.isEmpty ? 'DramaByte user' : displayName;

  String get initial => name[0].toUpperCase();

  @override
  List<Object?> get props => [
    id,
    displayName,
    email,
    avatarUrl,
    country,
    language,
    coins,
    bonusCoins,
    isVip,
    vipExpiresAt,
    isOnboarded,
  ];
}
