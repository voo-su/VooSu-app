import 'package:voosu/domain/repositories/account_repository.dart';

class UpdateProfilePersonalUseCase {
  UpdateProfilePersonalUseCase(this._repository);

  final AccountRepository _repository;

  Future<void> call({
    required String name,
    required String surname,
    required int gender,
    required String birthday,
    required String about,
  }) {
    return _repository.updateProfilePersonal(
      name: name,
      surname: surname,
      gender: gender,
      birthday: birthday,
      about: about,
    );
  }
}
