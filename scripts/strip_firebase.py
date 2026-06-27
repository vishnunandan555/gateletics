import os
import re

def strip_windows():
    print("Stripping Firebase from Windows configuration...")
    
    # 1. Strip generated_plugins.cmake
    cmake_path = "windows/flutter/generated_plugins.cmake"
    if os.path.exists(cmake_path):
        with open(cmake_path, "r", encoding="utf-8") as f:
            content = f.read()
        
        # Remove Firebase plugins from FLUTTER_PLUGIN_LIST
        lines_to_remove = ["cloud_firestore", "firebase_auth", "firebase_core"]
        new_content = content
        for line in lines_to_remove:
            new_content = re.sub(rf"\s*{line}\s*\n", "\n", new_content)
        
        with open(cmake_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"Successfully stripped {cmake_path}")
    else:
        print(f"Warning: {cmake_path} not found.")

    # 2. Strip generated_plugin_registrant.cc
    cc_path = "windows/flutter/generated_plugin_registrant.cc"
    if os.path.exists(cc_path):
        with open(cc_path, "r", encoding="utf-8") as f:
            content = f.read()
        
        # Remove includes
        includes_to_remove = [
            '#include <cloud_firestore/cloud_firestore_plugin_c_api.h>',
            '#include <firebase_auth/firebase_auth_plugin_c_api.h>',
            '#include <firebase_core/firebase_core_plugin_c_api.h>'
        ]
        new_content = content
        for inc in includes_to_remove:
            new_content = new_content.replace(inc, "")
            
        # Remove function calls (matching potential newlines and spaces)
        pattern = r'CloudFirestorePluginCApiRegisterWithRegistrar\(\s*registry->GetRegistrarForPlugin\("CloudFirestorePluginCApi"\)\);'
        new_content = re.sub(pattern, "", new_content)
        
        pattern = r'FirebaseAuthPluginCApiRegisterWithRegistrar\(\s*registry->GetRegistrarForPlugin\("FirebaseAuthPluginCApi"\)\);'
        new_content = re.sub(pattern, "", new_content)
        
        pattern = r'FirebaseCorePluginCApiRegisterWithRegistrar\(\s*registry->GetRegistrarForPlugin\("FirebaseCorePluginCApi"\)\);'
        new_content = re.sub(pattern, "", new_content)
        
        with open(cc_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"Successfully stripped {cc_path}")
    else:
        print(f"Warning: {cc_path} not found.")

if __name__ == "__main__":
    strip_windows()
