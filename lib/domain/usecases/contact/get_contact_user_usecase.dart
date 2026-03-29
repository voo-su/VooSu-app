import 'package:voosu/domain/entities/contact_user_profile.dart';
import 'package:voosu/domain/repositories/contact_repository.dart';

class GetContactUserUseCase {
  final ContactRepository _repo;

  GetContactUserUseCase(this._repo);

  Future<ContactUserProfile> call(int id) => _repo.getUser(id);
}
