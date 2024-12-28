class Company {
  int? id;
  String name;
  String url;
  String phone;
  String email;
  String products;
  String classification;

  Company({
    this.id,
    required this.name,
    required this.url,
    required this.phone,
    required this.email,
    required this.products,
    required this.classification,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'phone': phone,
      'email': email,
      'products': products,
      'classification': classification,
    };
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'],
      name: map['name'],
      url: map['url'],
      phone: map['phone'],
      email: map['email'],
      products: map['products'],
      classification: map['classification'],
    );
  }
}
