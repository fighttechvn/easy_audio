// ignore_for_file: deprecated_member_use

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/*
 * A material design circular checkbox.
 *
 * This checkbox is a modified version of `flutter/material.dart` [Checkbox],
 * his behaviour is the same except this draws a circular shape instead of
 * a squared.
 *
 * The checkbox itself does not maintain any state. Instead, when the state of
 * the checkbox changes, the widget calls the [onChanged] callback. Most
 * widgets that use a checkbox will listen for the [onChanged] callback and
 * rebuild the checkbox with a new [value] to update the visual appearance of
 * the checkbox.
 *
 * The checkbox can optionally display three values - true, false, and null -
 * if [tristate] is true. When [value] is null a dash is displayed. By default
 * [tristate] is false and the checkbox's [value] must be true or false.
 *
 * Requires one of its ancestors to be a [Material] widget.
 *
 * See also:
 *
 *  * [Checkbox]
 *  * [CircularCheckBoxListTile], 
 *  * which combines this widget with a [ListTile] so that
 *    you can give the checkbox a label.
 *  * [Switch], a widget with semantics similar to [CircularCheckBox].
 *  * [Radio], for selecting among a set of explicit values.
 *  * [Slider], for selecting a value in a range.
 *  * <https://material.io/design/components/selection-controls.html#checkboxes>
 *  * <https://material.io/design/components/lists.html#types>
 *
 */
const Duration _kToggleDuration = Duration(milliseconds: 200);

// Duration of the fade animation for the reaction when focus and hover occur.
const Duration _kReactionFadeDuration = Duration(milliseconds: 50);

class CircularCheckBox extends StatefulWidget {
  /*
   * Creates a material design circular checkbox.
   *
   * The checkbox itself does not maintain any state. Instead, when the state of
   * the checkbox changes, the widget calls the [onChanged] callback. Most
   * widgets that use a checkbox will listen for the [onChanged] callback and
   * rebuild the checkbox with a new [value] to update the visual appearance of
   * the checkbox.
   *
   * The following arguments are required:
   *
   * * [value], which determines whether the checkbox is checked. The [value]
   *   can only be null if [tristate] is true.
   * * [onChanged], which is called when the value of the checkbox should
   *   change. It can be set to null to disable the checkbox.
   *
   * The values of [tristate] and [autofocus] must not be null.
   */
  const CircularCheckBox({
    super.key,
    required this.value,
    this.tristate = false,
    required this.onChanged,
    this.mouseCursor,
    this.activeColor,
    this.fillColor,
    this.checkColor,
    this.focusColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.visualDensity,
    this.focusNode,
    this.autofocus = false,
  }) : assert(tristate || value != null, 'tristate || value != null');

  /// Whether this checkbox is checked.
  ///
  /// This property must not be null.
  final bool? value;

  /// Called when the value of the checkbox should change.
  ///
  /// The checkbox passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the checkbox with the new
  /// value.
  ///
  /// If this callback is null, the checkbox will be displayed as disabled
  /// and will not respond to input gestures.
  ///
  /// When the checkbox is tapped, if [tristate] is false (the default) then
  /// the [onChanged] callback will be applied to `!value`. If [tristate] is
  /// true this callback cycle from false to true to null.
  ///
  /// The callback provided to [onChanged] should update the state of the parent
  /// [StatefulWidget] using the [State.setState] method, so that the parent
  /// gets rebuilt; for example:
  ///
  /// ```dart
  /// CircularCheckBox(
  ///   value: _throwShotAway,
  ///   onChanged: (bool newValue) {
  ///     setState(() {
  ///       _throwShotAway = newValue;
  ///     });
  ///   },
  /// )
  /// ```
  final ValueChanged<bool?>? onChanged;

  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// If [mouseCursor] is a [MaterialStateProperty<MouseCursor>],
  /// [MaterialStateProperty.resolve] is used for the
  /// following [MaterialState]s:
  ///
  ///  * [MaterialState.selected].
  ///  * [MaterialState.hovered].
  ///  * [MaterialState.focused].
  ///  * [MaterialState.disabled].
  ///
  /// When [value] is null and [tristate] is true, [MaterialState.selected] is
  /// included as a state.
  ///
  /// If null, then the value of [CheckboxThemeData.mouseCursor] is used. If
  /// that is also null, then [MaterialStateMouseCursor.clickable] is used.
  ///
  /// See also:
  ///
  ///  * [MaterialStateMouseCursor], a [MouseCursor] that implements
  ///    `MaterialStateProperty` which is used in APIs that need to accept
  ///    either a [MouseCursor] or a [MaterialStateProperty<MouseCursor>].
  final MouseCursor? mouseCursor;

  /// The color to use when this checkbox is checked.
  ///
  /// Defaults to [ThemeData.toggleableActiveColor].
  final Color? activeColor;

