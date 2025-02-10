// class Session {
//   Session({
//     required this.token,
//     required this.user,
//     this.expiresOn,
//   });
//
//   final String token;
//   final DateTime? expiresOn;
//   final User user;
//
//   bool get isExpired {
//     return false;
//   }
// }

abstract class User {
  final String id;
  final String password;

  User({required this.id, required this.password});

  String get name;
  String get shortName;
}

class EmployeeUser extends Employee implements User {
  EmployeeUser({
    required this.id,
    required this.password,
    required super.firstName,
    super.middleName,
    super.lastName,
    super.suffixName,
    super.gender,
    super.civilStatus,
    super.nationality,
    required super.taxId,
    required super.designation,
  });

  @override
  final String id;

  @override
  final String password;

  @override
  String get name => displayName;

  @override
  String get shortName => nickName;
}

/// internal individual person working for the company
class Employee extends Person {
  Employee({
    required super.firstName,
    super.middleName,
    super.lastName,
    super.suffixName,
    super.gender,
    super.civilStatus,
    super.nationality,
    required this.taxId,
    required this.designation,
  });

  final String taxId;
  final String designation;
}

enum CustomerType {
  individual,
  company,
  unknown;

  static CustomerType of(Object obj) {
    switch (obj.runtimeType) {
      case IndividualVendor _:
        return CustomerType.individual;
      case CompanyVendor _:
        return CustomerType.company;
      default:
        return CustomerType.unknown;
    }
  }
}

/// external individual person consuming products/services offered by the company
abstract class Customer {
  Customer({
    required this.id,
    required this.taxId,
  });

  final String id;
  final String taxId;
  late final CustomerType type;
}

class IndividualCustomer extends Person implements Customer {
  IndividualCustomer({
    required this.id,
    required this.taxId,
    required super.firstName,
    super.middleName,
    super.lastName,
    super.suffixName,
    super.gender,
    super.civilStatus,
    super.nationality,
  }) {
    type = CustomerType.individual;
  }

  @override
  final String id;

  @override
  final String taxId;

  @override
  late final CustomerType type;

  static IndividualCustomer fromJson(Map<String, dynamic> json) {
    return IndividualCustomer(
      id: json['id'],
      taxId: json['tax_id'],
      firstName: json['first_name'],
    );
  }
}

class CompanyCustomer extends Organization implements Customer {
  CompanyCustomer({
    required this.id,
    required super.name,
    required super.startOperatingOn,
    required this.taxId,
  }) {
    type = CustomerType.company;
  }

  @override
  final String id;

  @override
  final String taxId;

  @override
  late final CustomerType type;

  static CompanyCustomer fromJson(Map<String, dynamic> json) {
    return CompanyCustomer(
      id: json['id'],
      name: json['name'],
      startOperatingOn: DateTime.parse(json['start_operating_on']),
      taxId: json['tax_id'],
    );
  }
}

enum VendorType {
  individual,
  company,
  unknown;

  static VendorType of(Object obj) {
    switch (obj.runtimeType) {
      case IndividualVendor _:
        return VendorType.individual;
      case CompanyVendor _:
        return VendorType.company;
      default:
        return VendorType.unknown;
    }
  }
}

/// external organization working for the company
abstract class Vendor {
  Vendor({required this.taxId});

  final String taxId;
  late final VendorType type;

  String get displayName;
}

class IndividualVendor extends Person implements Vendor {
  IndividualVendor({
    required this.taxId,
    required super.firstName,
    super.middleName,
    super.lastName,
    super.suffixName,
    super.gender,
    super.civilStatus,
    super.nationality,
  }) {
    type = VendorType.individual;
  }

  @override
  final String taxId;

  @override
  late final VendorType type;
}

class CompanyVendor extends Organization implements Vendor {
  CompanyVendor({
    required this.taxId,
    required super.name,
    required super.startOperatingOn,
  }) {
    type = VendorType.company;
  }

  @override
  final String taxId;

  @override
  late final VendorType type;

  @override
  String get displayName => name;
}

enum Gender { male, female, intersex, others }

enum CivilStatus { single, married, widowed, separated }

/// A model for generally defining a person
abstract class Person {
  Person({
    required this.firstName,
    this.lastName,
    this.middleName,
    this.suffixName,
    this.gender,
    this.civilStatus,
    this.nationality,
  }) {
    if (firstName.isEmpty) {
      throw Exception('Person error 1.0: firstName is an empty string');
    } else if (middleName != null && middleName!.isEmpty) {
      throw Exception('Person error 1.1: middleName is an empty string');
    } else if (middleName != null && lastName!.isEmpty) {
      throw Exception('Person error 1.2: lastName is an empty string');
    }
  }

  final String firstName;
  final String? middleName;
  final String? lastName;
  final String? suffixName;
  final Gender? gender;
  final String? nationality;
  final CivilStatus? civilStatus;

  /// A short version of their first name
  String get nickName {
    String nickName = firstName.split(',').reversed.join(' ').trim();
    return nickName.split(' ')[0];
  }

  /// Person's full name
  String get displayName {
    if ((middleName == null || suffixName == null) && lastName == null) {
      // missing names: middle, last and suffix
      return firstName;
    } else if (middleName == null && lastName == null) {
      // missing names: middle and last
      return '$firstName, $suffixName';
    } else if (middleName == null && suffixName == null) {
      // missing names: middle and suffix
      return '$firstName $lastName';
    } else if (lastName == null && suffixName == null) {
      // missing names: last and suffix
      return firstName;
    } else if (middleName == null) {
      // missing names: middle
      return '$firstName $lastName, $suffixName';
    } else if (suffixName == null) {
      return '$firstName ${middleName?[0]}. $lastName';
    }

    return '$firstName ${middleName?[0]}. $lastName, $suffixName';
  }

  String get monogramName {
    if (lastName != null) {
      return '${firstName[0]}${lastName![0]}'.toUpperCase();
    }

    List<String> segmentedFirstName = firstName.replaceAll(',', '').split(' ');
    if (segmentedFirstName.length > 1) {
      return '${segmentedFirstName[0][0]}${segmentedFirstName[1][0]}'
          .toUpperCase();
    } else {
      return firstName[0].toUpperCase();
    }
  }
}

abstract class Organization {
  final String name;
  final DateTime startOperatingOn;

  Organization({
    required this.name,
    required this.startOperatingOn,
  });
}
