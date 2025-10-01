import 'package:flutter/material.dart';

import 'checkbox_widget.dart';

typedef GroupCheckBoxBuilder<T> = Widget Function(
  int index,
  CheckBoxWidget<T> item,
  BoxConstraints constraints,
  bool isSelected,
  T data,
);

class GroupCheckBoxWidget<T> extends StatefulWidget {
  const GroupCheckBoxWidget({
    super.key,
    this.onSelected,
    this.onChanged,
    this.defaultValue,
    required this.values,
    this.numberOfRow,
    this.spacing = 8,
    this.error,
    this.isRadioType = false,
    this.checkBoxbuilder,
    this.groupCheckBoxBuilder,
    this.direction = Axis.horizontal,
    this.expendTitle = false,
    this.position = PositionRadio.start,
    this.wrapAlignment,
    this.canUnselect = false,
  }) : builderTitle = null;

  const GroupCheckBoxWidget.custom({
    super.key,
    this.onSelected,
    this.onChanged,
    this.defaultValue,
    required this.values,
    this.numberOfRow,
    this.spacing = 8,
    this.error,
    this.isRadioType = false,
    this.checkBoxbuilder,
    this.groupCheckBoxBuilder,
    this.direction = Axis.horizontal,
    required this.builderTitle,
    this.expendTitle = false,
    this.position = PositionRadio.start,
    this.wrapAlignment,
    this.canUnselect = false,
  });

  final ValueChanged<T?>? onSelected;
  final void Function(T? anwser, int index)? onChanged;
  final T? defaultValue;
  final List<T> values;
  final int? numberOfRow;
  final double spacing;
  final Widget? error;
  final bool isRadioType;
  final CheckboxBuilder<T>? checkBoxbuilder;
  final GroupCheckBoxBuilder<T>? groupCheckBoxBuilder;
  final Axis direction;
  final Widget Function(T data, bool isSelected)? builderTitle;
  final bool expendTitle;
  final PositionRadio position;
  final WrapAlignment? wrapAlignment;
  final bool canUnselect;

  @override
  State<GroupCheckBoxWidget<T>> createState() => _GroupCheckBoxWidgetState();
}

class _GroupCheckBoxWidgetState<T> extends State<GroupCheckBoxWidget<T>> {
  T? _selectedValue;

  void _onSelected(bool isSelected, T value, int index) {
    setState(() {
      if (isSelected) {
        _selectedValue = value;
        widget.onSelected?.call(_selectedValue);
        widget.onChanged?.call(_selectedValue, index);
      } else {
        _selectedValue = null;
        widget.onSelected?.call(null);
        widget.onChanged?.call(_selectedValue, index);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.defaultValue;
  }

  @override
  void didUpdateWidget(covariant GroupCheckBoxWidget<T> oldWidget) {
    if (oldWidget.defaultValue != widget.defaultValue) {
      setState(() {
        _selectedValue = widget.defaultValue;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        if (widget.numberOfRow != null) {
          return GridView.builder(
            shrinkWrap: true,
            itemCount: widget.values.length,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.numberOfRow!,
              childAspectRatio: 16 / widget.numberOfRow!,
              crossAxisSpacing: widget.spacing,
              mainAxisSpacing: widget.spacing,
            ),
            itemBuilder: (context, index) {
              final item = widget.values.elementAt(index);
              final isSelected = _selectedValue == item;
              final titleWidget = Tooltip(
                message: item.toString(),
                child: widget.builderTitle?.call(item, isSelected) ??
                    Text(
                      item.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              );

              final widgetItem = CheckBoxWidget<T>(
                position: widget.position,
                expendTitle: widget.expendTitle,
                textWidget: titleWidget,
                isSelected: isSelected,
                hasUnselect: widget.isRadioType == false,
                onSelected: (bool isSelected) => _onSelected(
                  widget.canUnselect == false || !isSelected,
                  item,
                  index,
                ),
                builder: widget.checkBoxbuilder,
                data: item,
              );
              if (widget.groupCheckBoxBuilder != null) {
                return GestureDetector(
                  onTap: () => _onSelected(
                    widget.canUnselect == false || !isSelected,
                    item,
                    index,
                  ),
                  behavior: HitTestBehavior.translucent,
                  child: widget.groupCheckBoxBuilder!.call(
                    index,
                    widgetItem,
                    constraints,
                    isSelected,
                    item,
                  ),
                );
              }
              return widgetItem;
            },
          );
        }

        final items = List.generate(widget.values.length, (index) {
          final item = widget.values.toList()[index];
          final isSelected = _selectedValue == item;
          final titleWidget = widget.builderTitle?.call(item, isSelected) ??
              Text(item.toString());

          final widgetCheckBox = CheckBoxWidget<T>(
            textWidget: titleWidget,
            data: item,
            position: widget.position,
            expendTitle: widget.expendTitle,
            isSelected: _selectedValue == item,
            hasUnselect: widget.isRadioType == false,
            onSelected: (bool isSelected) => _onSelected(
              widget.canUnselect == false || !isSelected,
              item,
              index,
            ),
            builder: widget.checkBoxbuilder,
          );

          if (widget.groupCheckBoxBuilder != null) {
            return GestureDetector(
              onTap: () => _onSelected(
                widget.canUnselect == false || !isSelected,
                item,
                index,
              ),
              behavior: HitTestBehavior.translucent,
              child: widget.groupCheckBoxBuilder!.call(
                index,
                widgetCheckBox,
                constraints,
                isSelected,
                item,
              ),
            );
          }

          return widgetCheckBox;
        });

        late List<Widget> itemsBuild;
        itemsBuild = items.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: widget.spacing,
          children: [
            if (widget.direction == Axis.vertical)
              ...itemsBuild
            else
              Wrap(
                spacing: widget.spacing,
                runSpacing: widget.spacing,
                direction: widget.direction,
                alignment: widget.wrapAlignment ?? WrapAlignment.spaceBetween,
                children: items,
              ),
            if (widget.error != null) widget.error!,
          ],
        );
      },
    );
  }
}