  /// The color that fills the checkbox, in all [MaterialState]s.
  ///
  /// Resolves in the following states:
  ///  * [MaterialState.selected].
  ///  * [MaterialState.hovered].
  ///  * [MaterialState.focused].
  ///  * [MaterialState.disabled].
  ///
  /// If null, then the value of [activeColor] is used in the selected
  /// state. If that is also null, the value of [CheckboxThemeData.fillColor]
  /// is used. If that is also null, then [ThemeData.disabledColor] is used in
  /// the disabled state, [ThemeData.toggleableActiveColor] is used in the
  /// selected state, and [ThemeData.unselectedWidgetColor] is used in the
  /// default state.
  final MaterialStateProperty<Color?>? fillColor;

  /// The color to use for the check icon when this checkbox is checked.
  ///
  /// Defaults to Color(0xFFFFFFFF)
  final Color? checkColor;

  /// If true the checkbox's [value] can be true, false, or null.
  ///
  /// CircularCheckBox displays a dash when its value is null.
  ///
  /// When a tri-state checkbox ([tristate] is true) is tapped, its [onChanged]
  /// callback will be applied to true if the current value is false, to null if
  /// value is true, and to false if value is null (i.e. it cycles through false
  /// => true => null => false when tapped).
  ///
  /// If tristate is false (the default), [value] must not be null.
  final bool tristate;

  /// Configures the minimum size of the tap target.
  ///
  /// Defaults to [ThemeData.materialTapTargetSize].
  ///
  /// See also:
  ///
  ///  * [MaterialTapTargetSize], for a description of how
  /// this affects tap targets.
  final MaterialTapTargetSize? materialTapTargetSize;

  /// Defines how compact the checkbox's layout will be.
  ///
  /// {@macro flutter.material.themedata.visualDensity}
  ///
  /// See also:
  ///
  ///  * [ThemeData.visualDensity], which specifies the [] for all
  /// widgets
  ///    within a [Theme].
  final VisualDensity? visualDensity;

  /// The color for the circular checkbox's [Material] when it has the input
  /// focus.
  ///
  /// If [overlayColor] returns a non-null color in the [MaterialState.focused]
  /// state, it will be used instead.
  ///
  /// If null, then the value of [CheckboxThemeData.overlayColor] is used in the
  /// focused state. If that is also null, then the value of
  /// [ThemeData.focusColor] is used.
  final Color? focusColor;

  /// The color for the circular checkbox's [Material] when a pointer is
  /// hovering over it.
  ///
  /// If [overlayColor] returns a non-null color in the [MaterialState.hovered]
  /// state, it will be used instead.
  ///
  /// If null, then the value of [CheckboxThemeData.overlayColor] is used in the
  /// hovered state. If that is also null, then the value of
  /// [ThemeData.hoverColor] is used.
  final Color? hoverColor;

  /// The color for the circular checkbox's [Material].
  ///
  /// Resolves in the following states:
  ///  * [MaterialState.pressed].
  ///  * [MaterialState.selected].
  ///  * [MaterialState.hovered].
  ///  * [MaterialState.focused].
  ///
  /// If null, then the value of [activeColor] with alpha
  /// [kRadialReactionAlpha], [focusColor] and [hoverColor] is used in the
  /// pressed, focused and hovered state. If that is also null,
  /// the value of [CheckboxThemeData.overlayColor] is used. If that is
  /// also null, then the value of [ThemeData.toggleableActiveColor] with alpha
  /// [kRadialReactionAlpha], [ThemeData.focusColor] and [ThemeData.hoverColor]
  /// is used in the pressed, focused and hovered state.
  final MaterialStateProperty<Color?>? overlayColor;

  /// The splash radius of the circular [Material] ink response.
  ///
  /// If null, then the value of [CheckboxThemeData.splashRadius] is used. If
  /// that is also null, then [kRadialReactionRadius] is used.
  final double? splashRadius;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// The width of a checkbox widget.
  static const double width = 18.0;

  @override
  State<CircularCheckBox> createState() => _CircularCheckBoxState();
}

