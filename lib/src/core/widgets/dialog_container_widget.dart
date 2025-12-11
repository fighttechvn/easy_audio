import 'package:flutter/material.dart';

class DialogContainerWidget extends StatelessWidget {
  final Widget? child;
  final String? title;
  final bool showButtonClose;
  final bool showTitle;

  const DialogContainerWidget({
    super.key,
    required this.child,
    this.title,
    this.showTitle = true,
    this.showButtonClose = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 16),
                        child: Text(
                          title ?? 'Confirm deletion',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    if (showButtonClose)
                      IconButton(
                        onPressed: Navigator.of(context).pop,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ),
            //         Container(
            //   height: 0.5,
            //   margin:const EdgeInsets.symmetric(vertical: 10),
            //   color:
            //       context.isDarkMode ? AppColors.lineDarkMode :
            // AppColors.dividerGrey,
            // ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}
