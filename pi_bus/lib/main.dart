import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pi_bus/pages/connection_page.dart';
import 'package:pi_bus/pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: routerConfig,
    );
  }
}

GoRouter routerConfig = GoRouter(

  redirect: (context, state) async {

    // Ping the server "10.0.0.1"
    Ping ping = Ping("10.0.0.1");
    final result = await ping.stream.first;

    if (result.summary == null) {
      return "/establish";
    }

    return "/home";
  },

  routes: [

    HomePage.route,

    ConnectionPage.route

  ]

);