class _CircularCheckBoxState extends State<CircularCheckBox>
    with TickerProviderStateMixin {
  bool get enabled => widget.onChanged != null;
  late Map<Type, Action<Intent>> _actionMap;

  @override
  void initState() {
    super.initState();
    _actionMap = <Type, Action<Intent>>{
      ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _actionHandler),
    };
  }

  void _actionHandler(ActivateIntent intent) {
    if (widget.onChanged != null) {
      switch (widget.value) {
        case false:
          widget.onChanged!(true);
          break;
        case true:
          widget.onChanged!(widget.tristate ? null : false);
          break;
        default: // case null:
          widget.onChanged!(false);
          break;
      }
    }
    context.findRenderObject()?.sendSemanticsEvent(const TapSemanticEvent());
  }

  bool _focused = false;

  void _handleFocusHighlightChanged(bool focused) {
    if (focused != _focused) {
      setState(() {
        _focused = focused;
      });
    }
  }

  bool _hovering = false;

  void _handleHoverChanged(bool hovering) {
    if (hovering != _hovering) {
      setState(() {
        _hovering = hovering;
      });
    }
  }

  Set<MaterialState> get _states => <MaterialState>{
        if (!enabled) MaterialState.disabled,
        if (_hovering) MaterialState.hovered,
        if (_focused) MaterialState.focused,
        if (widget.value == null || widget.value!) MaterialState.selected,
      };

  MaterialStateProperty<Color?> get _widgetFillColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return null;
      }
      if (states.contains(MaterialState.selected)) {
        return widget.activeColor;
      }
      return null;
    });
  }

  MaterialStateProperty<Color> get _defaultFillColor {
    final themeData = Theme.of(context);
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return themeData.disabledColor;
      }
      if (states.contains(MaterialState.selected)) {
        return themeData.colorScheme.secondary;
      }
      return themeData.unselectedWidgetColor;
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context), 'debugCheckHasMaterial(context)');
    final themeData = Theme.of(context);
    final effectiveMaterialTapTargetSize = widget.materialTapTargetSize ??
        themeData.checkboxTheme.materialTapTargetSize ??
        themeData.materialTapTargetSize;
    final effectiveVisualDensity = widget.visualDensity ??
        themeData.checkboxTheme.visualDensity ??
        themeData.visualDensity;
    Size size;
    switch (effectiveMaterialTapTargetSize) {
      case MaterialTapTargetSize.padded:
        size = const Size(kMinInteractiveDimension, kMinInteractiveDimension);
        break;
      case MaterialTapTargetSize.shrinkWrap:
        size = const Size(
          kMinInteractiveDimension - 8.0,
          kMinInteractiveDimension - 8.0,
        );
        break;
    }
    size += effectiveVisualDensity.baseSizeAdjustment;
    final additionalConstraints = BoxConstraints.tight(size);
    final effectiveMouseCursor = MaterialStateProperty.resolveAs<MouseCursor?>(
          widget.mouseCursor,
          _states,
        ) ??
        themeData.checkboxTheme.mouseCursor?.resolve(_states) ??
        MaterialStateProperty.resolveAs<MouseCursor>(
          MaterialStateMouseCursor.clickable,
          _states,
        );
    // Colors need to be resolved in selected and non selected states separately
    // so that they can be lerped between.
    final activeStates = _states..add(MaterialState.selected);
    final inactiveStates = _states..remove(MaterialState.selected);
    final effectiveActiveColor = widget.fillColor?.resolve(activeStates) ??
        _widgetFillColor.resolve(activeStates) ??
        themeData.checkboxTheme.fillColor?.resolve(activeStates) ??
        _defaultFillColor.resolve(activeStates);
    final effectiveInactiveColor = widget.fillColor?.resolve(inactiveStates) ??
        _widgetFillColor.resolve(inactiveStates) ??
        themeData.checkboxTheme.fillColor?.resolve(inactiveStates) ??
        _defaultFillColor.resolve(inactiveStates);

    final focusedStates = _states..add(MaterialState.focused);
    final effectiveFocusOverlayColor =
        widget.overlayColor?.resolve(focusedStates) ??
            widget.focusColor ??
            themeData.checkboxTheme.overlayColor?.resolve(focusedStates) ??
            themeData.focusColor;

    final hoveredStates = _states..add(MaterialState.hovered);
    final effectiveHoverOverlayColor =
        widget.overlayColor?.resolve(hoveredStates) ??
            widget.hoverColor ??
            themeData.checkboxTheme.overlayColor?.resolve(hoveredStates) ??
            themeData.hoverColor;

    final activePressedStates = activeStates..add(MaterialState.pressed);
    final effectiveActivePressedOverlayColor = widget.overlayColor
            ?.resolve(activePressedStates) ??
        themeData.checkboxTheme.overlayColor?.resolve(activePressedStates) ??
        effectiveActiveColor.withAlpha(kRadialReactionAlpha);

    final inactivePressedStates = inactiveStates..add(MaterialState.pressed);
    final effectiveInactivePressedOverlayColor = widget.overlayColor
            ?.resolve(inactivePressedStates) ??
        themeData.checkboxTheme.overlayColor?.resolve(inactivePressedStates) ??
        effectiveActiveColor.withAlpha(kRadialReactionAlpha);

    final effectiveCheckColor = widget.checkColor ??
        themeData.checkboxTheme.checkColor?.resolve(_states) ??
        const Color(0xFFFFFFFF);

    return FocusableActionDetector(
      actions: _actionMap,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: enabled,
      onShowFocusHighlight: _handleFocusHighlightChanged,
      onShowHoverHighlight: _handleHoverChanged,
      mouseCursor: effectiveMouseCursor,
      child: Builder(
        builder: (BuildContext context) {
          return _CircularCheckBoxRenderObjectWidget(
            value: widget.value,
            tristate: widget.tristate,
            activeColor: effectiveActiveColor,
            checkColor: effectiveCheckColor,
            inactiveColor: effectiveInactiveColor,
            focusColor: effectiveFocusOverlayColor,
            hoverColor: effectiveHoverOverlayColor,
            reactionColor: effectiveActivePressedOverlayColor,
            inactiveReactionColor: effectiveInactivePressedOverlayColor,
            splashRadius: widget.splashRadius ??
                themeData.checkboxTheme.splashRadius ??
                kRadialReactionRadius,
            onChanged: widget.onChanged,
            additionalConstraints: additionalConstraints,
            vsync: this,
            hasFocus: _focused,
            hovering: _hovering,
          );
        },
      ),
    );
  }
}

