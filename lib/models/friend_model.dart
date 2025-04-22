class Friend {
  final String uid;
  final String name;
  final String email;

  Friend({required this.uid, required this.name, required this.email});

  factory Friend.fromMap(Map<String, dynamic> data, String uid) {
    return Friend(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
    };
  }
}
