# App Store release kit

Everything needed to submit WatchNext, in one place.

| Folder | What |
|---|---|
| `Icon/` | `GenerateIcon.swift` draws the icon with CoreGraphics; `icon-1024.png` is the shipped variant (A, indigo) and is copied into `WatchNext/Assets.xcassets/AppIcon.appiconset/AppIcon.png`. `variants/` holds B (teal) and C (charcoal) with rounded previews; `contact-sheet.png` shows all three at 180, 120 and 60 px on light and dark. |
| `Metadata/<locale>.md` | Paste-ready App Store Connect text per language: `en-US.md` (name, subtitle, promo text, description, keywords, plus the shared category, age rating, privacy answers, export compliance and review notes) and `fr-FR.md` (the localized fields only). Add one file per additional store language. |
| `DemoServer/` | `demo_server.py` fakes Sonarr, Radarr and Jellyfin with an invented catalog and generated posters (`GeneratePosters.swift` → `posters/`). Used for every screenshot so no real title or artwork appears, and usable as the demo backend App Review asks for. |
| `Screenshots/*-preview-*.png` | Previews of the opt-in header-less layout (small at 6.3-inch, large at 6.9-inch), for reference, not for upload. |
| `Screenshots/<locale>/iPhone-6.9/` | 1320 × 2868 captures from the iPhone 17 Pro Max simulator, one folder per store language (`en-US`, `fr-FR`), clean status bar, demo catalog only: `01-ready-to-watch`, `02-coming-soon` (Ready collapsed, folded season), `03-select-items` (multi-select with the action bar), `04-widgets` (large in Comfortable and medium in Smart on one page), `05-settings`, `06-appearance` (Settings › Appearance with a Strong Orchid wash and the tint swatches), `07-widgets-small` (small next to a large, so all three sizes appear across 04 and 07). |
| `Screenshots/<locale>/iPad-13/` | 2064 × 2752 captures from the iPad Pro 13-inch (M5) simulator, same demo catalog and the same subjects: `01-ready-to-watch`, `02-coming-soon`, `03-select-items`, `04-widgets` (small, medium and large on one page), `05-settings`, `06-appearance`. Required because the build targets iPad; App Store Connect reuses them for 12.9-inch and 11-inch. |
| `Screenshots/<locale>/iPhone-6.5/` | 1284 × 2778 versions of the 6.9-inch set (scaled to width, 6 px trimmed top and bottom) for the "iPhone 6.5-inch Display" slot when App Store Connect shows that one instead of 6.9-inch. |

## Regenerate

```sh
# Icon (writes icon-1024.png, variants/, contact-sheet.png)
swiftc -O -o /tmp/genicon AppStore/Icon/GenerateIcon.swift && /tmp/genicon AppStore/Icon
cp AppStore/Icon/icon-1024.png WatchNext/Assets.xcassets/AppIcon.appiconset/AppIcon.png

# Posters, then the demo server (Sonarr :18989, Radarr :17878, Jellyfin :18096)
swiftc -O -o /tmp/genposters AppStore/DemoServer/GeneratePosters.swift && /tmp/genposters AppStore/DemoServer/posters
python3 AppStore/DemoServer/demo_server.py
```

Point a simulator's WatchNext at `http://127.0.0.1:18989`, `http://127.0.0.1:17878`, `http://127.0.0.1:18096`; any API key, token `demo-token`, user `Demo`. For a physical device or a reviewer, run with `--host 0.0.0.0 --poster-host <reachable-ip-or-domain>` behind a tunnel.

Screenshots: boot an iPhone 17 Pro Max simulator (or the iPad Pro 13-inch for the iPad set), set the simulator language to the store locale (`xcrun simctl spawn <udid> defaults write .GlobalPreferences AppleLanguages -array fr-FR` then shut down and boot), run the demo server on the standard ports (`--ports 8989,7878,8096`, loopback; the macOS firewall's stealth mode blocks the Mac's own LAN address), `xcrun simctl status_bar <udid> override --time 9:41 --dataNetwork wifi --wifiBars 3 --cellularBars 4 --batteryState discharging --batteryLevel 100`, enter the URLs and any keys in Settings, refresh, then `xcrun simctl io <udid> screenshot --type=png`. Edit a placed large widget to Density = Comfortable for the poster layout.

## Release checklist

Before the first upload:

- [x] Real identifiers everywhere (`com.mxf-apps.WatchNext`, `com.mxf-apps.WatchNext.Widget`, `group.com.mxf-apps.WatchNext`, `com.mxf-apps.WatchNext.shared`): both targets' bundle IDs, both `.entitlements`, both Info.plists, `WatchNextConstants.swift`. Development team set on both targets; automatic signing registers the App IDs, App Group and Keychain Sharing.
- [ ] Set `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` (currently 1.0 / 1).
- [x] Add `ITSAppUsesNonExemptEncryption = NO` to both Info.plists.
- [ ] Archive with Release configuration and upload with Xcode Organizer or `xcodebuild -exportArchive`.
- [ ] Create the app record in App Store Connect with the name, bundle ID and SKU; fill in `Metadata/en-US.md`.
- [ ] Upload the iPhone screenshots (6.9-inch set, or the 6.5-inch set if that is the slot App Store Connect offers) and the 13-inch iPad screenshots from `Screenshots/<locale>/` for each store language; App Store Connect scales them for the smaller sizes.
- [ ] Privacy: answer "Data Not Collected"; the policy is `PRIVACY.md` at the repository root, paste its GitHub URL.
- [ ] Trader status: declare non-trader (free app, no in-app purchases). Keep sponsorship links out of the app and the store metadata.
- [ ] Review notes: paste the demo-mode paragraph from `Metadata/en-US.md`.
- [ ] Support URL: a public issues page or contact address.

Known blockers and risks:

- **App Review needs content.** Demo mode (Settings › Demo, or the first-run button) covers this without infrastructure; the review notes explain it. Keep `demo_server.py` behind an HTTPS tunnel as a fallback if a reviewer asks for live servers.
- **Guideline 4.2 (minimum functionality) and 5.2 (third-party services).** The description names Sonarr, Radarr and Jellyfin as the servers the user runs. Do not use their logos or imply endorsement.
- **Plain-HTTP LAN access.** Info.plist allows local networking only, no arbitrary loads. Keep it that way; reviewers check ATS exceptions.
- **iOS 26.5 AppEnum bug.** Widget parameters are Strings on purpose; see the README's known limitations before "cleaning up" to enums.

## Privacy policy (draft)

> WatchNext connects only to the Sonarr, Radarr and Jellyfin servers you configure. Server addresses and display preferences are stored on your device. API keys and the Jellyfin session token are stored in the iOS Keychain. Media titles and artwork fetched from your servers are cached on your device for display in the app and its widgets. WatchNext does not collect, transmit or share any data with the developer or third parties, and contains no analytics, advertising or tracking. Deleting the app removes all stored data.
