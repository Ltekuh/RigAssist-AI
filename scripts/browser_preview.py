#!/usr/bin/env python3
"""Serve a browser-based RigAssist AI sample and optionally capture it."""

from __future__ import annotations

import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from io import BytesIO
from pathlib import Path
import shutil
import subprocess
import sys
from threading import Thread
from typing import Any


HTML = r"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>RigAssist AI — Browser Sample</title>
  <style>
    :root {
      color-scheme: light;
      --navy: #142334;
      --orange: #ee7e22;
      --background: #f4f6f8;
      --text: #191f26;
      --muted: #687582;
      --border: #e2e7ec;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }
    * { box-sizing: border-box; }
    body { margin: 0; background: var(--background); color: var(--text); }
    header {
      background: var(--navy); color: white; padding: 22px max(24px, calc((100% - 1040px) / 2));
      display: flex; align-items: center; justify-content: space-between; gap: 20px;
    }
    .brand { display: flex; align-items: center; gap: 13px; font-size: 19px; font-weight: 750; }
    .brand-mark {
      width: 40px; height: 40px; border-radius: 12px; display: grid; place-items: center;
      background: var(--orange); font-size: 22px;
    }
    .demo-badge {
      border: 1px solid #ffffff55; border-radius: 999px; padding: 7px 12px;
      color: #f4d0b1; font-size: 12px; font-weight: 650; letter-spacing: .04em;
    }
    main { max-width: 760px; padding: 28px 20px 46px; margin: auto; }
    nav { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; margin-bottom: 22px; }
    nav button {
      min-height: 46px; border: 1px solid var(--border); border-radius: 12px;
      background: white; color: var(--muted); font-size: 14px; font-weight: 700;
      cursor: pointer;
    }
    nav button.active { background: var(--navy); border-color: var(--navy); color: white; }
    h1 { margin: 0 0 8px; font-size: 27px; letter-spacing: -.025em; }
    h2 { margin: 0; font-size: 16px; }
    p { line-height: 1.55; }
    .intro { color: var(--muted); margin: 0 0 22px; }
    .card {
      background: white; border: 1px solid var(--border); border-radius: 17px;
      padding: 21px; margin: 16px 0; box-shadow: 0 5px 16px #14233408;
    }
    .card-title { display: flex; align-items: center; gap: 10px; margin-bottom: 18px; }
    .card-title .icon { color: var(--orange); font-size: 19px; }
    .eyebrow { color: var(--muted); font-size: 12px; font-weight: 750; letter-spacing: .08em; }
    label { display: block; font-size: 13px; font-weight: 650; margin: 14px 0 7px; }
    input, select {
      width: 100%; height: 48px; border: 1px solid var(--border); border-radius: 11px;
      background: #f8f9fa; color: var(--text); padding: 0 13px; font: inherit;
    }
    .input-wrap { position: relative; }
    .input-wrap input { padding-right: 50px; }
    .unit { position: absolute; right: 14px; top: 15px; color: var(--muted); font-size: 14px; }
    .help { margin: 8px 0 0; font-size: 12px; color: var(--muted); }
    .primary {
      width: 100%; height: 54px; margin-top: 3px; border: 0; border-radius: 12px;
      background: var(--orange); color: white; font-weight: 800; letter-spacing: .04em;
      cursor: pointer; font-size: 14px;
    }
    .notice {
      background: #fff6eb; color: #74420f; border: 1px solid #f5d6b7;
      border-radius: 12px; padding: 14px 16px; font-size: 13px; line-height: 1.5;
    }
    .notice strong { display: block; margin-bottom: 3px; }
    .error { display: none; color: #9c2525; background: #fff0ef; border-radius: 10px; padding: 12px; font-size: 13px; }
    #results { display: none; }
    .result-status { text-align: center; padding: 20px 10px; }
    .result-status .symbol { font-size: 34px; }
    .result-status h2 { margin: 8px; font-size: 19px; }
    .result-status p { color: var(--muted); margin: 0; font-size: 14px; }
    .metric { display: flex; justify-content: space-between; gap: 16px; padding: 13px 0; border-bottom: 1px solid var(--border); }
    .metric:last-child { border-bottom: 0; }
    .metric span { color: var(--muted); }
    .metric strong { text-align: right; }
    .list-item { padding: 16px 0; border-bottom: 1px solid var(--border); }
    .list-item:last-child { border: 0; padding-bottom: 0; }
    .list-item p { color: var(--muted); margin: 6px 0 0; font-size: 14px; }
    .empty { color: var(--muted); text-align: center; padding: 24px 12px; }
    .pill { display: inline-block; border-radius: 999px; padding: 5px 9px; background: #fff1e5; color: #9b4e0a; font-size: 11px; font-weight: 700; }
    .chat { background: #f4f6f8; padding: 16px; border-radius: 13px; color: #465361; }
    .chat strong { color: var(--navy); }
    footer { color: var(--muted); text-align: center; font-size: 12px; padding: 5px 0 20px; }
    [hidden] { display: none !important; }
    @media (max-width: 520px) {
      header { padding: 16px; }
      .demo-badge { font-size: 10px; padding: 6px 8px; }
      main { padding: 20px 14px 36px; }
      .card { padding: 17px; }
      h1 { font-size: 24px; }
    }
  </style>
</head>
<body>
  <header>
    <div class="brand"><div class="brand-mark">↗</div><span>RigAssist AI</span></div>
    <div class="demo-badge">BROWSER SAMPLE · NOT THE SWIFTUI APP</div>
  </header>
  <main>
    <nav aria-label="App sections">
      <button class="active" data-tab="calculator">ƒx &nbsp; Calculator</button>
      <button data-tab="reference">▤ &nbsp; Reference</button>
      <button data-tab="assistant">✦ &nbsp; Ask AI</button>
    </nav>
    <section id="calculator" class="view">
      <h1>Lift Calculator</h1>
      <p class="intro">Deterministic calculations based on the inputs you provide.</p>
      <div class="card">
        <div class="card-title"><span class="icon">◉</span><h2>LOAD</h2></div>
        <label for="load">Load Weight</label>
        <div class="input-wrap"><input id="load" inputmode="decimal" placeholder="Enter weight" value="8000"><span class="unit">lb</span></div>
      </div>
      <div class="card">
        <div class="card-title"><span class="icon">⛓</span><h2>SLING SETUP</h2></div>
        <label for="configuration">Configuration</label>
        <select id="configuration">
          <option value="vertical">Vertical Hitch</option>
          <option value="bridle">Two-Leg Bridle</option>
        </select>
        <label for="capacity">Rated Capacity Per Leg</label>
        <div class="input-wrap"><input id="capacity" inputmode="decimal" placeholder="Enter capacity" value="10000"><span class="unit">lb</span></div>
        <div id="angle-wrap" hidden>
          <label for="angle">Sling Angle From Horizontal</label>
          <div class="input-wrap"><input id="angle" inputmode="decimal" placeholder="30–90" value="60"><span class="unit">°</span></div>
          <p class="help">Supported range: 30° to 90°.</p>
        </div>
      </div>
      <p id="error" class="error" role="alert"></p>
      <button id="calculate" class="primary">ƒx &nbsp; CALCULATE</button>
      <div id="results" class="card" aria-live="polite">
        <div class="result-status">
          <div id="status-symbol" class="symbol"></div>
          <h2 id="status-title"></h2>
          <p id="utilization"></p>
        </div>
        <div class="eyebrow">CALCULATED VALUES</div>
        <div class="metric"><span>Load Per Leg</span><strong id="per-leg"></strong></div>
        <div class="metric"><span>Tension Per Leg</span><strong id="tension"></strong></div>
        <div class="metric"><span>Angle Multiplier</span><strong id="multiplier"></strong></div>
        <div class="metric"><span>Capacity Utilization</span><strong id="percent"></strong></div>
        <p class="help">Academic prototype: have a qualified person verify results before lift planning. Bridle estimates assume equal load sharing, equal angles, and a centered load. Dynamic and unequal loads are not modeled.</p>
      </div>
      <div class="notice"><strong>Safety Notice</strong>For learning and planning support only. Verify against original sources and applicable requirements; have a qualified person approve every lift. Never use this prototype as the sole basis for a lifting decision.</div>
    </section>
    <section id="reference" class="view" hidden>
      <h1>Reference Library</h1>
      <p class="intro">Searchable, locally bundled rigging references.</p>
      <div class="card">
        <div class="card-title"><span class="icon">▤</span><h2>LOCAL REFERENCES</h2></div>
        <div class="empty">
          <div style="font-size:30px;margin-bottom:8px">ⓘ</div>
          <strong>Reference content is currently unavailable</strong>
          <p>Bundled records are marked unverified, so the app intentionally does not display record content.</p>
        </div>
      </div>
      <div class="notice"><strong>Verification matters</strong>Reference records must be checked against their original source before they can be shown as verified guidance.</div>
    </section>
    <section id="assistant" class="view" hidden>
      <h1>Ask AI</h1>
      <p class="intro">Explanatory assistance grounded in approved references.</p>
      <div class="card">
        <div class="card-title"><span class="icon">✦</span><h2>REFERENCE-GROUNDED ASSISTANCE</h2></div>
        <div class="chat"><strong>Assistant</strong><p>No verified local reference content is currently available. No external AI provider is configured, so this sample cannot provide rigging guidance.</p></div>
      </div>
      <div class="notice"><strong>Not a calculation tool</strong>AI answers are not calculation results. Use the deterministic calculator for supported estimates and have a qualified person verify all lift plans.</div>
    </section>
    <footer>Browser demonstration only · no network requests · not for operational lift planning</footer>
  </main>
  <script>
    const config = document.querySelector("#configuration");
    const angleWrap = document.querySelector("#angle-wrap");
    const results = document.querySelector("#results");
    const error = document.querySelector("#error");
    const number = value => Number(value.trim());
    const format = value => Math.round(value).toLocaleString("en-US");

    config.addEventListener("change", () => {
      angleWrap.hidden = config.value !== "bridle";
      results.style.display = "none";
      error.style.display = "none";
    });

    document.querySelector("#calculate").addEventListener("click", () => {
      const load = number(document.querySelector("#load").value);
      const capacity = number(document.querySelector("#capacity").value);
      const angle = number(document.querySelector("#angle").value);
      let message = "";
      if (!Number.isFinite(load) || load <= 0 || !Number.isFinite(capacity) || capacity <= 0) {
        message = "Enter a valid load weight and rated capacity greater than zero.";
      } else if (config.value === "bridle" && (!Number.isFinite(angle) || angle < 30 || angle > 90)) {
        message = "Enter a valid sling angle from 30° to 90°.";
      }
      if (message) {
        error.textContent = message;
        error.style.display = "block";
        results.style.display = "none";
        return;
      }
      error.style.display = "none";
      const perLeg = config.value === "bridle" ? load / 2 : load;
      const multiplier = config.value === "bridle"
        ? (angle === 30 ? 2 : angle === 90 ? 1 : 1 / Math.sin(angle * Math.PI / 180))
        : 1;
      const tension = perLeg * multiplier;
      const utilization = tension / capacity;
      const within = tension <= capacity;
      document.querySelector("#status-symbol").textContent = within ? "✓" : "⚠";
      document.querySelector("#status-symbol").style.color = within ? "#25824b" : "#c63b32";
      document.querySelector("#status-title").textContent = within ? "Within Rated Capacity" : "Exceeds Rated Capacity";
      document.querySelector("#utilization").textContent = `${(utilization * 100).toFixed(1)}% capacity utilization`;
      document.querySelector("#per-leg").textContent = `${format(perLeg)} lb`;
      document.querySelector("#tension").textContent = `${format(tension)} lb`;
      document.querySelector("#multiplier").textContent = multiplier.toFixed(3);
      document.querySelector("#percent").textContent = `${(utilization * 100).toFixed(1)}%`;
      results.style.display = "block";
      results.scrollIntoView({ behavior: "smooth", block: "nearest" });
    });

    document.querySelectorAll("nav button").forEach(button => button.addEventListener("click", () => {
      document.querySelectorAll("nav button").forEach(item => item.classList.toggle("active", item === button));
      document.querySelectorAll(".view").forEach(section => section.hidden = section.id !== button.dataset.tab);
    }));
  </script>
</body>
</html>
"""


def build_core(repository: Path) -> None:
    swift = shutil.which("swift")
    if swift is None:
        raise RuntimeError("Swift is required for --build, but was not found on PATH.")
    print("Building the cross-platform RigAssistCore Swift package (not the SwiftUI app)...", flush=True)
    subprocess.run([swift, "build"], cwd=repository, check=True)


class PreviewHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path not in ("/", "/index.html"):
            self.send_error(404)
            return
        body = HTML.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format_string: str, *args: Any) -> None:
        print(f"[preview] {args[0]}", flush=True)


def capture_preview(server: ThreadingHTTPServer, output: Path, url: str) -> None:
    try:
        from PIL import Image
        from playwright.sync_api import Error as PlaywrightError, sync_playwright
    except ImportError as exc:
        raise RuntimeError(
            "Capture requires Pillow and Playwright. Install them with "
            "`python3 -m pip install Pillow playwright`, then run "
            "`python3 -m playwright install chromium`."
        ) from exc

    output.mkdir(parents=True, exist_ok=True)
    captures: list[Image.Image] = []
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch()
        page = browser.new_page(viewport={"width": 1365, "height": 1400}, device_scale_factor=1)
        page.goto(url, wait_until="networkidle")

        def save_frame(name: str) -> None:
            data = page.screenshot(path=str(output / name))
            captures.append(Image.open(BytesIO(data)).convert("RGB"))

        try:
            save_frame("calculator.png")
            page.locator("#configuration").select_option("bridle")
            save_frame("bridle-setup.png")
            page.locator("#calculate").click()
            page.wait_for_timeout(250)
            save_frame("calculation-results.png")
            page.locator('[data-tab="reference"]').click()
            save_frame("reference.png")
            page.locator('[data-tab="assistant"]').click()
            save_frame("ask-ai.png")
        except PlaywrightError as exc:
            raise RuntimeError(f"Browser automation failed: {exc}") from exc
        finally:
            browser.close()

    captures[0].save(
        output / "browser-sample.gif",
        save_all=True,
        append_images=captures[1:],
        duration=850,
        loop=0,
        optimize=True,
    )
    for frame in captures:
        frame.close()
    print(f"Saved screenshots and GIF to {output}", flush=True)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build RigAssistCore and serve a browser-based RigAssist AI sample."
    )
    parser.add_argument("--build", action="store_true", help="Run `swift build` before serving.")
    parser.add_argument("--capture", action="store_true", help="Capture PNG screenshots and an animated GIF.")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("browser-preview-output"),
        help="Capture output directory (default: ./browser-preview-output).",
    )
    parser.add_argument("--host", default="127.0.0.1", help="Preview server host (default: 127.0.0.1).")
    parser.add_argument("--port", type=int, default=8765, help="Preview server port (default: 8765).")
    args = parser.parse_args()

    repository = Path(__file__).resolve().parents[1]
    try:
        if args.build:
            build_core(repository)
        server = ThreadingHTTPServer((args.host, args.port), PreviewHandler)
    except (OSError, RuntimeError, subprocess.CalledProcessError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    url = f"http://{args.host}:{args.port}/"
    print(f"Browser sample: {url}", flush=True)
    print("This is a browser recreation; building/running the native SwiftUI app requires macOS and Xcode.", flush=True)

    if args.capture:
        thread = Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            capture_preview(server, args.output, url)
        except RuntimeError as exc:
            print(f"Capture failed: {exc}", file=sys.stderr)
            return 1
        finally:
            server.shutdown()
            server.server_close()
        return 0

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping browser sample.", flush=True)
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
