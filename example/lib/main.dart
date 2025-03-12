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
import 'package:vwo_fme_flutter_sdk/vwo/models/vwo_context.dart';
import 'package:vwo_fme_flutter_sdk/vwo/models/get_flag.dart';
import 'package:vwo_fme_flutter_sdk/vwo.dart';
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
  VWO? _vwo;

  final vwoContext = VWOContext(
    userId: userId,
    customVariables: {'number': 12, 'key2': 'value2'},
    ipAddress: "1.0.0.1",
    userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (HTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
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
        integrationCallback: (Map<String, dynamic> properties) {
          print('VWO: Integration callback received: $properties');
        });

    _vwo = await VWO.init(initOptions);

    var status = "VWO: Initialization successful.";
    if (_vwo == null) {
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
      final GetFlag? result = await _vwo?.getFlag(
        flagName: flagName,
        vwoContext: vwoContext,
      );
      if (result != null && result.isEnabled()) {
        print('VWO: Feature flag retrieved successfully and is enabled');
      } else {
        print('VWO: Failed to retrieve or enable feature flag');
      }

      dynamic color = result?.getVariable(variableName, 'unknownColor');
      dynamic variables = result?.getVariables();

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
      final trackingResult = await _vwo?.trackEvent(
          eventName: eventName,
          vwoContext: vwoContext,
          //eventProperties: properties
      );
      print("VWO: Tracking Result: $trackingResult");
  }

  /// Sets an attribute for a user in the vwoContext provided.
  void _setAttribute() async {

    var attributes = {
      'userType': 'free',
      'price': 99,
      "isEnterpriseCustomer": false
    };
    final success = await _vwo?.setAttribute(
      attributes: attributes,
      vwoContext: vwoContext,
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