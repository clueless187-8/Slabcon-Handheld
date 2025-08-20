#!/usr/bin/env bash
set -euo pipefail

# ===== CONFIG =====
USER="clueless187-8"
REPO="slabcon"
YEAR="$(date +%Y)"

# ===== CREATE TREE =====
mkdir -p "$REPO"/{apps/handheld,services/powerd,hardware/cad,docs,tools}
cd "$REPO"

# ----- .gitignore -----
cat > .gitignore << 'EOF'
# OS/editor
.DS_Store
Thumbs.db
.vscode/
.idea/

# Python
__pycache__/
*.pyc
.venv/

# Node
node_modules/
dist/
.parcel-cache/
.sass-cache/
*.map

# CAD exports
hardware/cad/exports/
EOF

# ----- .nojekyll -----
: > .nojekyll

# ----- LICENSE (MIT) -----
cat > LICENSE <<EOF
MIT License

Copyright (c) ${YEAR} ${USER}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# ----- README.md -----
cat > README.md << 'EOF'
# Slabcon — Chapter 01: Dawn Board

A prestige‑edition Raspberry Pi handheld project. This repo contains:
- Handheld runtime (Python)
- Power daemon (graceful low‑voltage shutdown + long‑press)
- GitHub Pages site (interactive shelf)
- Parametric OpenSCAD suite with exploded views
- Release and export tools (BOM, STEP)

## Quick start
- Handheld runtime: see apps/handheld/ (pip install pygame gpiozero smbus2 pyyaml)
- Power daemon: services/powerd/
- Site: docs/ (GitHub Pages serves from /docs)
- CAD: hardware/cad/ (OpenSCAD), export scripts in tools/

## CAD Render Style Guide
- Background #0F0F0F, edges white, accent gold #C9A85C
- Camera 35° iso, Z‑up; subtle shadows
- Exploded: show_exploded = true, explode_factor ≈ 1.5

Each release is a chapter; each chapter gets a spine on the shelf.
EOF

# ===== DOCS (GitHub Pages: interactive shelf) =====

# ----- docs/index.html -----
cat > docs/index.html << 'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>Slabcon — Vault Shelf</title>
  <link rel="stylesheet" href="styles.css"/>
</head>
<body>
  <header>
    <h1>Slabcon — Vault Shelf</h1>
    <input id="q" type="search" placeholder="Search chapters, tags..."/>
  </header>
  <main id="shelf" class="shelf"></main>
  <div id="modal" class="modal hidden">
    <div class="card">
      <button id="close">×</button>
      <h2 id="m_title"></h2>
      <p id="m_desc"></p>
      <div id="m_meta"></div>
      <nav id="m_links"></nav>
    </div>
  </div>
  <footer>Each spine a heartbeat in the series.</footer>
  <script src="app.js"></script>
</body>
</html>
EOF

