import importlib.util
import json
import os
import sys
import urllib.request

state = json.loads(os.environ.get('BOOP_STATE', '{}'))
module_ext = os.environ.get('BOOP_MODULE_EXT', '.py')
script_dir = os.environ.get('BOOP_SCRIPT_DIR', '')
lib_dir = os.environ.get('BOOP_LIB_DIR', '')

_loaded_modules = {}

def boop_require(path):
    if not path.endswith(module_ext):
        path += module_ext
    if path.startswith('@boop/'):
        mod_path = os.path.join(lib_dir, path[6:])
    else:
        mod_path = os.path.join(script_dir, path)
    if not os.path.isfile(mod_path):
        return None
    if mod_path in _loaded_modules:
        return _loaded_modules[mod_path]
    spec = importlib.util.spec_from_file_location('boop_mod_' + str(len(_loaded_modules)), mod_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    _loaded_modules[mod_path] = module
    return module

class State:
    def __init__(self, data):
        self.text = data.get('text')
        self.fullText = data.get('fullText')
        self.selection = data.get('selection')
        self.network = data.get('network', False)
        self.inserts = []
        self.messages = []
    def post_info(self, msg):
        self.messages.append({'type': 'info', 'message': msg})
    def post_error(self, msg):
        self.messages.append({'type': 'error', 'message': msg})
    def insert(self, value):
        self.inserts.append(value)
    def fetch(self, url, method=None, body=None):
        if not self.network:
            self.post_error('Network permission required')
            return None
        req = urllib.request.Request(url, data=body.encode('utf-8') if body else None, method=method or 'GET')
        try:
            with urllib.request.urlopen(req) as f:
                return f.read().decode('utf-8')
        except Exception:
            self.post_error('Failed to fetch')
            return None

state_obj = State(state)

globals()['boop_require'] = boop_require

script_path = sys.argv[1]

spec = importlib.util.spec_from_file_location('user_script', script_path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
if hasattr(module, 'main'):
    module.main(state_obj)

output = {
    'text': state_obj.text,
    'fullText': state_obj.fullText,
    'selection': state_obj.selection,
    'inserts': state_obj.inserts,
    'messages': state_obj.messages,
}
print(json.dumps(output))
