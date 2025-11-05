// lib/models/user.dart

class User {
  final int? id;
  final String username;
  final String fullName;
  final String role; // 'admin', 'doctor', 'nurse', 'staff'
  final String? specialization;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;

  User({
    this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.specialization,
    this.profileImageUrl,
    DateTime? createdAt,
    this.lastLogin,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  // Rôles disponibles
  // static const String roleAdmin = 'admin';
  static const String roleDoctor = 'doctor';
  static const String roleNurse = 'nurse';
  static const String roleStaff = 'staff';

  // Liste des rôles avec leurs labels
  static const Map<String, String> roleLabels = {
    // 'admin': 'Administrateur',
    'doctor': 'Médecin',
    'nurse': 'Infirmier(ère)',
    'staff': 'Personnel',
  };

  // Obtenir le label du rôle
  String get roleLabel => roleLabels[role] ?? role;

  // Vérifier si c'est un admin
  // bool get isAdmin => role == roleAdmin;

  // Vérifier si c'est un médecin
  bool get isDoctor => role == roleDoctor;

  // Obtenir les initiales
  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, 2).toUpperCase();
  }

  // Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'role': role,
      'specialization': specialization,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  // Créer depuis Map (SQLite)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      fullName: map['fullName'] as String,
      role: map['role'] as String,
      specialization: map['specialization'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastLogin: map['lastLogin'] != null
          ? DateTime.parse(map['lastLogin'] as String)
          : null,
      isActive: (map['isActive'] as int) == 1,
    );
  }

  // Créer une copie avec modifications
  User copyWith({
    int? id,
    String? username,
    String? fullName,
    String? role,
    String? specialization,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      specialization: specialization ?? this.specialization,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, fullName: $fullName, role: $role}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id && other.username == username;
  }

  @override
  int get hashCode => id.hashCode ^ username.hashCode;
}