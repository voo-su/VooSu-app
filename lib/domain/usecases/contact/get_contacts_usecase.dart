import 'package:voosu/domain/entities/contact_list_item.dart';
import 'package:voosu/domain/repositories/contact_repository.dart';

class GetContactsUseCase {
  final ContactRepository _repo;

  GetContactsUseCase(this._repo);

  Future<List<ContactListItem>> call() => _repo.getContacts();
}
