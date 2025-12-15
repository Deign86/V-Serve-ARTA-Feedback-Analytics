//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <firebase_core/firebase_core_plugin_c_api.h>
#include <local_notifier/local_notifier_plugin.h>
#include <permission_handler_windows/permission_handler_windows_plugin.h>
#include <printing/printing_plugin.h>
#include <windows_notification/windows_notification_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FirebaseCorePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FirebaseCorePluginCApi"));
  LocalNotifierPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("LocalNotifierPlugin"));
  PermissionHandlerWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PermissionHandlerWindowsPlugin"));
  PrintingPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PrintingPlugin"));
  WindowsNotificationPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WindowsNotificationPluginCApi"));
}
