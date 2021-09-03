import 'dart:convert';

import 'package:cpx_research_sdk_flutter/cpx_controller.dart';
import 'package:cpx_research_sdk_flutter/cpx_logger.dart';
import 'package:cpx_research_sdk_flutter/cpx_research.dart';
import 'package:cpx_research_sdk_flutter/model/cpx_response.dart';
import 'package:http/http.dart' as http;

final String BASE_URL = "offers.cpx-research.com";
final String API_URL = "jsscriptv1-live.cpx-research.com";
final String IMAGE_URL = "dyn-image.cpx-research.com";

class NetworkService {
  String homeEndpoint = "/index.php"; // HTML Page
  String surveyEndpoint = "/api/get-surveys.php"; // Survey API
  String imageEndpoint = "/image"; // Image API

  Controller controller = Controller.controller;
  CPXData cpxData = CPXData.cpxData;

  /// [getRequestParameter] provides the default parameter for every request: appID, userID, sdk, sdkVersion
  Map<String, dynamic> getRequestParameter() {
    // TODO: Update package version here as well
    String version =
        "0.0.1"; //  The package_info_plus package just shows the app version not the package version and adding the pubspec.yaml to the assets is a security issue for flutter web.
    return controller.config != null ? {'app_id': controller.config.appID, 'ext_user_id': controller.config.userID, 'sdk': 'flutter', 'sdkVersion': version} : {};
  }

  /// [getCPXImage] provides the image url for the widgets
  Uri getCPXImage({String type, String position, CPXStyle style}) {
    String backgroundColor = "." + style.backgroundColor.value.toRadixString(16).substring(2);
    String textColor = "." + style.textColor.value.toRadixString(16).substring(2);
    Map<String, dynamic> params = getRequestParameter();
    params['type'] = type;
    params['width'] = style.width.toString();
    params['height'] = style.height.toString();
    params['emptycolor'] = "transparent";
    params['backgroundcolor'] = backgroundColor;
    params['corner'] = style.roundedCorners.toString();
    params['position'] = position;
    params['text'] = style.text;
    params['textcolor'] = textColor;
    params['textsize'] = (type == "corner" ? style.textSize : style.textSize / 10).toString();
    return Uri.https(IMAGE_URL, imageEndpoint, params);
  }

  /// [getHomeURL] provides the home url for the webview
  Uri getHomeURL() {
    Map<String, dynamic> params = getRequestParameter();
    if (controller.isSingleSurveyDisplayed) {
      if (controller.singleSurveyID != null) {
        params['survey_id'] = controller.singleSurveyID;
      }
      else {
        params['survey_id'] = cpxData.surveys.value[0].id;
      }
    }
    return Uri.https(BASE_URL, homeEndpoint, params);
  }

  /// [getSettingsURL] provides the settings url for the webview
  Uri getSettingsURL() {
    Map<String, dynamic> params = getRequestParameter();
    params['site'] = "settings-webview";
    return Uri.https(BASE_URL, homeEndpoint, params);
  }

  /// [getHelpURL] provides the help url for the webview
  Uri getHelpURL() {
    Map<String, dynamic> params = getRequestParameter();
    params['site'] = "help";
    return Uri.https(BASE_URL, homeEndpoint, params);
  }

  /// [setTransactionPaid] marks the transaction with the provided [transactionID] as paid
  void setTransactionPaid(String transactionID, String messageID) async {
    Map<String, dynamic> params = getRequestParameter();
    params['transaction_set_paid'] = "true";
    params['transactionId'] = transactionID;
    params['messageId'] = messageID;
    Uri url = Uri.https(API_URL, surveyEndpoint, params);
    CPXLogger.log("Mark transaction $transactionID as paid with url: " + url.toString());
    await http.post(url).then((response) {
      if (response != null) {
        if (response.statusCode == 200) {
          CPXLogger.log("Transaction $transactionID marked as paid");
          fetchSurveysAndTransactions();
        } else {
          CPXLogger.log("API error " + response.statusCode.toString());
        }
      }
    });
  }

  /// [fetchSurveysAndTransactions] requests surveys and transactions from the api
  void fetchSurveysAndTransactions() async {
    Uri url = Uri.https(API_URL, surveyEndpoint, getRequestParameter());
    CPXLogger.log("Fetch surveys from api with url: " + url.toString());
    await http.post(url).then((response) {
      if (response != null) {
        if (response.statusCode == 200) {
          CPXLogger.log("Surveys and transactions fetched successfully from api");
          Map results = json.decode(response.body);
          CPXResponse cpxResponse = CPXResponse.fromJson(results);
          if (cpxResponse.surveys != null && cpxResponse.surveys.isNotEmpty) {
            if (cpxData.surveys.value.toString() != cpxResponse.surveys.toString()) {
              cpxData.setSurveys(cpxResponse.surveys);
              CPXLogger.log(cpxResponse.surveys.length.toString() + " new surveys are available");
            } else {
              CPXLogger.log("0 new surveys are available, ${cpxData.surveys.value.length.toString()} old surveys are available");
            }
            if (cpxResponse.transactions != null && cpxResponse.transactions.isNotEmpty) {
              if (cpxData.transactions.value.toString() != cpxResponse.transactions.toString()) {
                cpxData.setTransactions(cpxResponse.transactions);
                CPXLogger.log(cpxResponse.transactions.length.toString() + " new transactions are available");
              } else {
                CPXLogger.log("0 new transactions are available, ${cpxData.transactions.value.length.toString()} old transactions are available");
              }
            }
            controller.showCPXLayer();
          } else {
            CPXLogger.log("No surveys available");
            controller.hideCPXLayer();
          }
        } else {
          CPXLogger.log("API error " + response.statusCode.toString());
        }
      } else {
        CPXLogger.log("Survey API call failed");
      }
    },);
  }
}