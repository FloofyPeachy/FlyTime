
import 'package:cron/cron.dart';
import 'package:server/core/logging.dart';
import 'package:server/server.dart';
import 'package:server/data/subscriptions.dart';
import 'package:server/data/vatdata.dart';


Future<void> main(List<String> arguments) async {
  sLogger.i("FlyTime Notification Server v1.0");
  sLogger.i("FloofyPeachy 2025");

  await StaticData.init();

  final cron = Cron();
  await VatsimData.init();
  await Subscriptions.init();
  await VatsimData.update();
  cron.schedule(Schedule.parse('*/1 * * * *'), () async {
    await VatsimData.update();
  });



  run();

}
