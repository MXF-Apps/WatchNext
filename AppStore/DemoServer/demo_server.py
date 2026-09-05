#!/usr/bin/env python3
"""Fictional Sonarr, Radarr and Jellyfin for screenshots and App Review.

Serves the endpoints WatchNext reads, with invented titles and generated
posters, so no real media appears in marketing material. Dates are relative to
start time so the feed always looks fresh.

    python3 demo_server.py            # Sonarr :18989, Radarr :17878, Jellyfin :18096
    python3 demo_server.py --host 0.0.0.0 --poster-host 192.168.1.15 --ports 8989,7878,8096
                                      # reachable from other devices, on the real ports

Configure WatchNext with http://<host>:18989, http://<host>:17878 and
http://<host>:18096. Any API key works; Jellyfin sign-in accepts any
username/password and the token "demo-token". Pick the user "Demo".
"""
import argparse
import json
import os
import threading
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

HERE = os.path.dirname(os.path.abspath(__file__))
POSTERS = os.path.join(HERE, "posters")
NOW = datetime.now(timezone.utc)
HOST_FOR_URLS = "127.0.0.1"
JELLYFIN_PORT = 18096  # overridden by --ports


def iso(dt):
    return dt.strftime("%Y-%m-%dT%H:%M:%SZ")


def ago(**kw):
    return NOW - timedelta(**kw)


def ahead(**kw):
    return NOW + timedelta(**kw)


def poster(slug):
    return f"http://{HOST_FOR_URLS}:{JELLYFIN_PORT}/poster/{slug}.png"


# ---------------------------------------------------------------- catalog
# Shows: tvdb ids are invented. Episodes list (season, number, title, aired, imported or None, watched, progress).
SHOWS = [
    dict(id=1, slug="harbor-lights", title="Harbor Lights", tvdb=910001, episodes=[
        (2, n, t, ago(days=9 - n), ago(days=1, hours=3), False, None)
        for n, t in enumerate(["North Pier", "The Keeper's Daughter", "Fog Signals", "Undertow", "Low Water", "Last Light"], start=1)
    ]),
    dict(id=2, slug="the-cartographers", title="The Cartographers", tvdb=910002, episodes=[
        (1, 1, "Blank Spaces", ago(days=30), ago(days=28), True, None),
        (1, 2, "Contour Lines", ago(days=23), ago(days=21), True, None),
        (1, 3, "Dead Reckoning", ago(days=16), ago(days=14), True, None),
        (1, 4, "The Salt Road", ago(days=2, hours=5), ago(days=2), False, 0.35),
    ]),
    dict(id=3, slug="ninefold-station", title="Ninefold Station", tvdb=910003, episodes=[
        (3, 9, "Airlock Nine", ago(days=5), ago(days=5), True, None),
        (3, 10, "Pressure Drop", ahead(days=2, hours=4), None, False, None),
        (3, 11, "Quiet Orbit", ahead(days=9, hours=4), None, False, None),
    ]),
    dict(id=4, slug="saltmarsh", title="Saltmarsh", tvdb=910004, episodes=[
        (1, 1, "Spring Tide", ago(hours=3), None, False, None),  # aired, not imported: shows as awaiting download
    ]),
]

# Movies: (id, slug, title, year, tmdb, imported or None, release, quality, watched, progress)
MOVIES = [
    (101, "paper-meridian", "Paper Meridian", 2026, 820001, ago(days=1, hours=8), ago(days=40), "Bluray-2160p", False, None),
    (102, "the-long-static", "The Long Static", 2025, 820002, ago(days=3), ago(days=90), "WEBDL-1080p", False, 0.4),
    (103, "glasshouse-summer", "Glasshouse Summer", 2026, 820003, ago(days=6), ago(days=20), "Bluray-1080p", False, None),
    (104, "vantablack-sonata", "Vantablack Sonata", 2026, 820004, None, ahead(days=4), None, False, None),
    (105, "orbital-kitchen", "Orbital Kitchen", 2025, 820005, ago(days=10), ago(days=120), "WEBDL-2160p", False, None),
    (106, "copper-and-tide", "Copper and Tide", 2026, 820006, None, ahead(days=12), None, False, None),
]

