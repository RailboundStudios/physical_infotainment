
import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pi_bus/constants.dart';

class ConnectionPage extends StatelessWidget {

  static GoRoute route = GoRoute(
    path: "/establish",
    pageBuilder: (context, state) => NoTransitionPage(
      child: ConnectionPage(),
    ),
  );

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: [
            Text("Connection Page"),

            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Server Address"
              ),
            ),

            ElevatedButton(
              onPressed: () async {

                // Ping the server "10.0.0.1"
                Ping ping = Ping(_controller.text);
                final result = await ping.stream.first;

                if (result.summary == null) {
                  print("Server not found");
                  return;
                }

                print("Server found");

                Constants().serverAddress = _controller.text;

              },
              child: Text("Connect")
            )
          ],
        ),
      ),
    );
  }

}