import 'package:client/api.dart';
import 'package:client/core/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:gradient_elevated_button/gradient_elevated_button.dart';
import 'package:onboarding/onboarding.dart';
import 'package:url_launcher/url_launcher.dart';


class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key});

  @override
  _OnboardingDialog createState() => _OnboardingDialog();
}

class _OnboardingDialog extends State<OnboardingDialog> {
  List<Widget> pages = [
    Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Welcome to FlyTime"),
      ],
    ),
    Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Welcome to FlyTime"),
      ],
    )
  ];

  int index = 0;

  @override
  Widget build(BuildContext context) {

    return Material(
      color: Colors.transparent,
      child: Center(
        child: OnBoardingSlider(
          headerBackgroundColor: Colors.white,
          finishButtonText: 'Register',
          finishButtonStyle: FinishButtonStyle(
            backgroundColor: Colors.black,
          ),
          skipTextButton: Text('Skip'),
          trailing: Text('Login'),
          background: [
            SizedBox(),
            SizedBox(),
          ],
          totalPage: 2,
          speed: 1.8,
          pageBodies: [
            Container(
              padding: EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.radar, size: 128),
                  Text('Welcome to FlyTime!', style: Theme.of(context).textTheme.headlineLarge),
                  Text("This will notify you on the controllers you care about.", style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center,),
                  Text("Just a super short setup.")
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset("assets/vatsim_logo.png", height: dH(context) * 0.15,),
                  Text('Sync with VATSIM', style: Theme.of(context).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.bold)),
                  Text("Logging in is not required, but it will sync your controllers between your devices.", style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                  Divider(),
                  GradientElevatedButton(
                    style: GradientElevatedButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                      //2483C5
                      //29B473

                      backgroundGradient: const LinearGradient(
                        colors: [
                          Color(0xFF2483C5),
                          Color(0xFF29B473),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      var url = await FlyTimeAPI.vatsimLogin();
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Sign in with VATSIM", style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(height: dH(context) * 0.01,),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("I'm good", style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  Widget buildWelcomePage() {
    return  Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Welcome to FlyTime"),

      ],
    );
  }
}