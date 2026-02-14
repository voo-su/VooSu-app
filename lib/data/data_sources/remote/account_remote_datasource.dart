import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/grpc_error_handler.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/generated/grpc_pb/file.pbgrpc.dart' as filepb;

abstract class IAccountRemoteDataSource {
  Future<List<int>> getFile(int fileId);
}

class AccountRemoteDataSource implements IAccountRemoteDataSource {
  AccountRemoteDataSource(ClientChannel channel) : _channel = channel;

  final ClientChannel _channel;
  filepb.FileServiceClient? _fileClient;

  filepb.FileServiceClient get _file =>
      _fileClient ??= filepb.FileServiceClient(_channel);

  @override
  Future<List<int>> getFile(int fileId) async {
    try {
      final request = filepb.GetFileRequest(fileId: Int64(fileId));
      final response = await _file.getFile(request);
      return response.content;
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка getFile', e);
      throwGrpcError(e, 'Ошибка загрузки файла');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка getFile', e);
      throw ApiFailure('Ошибка загрузки файла');
    }
  }
}