QUALITY_TV = "WEBDL-1080p"


def sonarr_series(show):
    return {"title": show["title"], "monitored": True, "tvdbId": show["tvdb"],
            "images": [{"coverType": "poster", "remoteUrl": poster(show["slug"])}]}


def sonarr_episode(show, ep, with_file):
    season, number, title, aired, imported, _, _ = ep
    d = {"id": show["id"] * 1000 + season * 100 + number, "seriesId": show["id"], "title": title,
         "seasonNumber": season, "episodeNumber": number, "airDateUtc": iso(aired), "monitored": True,
         "hasFile": with_file, "tvdbId": 700000 + show["id"] * 1000 + season * 100 + number,
         "series": sonarr_series(show)}
    if with_file and imported:
        d["episodeFile"] = {"dateAdded": iso(imported), "quality": {"quality": {"name": QUALITY_TV}}}
    return d


def sonarr_history():
    records = []
    for show in SHOWS:
        for ep in show["episodes"]:
            if ep[4] is None:
                continue
            records.append({"date": iso(ep[4]), "quality": {"quality": {"name": QUALITY_TV}},
                            "series": sonarr_series(show), "episode": sonarr_episode(show, ep, True)})
    records.sort(key=lambda r: r["date"], reverse=True)
    return {"records": records}


def sonarr_calendar():
    return [sonarr_episode(show, ep, False) for show in SHOWS for ep in show["episodes"] if ep[4] is None]


def radarr_movie(m):
    mid, slug, title, year, tmdb, imported, release, quality, _, _ = m
    d = {"id": mid, "title": title, "year": year, "monitored": True, "hasFile": imported is not None,
         "digitalRelease": iso(release), "tmdbId": tmdb, "imdbId": f"tt{9000000 + mid}",
         "images": [{"coverType": "poster", "remoteUrl": poster(slug)}]}
    if imported:
        d["movieFile"] = {"dateAdded": iso(imported), "quality": {"quality": {"name": quality}}}
    return d


def radarr_history():
    records = [{"date": iso(m[5]), "quality": {"quality": {"name": m[7]}}, "movie": radarr_movie(m)} for m in MOVIES if m[5]]
    records.sort(key=lambda r: r["date"], reverse=True)
    return {"records": records}


def radarr_calendar():
    return [radarr_movie(m) for m in MOVIES if m[5] is None]


def jellyfin_items(include):
    items = []
    if "Series" in include:
        for show in SHOWS:
            items.append({"Id": f"series-{show['id']}", "Type": "Series", "Name": show["title"],
                          "ProviderIds": {"Tvdb": str(show["tvdb"])}})
    if "Episode" in include:
        for show in SHOWS:
            for season, number, title, aired, imported, watched, progress in show["episodes"]:
                if imported is None:
                    continue
                user = {"Played": watched}
                if progress:
                    user["PlayedPercentage"] = progress * 100
                items.append({"Id": f"ep-{show['id']}-{season}-{number}", "Type": "Episode", "Name": title,
                              "SeriesName": show["title"], "SeriesId": f"series-{show['id']}",
                              "ParentIndexNumber": season, "IndexNumber": number,
                              "ProviderIds": {"Tvdb": str(700000 + show["id"] * 1000 + season * 100 + number)},
                              "UserData": user})
    if "Movie" in include:
        for mid, slug, title, year, tmdb, imported, release, quality, watched, progress in MOVIES:
            if imported is None:
                continue
            user = {"Played": watched}
            if progress:
                user["PlayedPercentage"] = progress * 100
            items.append({"Id": f"movie-{mid}", "Type": "Movie", "Name": title, "ProductionYear": year,
                          "ProviderIds": {"Tmdb": str(tmdb), "Imdb": f"tt{9000000 + mid}"}, "UserData": user})
    return {"Items": items}


