import 'package:voosu/core/failures.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/data_sources/remote/contact_remote_datasource.dart';
import 'package:voosu/domain/entities/contact_list_item.dart';
import 'package:voosu/domain/entities/contact_user_profile.dart';
import 'package:voosu/domain/repositories/contact_repository.dart';

class ContactRepositoryImpl implements ContactRepository {
  final IContactRemoteDataSource _remote;

  ContactRepositoryImpl(this._remote);

  @override
  Future<List<ContactListItem>> getContacts() async {
    try {
      return await _remote.getContacts();
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ContactRepository: getContacts', e);
      throw ApiFailure('Ошибка загрузки контактов');
    }
  }

  @override
  Future<ContactUserProfile> getUser(int id) async {
    try {
      return await _remote.getUser(id);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ContactRepository: getUser', e);
      throw ApiFailure('Ошибка загрузки профиля');
    }
  }
}
