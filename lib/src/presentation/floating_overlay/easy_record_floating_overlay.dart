import 'dart:async';

import 'package:floating_draggable_widget/floating_draggable_widget.dart';
import 'package:flutter/material.dart';

import '../../application/easy_record_callbacks.dart';
import '../../application/easy_record_configuration.dart';
import '../../core/services/record_modal_service.dart';
import '../../domain/entities/record_session_data.dart';
import '../record_modal/record_session_manager.dart';
import '../record_modal/widgets/floating_record_widget.dart';

class EasyRecordFloatingOverlay extends StatefulWidget {
  const EasyRecordFloatingOverlay({
    super.key,
    required this.child,
    this.navigatorKey,
    this.onRecordComplete,
    this.configuration,
    this.floatingWidgetBuilder,
    this.floatingWidgetWidth = 80,
    this.floatingWidgetHeight = 80,
    this.initialDx,
    this.initialDy,
    this.autoAlign = true,
  });

  /// The child widget to wrap (typically your MaterialApp or Navigator).
  final Widget child;

  /// Navigator key for the app.
  /// If provided, will initialize [EasyRecordModalService] with this key.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Callback invoked when recording is completed.
  /// If not provided, uses the callback from the active session's config.
  final OnRecordComplete? onRecordComplete;

  /// Default configuration for recording sessions.
  final EasyRecordConfiguration? configuration;

  /// Custom builder for the floating widget.
  /// If null, uses the default [FloatingRecordWidget].
  final FloatingWidgetBuilder? floatingWidgetBuilder;

  /// Width of the floating widget.
  final double floatingWidgetWidth;

  /// Height of the floating widget.
  final double floatingWidgetHeight;

  /// Initial X position of the floating widget.
  /// If null, positioned near the right edge.
  final double? initialDx;

  /// Initial Y position of the floating widget.
  /// If null, positioned at 70% of screen height.
  final double? initialDy;

  /// Whether the floating widget should auto-align to screen edges.
  final bool autoAlign;

  @override
  State<EasyRecordFloatingOverlay> createState() =>
      _EasyRecordFloatingOverlayState();
}

class _EasyRecordFloatingOverlayState extends State<EasyRecordFloatingOverlay> {
  StreamSubscription<bool>? _minimizedStateSubscription;
  final ValueNotifier<bool> _showFloatingWidget = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    debugPrint('[EasyRecordFloatingOverlay] initState');

    // Initialize modal service if navigator key is provided
    if (widget.navigatorKey != null) {
      EasyRecordModalService.instance.initialize(widget.navigatorKey!);
    }

    // Listen to session manager for minimize/restore events
    _minimizedStateSubscription =
        RecordSessionManager.instance.minimizedStateStream.listen(
      (isMinimized) {
        debugPrint(
          '[EasyRecordFloatingOverlay] Received stream event: $isMinimized',
        );
        if (mounted && _showFloatingWidget.value != isMinimized) {
          _showFloatingWidget.value = isMinimized;
        }
      },
      onError: (error) {
        debugPrint('[EasyRecordFloatingOverlay] Stream error: $error');
      },
    );
  }

  @override
  void dispose() {
    _minimizedStateSubscription?.cancel();
    _showFloatingWidget.dispose();
    super.dispose();
  }

  void _onTapFloatingWidget() {
    final sessionManager = RecordSessionManager.instance;
    if (!sessionManager.hasActiveSession) {
      debugPrint('[EasyRecordFloatingOverlay] No active session');
      return;
    }

    final sessionData = sessionManager.data;
    final context = widget.navigatorKey?.currentContext ?? this.context;

    if (!context.mounted) {
      debugPrint('[EasyRecordFloatingOverlay] Context not mounted');
      return;
    }

    // Determine the configuration to use
    final config = widget.configuration ??
        EasyRecordModalService.instance.currentConfig ??
        EasyRecordConfiguration(
          defaultLocale: sessionManager.locale ?? 'en-US',
          title: sessionManager.title,
          onExitConfirmation: sessionManager.onExit,
          onRecordComplete: widget.onRecordComplete,
        );

    // Restore the modal
    EasyRecordModalService.instance
        .openModal(
      context: context,
      config: config.copyWith(
        sessionData: sessionData is RecordSessionData ? sessionData : null,
        defaultLocale: sessionManager.locale ?? config.defaultLocale,
        title: sessionManager.title ?? config.title,
      ),
      restoreFromSession: true,
    )
        .then((result) {
      if (result != null) {
        // Call the appropriate callback
        final callback = widget.onRecordComplete ?? config.onRecordComplete;
        callback?.call(
          result,
          sessionManager.locale ?? config.defaultLocale,
          sessionData is RecordSessionData ? sessionData : null,
        );
        sessionManager.endSession(disposeResources: true);
      }
    });
  }

  Widget _buildFloatingWidget(
    BuildContext context,
    Duration elapsedTime,
    bool isPaused,
  ) {
    // Use custom builder if provided
    if (widget.floatingWidgetBuilder != null) {
      final custom = widget.floatingWidgetBuilder!(
        context,
        _onTapFloatingWidget,
        elapsedTime,
        isPaused,
      );
      if (custom != null) {
        return custom;
      }
    }

    // Use default floating widget
    return FloatingRecordWidget(
      key: const ValueKey('floating_record_widget'),
      onTap: _onTapFloatingWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ValueListenableBuilder<bool>(
      valueListenable: _showFloatingWidget,
      builder: (context, isShow, child) {
        debugPrint(
          '[EasyRecordFloatingOverlay] Building, isShow: $isShow',
        );

        return FloatingDraggableWidget(
          floatingWidget: isShow
              ? _buildFloatingWidget(context, Duration.zero, false)
              : const SizedBox.shrink(),
          floatingWidgetWidth: widget.floatingWidgetWidth,
          floatingWidgetHeight: widget.floatingWidgetHeight,
          dx: widget.initialDx ?? screenWidth - 100,
          dy: widget.initialDy ?? screenHeight * 0.7,
          mainScreenWidget: widget.child,
          autoAlign: widget.autoAlign,
          speed: 10,
        );
      },
    );
  }
}
