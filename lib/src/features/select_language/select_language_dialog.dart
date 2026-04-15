import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/select_language_cubit.dart';
import 'cubit/select_language_state.dart';
import 'widgets/select_language_row.dart';

class SelectLanguageDialogWidget extends StatelessWidget {
  const SelectLanguageDialogWidget({super.key});

  static const _kAccentColor = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectLanguageCubit, SelectLanguageState>(
      builder: (context, state) {
        final showRecent = state.filteredRecent.isNotEmpty;
        final recentIdSet = state.filteredRecent.map((e) => e.localeId).toSet();

        return Material(
          color: Colors.transparent,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.72,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Select Language to use',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Icon(
                                  Icons.close,
                                  size: 20,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: InputDecoration(
                              hintText: 'Search country or language',
                              filled: true,
                              fillColor: const Color(0xFFF2F3F5),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) {
                              context.read<SelectLanguageCubit>().applyFilter(
                                value,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          if (state.loading)
                            const SizedBox(
                              height: 56,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else
                            Flexible(
                              child: Scrollbar(
                                child: ListView(
                                  padding: EdgeInsets.zero,
                                  children: [
                                    if (showRecent) ...[
                                      const SizedBox(height: 2),
                                      // const Text(
                                      //   'Recent',
                                      //   style: TextStyle(
                                      //     fontSize: 13,
                                      //     fontWeight: FontWeight.w600,
                                      //     color: Color(0xFF6B7280),
                                      //   ),
                                      // ),
                                      const SizedBox(height: 6),
                                      for (final l in state.filteredRecent)
                                        SelectLanguageRow(
                                          locale: l,
                                          selected:
                                              l.localeId ==
                                              state.selectedLocaleId,
                                          loading: state.loading,
                                          accentColor: _kAccentColor,
                                          onSelected: (id) {
                                            context
                                                .read<SelectLanguageCubit>()
                                                .selectLocale(id);
                                          },
                                        ),
                                      const SizedBox(height: 6),
                                    ],
                                    for (final l in state.filteredAll)
                                      if (!showRecent ||
                                          !recentIdSet.contains(l.localeId))
                                        SelectLanguageRow(
                                          locale: l,
                                          selected:
                                              l.localeId ==
                                              state.selectedLocaleId,
                                          loading: state.loading,
                                          accentColor: _kAccentColor,
                                          onSelected: (id) {
                                            context
                                                .read<SelectLanguageCubit>()
                                                .selectLocale(id);
                                          },
                                        ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: state.loading
                                ? null
                                : () async {
                                    final selection = await context
                                        .read<SelectLanguageCubit>()
                                        .confirm();
                                    if (context.mounted) {
                                      Navigator.of(context).pop(selection);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kAccentColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Confirm',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