class _CircularCheckBoxRenderObjectWidget extends LeafRenderObjectWidget {
  const _CircularCheckBoxRenderObjectWidget({
    required this.value,
    required this.tristate,
    required this.activeColor,
    required this.checkColor,
    required this.inactiveColor,
    required this.focusColor,
    required this.hoverColor,
    required this.reactionColor,
    required this.inactiveReactionColor,
    required this.splashRadius,
    required this.onChanged,
    required this.vsync,
    required this.additionalConstraints,
    required this.hasFocus,
    required this.hovering,
  }) : assert(tristate || value != null, 'tristate || value != null');

  final bool? value;
  final bool tristate;
  final bool hasFocus;
  final bool hovering;
  final Color activeColor;
  final Color checkColor;
  final Color inactiveColor;
  final Color focusColor;
  final Color hoverColor;
  final Color reactionColor;
  final Color inactiveReactionColor;
  final double splashRadius;
  final ValueChanged<bool?>? onChanged;
  final TickerProvider vsync;
  final BoxConstraints additionalConstraints;

  @override
  _RenderCircularCheckBox createRenderObject(BuildContext context) =>
      _RenderCircularCheckBox(
        value: value,
        tristate: tristate,
        activeColor: activeColor,
        checkColor: checkColor,
        inactiveColor: inactiveColor,
        focusColor: focusColor,
        hoverColor: hoverColor,
        reactionColor: reactionColor,
        inactiveReactionColor: inactiveReactionColor,
        splashRadius: splashRadius,
        onChanged: onChanged,
        vsync: vsync,
        additionalConstraints: additionalConstraints,
        hasFocus: hasFocus,
        hovering: hovering,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderCircularCheckBox renderObject,
  ) {
    renderObject
      ..tristate = tristate
      ..value = value
      ..activeColor = activeColor
      ..checkColor = checkColor
      ..inactiveColor = inactiveColor
      ..focusColor = focusColor
      ..hoverColor = hoverColor
      ..reactionColor = reactionColor
      ..inactiveReactionColor = inactiveReactionColor
      ..splashRadius = splashRadius
      ..onChanged = onChanged
      ..additionalConstraints = additionalConstraints
      ..vsync = vsync
      ..hasFocus = hasFocus
      ..hovering = hovering;
  }
}

const double _kEdgeSize = CircularCheckBox.width;
const double _kStrokeWidth = 2.0;

class _RenderCircularCheckBox extends RenderToggleable {
  _RenderCircularCheckBox({
    super.value,
    required super.tristate,
    required super.activeColor,
    required this.checkColor,
    required super.inactiveColor,
    super.focusColor,
    super.hoverColor,
    super.reactionColor,
    super.inactiveReactionColor,
    required super.splashRadius,
    required super.additionalConstraints,
    super.onChanged,
    required super.hasFocus,
    required super.hovering,
    required super.vsync,
  }) : _oldValue = value;

  bool? _oldValue;
  Color checkColor;

  @override
  set value(bool? newValue) {
    if (newValue == value) {
      return;
    }
    _oldValue = value;
    super.value = newValue;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isChecked = value == true;
  }

  // The checkbox's border color if value == false, or its fill color when
  // value == true or null.
  Color _colorAt(double t) {
    // As t goes from 0.0 to 0.25, animate from the inactiveColor to
    // activeColor.
    return t >= 0.25
        ? activeColor
        : Color.lerp(inactiveColor, activeColor, t * 4.0)!;
  }

  // checkColor stroke used to paint the check and dash.
  Paint _createStrokePaint() {
    return Paint()
      ..color = checkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kStrokeWidth;
  }

