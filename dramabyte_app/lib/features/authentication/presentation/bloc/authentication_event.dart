part of 'authentication_bloc.dart';

sealed class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object> get props => [];
}

final class AuthenticationStarted extends AuthenticationEvent {
  const AuthenticationStarted();
}

final class GoogleSignInRequested extends AuthenticationEvent {
  const GoogleSignInRequested({this.referralCode});

  final String? referralCode;

  @override
  List<Object> get props => [referralCode ?? ''];
}

final class SignOutRequested extends AuthenticationEvent {
  const SignOutRequested();
}

final class SessionExpired extends AuthenticationEvent {
  const SessionExpired();
}
