# Distributing Wicara

Two channels, no app store involved:

| Channel | Who it is for | Link |
| --- | --- | --- |
| **Web (PWA)** | Anyone, any phone or desktop. No install. | Vercel deployment |
| **Android APK** | People who want the real app installed | GitHub Releases |

Google Play and iOS/TestFlight are deliberately out of scope.

---

## 1. Web build on Vercel

The Flutter web target is built by `tool/build_web.sh`, which Vercel runs via
`vercel.json`. Vercel images ship no Flutter SDK, so the script downloads a
pinned one — `FLUTTER_VERSION` is pinned rather than tracking `stable` so that
an upstream Flutter release cannot break a deploy that changed nothing here.

### First deploy

```bash
cd ui-wicara-asean-mobile
vercel link          # create/select the project, e.g. ui-wicara-asean-mobile
vercel --prod
```

The project name must start with `ui-wicara-asean-` or the backend will reject
its origin — see the CORS note below.

### Environment variables

Set on the Vercel project (Production + Preview):

| Variable | Value | Required |
| --- | --- | --- |
| `WICARA_API_BASE_URL` | `https://ui-wicara-asean-be.vercel.app` | No — this is the default |
| `WICARA_GOOGLE_WEB_CLIENT_ID` | OAuth web client id | Only for Google sign-in |
| `FLUTTER_VERSION` | e.g. `3.44.9` | No — defaults in the script |

Without `WICARA_GOOGLE_WEB_CLIENT_ID` the **Google button on web does nothing**;
email/password sign-in still works. To enable it, create an OAuth 2.0 *Web
application* client in Google Cloud Console and add the Vercel domain to its
authorised JavaScript origins.

### Backend CORS

The browser sends an `Origin` header that the API must allow. `Settings.
cors_allow_origin_regex` in the backend matches
`https://ui-wicara-asean-*.vercel.app`, which covers production *and* the unique
hostname Vercel mints for every preview deploy. It is scoped to this project on
purpose — a bare `.*\.vercel\.app` would let any site hosted on Vercel drive the
API. If the web project is ever named something else, update that regex, or
override it with the `WICARA_CORS_ALLOW_ORIGIN_REGEX` env var on the backend.

**The backend must be redeployed before the web app works.** As of this writing
the live API still rejects the web origin — `OPTIONS /api/v1/subjects` with
`Origin: https://ui-wicara-asean-mobile.vercel.app` returns **400** with no
`access-control-allow-origin` header. Ship the backend change first, or the web
build loads and then fails every request with an opaque CORS error.

---

## 2. Android APK on GitHub Releases

`.github/workflows/build_wicara_mobile_apk.yml` builds the APK and, for tag
pushes, publishes a public GitHub Release. The download URL needs no GitHub
account and does not expire, unlike the 90-day build artifacts.

### Signing (do this once)

Sideloaded apps must keep a **stable signature** across releases: Android
refuses to install an update signed by a different key, and CI regenerates its
debug keystore on every run — so debug-signed releases would force every user to
uninstall before updating.

The keystore lives at `android/wicara-release.p12` (PKCS12, RSA-4096, valid
until 2056) with credentials in `android/key.properties`. Both are gitignored.

> **Back these two files up somewhere safe.** Losing them means every existing
> install has to be uninstalled before it can be updated.

Upload them to the repo as secrets:

```bash
base64 -i android/wicara-release.p12 | tr -d '\n' \
  | gh secret set WICARA_KEYSTORE_BASE64 --repo RahardiSalim/ui-wicara-asean-mobile

grep '^storePassword=' android/key.properties | cut -d= -f2- | tr -d '\n' \
  | gh secret set WICARA_KEYSTORE_PASSWORD --repo RahardiSalim/ui-wicara-asean-mobile
```

The build fails loudly if `WICARA_KEYSTORE_BASE64` is missing, rather than
silently falling back to the debug key.

### Cutting a release

```bash
# Verify the build first -- this uploads an artifact but publishes nothing.
gh workflow run "Build Wicara Mobile APK" --repo RahardiSalim/ui-wicara-asean-mobile

# Once that is green, publish:
git tag v1.0.0
git push origin v1.0.0
```

The tag push builds and attaches `wicara-1.0.0.apk` to a public release at
`github.com/RahardiSalim/ui-wicara-asean-mobile/releases/latest`.

`versionName` comes from the tag, `versionCode` from the CI run number — so
every release has a higher `versionCode` and Android accepts it as an upgrade.

### What users do

1. Open the release link and download the `.apk`.
2. Android asks to allow **Install unknown apps** for the browser — this warning
   is unavoidable outside the Play Store.
3. Tap Install. Requires Android 6.0 (API 23) or newer.

### Two traps that cost a build each

**v1 signing is not optional here.** APK Signature Scheme v2 only exists on API
24+, and AGP does not turn on v1 JAR signing just because `minSdk` is 23. The
first signed build verified as v2-only, so `apksigner verify --min-sdk-version
23` rejected it outright — it would have installed fine on a modern phone and
failed on Android 6. `enableV1Signing = true` in the release signing config is
what fixes it, and the workflow now asserts it on every build.

**ABI trimming goes through Flutter, not Gradle.** `ndk { abiFilters += ... }`
in the release build type does nothing useful: AGP *unions* it with what the
Flutter Gradle plugin already set, so nothing is removed. Use
`flutter build apk --target-platform android-arm,android-arm64` instead. That
took the APK from 117 MB to 91 MB. The remaining ~24 MB of `lib/x86_64/`
belongs to the LiteRT AAR rather than the Flutter engine; dropping it needs a
global `packaging { jniLibs { excludes } }`, which would also break x86_64
emulators, so it is deliberately left in.

---

## Notes

- `applicationId` is `com.wicara.mobile`. It was `com.example.wicara_mobile`,
  which is a placeholder Play would reject outright. Changing it again later
  makes Android treat the result as a *different app*, so anyone who installed
  an earlier build must uninstall first.
- `namespace` is still `com.example.wicara_mobile`. It only affects generated
  `R`/`BuildConfig` classes, not the installed identity, and changing it means
  moving the Kotlin sources under `android/app/src/main/kotlin/`.
- The web build is ~49 MB, mostly CanvasKit. First load on mobile data is slow;
  it is cached immutably afterwards.
