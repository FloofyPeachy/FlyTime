import 'dart:async';
import 'dart:convert';

import 'package:server/net/events.dart';
import 'package:server/core/model.dart';
import 'package:server/data/subscriptions.dart';
import 'package:server/core/util.dart';
import 'package:server/data/vatdata.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../core/const.dart';
import '../core/database.dart';
import '../core/logging.dart';
import '../data/search.dart';
part 'api.g.dart';

class ApiService {

  Map<String, StreamController<List<int>>> activeAuthStates = {};

  @Route.post('/subscribe')
  Future<Response> subscribe(Request request) async {
    try {
      Map<String, dynamic> data = jsonDecode(await request.readAsString());
      if (request.headers['Authorization'] != null) {
        String jwt = request.headers['Authorization']!;
        Map<String, User> users = Map<String, User>.from(UserDatabase.users.data)..removeWhere((x, y) => y.jwt != jwt);
        User? user = UserDatabase.users.data.values.firstWhere((x) => x.jwt == jwt);
        data['vatsimId'] = user.id;
      }


      Subscriptions.updateSubscription(SubscriptionFreq.fromJson(data));

      sLogger.d(
        data['firebaseId'] +
            " just subscribed to " +
            data['regions'].toString(),
      );

      return Response.ok('Added successfully!');
    } on Exception catch (e) {
      sLogger.e(e);
      return Response.badRequest(
        body: jsonEncode({"error": "Couldn't add subscription"}),
      );
    }
  }

  @Route.get("/get_subs")
  Future<Response> getSubs(Request request) async {
    //Get token from header.
    String? token = request.headers['Authorization'];
    if (token == null) {
      return Response.forbidden("Need a token");
    }
    Map<String, User> data = Map<String, User>.from(UserDatabase.users.data)..removeWhere((x, y) => y.jwt != token);
    User? user = data.values.first;

    SubscriptionFreq? subscription = Subscriptions.subscriptions.firstWhere((x) => x.vatsimId == user.id, orElse: () => SubscriptionFreq([], "", user.id));
    return Response.ok(jsonEncode(subscription), headers: {"Content-Type": "application/json"});

  }

  @Route.post('/vatsim_login')
  Future<Response> vatsimLogin(Request request) async {
    String state = getRandomString(16);
    String internalState = getRandomString(16);
    Map<String, dynamic> query = {
      "response_type" : "code",
      "client_id" : "1137",
      "scope" : ["email"],
      "state" : state,
      "prompt" : "consent"
    };
    activeAuthStates[state] = StreamController<List<int>>();
    activeAuthStates[state]!.add(utf8.encode(jsonEncode({
      "url" : Uri.https("auth-dev.vatsim.net", "/oauth/authorize", query).toString()
    })));
    return Response.ok(activeAuthStates[state]!.stream, context: {"shelf.io.buffer_output": false});


  }

