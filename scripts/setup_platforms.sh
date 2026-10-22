#!/usr/bin/env bash
# Generates the Android, iOS and web folders (if missing) and adds the
# microphone, speech and link permissions Ozouma needs. Safe to run again.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -d android ] || [ ! -d ios ] || [ ! -d web ]; then
  flutter create . --project-name ozouma --org com.ozouma --platforms=android,ios,web
fi

python3 - <<'PY'
import re, pathlib

manifest = pathlib.Path('android/app/src/main/AndroidManifest.xml')
if manifest.exists():
    text = manifest.read_text()
    perms = [
        'android.permission.RECORD_AUDIO',
        'android.permission.INTERNET',
        'android.permission.BLUETOOTH',
        'android.permission.BLUETOOTH_CONNECT',
    ]
    for p in perms:
        tag = f'<uses-permission android:name="{p}"/>'
        if p not in text:
            text = text.replace('<application', tag + '\n    <application', 1)
    if 'android.speech.RecognitionService' not in text:
        queries = '''    <queries>
        <intent>
            <action android:name="android.speech.RecognitionService" />
        </intent>
        <intent>
            <action android:name="android.intent.action.TTS_SERVICE" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
    </queries>
'''
        text = text.replace('</manifest>', queries + '</manifest>', 1)
    manifest.write_text(text)

plist = pathlib.Path('ios/Runner/Info.plist')
if plist.exists():
    text = plist.read_text()
    extra = {
        'NSMicrophoneUsageDescription': 'Ozouma listens for short cooking commands like next and back while cooking mode is open.',
        'NSSpeechRecognitionUsageDescription': 'Ozouma turns your voice commands into actions so you can cook without touching the phone.',
    }
    for key, value in extra.items():
        if key not in text:
            idx = text.rfind('</dict>')
            text = text[:idx] + f'\t<key>{key}</key>\n\t<string>{value}</string>\n' + text[idx:]
    plist.write_text(text)

gradle = None
for name in ('android/app/build.gradle.kts', 'android/app/build.gradle'):
    p = pathlib.Path(name)
    if p.exists():
        gradle = p
        break
if gradle:
    text = gradle.read_text()
    text = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 23', text)
    text = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 23', text)
    gradle.write_text(text)
print('Platform setup done')
PY