def poster_for_jellyfin_item(item_id):
    if item_id.startswith("series-") or item_id.startswith("ep-"):
        show_id = int(item_id.split("-")[1])
        return next(s["slug"] for s in SHOWS if s["id"] == show_id)
    if item_id.startswith("movie-"):
        mid = int(item_id.split("-")[1])
        return next(m[1] for m in MOVIES if m[0] == mid)
    return None


# ---------------------------------------------------------------- servers
class Handler(BaseHTTPRequestHandler):
    kind = "sonarr"

    def log_message(self, fmt, *args):
        print(f"[{self.kind}] {self.command} {self.path}")

    def send_json(self, payload, status=200):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_png(self, slug):
        path = os.path.join(POSTERS, f"{slug}.png")
        if not os.path.exists(path):
            return self.send_json({"error": "no poster"}, 404)
        with open(path, "rb") as f:
            data = f.read()
        self.send_response(200)
        self.send_header("Content-Type", "image/png")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        self.do_GET()

    def do_GET(self):
        url = urlparse(self.path)
        p = url.path.rstrip("/")
        q = dict(part.split("=", 1) if "=" in part else (part, "") for part in url.query.split("&") if part)
        if self.kind == "sonarr":
            if p == "/api/v3/system/status":
                return self.send_json({"appName": "Sonarr", "version": "4.0.0.0 (demo)"})
            if p == "/api/v3/history":
                return self.send_json(sonarr_history())
            if p == "/api/v3/calendar":
                return self.send_json(sonarr_calendar())
        elif self.kind == "radarr":
            if p == "/api/v3/system/status":
                return self.send_json({"appName": "Radarr", "version": "5.0.0.0 (demo)"})
            if p == "/api/v3/history":
                return self.send_json(radarr_history())
            if p == "/api/v3/calendar":
                return self.send_json(radarr_calendar())
        else:
            if p == "/System/Info":
                return self.send_json({"ServerName": "Demo Server", "Version": "10.10.0 (demo)"})
            if p == "/Users/AuthenticateByName":
                return self.send_json({"AccessToken": "demo-token", "User": {"Id": "demo-user", "Name": "Demo"}})
            if p == "/Users":
                return self.send_json([{"Id": "demo-user", "Name": "Demo"}])
            if p.startswith("/Users/") and p.endswith("/Items"):
                return self.send_json(jellyfin_items(q.get("IncludeItemTypes", "").replace("%2C", ",")))
            if p.startswith("/Items/") and p.endswith("/Images/Primary"):
                slug = poster_for_jellyfin_item(p.split("/")[2])
                return self.send_png(slug) if slug else self.send_json({"error": "unknown item"}, 404)
            if p.startswith("/poster/"):
                return self.send_png(p.split("/")[2].removesuffix(".png"))
        self.send_json({"error": f"unhandled {p}"}, 404)


class QuickBindServer(ThreadingHTTPServer):
    """HTTPServer resolves the bind host's FQDN, which can hang for 0.0.0.0; skip it."""

    def server_bind(self):
        import socketserver
        socketserver.TCPServer.server_bind(self)
        self.server_name, self.server_port = self.server_address[0], self.server_address[1]


def serve(kind, host, port):
    handler = type(f"{kind.title()}Handler", (Handler,), {"kind": kind})
    server = QuickBindServer((host, port), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    print(f"{kind}: http://{host}:{port}")
    return server


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--poster-host", default=None, help="host other devices use to fetch posters (default: --host)")
    ap.add_argument("--ports", default="18989,17878,18096", help="Sonarr,Radarr,Jellyfin ports (use 8989,7878,8096 to mimic real servers)")
    args = ap.parse_args()
    HOST_FOR_URLS = args.poster_host or args.host
    sonarr_port, radarr_port, JELLYFIN_PORT = (int(x) for x in args.ports.split(","))
    servers = [serve("sonarr", args.host, sonarr_port), serve("radarr", args.host, radarr_port), serve("jellyfin", args.host, JELLYFIN_PORT)]
    print("demo catalog ready; Ctrl-C to stop")
    try:
        threading.Event().wait()
    except KeyboardInterrupt:
        pass
