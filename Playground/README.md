# ThunderID iOS Playground

A SwiftUI app for exercising every capability of the ThunderID iOS SDK from source. It depends on
`ThunderID` and `ThunderIDSwiftUI` through a local package reference to the repository root, so it
always runs the SDK code in your checkout. For a minimal app to copy from, use the
[iOS quickstart](https://github.com/thunder-id/samples/tree/main/quickstarts/ios) instead.

The app has four tabs:

- **Checks**: capability checks that call the real SDK (system browser sign-in, app-native sign-in,
  passkey, sign-out, redirect callback, token refresh, Keychain storage, user info, translations),
  with run one or run all, a pass/fail reason per check, a summary ring and the server's health.
  Capabilities the iOS SDK has no API for (biometric unlock, organizations, theming) are shown as
  unavailable with the reason. Checks that need you (a browser sheet, a sign-in form, ending the
  session) run only when tapped; Run all covers the rest.
- **Components**: a component explorer for the ThunderIDSwiftUI components. Pick a component and a
  story, edit its props under Controls, preview it in light or dark, and copy the SwiftUI snippet
  generated from the current props under Code.
- **Session**: the signed-in user, an access token countdown, refresh and sign out, and tabs for
  the tokens (reveal and copy), the decoded claims and recent events.
- **Logs**: everything the playground asked the SDK to do and what came back, including every
  write the SDK makes to the Keychain (key names only).

## Prerequisites

- Xcode 16 or later, iOS 16 or later (simulator or device)
- A ThunderID server. To run one locally, follow
  [Get started](https://thunderid.dev/docs/next/getting-started/); it listens on
  `https://localhost:8090` with a self-signed certificate. The SDK accepts that certificate from a
  loopback host, and the iOS Simulator reaches the host Mac's `localhost` directly. On a device,
  point the base URL at your Mac's address and trust the server certificate on the device.

## Set up an application

In the ThunderID Console, create a **mobile** application and note its ID.

- For **app-native sign-in** (the `SignIn` component and the passkey check), the application ID is
  enough. Mobile applications must prove their identity with App Attest before they can start a
  flow, which the simulator cannot do; for local development, enable attestation dev mode on the
  application.
- For **system browser sign-in**, also give the application an OAuth client with the
  authorization code grant, PKCE, a public client, and the redirect URI
  `dev.thunderid.playground://callback`. The app registers the `dev.thunderid.playground` URL
  scheme in `Info.plist`.

## Configure

```bash
cp Sources/Config.plist.example Sources/Config.plist
```

| Key | Value |
|---|---|
| `THUNDERID_BASE_URL` | Server URL, for example `https://localhost:8090` |
| `THUNDERID_APPLICATION_ID` | The application ID, for app-native sign-in |
| `THUNDERID_CLIENT_ID` | The OAuth client ID, for system browser sign-in |
| `THUNDERID_AFTER_SIGN_IN_URL` | Redirect URI, `dev.thunderid.playground://callback` |
| `THUNDERID_AFTER_SIGN_OUT_URL` | Where to go after sign-out |
| `THUNDERID_SCOPES` | Space-separated scopes, `openid profile email` by default |

`Config.plist` is gitignored. Without it the app still opens against `https://localhost:8090`
and each check explains what is missing.

## Run

Open `Playground.xcodeproj` in Xcode, pick a simulator and run the `Playground` scheme. Or from
the command line:

```bash
xcodebuild -project Playground.xcodeproj -scheme Playground \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Launch arguments, handy for screenshots: `-tab Components` (or `Session`, `Logs`) opens that tab,
and `-runAll YES` runs every automatic check once the SDK has initialized.

The playground is also a Swift package, which is how CI type-checks it against the SDK:

```bash
swift build
```

## Notes

- The SDK has no event emitter, so the log is recorded around each SDK call, from the storage
  adapter the playground hands the SDK through `ThunderIDConfig.storage`, and from changes to
  `ThunderIDState`.
- The SDK exposes no public accessor for the ID token, refresh token or expiry, so the session
  inspector reads them back through that storage adapter. The token refresh check drops the
  stored expiry so the next `getAccessToken()` runs the refresh grant, since there is no public
  "refresh now" call. App-native sign-in stores only an access token, so token refresh needs a
  system browser session.
