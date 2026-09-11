library file_opener;

// Platform-adaptive file opener.
//
// On web: triggers a browser download via an anchor element.
// On native (Android/iOS/desktop): writes to a temp file and opens it
// with the OS default app.
export 'file_opener_io.dart'
    if (dart.library.html) 'file_opener_web.dart';
