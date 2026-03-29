import 'package:voosu/domain/entities/contact_list_item.dart';
import 'package:voosu/domain/entities/contact_user_profile.dart';

abstract class ContactRepository {
  Future<List<ContactListItem>> getContacts();

  Future<ContactUserProfile> getUser(int id);
}
