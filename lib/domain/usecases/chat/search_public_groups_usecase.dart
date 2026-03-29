import 'package:voosu/domain/entities/overt_group_listing.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class SearchPublicGroupsUseCase {
  final ChatRepository _repo;

  SearchPublicGroupsUseCase(this._repo);

  Future<({List<OvertGroupListing> items, bool hasMore})> call({
    required String nameQuery,
    required int page,
  }) => _repo.searchPublicGroups(nameQuery: nameQuery, page: page);
}
