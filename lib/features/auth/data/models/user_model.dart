import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.avatar,
    super.dob,
    super.gender,
    super.description,
    super.settings,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final settingsJson = json['settings'] as Map<String, dynamic>?;
    final firstName = json['first_name'] as String?;
    final lastName = json['last_name'] as String?;
    final fallbackName = [
      if (firstName != null && firstName.isNotEmpty) firstName,
      if (lastName != null && lastName.isNotEmpty) lastName,
    ].join(' ');
    return UserModel(
      id: (json['id'] as int?) ?? 0,
      name: (json['name'] as String?) ??
          (fallbackName.isNotEmpty ? fallbackName : ''),
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      dob: json['dob'] as String?,
      gender: json['gender'] as String?,
      description: json['description'] as String?,
      settings: settingsJson == null
          ? null
          : UserSettings(
              biometricEnabled: settingsJson['biometric_enabled'] as bool? ?? false,
              notificationEnabled: settingsJson['notification_enabled'] as bool? ?? true,
              language: settingsJson['language'] as String? ?? 'en',
              currency: settingsJson['currency'] as String?,
              theme: settingsJson['theme'] as String?,
              timezone: settingsJson['timezone'] as String?,
            ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar': avatar,
        'dob': dob,
        'gender': gender,
        'description': description,
        if (settings != null)
          'settings': {
            'biometric_enabled': settings!.biometricEnabled,
            'notification_enabled': settings!.notificationEnabled,
            'language': settings!.language,
            if (settings!.currency != null) 'currency': settings!.currency,
            if (settings!.theme != null) 'theme': settings!.theme,
            if (settings!.timezone != null) 'timezone': settings!.timezone,
          },
      };
}
