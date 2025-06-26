import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginRequested extends AuthEvent {

  const LoginRequested({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object> get props => [email, password];
}

class RegisterRequested extends AuthEvent {

  const RegisterRequested({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object> get props => [email, password];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class LinkPartnerRequested extends AuthEvent {

  const LinkPartnerRequested({
    required this.userId,
    required this.partnerId,
  });
  final String userId;
  final String partnerId;

  @override
  List<Object> get props => [userId, partnerId];
}
