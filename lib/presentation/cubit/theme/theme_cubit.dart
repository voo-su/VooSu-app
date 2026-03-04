import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/data/data_sources/local/user_local_data_source.dart';
import 'package:voosu/presentation/cubit/theme/theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(this._dataSource) : super(ThemeState(themeMode: _dataSource.getThemeMode()));

  final UserLocalDataSource _dataSource;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _dataSource.setThemeMode(mode);
    emit(ThemeState(themeMode: mode));
  }
}
