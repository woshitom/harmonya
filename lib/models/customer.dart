class Customer {
  final String id; // email
  final String email;
  final String name;
  final String phone;
  final List<String> massageTypes;
  final List<String> treatmentTypes;
  final List<String> massageTypesNames;
  final List<String> treatmentTypesNames;

  Customer({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.massageTypes,
    this.treatmentTypes = const [],
    this.massageTypesNames = const [],
    this.treatmentTypesNames = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'massageTypes': massageTypes,
      'treatmentTypes': treatmentTypes,
      'massageTypesNames': massageTypesNames,
      'treatmentTypesNames': treatmentTypesNames,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map, String id) {
    return Customer(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      massageTypes: List<String>.from(map['massageTypes'] ?? []),
      treatmentTypes: List<String>.from(map['treatmentTypes'] ?? []),
      massageTypesNames: List<String>.from(map['massageTypesNames'] ?? []),
      treatmentTypesNames: List<String>.from(map['treatmentTypesNames'] ?? []),
    );
  }

  Customer copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    List<String>? massageTypes,
    List<String>? treatmentTypes,
    List<String>? massageTypesNames,
    List<String>? treatmentTypesNames,
  }) {
    return Customer(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      massageTypes: massageTypes ?? this.massageTypes,
      treatmentTypes: treatmentTypes ?? this.treatmentTypes,
      massageTypesNames: massageTypesNames ?? this.massageTypesNames,
      treatmentTypesNames: treatmentTypesNames ?? this.treatmentTypesNames,
    );
  }
}

