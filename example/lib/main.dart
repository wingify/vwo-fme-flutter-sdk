/// Copyright 2024-2025 Wingify Software Pvt. Ltd.
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
/// http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.

import 'package:flutter/material.dart';

import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_init_options.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/get_flag.dart';
import 'package:vwo_fme_flutter_sdk/vwo.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_user_context.dart';
import 'package:vwo_fme_flutter_sdk_example/constants/constants.dart';
import 'package:vwo_fme_flutter_sdk_example/logger/dart_logger.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  VWO? _vwoClient;

  final userContext = VWOUserContext(
    id: userId,
    customVariables: {'number': 12, 'key2': 'value2'}
  );

  @override
  void initState() {
    super.initState();
  }

  /// Initializes VWO-FME sdk sending the desired parameters to native SDK.
  void _vwoInit() async {
    // Create a list of transports
    var transport = <String, dynamic>{};
    transport["defaultTransport"] = DartLogger();

    var logger = <Map<String, dynamic>>[];
    logger.add(transport);

    var initOptions = VWOInitOptions(
        sdkKey: sdkKey,
        accountId: accountId,
        logger: {"level": "TRACE", "transports": logger},
        /*gatewayService: {
              "url": "http://localhost:8000",
            },*/
        //pollInterval: 10000,
        //batchMinSize: 4,
        //batchUploadTimeInterval: 3 * 60 * 1000,
        //cachedSettingsExpiryTime: 10000,
        //isUsageStatsDisabled: true,
        integrations: (Map<String, dynamic> properties) {
          print('VWO: Integration callback received: $properties');
        });

    // This is intended for VWO's internal applications only.
    // Clients should not use this in their implementations.
    initOptions.vwo_meta["ea"] = 1;

    _vwoClient = await VWO.init(initOptions);

    var status = "VWO: Initialization successful.";
    if (_vwoClient == null) {
      status = "VWO: Initialization failed.";
    }
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = status;
    });
  }

  /// This method is used to get the flag value for the given feature key.
  void _getFlag() async {
      final GetFlag? featureFlag = await _vwoClient?.getFlag(
        featureKey: featureKey,
        context: userContext,
      );
      if (featureFlag != null && featureFlag.isEnabled()) {
        print('VWO: Feature flag retrieved successfully and is enabled');
      } else {
        print('VWO: Failed to retrieve or enable feature flag');
      }

      dynamic color = featureFlag?.getVariable(variableName, 'unknownColor');
      dynamic variables = featureFlag?.getVariables();

      print("VWO: Color = $color variable = $variables");
  }

  /// Track method to track the event.
  void _trackEvent() async {
      var properties = {
        "category": "electronics",
        "isWishlisted":false,
        "price": 21,
        "productId":1,
      };
      final trackingResult = await _vwoClient?.trackEvent(
          eventName: eventName,
          context: userContext,
          //eventProperties: properties
      );
      print("VWO: Tracking Result: $trackingResult");
  }

  /// Sets an attribute for a user in the userContext provided.
  void _setAttribute() async {

    var attributes = {
      'userType': 'free',
      'price': 99,
      "isEnterpriseCustomer": false
    };
    await _vwoClient?.setAttribute(
      attributes: attributes,
      context: userContext,
    );
  }

  @override
  Widget build(BuildContext context) {
    const double width = 200;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              Text(
                'Running on: $_platformVersion\n',
                style: TextStyle(fontSize: 20.0),
              ),
              SizedBox(
                  width: width, // Makes the button full width
                  child: ElevatedButton(
                    onPressed: () {
                      _vwoInit();
                    }, // Call initializeVwo on button press
                    child: const Text(
                      'Init FME',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  )),
              SizedBox(
                  width: width, // Makes the button full width
                  child: ElevatedButton(
                    onPressed: () {
                      _getFlag();
                    },
                    child: const Text(
                      'Get Flag',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  )),
              SizedBox(
                  width: width, // Makes the button full width
                  child: ElevatedButton(
                    onPressed: () {
                      _trackEvent();
                    },
                    child: const Text(
                      'Track event',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  )),
              SizedBox(
                  width: width, // Makes the button full width
                  child: ElevatedButton(
                    onPressed: () {
                      _setAttribute();
                    },
                    child: const Text(
                      'Set Attribute',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}