# ----- docs/styles.css -----
cat > docs/styles.css << 'EOF'
:root {
  --bg: #0f0f0f;
  --fg: #e6e6e6;
  --muted: #9aa0a6;
  --accent: #c9a85c;
  --card: #15151b;
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--fg); font: 16px/1.5 system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, sans-serif; }
header { display:flex; gap:1rem; align-items:center; padding: 1rem 1.5rem; border-bottom:1px solid #202028; }
h1 { font-size: 1.1rem; margin: 0; color: var(--accent); letter-spacing:.2px; }
#q { flex:1; background:#101016; border:1px solid #242434; color:var(--fg); padding:.6rem .8rem; border-radius:.5rem; }

.shelf { padding: 1.5rem; display:grid; grid-template-columns: repeat(auto-fill, minmax(160px,1fr)); gap: 1rem; }
.spine {
  background: linear-gradient(180deg, #1b1b24, #12121a);
  border: 1px solid #282838;
  border-radius: .6rem;
  height: 220px; padding: .8rem;
  display:flex; flex-direction:column; justify-content:space-between;
  transition: transform .08s ease, border-color .08s ease;
}
.spine:hover { transform: translateY(-2px); border-color: var(--accent); }
.spine .title { font-weight: 700; font-size: .95rem; }
.spine .meta { color: var(--muted); font-size: .8rem; }

.modal { position: fixed; inset:0; background: rgba(0,0,0,.6); display:flex; align-items:center; justify-content:center; }
.hidden { display:none; }
.card { width:min(720px, 92vw); background: var(--card); border:1px solid #2a2a3a; border-radius:.8rem; padding:1rem 1.2rem; position:relative; }
.card h2 { margin-top:0; }
.card #close { position:absolute; top:.6rem; right:.6rem; background:#202028; color:var(--fg); border:1px solid #2a2a3a; border-radius:.4rem; width:2rem; height:2rem; }
#m_meta { color: var(--muted); margin:.4rem 0 .8rem; font-size:.9rem; }
#m_links a { display:inline-block; margin:.2rem .4rem .2rem 0; padding:.4rem .6rem; background:#101016; border:1px solid #2a2a3a; border-radius:.4rem; color:var(--fg); text-decoration:none; }
footer { padding: 1rem 1.5rem; color: var(--muted); border-top:1px solid #202028; }
EOF

# ----- docs/app.js -----
cat > docs/app.js << 'EOF'
const state = { data: [], filtered: [] };

async function load() {
  const res = await fetch('releases.json');
  state.data = await res.json();
  state.filtered = state.data;
  render();
}

function render() {
  const shelf = document.getElementById('shelf');
  shelf.innerHTML = '';
  state.filtered.forEach((r) => {
    const el = document.createElement('button');
    el.className = 'spine';
    el.innerHTML = `
      <div class="title">${r.title}</div>
      <div class="meta">${r.version} • ${r.date}</div>
      <div class="meta">${r.tags.join(' • ')}</div>
    `;
    el.addEventListener('click', () => openModal(r));
    shelf.appendChild(el);
  });
}

function openModal(r) {
  document.getElementById('m_title').textContent = r.title;
  document.getElementById('m_desc').textContent = r.description;
  document.getElementById('m_meta').textContent = `${r.version} • ${r.date} • ${r.tags.join(', ')}`;
  const links = document.getElementById('m_links');
  links.innerHTML = '';
  r.links.forEach(l => {
    const a = document.createElement('a');
    a.href = l.href; a.target = '_blank'; a.textContent = l.label;
    links.appendChild(a);
  });
  document.getElementById('modal').classList.remove('hidden');
}

function filter(q) {
  const s = q.trim().toLowerCase();
  state.filtered = !s ? state.data : state.data.filter(r =>
    r.title.toLowerCase().includes(s) ||
    r.tags.join(' ').toLowerCase().includes(s) ||
    r.version.toLowerCase().includes(s)
  );
  render();
}

document.getElementById('q').addEventListener('input', (e) => filter(e.target.value));
document.getElementById('close').addEventListener('click', () => document.getElementById('modal').classList.add('hidden'));
window.addEventListener('keydown', (e) => { if (e.key === 'Escape') document.getElementById('modal').classList.add('hidden'); });

load();
EOF

# ----- docs/releases.json -----
cat > docs/releases.json << 'EOF'
[
  {
    "title": "Slabcon — Chapter 01: Dawn Board",
    "version": "v1.0.0",
    "date": "2025-08-20",
    "tags": ["handheld", "rpi", "launch"],
    "description": "First public chapter: stable runtime, power daemon, shelf site, and parametric SCAD.",
    "links": [
      { "label": "Source", "href": "https://github.com/YOUR_GITHUB_USERNAME/slabcon" },
      { "label": "Release", "href": "https://github.com/YOUR_GITHUB_USERNAME/slabcon/releases/tag/v1.0.0" }
    ]
  }
]
EOF

# ===== APPS: handheld runtime =====

# ----- apps/handheld/main.py -----
cat > apps/handheld/main.py << 'EOF'
#!/usr/bin/env python3
import signal, yaml
from pathlib import Path
from ui import UI
from inputs import InputManager
from sensors import SensorManager

RUN = True
def handle_signal(signum, frame):
    global RUN
    RUN = False
signal.signal(signal.SIGINT, handle_signal)
signal.signal(signal.SIGTERM, handle_signal)

def load_config():
    cfg_path = Path(__file__).with_name("config.yaml")
    if not cfg_path.exists():
        return {
            "fps": 60,
            "pins": {"btn_a": 5, "btn_b": 6, "btn_start": 13, "btn_select": 19},
            "battery": {"driver": "ina219", "warn_v": 3.55, "crit_v": 3.40},
            "theme": {"accent": [255,215,0], "bg": [10,10,14], "fg": [230,230,230]},
        }
    return yaml.safe_load(cfg_path.read_text())

def main():
    cfg = load_config()
    ui = UI(theme=cfg.get("theme", {}))
    im = InputManager(pins=cfg.get("pins", {}))
    sm = SensorManager(cfg.get("battery", {}))

    clock = ui.clock
    fps = cfg.get("fps", 60)

    while RUN:
        events = im.poll()
        if events.get("quit"): break

        batt = sm.read_battery()
        therm = sm.read_thermals()

        ui.draw_frame(
            status={
                "battery_percent": batt.get("percent"),
                "battery_voltage": batt.get("voltage"),
                "battery_state": batt.get("state"),
                "cpu_temp_c": therm.get("cpu_c"),
                "soc_load": therm.get("load"),
                "btns": events.get("buttons", {}),
            }
        )
        clock.tick(fps)

    ui.shutdown(); im.shutdown(); sm.shutdown()

if __name__ == "__main__":
    main()
EOF

# ----- apps/handheld/ui.py -----
cat > apps/handheld/ui.py << 'EOF'
import pygame

class UI:
    def __init__(self, theme=None, size=(800, 480)):
        self.theme = {"bg": (10,10,14), "fg": (230,230,230), "accent": (201,168,92)}
        if theme: self.theme.update({k: tuple(theme[k]) for k in theme})
        pygame.display.init(); pygame.font.init()
        flags = 0  # switch to pygame.FULLSCREEN on-device
        self.screen = pygame.display.set_mode(size, flags)
        pygame.display.set_caption("Slabcon — Chapter Runtime")
        self.font = pygame.font.SysFont("Menlo", 22)
        self.clock = pygame.time.Clock()

    def draw_bar(self, x, y, w, h, pct, color):
        import pygame
        pygame.draw.rect(self.screen, (60,60,70), (x, y, w, h), border_radius=6)
        pygame.draw.rect(self.screen, color, (x, y, int(w*max(0.0,min(1.0,pct or 0))), h), border_radius=6)

    def draw_text(self, txt, x, y, color=None):
        surf = self.font.render(txt, True, color or self.theme["fg"]); self.screen.blit(surf, (x, y))

    def draw_frame(self, status):
        import pygame
        self.screen.fill(self.theme["bg"])
        bp = status.get("battery_percent") or 0.0
        bv = status.get("battery_voltage") or 0.0
        bs = status.get("battery_state") or "—"
        color = (120,200,80) if bp > 0.3 else (230,100,80)
        self.draw_text("Power", 40, 30, self.theme["accent"])
        self.draw_bar(40, 60, 300, 20, bp, color)
        self.draw_text(f"{int(bp*100)}%  {bv:.2f} V  {bs}", 40, 90)
        cpu = status.get("cpu_temp_c") or 0.0
        load = status.get("soc_load") or 0.0
        self.draw_text("Thermals", 40, 140, self.theme["accent"])
        self.draw_text(f"CPU {cpu:.1f} °C  Load {load:.2f}", 40, 170)
        btns = status.get("btns", {})
        self.draw_text("Inputs", 40, 220, self.theme["accent"])
        self.draw_text(f"A:{int(btns.get('a',0))} B:{int(btns.get('b',0))} Start:{int(btns.get('start',0))} Select:{int(btns.get('select',0))}", 40, 250)
        self.draw_text("Slabcon — Chapter Runtime", 40, 420, (150,150,160))
        pygame.display.flip()

    def shutdown(self):
        pygame.quit()
EOF

# ----- apps/handheld/inputs.py -----
cat > apps/handheld/inputs.py << 'EOF'
try:
    from gpiozero import Button
except Exception:
    Button = None
import pygame

class InputManager:
    def __init__(self, pins):
        self.buttons = {}
        if Button:
            self.buttons = {
                "a": Button(pins.get("btn_a", 5), pull_up=True),
                "b": Button(pins.get("btn_b", 6), pull_up=True),
                "start": Button(pins.get("btn_start", 13), pull_up=True),
                "select": Button(pins.get("btn_select", 19), pull_up=True),
            }
        pygame.event.set_allowed([pygame.QUIT, pygame.KEYDOWN, pygame.KEYUP])

    def poll(self):
        events = {"buttons": {}, "quit": False}
        if self.buttons:
            for k, btn in self.buttons.items():
                events["buttons"][k] = int(btn.is_pressed)
        for e in pygame.event.get():
            if e.type == pygame.QUIT: events["quit"] = True
            elif e.type in (pygame.KEYDOWN, pygame.KEYUP):
                pressed = e.type == pygame.KEYDOWN
                if e.key == pygame.K_q and pressed: events["quit"] = True
                if e.key == pygame.K_z: events["buttons"]["a"] = int(pressed)
                if e.key == pygame.K_x: events["buttons"]["b"] = int(pressed)
                if e.key == pygame.K_RETURN: events["buttons"]["start"] = int(pressed)
                if e.key == pygame.K_RSHIFT: events["buttons"]["select"] = int(pressed)
        return events

    def shutdown(self): pass
EOF

# ----- apps/handheld/sensors.py -----
cat > apps/handheld/sensors.py << 'EOF'
from collections import deque

class SensorManager:
    def __init__(self, batt_cfg):
        self.batt_driver = batt_cfg.get("driver", "ina219")
        self.warn_v = batt_cfg.get("warn_v", 3.55)
        self.crit_v = batt_cfg.get("crit_v", 3.40)
        self.load_hist = deque(maxlen=30)
        self._ina = None
        if self.batt_driver == "ina219":
            try:
                from ina219 import INA219
                self._ina = INA219(0.1); self._ina.configure()
            except Exception:
                self._ina = None

    def read_battery(self):
        v = None
        if self._ina:
            try: v = self._ina.voltage()
            except Exception: v = None
        if v is None: v = 3.9
        percent = max(0.0, min(1.0, (v - 3.3) / (4.15 - 3.3)))
        state = "ok"
        if v <= self.crit_v: state = "critical"
        elif v <= self.warn_v: state = "warning"
        return {"voltage": v, "percent": percent, "state": state}

    def read_thermals(self):
        try:
            with open("/sys/class/thermal/thermal_zone0/temp") as f:
                cpu_c = float(f.read().strip())/1000.0
        except Exception:
            cpu_c = 45.0
        try:
            with open("/proc/loadavg") as f:
                load = float(f.read().split()[0])
        except Exception:
            load = 0.2
        self.load_hist.append(load)
        ema = sum(self.load_hist)/len(self.load_hist)
        return {"cpu_c": cpu_c, "load": ema}

    def shutdown(self): pass
EOF

# ----- apps/handheld/config.yaml -----
cat > apps/handheld/config.yaml << 'EOF'
fps: 60
pins:
  btn_a: 5
  btn_b: 6
  btn_start: 13
  btn_select: 19
battery:
  driver: ina219
  warn_v: 3.55
  crit_v: 3.40
theme:
  accent: [201, 168, 92]
  bg: [10, 10, 14]
  fg: [230, 230, 230]
EOF

# ===== SERVICES: power daemon =====

# ----- services/powerd/powerd.py -----
cat > services/powerd/powerd.py << 'EOF'
#!/usr/bin/env python3
import time, os, signal
from statistics import median
try:
    from gpiozero import Button
except Exception:
    Button = None
try:
    from ina219 import INA219
except Exception:
    INA219 = None

RUN = True
def handle_signal(signum, frame):
    global RUN; RUN = False
signal.signal(signal.SIGINT, handle_signal)
signal.signal(signal.SIGTERM, handle_signal)

class PowerDaemon:
    def __init__(self, cfg=None):
        cfg = cfg or {}
        self.longpress_sec = cfg.get("longpress_sec", 2.0)
        self.crit_v = cfg.get("crit_v", 3.40)
        self.hyst = cfg.get("hyst", 0.03)
        self.check_period = cfg.get("check_period", 1.0)
        self._init_button(cfg.get("pin_button", 26))
        self._init_battery()

    def _init_button(self, pin):
        self.button = None
        if Button:
            try:
                self.button = Button(pin, pull_up=True, hold_time=self.longpress_sec)
                self.button.when_held = lambda: self.shutdown("long-press")
            except Exception:
                self.button = None

    def _init_battery(self):
        self.ina = None
        if INA219:
            try:
                self.ina = INA219(0.1); self.ina.configure()
            except Exception:
                self.ina = None

    def read_voltage(self):
        if self.ina:
            try: return self.ina.voltage()
            except Exception: return None
        return None

    def shutdown(self, reason):
        print(f"[powerd] Shutdown requested: {reason}", flush=True)
        os.system("sudo shutdown -h now")

    def loop(self):
        vwindow = []; low_latched = False
        while RUN:
            v = self.read_voltage()
            if v is not None:
                vwindow.append(v); vwindow = vwindow[-10:]
                vmed = median(vwindow)
                if not low_latched and vmed <= self.crit_v:
                    low_latched = True; self.shutdown(f"battery {vmed:.2f}V <= {self.crit_v:.2f}V")
                elif low_latched and vmed >= self.crit_v + self.hyst:
                    low_latched = False
            time.sleep(self.check_period)

if __name__ == "__main__":
    PowerDaemon().loop()
EOF

# ----- services/powerd/powerd.service -----
cat > services/powerd/powerd.service << 'EOF'
[Unit]
Description=Slabcon Power Daemon
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/env python3 /home/pi/slabcon/services/powerd/powerd.py
Restart=on-failure
RestartSec=2
User=root

[Install]
WantedBy=multi-user.target
EOF

# ===== HARDWARE: OpenSCAD suite =====

# ----- hardware/cad/slabcon_params.scad -----
cat > hardware/cad/slabcon_params.scad << 'EOF'
// ===== Slabcon — parameters (Rev01-A) =====
shell_w = 220; shell_h = 95; shell_t = 22; corner_r = 10;
top_thk = 6.0; bot_thk = shell_t - top_thk;
wall_t = 2.4; rib_t = 2.0;
screen_w = 165; screen_h = 75; bezel_t = 6; lens_th = 1.5; lens_lip = 1.2;
pcb_w = 200; pcb_h = 80; pcb_t = 1.6; pcb_z = 5.0;
screw_nom = "M2"; screw_clear_d = 2.4; screw_pilot_d = 1.7; boss_outer_d = 6.0; boss_height = 6.0;
post_offset_x = 12; post_offset_y = 12; post_outer_d = 7.5; post_hole_d = screw_clear_d;
dpad_d = 18; btn_d = 12; stick_d = 17; btn_spacing = 14;
dpad_pos = [-(shell_w/2) + 40, 0, 0];
abxy_center = [ (shell_w/2) - 44, 0, 0];
stick_left  = [-(shell_w/2) + 58, -22, 0];
stick_right = [ (shell_w/2) - 58, -22, 0];
usb_c_w = 9.0; usb_c_h = 3.2; hdmi_w = 14.0; hdmi_h = 4.8; audio_d = 6.0; microsd_w = 15.0; microsd_h = 2.0;
grille_w = 30; grille_h = 6; grille_slots = 7; grille_gap = 2.4;
fit_gap = 0.25; snap_gap = 0.15;
explode_gap = 15;
EOF

# ----- hardware/cad/slabcon_lib.scad -----
cat > hardware/cad/slabcon_lib.scad << 'EOF'
// ===== Slabcon — utilities =====
module rounded_rect2d(w, h, r){ offset(r) square([w-2*r,h-2*r], center=true); }
module rounded_rect3d(w, h, r, th){ linear_extrude(height=th) rounded_rect2d(w,h,r); }
module cavity_outline2d(ow,oh,r,wall){ rounded_rect2d(ow-2*wall, oh-2*wall, max(r-wall,0)); }
module screw_boss(d_outer,d_hole,h){ difference(){ cylinder(d=d_outer,h=h,$fn=48); translate([0,0,-0.1]) cylinder(d=d_hole,h=h+0.2,$fn=36);} }
module countersink(d_top,d_shank,depth){ difference(){ cylinder(d=d_top,h=depth,$fn=48); translate([0,0,-0.1]) cylinder(d=d_shank,h=depth+0.2,$fn=36);} }
module slot_grille(w,h,slots=7,gap=2.0,slot_h=1.2,r=1.0){
  intersection(){ rounded_rect3d(w,h,r,2);
    for(i=[0:slots-1]) translate([-w/2,-h/2+gap/2+i*(slot_h+gap),0]) cube([w,slot_h,3],center=false);
  }
}
module dot_grille2d(w,h,pitch=3.0,d=1.2){ for(x=[-w/2+pitch/2:pitch:w/2-pitch/2]) for(y=[-h/2+pitch/2:pitch:h/2-pitch/2]) translate([x,y]) circle(d=d,$fn=24); }
module at_inner_corners(inn_w,inn_h,off_x,off_y){ for(sx=[-1,1]) for(sy=[-1,1]) translate([sx*(inn_w/2-off_x), sy*(inn_h/2-off_y),0]) children(); }
module cut_through(shape_h=100){ translate([0,0,-shape_h/2]) linear_extrude(height=shape_h) children(); }
EOF

# ----- hardware/cad/slabcon_controls.scad -----
cat > hardware/cad/slabcon_controls.scad << 'EOF'
include <slabcon_params.scad>;
include <slabcon_lib.scad>;
module controls_cutouts_top(){
  translate([dpad_pos[0], dpad_pos[1], 0]) cylinder(d=dpad_d+fit_gap, h=100, center=true);
  translate([abxy_center[0], abxy_center[1], 0]){
    for(p=[[-btn_spacing/2, btn_spacing/2],[btn_spacing/2, btn_spacing/2],[-btn_spacing/2,-btn_spacing/2],[btn_spacing/2,-btn_spacing/2]])
      translate([p[0],p[1],0]) cylinder(d=btn_d+fit_gap, h=100, center=true);
  }
  translate([stick_left[0], stick_left[1], 0])  cylinder(d=stick_d+fit_gap, h=100, center=true);
  translate([stick_right[0], stick_right[1], 0]) cylinder(d=stick_d+fit_gap, h=100, center=true);
  for(sx=[-1,1]) translate([sx*(shell_w/2-38), -shell_h/2+20, 0]) slot_grille(grille_w,grille_h,grille_slots,grille_gap,slot_h=1.4,r=1.5);
}
module ports_cutouts_bottom(){
  translate([0,-shell_h/2-0.1, bot_thk/2]) rotate([90,0,0]) cube([usb_c_w+0.6, usb_c_h+0.6, 6], center=true);
  translate([ shell_w/2+0.1, -10, bot_thk/2]) rotate([0,90,0]) cube([hdmi_w+0.6, hdmi_h+0.6, 6], center=true);
  translate([-shell_w/2-0.1, -12, bot_thk/2]) rotate([0,90,0]) cylinder(d=audio_d+0.5, h=6, center=true, $fn=48);
  translate([30,-shell_h/2-0.1, bot_thk/2]) rotate([90,0,0]) cube([microsd_w+0.6, microsd_h+0.6, 6], center=true);
}
EOF

# ----- hardware/cad/slabcon_top.scad -----
cat > hardware/cad/slabcon_top.scad << 'EOF'
include <slabcon_params.scad>;
include <slabcon_lib.scad>;
include <slabcon_controls.scad>;
module top_shell(){
  difference(){
    rounded_rect3d(shell_w, shell_h, corner_r, top_thk);
    translate([0,0,fit_gap]) rounded_rect3d(shell_w-2*wall_t, shell_h-2*wall_t, max(corner_r-wall_t,0), top_thk);
    cut_through() translate([0,8,0]) rounded_rect2d(screen_w, screen_h, 3);
    controls_cutouts_top();
    translate([0,8, top_thk-lens_lip]) linear_extrude(height=lens_lip+0.2) rounded_rect2d(screen_w+2*bezel_t, screen_h+2*bezel_t, 4.5);
  }
}
module top_bosses(){
  inner_w = shell_w-2*wall_t; inner_h = shell_h-2*wall_t;
  translate([0,0, top_thk-boss_height])
  at_inner_corners(inner_w, inner_h, post_offset_x, post_offset_y)
    screw_boss(boss_outer_d, screw_pilot_d, boss_height);
}
module part_top(){ union(){ top_shell(); top_bosses(); } }
EOF

# ----- hardware/cad/slabcon_bottom.scad -----
cat > hardware/cad/slabcon_bottom.scad << 'EOF'
include <slabcon_params.scad>;
include <slabcon_lib.scad>;
include <slabcon_controls.scad>;
module bottom_tray(){
  outer = rounded_rect3d(shell_w, shell_h, corner_r, bot_thk);
  inner = translate([0,0,wall_t]) rounded_rect3d(shell_w-2*wall_t, shell_h-2*wall_t, max(corner_r-wall_t,0), bot_thk);
  difference(){
    outer; inner;
    translate([0,0,0]) controls_cutouts_top();
    ports_cutouts_bottom();
    inner_w = shell_w-2*wall_t; inner_h = shell_h-2*wall_t;
    at_inner_corners(inner_w, inner_h, post_offset_x, post_offset_y)
      translate([0,0,-0.1]) cylinder(d=screw_clear_d, h=bot_thk+0.2, $fn=36);
  }
}
module pcb_standoffs(){
  for (sx=[-1,1]) for (sy=[-1,1])
    translate([sx*(pcb_w/2-6), sy*(pcb_h/2-6), wall_t+pcb_z-pcb_t/2]) screw_boss(5.5, 2.1, pcb_z-1.0);
}
module corner_posts(){
  inner_w = shell_w-2*wall_t; inner_h = shell_h-2*wall_t;
  at_inner_corners(inner_w, inner_h, post_offset_x, post_offset_y) cylinder(d=post_outer_d, h=bot_thk-0.6, $fn=48);
}
module part_bottom(){ union(){ bottom_tray(); pcb_standoffs(); corner_posts(); } }
EOF

# ----- hardware/cad/slabcon_lens.scad -----
cat > hardware/cad/slabcon_lens.scad << 'EOF'
include <slabcon_params.scad>;
include <slabcon_lib.scad>;
module part_lens(){ translate([0,8,0]) rounded_rect3d(screen_w+2*bezel_t-0.3, screen_h+2*bezel_t-0.3, 4.0, lens_th); }
EOF

# ----- hardware/cad/slabcon_pcb_dummy.scad -----
cat > hardware/cad/slabcon_pcb_dummy.scad << 'EOF'
include <slabcon_params.scad>;
module part_pcb_dummy(){ color([0.04,0.35,0.10]) translate([0,0, 2.4 + 5.0 - 0.8]) cube([200,80,1.6], center=true); }
EOF

# ----- hardware/cad/slabcon_assembly.scad -----
cat > hardware/cad/slabcon_assembly.scad << 'EOF'
// ===== Slabcon — assembly =====
include <slabcon_params.scad>;
include <slabcon_lib.scad>;
include <slabcon_top.scad>;
include <slabcon_bottom.scad>;
include <slabcon_lens.scad>;
include <slabcon_pcb_dummy.scad>;

// Style lock
$fa = 1; $fs = 0.5;
bg_color = [15/255,15/255,15/255];
background(bg_color);
show_top = true; show_bottom = true; show_lens = true; show_pcb = true;
show_exploded = true; explode_factor = 1.5;

z0_top  = bot_thk + 0;
z0_lens = bot_thk + top_thk - lens_th - 0.2;
z0_pcb  = 2.4 + 5.0 - 0.8;

function EZ(n) = show_exploded ? n*explode_factor : 0;

module assembly(){
  if (show_bottom) translate([0,0, 0 - EZ(explode_gap)]) color("gainsboro") part_bottom();
  if (show_pcb)    translate([0,0, z0_pcb]) color("green") part_pcb_dummy();
  if (show_lens)   translate([0,0, z0_lens + EZ(explode_gap*1.2)]) color([0.95,0.97,1.0,0.6]) part_lens();
  if (show_top)    translate([0,0, z0_top + EZ(explode_gap*2.2)]) color("lightgray") part_top();
}
assembly();
EOF

# ===== TOOLS =====

# ----- tools/bom_to_md.py -----
cat > tools/bom_to_md.py << 'EOF'
#!/usr/bin/env python3
import csv, sys
def bom_to_md(csv_path, md_path):
    rows = list(csv.DictReader(open(csv_path, newline=''), skipinitialspace=True))
    cols = ["Category","Item","Specification / Description","Qty","Manufacturer","Part Number","Supplier","Unit Price","Total Price","Notes"]
    with open(md_path,"w") as f:
        f.write("| " + " | ".join(cols) + " |\n")
        f.write("| " + " | ".join(["---"]*len(cols)) + " |\n")
        for r in rows:
            f.write("| " + " | ".join((r.get(c,"") or "").replace("|","\\|") for c in cols) + " |\n")
    print(f"Wrote {md_path}")
if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: bom_to_md.py bom.csv bom.md"); sys.exit(1)
    bom_to_md(sys.argv[1], sys.argv[2])
EOF
chmod +x tools/bom_to_md.py

# ----- tools/pack_release.py -----
cat > tools/pack_release.py << 'EOF'
#!/usr/bin/env python3
import json, shutil, pathlib, sys, datetime
ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "dist"
def clean():
    if OUT.exists(): shutil.rmtree(OUT)
    OUT.mkdir(parents=True, exist_ok=True)
def write_manifest(tag):
    manifest = {
        "tag": tag,
        "date": datetime.date.today().isoformat(),
        "paths": ["apps/handheld", "services/powerd", "hardware/cad", "docs", "tools"]
    }
    (OUT / f"{tag}.json").write_text(json.dumps(manifest, indent=2))
def main():
    if len(sys.argv) < 2:
        print("Usage: pack_release.py vX.Y.Z"); sys.exit(1)
    clean(); write_manifest(sys.argv[1])
    print(f"Prepared {OUT} for {sys.argv[1]}. Create a GitHub release and upload artifacts.")
if __name__ == "__main__":
    main()
EOF
chmod +x tools/pack_release.py

# ----- tools/batch_step_export.sh -----
cat > tools/batch_step_export.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
SRC_DIR="hardware/cad"
OUT_DIR="$SRC_DIR/exports/step"
mkdir -p "$OUT_DIR"
PARTS=( "slabcon_top.scad" "slabcon_bottom.scad" "slabcon_lens.scad" "slabcon_pcb_dummy.scad" )
ASSEMBLY="slabcon_assembly.scad"
echo "🔧 Exporting parts..."
for part in "${PARTS[@]}"; do
  name="${part%.*}"
  openscad -o "$OUT_DIR/${name}.step" "$SRC_DIR/$part"
done
echo "🎯 Exporting assembly (assembled)..."
openscad -D show_exploded=false -o "$OUT_DIR/slabcon_assembled.step" "$SRC_DIR/$ASSEMBLY"
echo "💥 Exporting assembly (exploded)..."
openscad -D show_exploded=true -D explode_factor=1.5 -o "$OUT_DIR/slabcon_exploded.step" "$SRC_DIR/$ASSEMBLY"
echo "📦 STEP exports at $OUT_DIR"
EOF
chmod +x tools/batch_step_export.sh

# ===== GIT INIT / PUSH / PAGES =====
git init
git add .
git commit -m "Chapter 01: Initial public release — runtime, powerd, site, SCAD, tools"

if command -v gh >/dev/null 2>&1; then
  gh repo create "$REPO" --public --source=. --remote=origin --push
  git branch -M main
  git push -u origin main
  # Enable Pages from /docs
  gh api -X POST "repos/$USER/$REPO/pages" -f source[branch]='main' -f source[path]='/docs' >/dev/null 2>&1 || true
  echo "Pages: https://$USER.github.io/$REPO"
else
  echo "gh not found; repo created locally. Add remote and push when ready."
fi

echo "Done. Repo at: $(pwd)"
