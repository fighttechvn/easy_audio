import 'dart:async';
import 'dart:io';

import 'package:floating_draggable_widget/floating_draggable_widget.dart';
import 'package:flutter/material.dart';

import '../../../core/services/record_modal_service.dart';
import '../../record_modal/record_session_manager.dart';
import '../../record_modal/widgets/floating_record_widget.dart';

class RecordFloatingOverlayWidget<T> extends StatefulWidget {
  const RecordFloatingOverlayWidget({
    super.key,
    required this.navigatorKey,
    required this.child,
    required this.isSameData,
    required this.validData,
    required this.onDone,
  });

  /// Navigator key để khởi tạo RecordModalService và truy cập context
  final GlobalKey<NavigatorState> navigatorKey;

  final bool Function(T dataCurrent, T data) isSameData;
  final bool Function(T data) validData;
  final void Function(
    T data,
    String content,
    File record,
    String locale,
  ) onDone;

  final Widget child;

  @override
  State<RecordFloatingOverlayWidget<T>> createState() =>
      _RecordFloatingOverlayWidgetState<T>();
}

class _RecordFloatingOverlayWidgetState<T>
    extends State<RecordFloatingOverlayWidget<T>> {
  StreamSubscription<bool>? _minimizedStateSubscription;
  final ValueNotifier<bool> _showFloatingWidget = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    debugPrint('[RecordFloatingOverlay] initState - setting up listener');

    // Initialize RecordModalService với global navigator
    RecordModalService.instance.initialize(widget.navigatorKey);

    // Listen to session manager để show/hide floating widget
    _minimizedStateSubscription =
        RecordSessionManager.instance.minimizedStateStream.listen(
      (isMinimized) {
        debugPrint(
          '[FloatingWidget] ✅ Received stream event: $isMinimized',
        );
        if (_showFloatingWidget.value != isMinimized) {
          _showFloatingWidget.value = isMinimized;
          debugPrint(
            '[FloatingWidget] _showFloatingWidget: $_showFloatingWidget',
          );
        } else {
          debugPrint(
            '[FloatingWidget] ❌ Widget not mounted, cannot setState',
          );
        }
      },
      onError: (error) {
        debugPrint('[FloatingWidget] ❌ Stream error: $error');
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
      return;
    }

    // Restore modal với session hiện tại
    final sessionData = sessionManager.data;
    if (sessionData is T) {
      RecordModalService.instance
          .openModal<T>(
        locale: sessionManager.locale ?? 'en-US',
        data: sessionData,
        transcript: sessionManager.title,
        onExit: sessionManager.onExit,
        restoreFromSession: true,
        isSameData: widget.isSameData,
        validData: widget.validData,
      )
          .then(
        (result) {
          // Xử lý result từ service để upload recording
          if (result != null) {
            widget.onDone(
              sessionData,
              result.content ?? '',
              File(result.url),
              sessionManager.locale ?? 'en-US',
            );

            sessionManager.endSession(disposeResources: true);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _showFloatingWidget,
      builder: (context, isShow, child) {
        debugPrint(
          '[Build][SessionManager] Building '
          'FloatingDraggableWidget, isShow: $isShow',
        );
        return FloatingDraggableWidget(
          floatingWidget: isShow
              ? FloatingRecordWidget(
                  key: const ValueKey(
                    'floating_record_widget',
                  ),
                  onTap: _onTapFloatingWidget,
                )
              : const SizedBox.shrink(),
          floatingWidgetWidth: 80,
          floatingWidgetHeight: 80,
          dx: MediaQuery.of(context).size.width - 100,
          dy: MediaQuery.of(context).size.height * 0.7,
          mainScreenWidget: widget.child,
          autoAlign: true,
          speed: 10,
          // isDraggble: true,
        );
      },
    );
  }
}
