class UserModel {
  final String id;
  final String fullname;
  final String? profil;
  final String email;
  final String? password;
  final String? telephone;

  UserModel({
    required this.id,
    required this.fullname,
    this.profil,
    required this.email,
    this.password,
    this.telephone,
  });

  /// Convertit un JSON en objet UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullname: json['fullname'],
      profil: json['profil'],
      email: json['email'],
      telephone: json['telephone'],
    );
  }

  /// Convertit l'objet en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullname,
      'profil': profil,
      'email': email,
      'telephone': telephone,
    };
  }

  /// Permet de modifier certaines valeurs
  UserModel copyWith({
    String? id,
    String? fullname,
    String? profil,
    String? email,
    String? password,
    String? telephone,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullname: fullname ?? this.fullname,
      profil: profil ?? this.profil,
      email: email ?? this.email,
      password: password ?? this.password,
      telephone: telephone ?? this.telephone,
    );
  }
}