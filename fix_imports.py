import os
import glob

def fix_imports(filepath, depth):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # if depth is 3 (e.g. lib/features/chat/state), we need to go up 3 levels to reach lib: ../../../
    # previously it was in lib/core/state, depth 2, so it used ../../
    
    if depth == 3:
        content = content.replace("'../../core/", "'../../../core/")
        content = content.replace("'../../features/", "'../../../features/")
    
    with open(filepath, 'w') as f:
        f.write(content)

for root, dirs, files in os.walk('lib/features'):
    for file in files:
        if file.endswith('.dart'):
            depth = len(root.split('/')) - 1 # lib is 1, features is 2, chat is 3, state is 4? Wait.
            # actually path is lib/features/chat/state/file.dart
            # split('/') -> ['lib', 'features', 'chat', 'state'] -> len=4
            # We need 3 `../` to get from `state` to `lib`.
            
            path = os.path.join(root, file)
            # Just blindly replace since we know the context
            with open(path, 'r') as f:
                content = f.read()
            content = content.replace("'../../core/", "'../../../core/")
            content = content.replace("'../../features/", "'../../../features/")
            content = content.replace("'../../features/chat/state/ui_state_provider.dart'", "'ui_state_provider.dart'")
            
            with open(path, 'w') as f:
                f.write(content)

# And fix chat_sessions_provider missing ConflictAlgorithm
with open('lib/features/chat/state/chat_sessions_provider.dart', 'r') as f:
    content = f.read()
if "import 'package:sqflite/sqflite.dart';" not in content:
    content = "import 'package:sqflite/sqflite.dart';\n" + content
with open('lib/features/chat/state/chat_sessions_provider.dart', 'w') as f:
    f.write(content)
