class Customer {
  final String id; // email
  final String email;
  final String name;
  final String phone;
  final List<String> massageTypes;

  Customer({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.massageTypes,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'massageTypes': massageTypes,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map, String id) {
    return Customer(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      massageTypes: List<String>.from(map['massageTypes'] ?? []),
    );
  }

  Customer copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    List<String>? massageTypes,
  }) {
    return Customer(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      massageTypes: massageTypes ?? this.massageTypes,
    );
  }
}

