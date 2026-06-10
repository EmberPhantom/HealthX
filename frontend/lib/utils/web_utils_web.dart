import 'dart:js' as js;

void removeSplashFromWeb() {
  try {
    js.context.callMethod('removeSplashFromWeb');
  } catch (e) {
    // Ignore errors
  }
}
