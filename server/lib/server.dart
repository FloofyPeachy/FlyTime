
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'net/api.dart';
import 'core/logging.dart';
var app = Router();

void run() async {
  var service = ApiService();
  var router = service.router;
  var handler = const Pipeline()
      .addMiddleware(logRequestsBetter())
      .addHandler(router.call);

  var server = await shelf_io.serve(handler, '0.0.0.0', 1337);

  // Enable content compression
  server.autoCompress = true;

  sLogger.i('Serving at http://${server.address.host}:${server.port}');
}
format(Duration d) => d.toString().split('.').first.padLeft(8, "0");


Middleware logRequestsBetter({void Function(String message, bool isError)? logger}) =>
        (innerHandler) {

      return (request) {
        var watch = Stopwatch()..start();

        return Future.sync(() => innerHandler(request)).then((response) {
          sLogger.i("http::${request.method} ${request.requestedUri} -> [${response.statusCode}] in " + format(watch.elapsed) );

          return response;
        }, onError: (Object error, StackTrace stackTrace) {
          if (error is HijackException) throw error;
          sLogger.e("http${request.method} ${request.requestedUri} -> $error $stackTrace");
          throw error;
        });
      };
    };