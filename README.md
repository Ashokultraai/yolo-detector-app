# Flutter App → APK

A Flutter app that sends a photo or sampled video frames to the backend and draws
the merged (3-model ensemble) detections.

> These are the `lib/` source files + `pubspec.yaml`. You generate the Android
> scaffolding once with `flutter create .`, which fills in `android/` around them.

## One-time setup (free)

1. Install **Flutter** (includes Dart) + **Android SDK** (via Android Studio or
   the command-line tools). Verify:
   ```bash
   flutter doctor
   ```
2. Generate platform folders **inside this `app/` directory** (keeps our lib/ + pubspec):
   ```bash
   cd app
   flutter create .
   flutter pub get
   ```

## Android permissions

After `flutter create .`, edit `android/app/src/main/AndroidManifest.xml`:

- Add above `<application>`:
  ```xml
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.CAMERA"/>
  ```
- For plain-HTTP local dev (e.g. `http://192.168...:8000`) add to the `<application>`
  tag: `android:usesCleartextTraffic="true"`. (Not needed for https ngrok / HF URLs.)
- Set `minSdkVersion` to at least `24` in `android/app/build.gradle` (video_thumbnail).

## Set the backend URL

- In-app: type it in the **Backend URL** field and tap **Save** (it's remembered and
  a health check runs).
- Default baked into the build: edit `_defaultUrl` in `lib/detection_screen.dart`
  — set it to your **Hugging Face Space** URL before building the release APK.

## Run during development

With the backend running locally + `ngrok http 8000`, put the ngrok URL in the app:
```bash
flutter run           # on an attached phone (USB debugging) or emulator
```

## Build the APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.
Copy it to your phone and install (allow "install from unknown sources").

## How it works

- **Take Photo / Pick Image** → one `POST /detect` (ensemble) → boxes + per-model latency.
- **Pick Video** → samples ~8 frames (every 0.7s) via `video_thumbnail`, sends each,
  shows a scrollable strip of annotated frames.
- The app never knows three models were involved — the backend merges them.
