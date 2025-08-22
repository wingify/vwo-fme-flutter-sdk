// Test runner that imports all test files
// Run this with: flutter test test/all_tests.dart

import 'fme_config_test.dart' as fme_config_test;
import 'logger/log_transport_test.dart' as log_transport_test;
import 'models/get_flag_test.dart' as get_flag_test;
import 'models/variable_test.dart' as variable_test;
import 'models/vwo_init_options_test.dart' as vwo_init_options_test;
import 'models/vwo_user_context_test.dart' as vwo_user_context_test;
import 'utils/constants_test.dart' as constants_test;
import 'utils/sdk_info_test.dart' as sdk_info_test;
import 'utils/usage_stats_test.dart' as usage_stats_test;
import 'vwo_simple_test.dart' as vwo_simple_test;
import 'method_channel_test.dart' as method_channel_test;
import 'platform_interface_test.dart' as platform_interface_test;
import 'vwo_test.dart' as vwo_test;

void main() {
  // Run all test groups
  fme_config_test.main();
  log_transport_test.main();
  get_flag_test.main();
  variable_test.main();
  vwo_init_options_test.main();
  vwo_user_context_test.main();
  constants_test.main();
  sdk_info_test.main();
  usage_stats_test.main();
  vwo_simple_test.main();
  method_channel_test.main();
  platform_interface_test.main();
  vwo_test.main();
}
