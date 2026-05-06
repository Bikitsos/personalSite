# Personal Site — Panayiotis Papallis

A small Flask-based personal website that introduces who I am and showcases a few of my side projects. Built with Python, Jinja2, and Tailwind (via CDN) — styled in an Apple-inspired *Liquid Glass* aesthetic.

Live tools showcased:
- [childhoodmovies.bikitsos.com](https://childhoodmovies.bikitsos.com)
- [whatismyip.bikitsos.com](https://whatismyip.bikitsos.com)
- [snaptrack.bikitsos.com](https://snaptrack.bikitsos.com)
- [bgremover.bikitsos.com](https://bgremover.bikitsos.com)

---

## Stack

- **Python 3.13** — managed by [uv](https://docs.astral.sh/uv/)
- **Flask 3** — minimal web framework
- **Jinja2** — server-side templating
- **Tailwind CSS** — utility classes via the Play CDN (no build step)
- **Inter** (Google Fonts) — typography fallback for non-Apple systems

## Project structure

```
personalSite/
├── app.py                 # Flask app + content data (BIO, PROJECTS, SKILL_GROUPS, CONTACTS)
├── pyproject.toml         # uv project + dependencies
├── uv.lock
├── .python-version
└── templates/
    ├── base.html          # Layout, fonts, glass CSS, aurora backdrop
    └── index.html         # Hero, work, expertise, contact sections
```

## Getting started

```bash
# Install dependencies into a local .venv
uv sync

# Run the dev server
uv run flask --app app run --debug
```

Then open <http://127.0.0.1:5000>.

## Editing content

All copy lives in [`app.py`](app.py) as plain Python data structures:

| Variable       | Purpose                                                |
| -------------- | ------------------------------------------------------ |
| `BIO`          | Name, title, location, tagline, about paragraph        |
| `CONTACTS`     | Email, LinkedIn, company links                         |
| `SKILL_GROUPS` | Categorized expertise (infra, networking, cloud, etc.) |
| `PROJECTS`     | Showcased websites (name, url, description)            |

Update any of these and refresh — no build step required.

---

## Deployment (Podman + Cloudflare Tunnel)

The site is designed to run on a Fedora server inside a single **Podman** container that also runs **cloudflared**, exposing the site over a [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) — no open inbound ports required.

### Files

| File             | Purpose                                                            |
| ---------------- | ------------------------------------------------------------------ |
| `Containerfile`  | Builds a Python 3.13 image with gunicorn + cloudflared             |
| `entrypoint.sh`  | Starts gunicorn and cloudflared together, with graceful shutdown   |
| `manage.sh`      | Lifecycle helper: build / start / stop / restart / logs / cleanup  |
| `.env.example`   | Template for the required `CLOUDFLARED_TOKEN`                      |

### One-time setup on the Fedora server

1. Install Podman: `sudo dnf install -y podman`
2. Create a Cloudflare Tunnel in **Cloudflare Zero Trust → Networks → Tunnels**, point it at `http://localhost:8000`, and copy the connector token.
3. Copy the project to the server (e.g. `git clone …`), then:
   ```bash
   cp .env.example .env
   # edit .env and set CLOUDFLARED_TOKEN=<your token>
   ```

### Lifecycle commands

```bash
./manage.sh build      # build the image
./manage.sh start      # build (if needed) + run detached (one-off)
./manage.sh logs       # follow logs from the container
./manage.sh status     # show container status
./manage.sh stop       # stop and remove the container
./manage.sh restart    # stop + start
./manage.sh install    # install as a systemd service — auto-start on boot (recommended)
./manage.sh uninstall  # remove the systemd service
./manage.sh cleanup    # remove container, image, and dangling layers
```

### Running it permanently (auto-start on boot)

For production use, install the container as a **rootless systemd service** via [Podman Quadlet](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) — the modern Fedora-recommended way:

```bash
./manage.sh install
```

This will:

1. Build the image if it doesn't exist.
2. Write a Quadlet unit to `~/.config/containers/systemd/personalsite.container`.
3. Enable **lingering** (`loginctl enable-linger $USER`) so the service runs even when you're logged out.
4. Reload user systemd and start `personalsite.service`.

Once installed, the container will:

- **Start automatically on boot.**
- **Restart on crash** (`Restart=always`, 5-second backoff).
- **Survive logout** thanks to user-linger.

Manage it with the standard systemd tools:

```bash
systemctl --user status  personalsite.service
systemctl --user restart personalsite.service
journalctl --user -u     personalsite.service -f
```

To remove the service: `./manage.sh uninstall`.

### How the container works

- **gunicorn** serves the Flask app on `0.0.0.0:8000` with 2 workers (override via `GUNICORN_WORKERS`).
- **cloudflared** runs alongside it inside the same container, connecting to Cloudflare with the supplied token.
- A small `entrypoint.sh` traps `SIGTERM`/`SIGINT` so `podman stop` cleanly terminates both processes.
- `tini` is used as PID 1 to reap zombie processes from the two background workers.
- The container runs as a non-root user (`appuser`, uid 1001).

---

## Design / CSS

The site uses an **Apple-inspired "Liquid Glass"** aesthetic — translucent, frosted-glass cards floating above a soft, slowly-drifting aurora backdrop. The look is implemented in [`templates/base.html`](templates/base.html) using a small set of custom CSS classes layered on top of Tailwind utilities.

### Typography

Apple system font stack with progressive fallbacks:

```
-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", "Segoe UI",
"Helvetica Neue", Helvetica, Arial, sans-serif
```

- **macOS / iOS** — renders as native **SF Pro**.
- **Windows** — falls through to **Inter** (loaded from Google Fonts), then **Segoe UI** as a final native fallback.
- **Linux / others** — Inter, then system sans-serif.

Two display variants are defined for hierarchy:

| Class                | Weight | Tracking   | Use                            |
| -------------------- | ------ | ---------- | ------------------------------ |
| `.font-display`      | 600    | -0.022em   | Headlines, section titles      |
| `.font-display-light`| 400    | -0.018em   | Manifesto sub-statements, links |

Negative letter-spacing matches Apple's tight optical kerning on `apple.com` headlines.

### Color palette

Intentionally muted and neutral — no saturated brand colors.

| Role             | Value                  | Notes                                |
| ---------------- | ---------------------- | ------------------------------------ |
| Background base  | `#f5f5f7`              | Apple's standard light gray          |
| Aurora blobs     | Cool/warm grays @ 40-50% alpha | Barely tinted, subtle depth          |
| Text primary     | `stone-900`            | High-contrast body and headlines     |
| Text secondary   | `stone-700` / `stone-600` | Sub-statements                       |
| Text tertiary    | `stone-500`            | Labels, metadata, captions           |
| Glass shadow     | `rgba(60, 60, 67, …)`  | Apple's neutral separator gray       |

### The aurora backdrop

The body has five overlapping radial gradients positioned around the viewport, fixed to the background and animated with a 45-second `@keyframes drift` that slides the background-position from `0% 0%` to `100% 100%`. This produces a slow, calm color shift that gives the glass surfaces something interesting to refract over.

### Glass surfaces

Three reusable classes power every translucent panel:

- **`.glass`** — primary card surface
  - `background: rgba(255, 255, 255, 0.55)`
  - `backdrop-filter: blur(28px) saturate(160%)`
  - 1px white border + soft drop shadow + inner highlight

- **`.glass-strong`** — used for the hero and contact slabs
  - Higher opacity (`0.7`) and stronger blur (`32px / 180% saturate`) for legibility on long text

- **`.glass-pill`** — small inline elements (nav, skill chips)
  - Lighter shadow, tighter blur, brighter border

All three include an `inset 0 1px 0 rgba(255,255,255,0.8)` pseudo-bevel — the same trick Apple uses to fake a top-edge specular highlight on glass.

### Hover specular highlight

`.glass-hover` adds a `::before` pseudo-element with a diagonal `linear-gradient(135deg, …)` of white-to-transparent stops. On hover the element lifts (`translateY(-2px)`) and the gradient fades in via `opacity` — mimicking a soft light catching the edge of a glass surface.

### Browser support

| Browser           | Glass blur | Notes                                          |
| ----------------- | ---------- | ---------------------------------------------- |
| Safari (mac/iOS)  | ✅          | Native, hardware-accelerated                   |
| Chrome / Edge     | ✅          | Full `backdrop-filter` support                 |
| Firefox 103+      | ✅          | Enabled by default                             |
| Older browsers    | Graceful degradation — translucent white panel without blur |

`backdrop-filter` runs on the GPU, so it remains smooth even on modest hardware. The aurora animation only animates `background-position`, which is also cheap to composite.

### Accessibility notes

- All interactive elements use semantic `<a>` tags with visible hover states.
- Color contrast: `stone-900` on the cream/white-frosted backgrounds passes WCAG AA for body text.
- The drift animation is slow (45s) and respects user motion preferences indirectly — it's purely background and never moves UI. (A `@media (prefers-reduced-motion)` guard could be added if desired.)

---

## License

Personal project — all content © Panayiotis Papallis.
