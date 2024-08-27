
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {

  static GoRoute route = GoRoute(
    path: "/home",
    pageBuilder: (context, state) => NoTransitionPage(
      child: HomePage(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      child: Text("Home Page"),
    );
  }

}