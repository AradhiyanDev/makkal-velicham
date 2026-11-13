import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String? dob;
  final String? gender;
  final String? description;
  final UserSettings? settings;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.dob,
    this.gender,
    this.description,
    this.settings,
  });

  @override
  List<Object?> get props => [id, name, email, phone, avatar, dob, gender, description, settings];
}

class UserSettings extends Equatable {
  final bool biometricEnabled;
  final bool notificationEnabled;
  final String language;
  final String? currency;
  final String? theme;
  final String? timezone;

  const UserSettings({
    this.biometricEnabled = false,
    this.notificationEnabled = true,
    this.language = 'en',
    this.currency,
    this.theme,
    this.timezone,
  });

  @override
  List<Object?> get props => [biometricEnabled, notificationEnabled, language, currency, theme, timezone];
}
