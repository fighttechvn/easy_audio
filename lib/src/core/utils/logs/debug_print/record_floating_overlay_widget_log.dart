import '../print_log.dart';

void debugPrintInitStateSettingUpListener() {
  PrintLog.debug('[RecordFloatingOverlay] initState - setting up listener');
}

void debugPrintReceivedStreamEvent(bool isMinimized) {
  PrintLog.debug('[FloatingWidget] ✅ Received stream event: $isMinimized');
}

void debugPrintUpdateShowFloatingWidget(bool isShow) {
  PrintLog.debug('[FloatingWidget] _showFloatingWidget: $isShow');
}

void debugPrintShowFloatingWidgetNotChanged() {
  PrintLog.debug('[FloatingWidget] ❌ Value unchanged, skipping update');
}

void debugPrintStreamError(Object error) {
  PrintLog.debug('[FloatingWidget] ❌ Stream error: $error');
}

void debugPrintBuildingFloatingDraggableWidget(bool isShow) {
  PrintLog.debug(
    '[Build][SessionManager] Building FloatingDraggableWidget, isShow: $isShow',
  );
}
