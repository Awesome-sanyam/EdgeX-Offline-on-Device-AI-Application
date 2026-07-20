import re
import os

with open('lib/core/state/app_providers.dart', 'r') as f:
    content = f.read()

imports = """import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, File;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:system_info_plus/system_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:background_downloader/background_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:fllama/fllama.dart';
import '../../core/db/local_db.dart';
"""

# Extract sections
headers = re.findall(r'// --- (.*?) ---', content)
sections = re.split(r'// --- .*? ---', content)

# sections[0] is imports
# headers and sections[1:] correspond

mapping = {
    'THE LOCAL DATABASE INSTANCE': 'lib/core/db/local_db.dart',
    'DEEP NATIVE HARDWARE PROFILING': 'lib/core/hardware/hardware_provider.dart',
    'PERSISTENT SETTINGS & PRIVACY': 'lib/core/settings/settings_provider.dart',
    'TASKS': 'lib/core/state/tasks_provider.dart',
    'NATIVE BACKGROUND MODELS DOWNLOADER': 'lib/features/models/state/models_provider.dart',
    'CHAT SESSIONS MANAGEMENT': 'lib/features/chat/state/chat_sessions_provider.dart',
    'PERSISTENT CHAT STATE & LIVE GENERATIVE ENGINE': 'lib/features/chat/state/chat_provider.dart',
    'UI STATE PROVIDERS': 'lib/features/chat/state/ui_state_provider.dart',
    'DYNAMIC TELEMETRY ENGINE': 'lib/core/hardware/telemetry_provider.dart',
    'NATIVE VOICE ENGINE': 'lib/features/chat/state/voice_provider.dart'
}

files_content = {}
for h, s in zip(headers, sections[1:]):
    if h in mapping:
        path = mapping[h]
        if path not in files_content:
            if path == 'lib/core/db/local_db.dart':
                files_content[path] = "import 'package:shared_preferences/shared_preferences.dart';\n"
            else:
                files_content[path] = imports + "\n"
        files_content[path] += f"// --- {h} ---\n{s}\n"

# Special inter-dependencies fix for telemetry_provider
# It needs models_provider, hardware_provider, settings_provider, chat_provider
files_content['lib/core/hardware/telemetry_provider.dart'] += """
import '../../features/models/state/models_provider.dart';
import '../../core/settings/settings_provider.dart';
import '../../core/hardware/hardware_provider.dart';
import '../../features/chat/state/chat_provider.dart';
"""

# Write files
for path, data in files_content.items():
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(data)

# Create app_providers.dart exporter
with open('lib/core/state/app_providers.dart', 'w') as f:
    for path in set(mapping.values()):
        rel_path = os.path.relpath(path, 'lib/core/state')
        f.write(f"export '{rel_path}';\n")

print("Splitting complete.")