  @Route.get('/vatsim_callback')
  Future<Response> vatsimCallback(Request request) async {
    String? state = request.url.queryParameters['state'];
    String? code = request.url.queryParameters['code'];
    //We got that code? Bet. Let's ask for a token.
    if (state == null || code == null) {
      return Response.badRequest(
        body: jsonEncode({"error": "Wtf? You need to specify a state/code"}),
      );
    }

    if (!activeAuthStates.containsKey(state)) {
      return Response.badRequest(
        body: jsonEncode({"error": "That state doesn't exist"}),
      );
    }


    //Get the token..
    const redirectUri = "http://10.0.0.127:1337/vatsim_callback";
    final encodedRedirectUri = Uri.encodeComponent(redirectUri);
    Map<String, dynamic> query = {
      "grant_type" : "authorization_code",
      "client_id" : "1137",
      "client_secret" : "bk1QvtDtfD8rVKe4JiwkYXZ4XX8EPdXNagmAMaFV",
     // "redirect_uri" : encodedRedirectUri,
      "code" : code,
      //"scope" : ["email"],
    };
    var tokenRs = await client.post(Uri.https("auth-dev.vatsim.net", "/oauth/token", query), headers:
    {

    },
      body: query

    );

    if (tokenRs.statusCode != 200) {
      sLogger.e(tokenRs.body);
      return Response.badRequest(
        body: jsonEncode({"error": "Couldn't get token"}),
      );
    }

    //Finally, get the user info.
    var userInfoRs = await client.get(Uri.https("auth-dev.vatsim.net", "/api/user"), headers: {"Authorization": "Bearer ${jsonDecode(tokenRs.body)['access_token']}"});
    if (userInfoRs.statusCode != 200) {
      sLogger.e(userInfoRs.body);
      return Response.badRequest(
        body: jsonEncode({"error": "Couldn't get user info"}),
      );
    }

    Map<String, dynamic> userInfo = jsonDecode(userInfoRs.body);
    if (userInfo['data']['personal']['email'] == null) {
      return Response.badRequest(
        body: jsonEncode({"error": "Couldn't get email"}),
      );
    }

    if (UserDatabase.users.get(userInfo['data']['cid']) != null) {
      User user = UserDatabase.users.get(userInfo['data']['cid'])!;
      activeAuthStates[state]!.sink.add(utf8.encode(jsonEncode(user)));
      return Response.ok(jsonEncode({
        "status" : 200,
      }));
    }
    String token = getRandomString(16);
    User user = User(
      id: userInfo['data']['cid'],
      jwt: token,
      createdAt: DateTime.now(),
      email: userInfo['data']['personal']['email'],
      fcmTokens: [],
    );

    UserDatabase.users.add(userInfo['data']['cid'], user);
    UserDatabase.users.save();
    activeAuthStates[state]!.sink.add(utf8.encode(jsonEncode(user)));

    Subscriptions.updateSubscription(SubscriptionFreq(
    [], "", userInfo['data']['cid']
    ));
    return Response.ok(jsonEncode({
      "status" : 200,
    }));


  }

  @Route.get("/get_sub/<vatsimId>")
  Future<Response> getSub(Request request, String vatsimId) async {
    SubscriptionFreq subscription =
        Subscriptions.subscriptions.firstWhere((x) => x.vatsimId == vatsimId);

    return Response.ok(jsonEncode(subscription));
  }

  @Route.get('/online/<regionsString>')
  Future<Response> online(Request request, String? regionsString) async {
    if (regionsString == null) {
      return Response.badRequest(
        body: jsonEncode({"error": "You need to specify regions"}),
      );
    }

    if (regionsString == "all") {
      return Response.ok(jsonEncode(VatsimData.allOnlineControllers));
    }

    List<String> regions = regionsString.split(",");
    List<OnlineController> controllers = [];
    List<Event> events = [];
    for (String region in regions) {
      controllers.addAll(
        VatsimData.allOnlineControllers
            .where((x) => x.callsign.startsWith(region) && controllers.where((x1) => x1.callsign == x.callsign).isEmpty)
            .toList(),
      );

      events.addAll(
        VatsimData.allEvents
            .where((x) => x.airports.contains(region))
            .toList(),
      );
    }

    //Get events.

    return Response.ok(jsonEncode(controllers));
  }

  @Route.get('/get_active_event/<query>')
  Future<Response> getActiveEvent(Request request, String? query) async {

    if (query == null) {
      return Response.badRequest(
        body: jsonEncode({"error": "You need to specify an event to search for"}),
      );
    }


    Event event = VatsimData.allEvents.where((x) => x.id == int.parse(query)).first;
    return Response.ok(jsonEncode(event));

  }


  @Route.get('/search_airport/<query>')
  Future<Response> searchAirport(Request request, String? query) async {
    if (query == null) {
      return Response.badRequest(
        body: jsonEncode({"error": "You need to specify an airport to search for"}),
      );
    }


    List<ControlledAirport> airports = DataSearch.searchAirports(query.toLowerCase());
    return Response.ok(jsonEncode(airports.map((e) => e.toJson()).toList()));
  }

  @Route.get('/search_airspace/<query>')
  Future<Response> searchAirspace(Request request, String? query) async {
    if (query == null) {
      return Response.badRequest(
        body: jsonEncode({"error": "You need to specify an airspace to search for"}),
      );
    }

    List<ControlledAirspace> airspaces = DataSearch.searchAirspaces(query.toLowerCase());
    return Response.ok(jsonEncode(airspaces.map((e) => e.toJson()).toList()));
  }

  Router get router => _$ApiServiceRouter(this);



}