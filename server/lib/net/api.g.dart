// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api.dart';

// **************************************************************************
// ShelfRouterGenerator
// **************************************************************************

Router _$ApiServiceRouter(ApiService service) {
  final router = Router();
  router.add('POST', r'/subscribe', service.subscribe);
  router.add('GET', r'/get_subs', service.getSubs);
  router.add('POST', r'/vatsim_login', service.vatsimLogin);
  router.add('GET', r'/vatsim_callback', service.vatsimCallback);
  router.add('GET', r'/get_sub/<vatsimId>', service.getSub);
  router.add('GET', r'/online/<regionsString>', service.online);
  router.add('GET', r'/get_active_event/<query>', service.getActiveEvent);
  router.add('GET', r'/search_airport/<query>', service.searchAirport);
  router.add('GET', r'/search_airspace/<query>', service.searchAirspace);
  return router;
}
