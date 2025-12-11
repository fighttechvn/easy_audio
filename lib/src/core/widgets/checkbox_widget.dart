// Copyright 2022 Fighttech.vn, Ltd. All rights reserved.

import 'package:flutter/material.dart';

typedef CheckboxBuilder<T> = Widget Function(bool isSelected, T data);

enum PositionRadio {
  start,
  end;

  bool get isStart => this == PositionRadio.start;
  bool get isEnd => this == PositionRadio.end;
}

class CheckBoxWidget<T> extends StatefulWidget {
  final double size;
  final Color borderColor;
  final bool isSelected;
  final bool hasUnselect;
  final Function(bool isSelected)? onSelected;
  final String? text;
  final Widget? textWidget;
  final Color? activeColor;
  final Color? inactiveColor;
  final CheckboxBuilder<T>? builder;
  final TextStyle? style;
  final T data;
  final bool expendTitle;
  final PositionRadio position;

  const CheckBoxWidget({
    super.key,
    this.size = 22,
    this.borderColor = Colors.grey,
    this.isSelected = false,
    this.hasUnselect = false,
    this.onSelected,
    this.text,
    this.activeColor,
    this.inactiveColor,
    this.builder,
    this.style,
    required this.data,
    this.textWidget,
    this.expendTitle = false,
    this.position = PositionRadio.start,
  });

  @override
  State<CheckBoxWidget<T>> createState() => _CheckBoxWidgetState<T>();
}

class _CheckBoxWidgetState<T> extends State<CheckBoxWidget<T>> {
  late bool _isSelected;

  @override
  void initState() {
    _isSelected = widget.isSelected;

    super.initState();
  }

  @override
  void didUpdateWidget(covariant CheckBoxWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      _isSelected = widget.isSelected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('checkbox_widget_key'),
      onTap: () {
        if (_isSelected == true && widget.hasUnselect == false) {
          return;
        }

        setState(() {
          _isSelected = !_isSelected;
        });
        widget.onSelected?.call(_isSelected);
      },
      child: Container(
        color: Colors.transparent,
        child: (widget.text?.isNotEmpty ?? false) || widget.textWidget != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.position.isStart) ...[
                    _buildCheckBoxCustom(),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    fit: widget.expendTitle ? FlexFit.tight : FlexFit.loose,
                    child: widget.textWidget ??
                        ((widget.text?.isNotEmpty ?? false)
                            ? Tooltip(
                                message: widget.text,
                                child: Text(
                                  widget.text!,
                                  style: widget.style,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            : const SizedBox()),
                  ),
                  if (widget.position.isEnd) ...[
                    const SizedBox(width: 10),
                    _buildCheckBoxCustom(),
                  ],
                ],
              )
            : _buildCheckBoxCustom(),
      ),
    );
  }

  Widget _buildCheckBoxCustom() {
    if (widget.builder != null) {
      return widget.builder!.call(_isSelected, widget.data);
    }

    return CircleCheckBox(
      key: const ValueKey('checkbox_widget_container_key'),
      isSelected: _isSelected,
      activeColor: widget.activeColor,
      inactiveColor: widget.inactiveColor,
      size: widget.size,
      borderColor: widget.borderColor,
    );
  }
}

class CircleCheckBox extends StatelessWidget {
  const CircleCheckBox({
    super.key,
    required this.isSelected,
    this.activeColor,
    this.inactiveColor,
    this.size = 20,
    this.borderColor = Colors.grey,
    this.value,
  });

  final bool isSelected;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;
  final Color borderColor;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: isSelected ? null : Border.all(color: borderColor),
        color: isSelected
            ? (activeColor ?? Theme.of(context).colorScheme.secondary)
            : (inactiveColor ?? Theme.of(context).scaffoldBackgroundColor),
        borderRadius: BorderRadius.circular(
          size / 2,
        ),
      ),
      alignment: Alignment.center,
      padding: value == null ? null : const EdgeInsets.all(2),
      child: value == null
          ? null
          : Center(
              child: Text(
                '$value',
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
    );
  }
}
