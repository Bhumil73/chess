# Play Store Deployment Guide for Paper Chess

## Pre-requisites Completed ✅
- ✅ App configured for release build
- ✅ ProGuard rules added for code obfuscation
- ✅ App name updated to "Paper Chess"
- ✅ Description updated in pubspec.yaml
- ✅ Version set to 1.0.0 (versionCode: 1)

## Step 1: Generate Signing Key

Run this command to create your keystore:

```bash
cd /Users/bpatel/StudioProjects/chess/android/app
keytool -genkey -v -keystore keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias paper-chess-key
```

**Important:** Save the passwords securely! You'll need:
- Keystore password
- Key password
- Key alias: `paper-chess-key`

## Step 2: Set Environment Variables

Add these to your `~/.zshrc` or `~/.bash_profile`:

```bash
export KEYSTORE_PASSWORD="your_keystore_password"
export KEY_ALIAS="paper-chess-key"
export KEY_PASSWORD="your_key_password"
```

Then reload:
```bash
source ~/.zshrc
```

## Step 3: Build Release APK/AAB

For Play Store, use Android App Bundle (AAB):

```bash
cd /Users/bpatel/StudioProjects/chess
flutter build appbundle --release
```

The bundle will be at: `build/app/outputs/bundle/release/app-release.aab`

Or for APK:
```bash
flutter build apk --release
```

## Step 4: Prepare Play Store Assets

### App Icon
✅ Already configured: `assets/icons/paper_chess_icon.png`

### Screenshots Required
You need 2-8 screenshots (min 320px, max 3840px on any side):
- Phone: 1080 x 1920px or similar
- 7-inch tablet: Optional
- 10-inch tablet: Optional

Take screenshots by running:
```bash
flutter run --release
# Then use device screenshot tools
```

### Feature Graphic (Required)
- Size: 1024 x 500px
- PNG or JPEG

### Privacy Policy
Since your app doesn't collect user data, you can use a simple privacy policy or state "No data collected" in Play Console.

## Step 5: Play Console Upload

1. Go to https://play.google.com/console
2. Sign in with: bhumilpatel06@gmail.com
3. Click "Create app"
4. Fill in:
   - **App name**: Paper Chess
   - **Default language**: English (United States)
   - **App or game**: Game
   - **Free or paid**: Free

5. Complete the questionnaire:
   - Target audience: Everyone
   - Content rating: Fill questionnaire (likely Everyone/PEGI 3)
   - Select your app category: Board game

6. Store listing:
   - **Short description** (80 chars max):
     ```
     Beautiful pen & paper style chess with AI opponent and player vs player mode
     ```
   
   - **Full description** (4000 chars max):
     ```
     Paper Chess brings the classic game of chess to life with a beautiful pen-and-paper aesthetic. 
     
     Features:
     • Play against AI with intelligent minimax algorithm
     • Player vs Player mode on same device
     • Beautiful hand-drawn board design
     • Full chess rules including castling, en passant, and pawn promotion
     • Check and checkmate detection
     • Elegant 3D paper-style UI
     • Smooth animations for piece movement
     • No ads, no data collection
     
     Perfect for chess enthusiasts who appreciate clean design and strategic gameplay!
     ```

7. Upload assets:
   - App icon (automatically from flutter_launcher_icons)
   - Feature graphic
   - Screenshots (2-8 required)

8. Upload the AAB file:
   - Go to "Production" → "Create new release"
   - Upload `app-release.aab`
   - Add release notes

9. Content rating:
   - Fill out questionnaire (game with no mature content)

10. Submit for review

## Step 6: Post-Submission

- Review typically takes 1-7 days
- You'll receive email at bhumilpatel06@gmail.com
- App will be available on Play Store after approval

## Important Files Created

1. `/android/app/build.gradle.kts` - Configured for release signing
2. `/android/app/proguard-rules.pro` - Code obfuscation rules
3. `/android/key.properties.example` - Environment variables template
4. `/android/app/keystore.jks` - Will be created by you (DO NOT commit to git!)

## Troubleshooting

If build fails:
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

If signing fails, check:
- Environment variables are set correctly
- Keystore file is in `/android/app/keystore.jks`
- Passwords match the keystore creation

## Version Updates

To release updates:

1. Update version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # 1.0.1 is versionName, 2 is versionCode
   ```

2. Build new bundle:
   ```bash
   flutter build appbundle --release
   ```

3. Upload to Play Console under "Production" → "Create new release"

---

**Developer**: Bhumil Patel (bhumilpatel06@gmail.com)
**Package**: com.bhumil73.chess
**Version**: 1.0.0 (1)

