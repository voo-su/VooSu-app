import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:voosu/core/auth_guard.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/grpc_channel_manager.dart';
import 'package:voosu/core/grpc_error_handler.dart';
import 'package:voosu/core/storage_file_id.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/domain/entities/contact_list_item.dart';
import 'package:voosu/domain/entities/contact_user_profile.dart';
import 'package:voosu/generated/grpc_pb/contact.pbgrpc.dart' as contactpb;

abstract class IContactRemoteDataSource {
  Future<List<ContactListItem>> getContacts();

  Future<ContactUserProfile> getUser(int id);
}

class ContactRemoteDataSource implements IContactRemoteDataSource {
  final GrpcChannelManager _channelManager;
  final AuthGuard _authGuard;

  ContactRemoteDataSource(this._channelManager, this._authGuard);

  contactpb.ContactServiceClient get _client => _channelManager.contactClient;

  @override
  Future<List<ContactListItem>> getContacts() async {
    Logs().d('ContactRemoteDataSource: getContacts');
    try {
      final resp = await _authGuard.execute(
        () => _client.getContacts(contactpb.GetContactsRequest()),
      );
      return resp.items
          .map(
            (e) {
              final av = e.photoId.trim();
              return ContactListItem(
                id: e.id.toInt(),
                username: e.username,
                name: e.name,
                surname: e.surname,
                photoId: looksLikeStorageFileId(av) ? av : null,
              );
            },
          )
          .toList();
    } on GrpcError catch (e) {
      Logs().e('ContactRemoteDataSource: gRPC getContacts', e);
      throwGrpcError(e, 'Ошибка загрузки контактов');
    } catch (e) {
      Logs().e('ContactRemoteDataSource: getContacts', e);
      throw ApiFailure('Ошибка загрузки контактов');
    }
  }

  @override
  Future<ContactUserProfile> getUser(int id) async {
    Logs().d('ContactRemoteDataSource: getUser id=$id');
    try {
      final req = contactpb.GetUserRequest(id: Int64(id));
      final r = await _authGuard.execute(() => _client.getUser(req));
      final av = r.photoId.trim();
      return ContactUserProfile(
        id: r.id.toInt(),
        username: r.username,
        photoId: looksLikeStorageFileId(av) ? av : null,
        name: r.name,
        surname: r.surname,
        gender: r.gender,
        about: r.about,
      );
    } on GrpcError catch (e) {
      Logs().e('ContactRemoteDataSource: gRPC getUser', e);
      throwGrpcError(e, 'Ошибка загрузки профиля');
    } catch (e) {
      Logs().e('ContactRemoteDataSource: getUser', e);
      throw ApiFailure('Ошибка загрузки профиля');
    }
  }
}
