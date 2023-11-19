import 'dart:io';

import 'package:cpx_research_sdk_flutter/cpx_controller.dart';
import 'package:cpx_research_sdk_flutter/utils/cpx_logger.dart';
import 'package:cpx_research_sdk_flutter/utils/network_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum BrowserTab { home, settings, help }

class BrowserView extends StatefulWidget {
  final BrowserTab currentTab;

  BrowserView(this.currentTab);

  @override
  _BrowserViewState createState() => _BrowserViewState();
}


class _BrowserViewState extends State<BrowserView> {
  Controller controller = Controller.controller;
  late final WebViewController webViewController;
  bool isLoading = true;
  late List pages;
  late BrowserTab activeTab;
  bool isAlertDisplayed = false;

  /// [loadURL] loads the url in the webview
  void loadURL(int index) {
    webViewController.loadRequest(Uri.parse(pages[index]));
    CPXLogger.log("Load url: " + pages[index]);
  }

  @override
  void initState() {
    super.initState();
    activeTab = widget.currentTab;
    pages = [
      NetworkService().getHomeURL().toString(),
      NetworkService().getSettingsURL().toString(),
      NetworkService().getHelpURL().toString(),
    ];

    webViewController = WebViewController(

    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (String _) {
          setState(() => isLoading = false);
        },
        onPageStarted: (String _) {
          setState(() => isLoading = true);
        },
        onWebResourceError: (error) {
          HapticFeedback.selectionClick();
          setState(() => isAlertDisplayed = true);
          CPXLogger.log("Browser error: " +
              error.errorCode.toString() +
              " | " +
              error.description);
          NetworkService().onWebViewError(
              error.errorCode.toString(),
              error.description,
              error.failingUrl ?? "no url");
        },
      ));
    loadURL(activeTab == BrowserTab.settings ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black38,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: new BoxDecoration(
                    color: activeTab == BrowserTab.help
                        ? controller.config.accentColor
                        : Colors.white,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(10.0)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.help_outline),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      loadURL(2);
                      activeTab = BrowserTab.help;
                    },
                    color: Colors.black,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: new BoxDecoration(
                    color: activeTab == BrowserTab.settings
                        ? controller.config.accentColor
                        : Colors.white,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(10.0)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.settings_outlined),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      loadURL(1);
                      activeTab = BrowserTab.settings;
                    },
                    color: Colors.black,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: new BoxDecoration(
                    color: activeTab == BrowserTab.home
                        ? controller.config.accentColor
                        : Colors.white,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(10.0)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.home_outlined),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      loadURL(0);
                      activeTab = BrowserTab.home;
                    },
                    color: Colors.black,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: new BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(10.0)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      CPXLogger.log("Close CPX Browser");
                      Controller.controller.showWidgets();
                    },
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: webViewController),
                  if (isLoading)
                    LinearProgressIndicator(
                      valueColor: new AlwaysStoppedAnimation<Color>(
                          controller.config.accentColor),
                      backgroundColor: Colors.white,
                    ),
                  if (isAlertDisplayed) ErrorAlertDialog(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container ErrorAlertDialog() {
    Widget textButton = TextButton(
      child: Text(
        "OK",
        style: TextStyle(color: controller.config.accentColor),
      ),
      onPressed: () {
        HapticFeedback.selectionClick();
        setState(() => isAlertDisplayed = false);
        CPXLogger.log("Close CPX Browser");
        Controller.controller.showWidgets();
      },
    );
    return Container(
      color: Colors.black87,
      child: Platform.isIOS
          ? CupertinoAlertDialog(
        title: Text("Browser Error"),
        content:
        Text("An error occurred, while using the survey browser"),
        actions: [textButton],
      )
          : AlertDialog(
        title: Text("Browser Error"),
        content:
        Text("An error occurred, while using the survey browser"),
        actions: [textButton],
      ),
    );
  }
}
