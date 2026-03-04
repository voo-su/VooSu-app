import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/presentation/cubit/theme/theme_cubit.dart';
import 'package:voosu/presentation/cubit/theme/theme_state.dart';

class ProfileAppearanceWidget extends StatelessWidget {
  const ProfileAppearanceWidget({super.key, this.scrollable = true});

  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: BlocBuilder<ThemeCubit, ThemeState>(
            buildWhen: (a, b) => a.themeMode != b.themeMode,
            builder: (context, themeState) {
              final isDark = themeState.themeMode == ThemeMode.dark;
              return SwitchListTile(
                title: const Text('Тёмная тема'),
                subtitle: Text(isDark ? 'Включена' : 'Выключена'),
                value: isDark,
                onChanged: (value) {
                  context.read<ThemeCubit>().setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
    final content = Padding(padding: const EdgeInsets.all(24), child: column);
    if (scrollable) {
      return SingleChildScrollView(child: content);
    }
    return content;
  }
}
