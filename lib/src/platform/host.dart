import 'host_stub.dart' if (dart.library.io) 'host_io.dart' as impl;

/// Reads a process environment variable. Always `null` on web.
String? hostEnv(String key) => impl.hostEnv(key);

/// Closes the desktop window. A no-op in the browser.
void exitApp() => impl.exitApp();
