# App Store metadata — en-US

Paste-ready text for App Store Connect. Character limits are Apple's; counts are
given so edits stay legal.

## Name (30 max)

WatchNext

## Subtitle (30 max)

What's ready on your server

(28 characters)

## Promotional text (170 max, editable without a new build)

Your Jellyfin, Sonarr and Radarr in one glance: what's ready to watch, what's coming, and a widget that keeps up.

(112 characters)

## Description (4000 max)

WatchNext is a companion for your self-hosted media stack. It reads Sonarr, Radarr and Jellyfin, then answers the only two questions that matter tonight: what is ready to watch, and what is coming next.

READY TO WATCH
Everything Sonarr and Radarr imported recently that you have not watched in Jellyfin. A whole new season shows as one row with the first unwatched episode and an "and N more" count, so a season drop does not bury the rest of your list. Watched something? It disappears on the next refresh.

COMING SOON
Monitored episodes and movies with a release date ahead, with the time left: in 2 hours, in 6 days.

WIDGETS THAT FIT
Small, medium and large Home Screen widgets, text-first so more fits. Choose a density (Comfortable, Compact or Smart, which lists the most items that fit), show only movies or only shows, and toggle posters in the large widget. Refresh straight from the widget.

MAKE IT YOURS
Hide a title or a whole series from the feed, in one swipe or many at once with Select Items. Filter by Movies or Shows. Collapse a section. Choose how far back and how far ahead the feed looks, or remove the limits.

YOUR SERVERS, YOUR DATA
WatchNext talks only to the servers you configure, on your network or over HTTPS. Read-only against Sonarr, Radarr and Jellyfin; the one write is the Jellyfin sign-in that creates your session token. API keys and tokens live in the Keychain. Nothing is sent anywhere else, and there are no accounts, analytics or ads.

WatchNext is free and open source.

Requires Sonarr v3, Radarr v3 and a Jellyfin server you can reach from your iPhone.

(1,543 characters)

## Keywords (100 max, comma-separated, no spaces after commas)

jellyfin,sonarr,radarr,plex,media,server,widget,tv,movies,episodes,homelab,selfhosted,watchlist

(95 characters)

## What's New (first release)

First release.

## URLs

- Support URL: `https://github.com/MXF-Apps/WatchNext/issues` (adjust the account name if the repository lives elsewhere)
- Marketing URL: `https://github.com/MXF-Apps/WatchNext`, optional
- Privacy Policy URL: `https://github.com/MXF-Apps/WatchNext/blob/main/PRIVACY.md`
- Trader status: **non-trader**. The app is free with no in-app purchases; sponsorship happens on GitHub, outside the App Store. Do not mention sponsorship in the app or in this metadata (guideline 3.1.1).

## Category

- Primary: Entertainment
- Secondary: Utilities

## Age rating

None of the questionnaire items apply. Expect 4+.

## App Privacy (App Store Connect questionnaire)

- Data collection: **No, we do not collect data from this app.**
  Server URLs and Jellyfin user choice stay on device (App Group defaults). API keys and tokens stay in the Keychain. Media titles and artwork are cached on device only. No third-party SDKs.
- Local network: the app declares `NSLocalNetworkUsageDescription` because most users run these servers on their LAN.

## Export compliance

Uses only standard HTTPS/TLS provided by iOS. Answer: uses encryption, exempt (standard encryption for network communication). Set `ITSAppUsesNonExemptEncryption = NO` in the Info.plist to skip the question on each upload.

## Review notes (for App Review)

Paste-ready:

> WatchNext is a companion for self-hosted Sonarr, Radarr and Jellyfin servers, so it shows nothing until servers are configured. A built-in demo mode exercises every feature without a server: on first launch tap "Try with sample data", or open Settings › Demo › Demo mode. The app and the Home Screen widgets (small, medium, large; add them from the widget gallery, long-press a widget for Edit Widget to see the density, content and layout options) then show a fictional library covering every state: ready items, a folded season, a partially watched movie, upcoming releases, and an aired episode awaiting download. Demo mode is a supported user feature, not a review-only switch. The Jellyfin sign-in form is only used against the reviewer's own server; no account exists on our side.

If a reviewer insists on live servers, `AppStore/DemoServer/demo_server.py` can be hosted behind an HTTPS tunnel for the review window; any API key works, Jellyfin accepts any sign-in, user "Demo".

## Screenshot captions (optional, if using framed screenshots)

1. Everything ready to watch, in one list.
2. Seasons fold into the next episode.
3. Hide what you don't want to see. Many at once.
4. Widgets that fit: small, medium, large.
5. Your servers, your Keychain. Nothing leaves your device.