  void _drawCircleBorder(
    Canvas canvas,
    Offset center,
    double radius,
    double t,
    Paint paint,
  ) {
    assert(t >= 0.0 && t <= 0.5, 't >= 0.0 && t <= 0.5');
    paint
      ..strokeWidth = _kStrokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, paint);
  }

  void _drawCheck(Canvas canvas, Offset origin, double t, Paint paint) {
    assert(t >= 0.0 && t <= 1.0, 't >= 0.0 && t <= 1.0');
    // As t goes from 0.0 to 1.0, animate the two check mark strokes from the
    // short side to the long side.
    final path = Path();
    const start = Offset(_kEdgeSize * 0.15, _kEdgeSize * 0.45);
    const mid = Offset(_kEdgeSize * 0.4, _kEdgeSize * 0.7);
    const end = Offset(_kEdgeSize * 0.85, _kEdgeSize * 0.25);
    if (t < 0.5) {
      final strokeT = t * 2.0;
      final drawMid = Offset.lerp(start, mid, strokeT)!;
      path
        ..moveTo(origin.dx + start.dx, origin.dy + start.dy)
        ..lineTo(origin.dx + drawMid.dx, origin.dy + drawMid.dy);
    } else {
      final strokeT = (t - 0.5) * 2.0;
      final drawEnd = Offset.lerp(mid, end, strokeT)!;
      path
        ..moveTo(origin.dx + start.dx, origin.dy + start.dy)
        ..lineTo(origin.dx + mid.dx, origin.dy + mid.dy)
        ..lineTo(origin.dx + drawEnd.dx, origin.dy + drawEnd.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawDash(Canvas canvas, Offset origin, double t, Paint paint) {
    assert(t >= 0.0 && t <= 1.0, 't >= 0.0 && t <= 1.0');
    // As t goes from 0.0 to 1.0, animate the horizontal line from the
    // mid point outwards.
    const start = Offset(_kEdgeSize * 0.2, _kEdgeSize * 0.5);
    const mid = Offset(_kEdgeSize * 0.5, _kEdgeSize * 0.5);
    const end = Offset(_kEdgeSize * 0.8, _kEdgeSize * 0.5);
    final drawStart = Offset.lerp(start, mid, 1.0 - t)!;
    final drawEnd = Offset.lerp(mid, end, t)!;
    canvas.drawLine(origin + drawStart, origin + drawEnd, paint);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    paintRadialReaction(canvas, offset, size.center(Offset.zero));

    final strokePaint = _createStrokePaint();
    final origin =
        offset + (size / 2.0 - const Size.square(_kEdgeSize) / 2.0 as Offset);
    final status = position.status;
    final tNormalized =
        status == AnimationStatus.forward || status == AnimationStatus.completed
            ? position.value
            : 1.0 - position.value;
    final center = (offset & size).center;

    // Four cases: false to null, false to true, null to false, true to false
    if (_oldValue == false || value == false) {
      final t = value == false ? 1.0 - tNormalized : tNormalized;
      final paint = Paint()..color = _colorAt(t);

      if (t <= 0.5) {
        _drawCircleBorder(canvas, center, 11, t, paint);
      } else {
        canvas.drawCircle(center, 13, paint);

        final tShrink = (t - 0.5) * 2.0;
        if (_oldValue == null || value == null) {
          _drawDash(canvas, origin, tShrink, strokePaint);
        } else {
          _drawCheck(canvas, origin, tShrink, strokePaint);
        }
      }
    } else {
      // Two cases: null to true, true to null
      final paint = Paint()..color = _colorAt(1.0);
      canvas.drawCircle(center, 12, paint);

      if (tNormalized <= 0.5) {
        final tShrink = 1.0 - tNormalized * 2.0;
        if (_oldValue == true) {
          _drawCheck(canvas, origin, tShrink, strokePaint);
        } else {
          _drawDash(canvas, origin, tShrink, strokePaint);
        }
      } else {
        final tExpand = (tNormalized - 0.5) * 2.0;
        if (value == true) {
          _drawCheck(canvas, origin, tExpand, strokePaint);
        } else {
          _drawDash(canvas, origin, tExpand, strokePaint);
        }
      }
    }
  }
}

abstract class RenderToggleable extends RenderConstrainedBox {
  /// Creates a toggleable render object.
  ///
  /// The [activeColor], and [inactiveColor] arguments must not be
  /// null. The [value] can only be null if tristate is true.
  RenderToggleable({
    required bool? value,
    bool tristate = false,
    required Color activeColor,
    required Color inactiveColor,
    Color? hoverColor,
    Color? focusColor,
    Color? reactionColor,
    Color? inactiveReactionColor,
    required double splashRadius,
    ValueChanged<bool?>? onChanged,
    required super.additionalConstraints,
    required TickerProvider vsync,
    bool hasFocus = false,
    bool hovering = false,
  })  : _value = value,
        _tristate = tristate,
        _activeColor = activeColor,
        _inactiveColor = inactiveColor,
        _hoverColor = hoverColor ?? activeColor.withAlpha(kRadialReactionAlpha),
        _focusColor = focusColor ?? activeColor.withAlpha(kRadialReactionAlpha),
        _reactionColor =
            reactionColor ?? activeColor.withAlpha(kRadialReactionAlpha),
        _inactiveReactionColor = inactiveReactionColor ??
            activeColor.withAlpha(kRadialReactionAlpha),
        _splashRadius = splashRadius,
        _onChanged = onChanged,
        _hasFocus = hasFocus,
        _hovering = hovering,
        _vsync = vsync {
    _tap = TapGestureRecognizer()
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap
      ..onTapUp = _handleTapUp
      ..onTapCancel = _handleTapCancel;
    _positionController = AnimationController(
      duration: _kToggleDuration,
      value: value == false ? 0.0 : 1.0,
      vsync: vsync,
    );
    _position = CurvedAnimation(
      parent: _positionController,
      curve: Curves.linear,
    )..addListener(markNeedsPaint);
    _reactionController = AnimationController(
      duration: kRadialReactionDuration,
      vsync: vsync,
    );
    _reaction = CurvedAnimation(
      parent: _reactionController,
      curve: Curves.fastOutSlowIn,
    )..addListener(markNeedsPaint);
    _reactionHoverFadeController = AnimationController(
      duration: _kReactionFadeDuration,
      value: hovering || hasFocus ? 1.0 : 0.0,
      vsync: vsync,
    );
    _reactionHoverFade = CurvedAnimation(
      parent: _reactionHoverFadeController,
      curve: Curves.fastOutSlowIn,
    )..addListener(markNeedsPaint);
    _reactionFocusFadeController = AnimationController(
      duration: _kReactionFadeDuration,
      value: hovering || hasFocus ? 1.0 : 0.0,
      vsync: vsync,
    );
    _reactionFocusFade = CurvedAnimation(
      parent: _reactionFocusFadeController,
      curve: Curves.fastOutSlowIn,
    )..addListener(markNeedsPaint);
  }

  /// Used by subclasses to manipulate the visual value of the control.
  ///
  /// Some controls respond to user input by updating their visual value. For
  /// example, the thumb of a switch moves from one position to another when
  /// dragged. These controls manipulate this animation controller to update
  /// their [position] and eventually trigger an [onChanged] callback when the
  /// animation reaches either 0.0 or 1.0.
  @protected
  AnimationController get positionController => _positionController;
  late AnimationController _positionController;

  /// The visual value of the control.
  ///
  /// When the control is inactive, the [value] is false and this animation has
  /// the value 0.0. When the control is active, the value either true or t
  /// ristate is true and the value is null. When the control is active the
  /// animation has a value of 1.0. When the control is changing from inactive
  /// to active (or vice versa), [value] is the target value and this animation
  /// gradually updates from 0.0 to 1.0 (or vice versa).
  CurvedAnimation get position => _position;
  late CurvedAnimation _position;

  /// Used by subclasses to control the radial reaction animation.
  ///
  /// Some controls have a radial ink reaction to user input. This animation
  /// controller can be used to start or stop these ink reactions.
  ///
  /// Subclasses should call [paintRadialReaction] to actually paint the radial
  /// reaction.
  @protected
  AnimationController get reactionController => _reactionController;
  late AnimationController _reactionController;
  late Animation<double> _reaction;

  /// Used by subclasses to control the radial reaction's opacity animation for
  /// [hasFocus] changes.
  ///
  /// Some controls have a radial ink reaction to focus. This animation
  /// controller can be used to start or stop these ink reaction fade-ins and
  /// fade-outs.
  ///
  /// Subclasses should call [paintRadialReaction] to actually paint the radial
  /// reaction.
  @protected
  AnimationController get reactionFocusFadeController =>
      _reactionFocusFadeController;
  late AnimationController _reactionFocusFadeController;
  late Animation<double> _reactionFocusFade;

  /// Used by subclasses to control the radial reaction's opacity animation for
  /// [hovering] changes.
  ///
  /// Some controls have a radial ink reaction to pointer hover. This animation
  /// controller can be used to start or stop these ink reaction fade-ins and
  /// fade-outs.
  ///
  /// Subclasses should call [paintRadialReaction] to actually paint the radial
  /// reaction.
  @protected
  AnimationController get reactionHoverFadeController =>
      _reactionHoverFadeController;
  late AnimationController _reactionHoverFadeController;
  late Animation<double> _reactionHoverFade;

  /// True if this toggleable has the input focus.
  bool get hasFocus => _hasFocus;
  bool _hasFocus;

  set hasFocus(bool value) {
    if (value == _hasFocus) {
      return;
    }
    _hasFocus = value;
    if (_hasFocus) {
      _reactionFocusFadeController.forward();
    } else {
      _reactionFocusFadeController.reverse();
    }
    markNeedsPaint();
  }

  /// True if this toggleable is being hovered over by a pointer.
  bool get hovering => _hovering;
  bool _hovering;

  set hovering(bool value) {
    if (value == _hovering) {
      return;
    }
    _hovering = value;
    if (_hovering) {
      _reactionHoverFadeController.forward();
    } else {
      _reactionHoverFadeController.reverse();
    }
    markNeedsPaint();
  }

  /// The [TickerProvider] for the [AnimationController]s that run the
  /// animations.
  TickerProvider get vsync => _vsync;
  TickerProvider _vsync;

  set vsync(TickerProvider value) {
    if (value == _vsync) {
      return;
    }
    _vsync = value;
    positionController.resync(vsync);
    reactionController.resync(vsync);
  }

  /// False if this control is "inactive" (not checked, off, or unselected).
  ///
  /// If value is true then the control "active" (checked, on, or selected). If
  /// tristate is true and value is null, then the control is considered to be
  /// in its third or "indeterminate" state.
  ///
  /// When the value changes, this object starts the [positionController] and
  /// [position] animations to animate the visual appearance of the control to
  /// the new value.
  bool? get value => _value;
  bool? _value;

  set value(bool? value) {
    assert(tristate || value != null, 'tristate || value != null');
    if (value == _value) {
      return;
    }
    _value = value;
    markNeedsSemanticsUpdate();
    _position
      ..curve = Curves.easeIn
      ..reverseCurve = Curves.easeOut;
    if (tristate) {
      if (value == null) {
        _positionController.value = 0.0;
      }
      if (value != false) {
        _positionController.forward();
      } else {
        _positionController.reverse();
      }
    } else {
      if (value == true) {
        _positionController.forward();
      } else {
        _positionController.reverse();
      }
    }
  }

  /// If true, [value] can be true, false, or null, otherwise [value] must
  /// be true or false.
  ///
  /// When [tristate] is true and [value] is null, then the control is
  /// considered to be in its third or "indeterminate" state.
  bool get tristate => _tristate;
  bool _tristate;

  set tristate(bool value) {
    if (value == _tristate) {
      return;
    }
    _tristate = value;
    markNeedsSemanticsUpdate();
  }

  /// The color that should be used in the active state
  /// (i.e., when [value] is true).
  ///
  /// For example, a checkbox should use this color when checked.
  Color get activeColor => _activeColor;
  Color _activeColor;

  set activeColor(Color value) {
    if (value == _activeColor) {
      return;
    }
    _activeColor = value;
    markNeedsPaint();
  }

  /// The color that should be used in the inactive state
  /// (i.e., when [value] is false).
  ///
  /// For example, a checkbox should use this color when unchecked.
  Color get inactiveColor => _inactiveColor;
  Color _inactiveColor;

  set inactiveColor(Color value) {
    if (value == _inactiveColor) {
      return;
    }
    _inactiveColor = value;
    markNeedsPaint();
  }

  /// The color that should be used for the reaction when [hovering] is true.
  ///
  /// Used when the toggleable needs to change the reaction color/transparency,
  /// when it is being hovered over.
  ///
  /// Defaults to the [activeColor] at alpha [kRadialReactionAlpha].
  Color get hoverColor => _hoverColor;
  Color _hoverColor;

  set hoverColor(Color value) {
    if (value == _hoverColor) {
      return;
    }
    _hoverColor = value;
    markNeedsPaint();
  }

  /// The color that should be used for the reaction when [hasFocus] is true.
  ///
  /// Used when the toggleable needs to change the reaction color/transparency,
  /// when it has focus.
  ///
  /// Defaults to the [activeColor] at alpha [kRadialReactionAlpha].
  Color get focusColor => _focusColor;
  Color _focusColor;

  set focusColor(Color value) {
    if (value == _focusColor) {
      return;
    }
    _focusColor = value;
    markNeedsPaint();
  }

  /// The color that should be used for the reaction when the toggleable is
  /// active.
  ///
  /// Used when the toggleable needs to change the reaction color/transparency
  /// that is displayed when the toggleable is active and tapped.
  ///
  /// Defaults to the [activeColor] at alpha [kRadialReactionAlpha].
  Color? get reactionColor => _reactionColor;
  Color? _reactionColor;

  set reactionColor(Color? value) {
    if (value == _reactionColor) {
      return;
    }
    _reactionColor = value;
    markNeedsPaint();
  }

  /// The color that should be used for the reaction when the toggleable is
  /// inactive.
  ///
  /// Used when the toggleable needs to change the reaction color/transparency
  /// that is displayed when the toggleable is inactive and tapped.
  ///
  /// Defaults to the [activeColor] at alpha [kRadialReactionAlpha].
  Color? get inactiveReactionColor => _inactiveReactionColor;
  Color? _inactiveReactionColor;

  set inactiveReactionColor(Color? value) {
    if (value == _inactiveReactionColor) {
      return;
    }
    _inactiveReactionColor = value;
    markNeedsPaint();
  }

  /// The splash radius for the radial reaction.
  double get splashRadius => _splashRadius;
  double _splashRadius;

  set splashRadius(double value) {
    if (value == _splashRadius) {
      return;
    }
    _splashRadius = value;
    markNeedsPaint();
  }

  /// Called when the control changes value.
  ///
  /// If the control is tapped, [onChanged] is called immediately with the new
  /// value.
  ///
  /// The control is considered interactive (see [isInteractive]) if this
  /// callback is non-null. If the callback is null, then the control is
  /// disabled, and non-interactive. A disabled checkbox, for example, is
  /// displayed using a grey color and its value cannot be changed.
  ValueChanged<bool?>? get onChanged => _onChanged;
  ValueChanged<bool?>? _onChanged;

  set onChanged(ValueChanged<bool?>? value) {
    if (value == _onChanged) {
      return;
    }
    final wasInteractive = isInteractive;
    _onChanged = value;
    if (wasInteractive != isInteractive) {
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  /// Whether [value] of this control can be changed by user interaction.
  ///
  /// The control is considered interactive if the [onChanged] callback is
  /// non-null. If the callback is null, then the control is disabled, and
  /// non-interactive. A disabled checkbox, for example, is displayed using a
  /// grey color and its value cannot be changed.
  bool get isInteractive => onChanged != null;

  late TapGestureRecognizer _tap;
  Offset? _downPosition;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (value == false) {
      _positionController.reverse();
    } else {
      _positionController.forward();
    }
    if (isInteractive) {
      switch (_reactionController.status) {
        case AnimationStatus.forward:
          _reactionController.forward();
          break;
        case AnimationStatus.reverse:
          _reactionController.reverse();
          break;
        case AnimationStatus.dismissed:
        case AnimationStatus.completed:
          // nothing to do
          break;
      }
    }
  }

  @override
  void detach() {
    _positionController.stop();
    _reactionController.stop();
    _reactionHoverFadeController.stop();
    _reactionFocusFadeController.stop();
    super.detach();
  }

  void _handleTapDown(TapDownDetails details) {
    if (isInteractive) {
      _downPosition = globalToLocal(details.globalPosition);
      _reactionController.forward();
    }
  }

  void _handleTap() {
    if (!isInteractive) {
      return;
    }
    switch (value) {
      case false:
        onChanged!(true);
        break;
      case true:
        onChanged!(tristate ? null : false);
        break;
      case null:
        onChanged!(false);
        break;
    }
    sendSemanticsEvent(const TapSemanticEvent());
  }

  void _handleTapUp(TapUpDetails details) {
    _downPosition = null;
    if (isInteractive) {
      _reactionController.reverse();
    }
  }

  void _handleTapCancel() {
    _downPosition = null;
    if (isInteractive) {
      _reactionController.reverse();
    }
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry), 'debugHandleEvent(event, entry)');
    if (event is PointerDownEvent && isInteractive) {
      _tap.addPointer(event);
    }
  }

  /// Used by subclasses to paint the radial ink reaction for this control.
  ///
  /// The reaction is painted on the given canvas at the given offset. The
  /// origin is the center point of the reaction (usually distinct from the
  /// point at which the user interacted with the control, which is handled
  /// automatically).
  void paintRadialReaction(Canvas canvas, Offset offset, Offset origin) {
    if (!_reaction.isDismissed ||
        !_reactionFocusFade.isDismissed ||
        !_reactionHoverFade.isDismissed) {
      final reactionPaint = Paint()
        ..color = Color.lerp(
          Color.lerp(
            Color.lerp(inactiveReactionColor, reactionColor, _position.value),
            hoverColor,
            _reactionHoverFade.value,
          ),
          focusColor,
          _reactionFocusFade.value,
        )!;
      final center =
          Offset.lerp(_downPosition ?? origin, origin, _reaction.value)!;
      final Animatable<double> radialReactionRadiusTween = Tween<double>(
        begin: 0.0,
        end: splashRadius,
      );
      final reactionRadius = hasFocus || hovering
          ? splashRadius
          : radialReactionRadiusTween.evaluate(_reaction);
      if (reactionRadius > 0.0) {
        canvas.drawCircle(center + offset, reactionRadius, reactionPaint);
      }
    }
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config.isEnabled = isInteractive;
    if (isInteractive) {
      config.onTap = _handleTap;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        FlagProperty(
          'value',
          value: value,
          ifTrue: 'checked',
          ifFalse: 'unchecked',
          showName: true,
        ),
      )
      ..add(
        FlagProperty(
          'isInteractive',
          value: isInteractive,
          ifTrue: 'enabled',
          ifFalse: 'disabled',
          defaultValue: true,
        ),
      );
  }
}
