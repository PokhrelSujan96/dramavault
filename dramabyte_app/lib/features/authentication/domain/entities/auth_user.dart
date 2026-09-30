import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}
