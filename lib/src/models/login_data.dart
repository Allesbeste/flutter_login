import 'package:flutter/foundation.dart';
import 'package:quiver/core.dart';

class LoginData {
  final String name;
  final String password;

  LoginData({
    @required this.name,
    @required this.password,
  });

  @override
  String toString() {
    return '$runtimeType($name, $password)';
  }

  bool operator ==(Object other) {
    if (other is LoginData) {
      return name == other.name && password == other.password;
    }
    return false;
  }

  int get hashCode => hash2(name, password);
}

class SignupData {
  final String name;
  final String password;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;

  SignupData({
    @required this.name,
    @required this.password,
    @required this.firstName,
    @required this.lastName,
    @required this.email,
    @required this.mobile,
  });

  @override
  String toString() {
    return '$runtimeType($name, $password, $firstName, $lastName, $email, $mobile)';
  }

  bool operator ==(Object other) {
    if (other is SignupData) {
      return name == other.name && password == other.password && firstName == other.firstName && lastName == other.lastName && email == other.email && mobile == other.mobile;
    }
    return false;
  }

  int get hashCode => hash2(hash4(name, password, firstName, lastName), hash2(email, mobile));
}

class SignupConfirmData {
  final String name;
  final String confirmationString;

  SignupConfirmData({
    @required this.name,
    @required this.confirmationString,
  });

  @override
  String toString() {
    return '$runtimeType($name, $confirmationString)';
  }

  bool operator ==(Object other) {
    if (other is SignupConfirmData) {
      return name == other.name && confirmationString == other.confirmationString;
    }
    return false;
  }

  int get hashCode => hash2(name, confirmationString);
}
