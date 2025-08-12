import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

Logger sLogger = Logger(
  filter: ProductionFilter(

  )
  ,
  printer: ThePrinter(),
  output: ConsoleOutput(),
  /*output: FileOutput(
    file:  File("flytime.log")
  )*/
);

class ThePrinter extends LogPrinter {
  static final levelPrefixes = {
    Level.trace: 'trace',
    Level.debug: 'debug',
    Level.info: 'info',
    Level.warning: 'warning',
    Level.error: 'ERROR',
    Level.fatal: 'FATAL',
  };

  static final levelColors = {
    Level.trace: AnsiColor.fg(AnsiColor.grey(0.5)),
    Level.debug: const AnsiColor.none(),
    Level.info: const AnsiColor.fg(12),
    Level.warning: const AnsiColor.fg(208),
    Level.error: const AnsiColor.fg(196),
    Level.fatal: const AnsiColor.fg(199),
  };

  ThePrinter();

  @override
  List<String> log(LogEvent event) {
    var messageStr = _stringifyMessage(event.message);
    var errorStr = event.error != null ? '  ERROR: ${event.error}' : '';
    var timeStr =DateFormat.jms().format(event.time);
    String? areaString;
    if (event.message.contains("::")) {
      areaString = event.message.toString().split("::")[0];
      messageStr = messageStr.split("::")[1];
      return ['[${_labelFor(event.level) } / ${const AnsiColor.fg(45)(areaString)} / $timeStr] $messageStr$errorStr'];
    }
    return ['[${_labelFor(event.level) } / $timeStr] $messageStr$errorStr'];
  }

  String _labelFor(Level level) {
    var prefix = levelPrefixes[level]!;
    var color = levelColors[level]!;

    return color(prefix);
  }

  String _stringifyMessage(dynamic message) {
    final finalMessage = message is Function ? message() : message;
    if (finalMessage is Map || finalMessage is Iterable) {
      var encoder = const JsonEncoder.withIndent(null);
      return encoder.convert(finalMessage);
    } else {
      return finalMessage.toString();
    }
  }

  bool shouldLog(LogEvent event) {
    return true;
  }
}
