import "package:flutter/material.dart";

import "core/router.dart";
import "core/theme.dart";

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "TFI Bagundaali",
      theme: appTheme(),
      routerConfig: router,
    );
  }
}
