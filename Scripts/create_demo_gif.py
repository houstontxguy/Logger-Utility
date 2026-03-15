#!/usr/bin/env python3
"""Generate a demo GIF showing the Ask AI workflow in Logger Utility."""

from PIL import Image, ImageDraw, ImageFont
import struct
import io
import os

# Colors (dark mode macOS style)
BG = (30, 30, 30)
BG_ALT = (38, 38, 38)
HEADER_BG = (45, 45, 45)
TOOLBAR_BG = (50, 50, 50)
BORDER = (60, 60, 60)
TEXT = (230, 230, 230)
TEXT_DIM = (140, 140, 140)
ACCENT = (50, 130, 246)  # blue
WHITE = (255, 255, 255)
ERROR_COLOR = (255, 149, 0)  # orange
FAULT_COLOR = (255, 69, 58)  # red
INFO_COLOR = (50, 130, 246)
DEBUG_COLOR = (142, 142, 147)
DEFAULT_COLOR = (230, 230, 230)
HIGHLIGHT = (50, 80, 140)
MENU_BG = (55, 55, 55)
MENU_HOVER = (50, 130, 246)
GROUPBOX_BG = (42, 42, 42)
TITLE_BAR = (42, 42, 42)
TITLE_TEXT = (180, 180, 180)
GREEN_DOT = (52, 199, 89)
YELLOW_DOT = (255, 204, 0)
RED_DOT = (255, 69, 58)

W, H = 800, 500

def get_font(size=12, bold=False):
    """Try to load a system font, fall back to default."""
    paths = [
        "/System/Library/Fonts/SFMono-Regular.otf",
        "/System/Library/Fonts/Menlo.ttc",
        "/System/Library/Fonts/Monaco.dfont",
    ]
    bold_paths = [
        "/System/Library/Fonts/SFMono-Bold.otf",
        "/System/Library/Fonts/Menlo.ttc",
    ]
    for p in (bold_paths if bold else paths):
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size)
            except Exception:
                continue
    return ImageFont.load_default()

FONT = get_font(11)
FONT_SM = get_font(10)
FONT_BOLD = get_font(11, bold=True)
FONT_TITLE = get_font(13, bold=True)
FONT_HEADER = get_font(10, bold=True)

# Log entries data
LOG_ENTRIES = [
    ("10:42:01.334", "Info",    "bluetoothd",  "321", "com.apple.bluetooth", "Session", "Connection established to peripheral"),
    ("10:42:01.891", "Default", "kernel",      "0",   "",                    "",        "IOService::terminate called"),
    ("10:42:02.115", "Debug",   "WiFiAgent",   "445", "com.apple.wifi",      "Scan",    "Channel scan complete, 12 networks found"),
    ("10:42:02.773", "Error",   "coreauthd",   "198", "com.apple.security",  "Auth",    "Failed to verify credential: errSecAuthFailed (-25293)"),
    ("10:42:03.001", "Info",    "loginwindow", "102", "com.apple.login",     "Session", "User session active, idle timer reset"),
    ("10:42:03.445", "Default", "mds_stores",  "511", "com.apple.spotlight", "Index",   "Indexing volume: Macintosh HD"),
    ("10:42:03.890", "Fault",   "kernel",      "0",   "com.apple.kernel",    "VM",      "Page fault at address 0x7fff204a1000"),
    ("10:42:04.112", "Info",    "powerd",      "88",  "com.apple.powerd",    "Sleep",   "Assertion created: PreventUserIdleSystemSleep"),
]

COL_X = [10, 120, 180, 260, 300, 450, 520]  # timestamp, level, process, pid, subsystem, category, message
COL_LABELS = ["Timestamp", "Level", "Process", "PID", "Subsystem", "Category", "Message"]

def level_color(level):
    return {"Info": INFO_COLOR, "Error": ERROR_COLOR, "Fault": FAULT_COLOR,
            "Debug": DEBUG_COLOR, "Default": DEFAULT_COLOR}.get(level, TEXT)

def draw_title_bar(draw):
    draw.rectangle([0, 0, W, 28], fill=TITLE_BAR)
    # Traffic lights
    draw.ellipse([8, 8, 20, 20], fill=RED_DOT)
    draw.ellipse([26, 8, 38, 20], fill=YELLOW_DOT)
    draw.ellipse([44, 8, 56, 20], fill=GREEN_DOT)
    draw.text((W // 2 - 50, 6), "Logger Utility", fill=TITLE_TEXT, font=FONT_BOLD)
    draw.line([0, 28, W, 28], fill=BORDER)

def draw_toolbar(draw):
    y = 29
    draw.rectangle([0, y, W, y + 32], fill=TOOLBAR_BG)
    # Tab indicators
    draw.rectangle([10, y + 6, 80, y + 26], fill=ACCENT, outline=ACCENT)
    draw.text((22, y + 9), "Stream", fill=WHITE, font=FONT_SM)
    draw.rectangle([90, y + 6, 170, y + 26], outline=BORDER)
    draw.text((100, y + 9), "Historical", fill=TEXT_DIM, font=FONT_SM)
    # Status
    draw.ellipse([W - 100, y + 11, W - 92, y + 19], fill=GREEN_DOT)
    draw.text((W - 88, y + 8), "Streaming", fill=GREEN_DOT, font=FONT_SM)
    draw.line([0, y + 32, W, y + 32], fill=BORDER)

def draw_table_header(draw):
    y = 62
    draw.rectangle([0, y, W, y + 22], fill=HEADER_BG)
    for i, label in enumerate(COL_LABELS):
        x = COL_X[i] if i < len(COL_X) else COL_X[-1]
        draw.text((x, y + 4), label, fill=TEXT_DIM, font=FONT_HEADER)
    draw.line([0, y + 22, W, y + 22], fill=BORDER)

def draw_log_row(draw, y, entry, selected=False, hover=False):
    bg = HIGHLIGHT if selected else (BG_ALT if hover else BG)
    row_h = 20
    draw.rectangle([0, y, W, y + row_h], fill=bg)
    ts, level, proc, pid, sub, cat, msg = entry
    draw.text((COL_X[0], y + 3), ts, fill=TEXT, font=FONT)
    draw.text((COL_X[1], y + 3), level, fill=level_color(level), font=FONT_BOLD)
    draw.text((COL_X[2], y + 3), proc, fill=TEXT, font=FONT)
    draw.text((COL_X[3], y + 3), pid, fill=TEXT, font=FONT)
    draw.text((COL_X[4], y + 3), sub, fill=TEXT_DIM, font=FONT)
    draw.text((COL_X[5], y + 3), cat, fill=TEXT_DIM, font=FONT)
    draw.text((COL_X[6], y + 3), msg[:40], fill=TEXT, font=FONT)

def draw_status_bar(draw):
    y = H - 24
    draw.rectangle([0, y, W, H], fill=TOOLBAR_BG)
    draw.line([0, y, W, y], fill=BORDER)
    draw.text((10, y + 5), "8 entries  |  12.4 entries/sec  |  Buffer: 8/100,000", fill=TEXT_DIM, font=FONT_SM)

def draw_context_menu(draw, x, y, items, hover_idx=-1):
    menu_w = 260
    item_h = 24
    pad = 6
    total_h = len(items) * item_h + pad * 2
    # Shadow
    draw.rectangle([x + 3, y + 3, x + menu_w + 3, y + total_h + 3], fill=(0, 0, 0, 80))
    # Menu background
    draw.rounded_rectangle([x, y, x + menu_w, y + total_h], radius=6, fill=MENU_BG, outline=BORDER)
    for i, item in enumerate(items):
        iy = y + pad + i * item_h
        if item == "---":
            draw.line([x + 10, iy + item_h // 2, x + menu_w - 10, iy + item_h // 2], fill=BORDER)
        else:
            if i == hover_idx:
                draw.rounded_rectangle([x + 4, iy, x + menu_w - 4, iy + item_h - 2], radius=4, fill=MENU_HOVER)
                draw.text((x + 14, iy + 4), item, fill=WHITE, font=FONT)
            else:
                draw.text((x + 14, iy + 4), item, fill=TEXT, font=FONT)

def draw_detail_panel(draw, entry, show_ai_section=True):
    """Draw the detail panel on the right side."""
    panel_x = 560
    draw.rectangle([panel_x, 62, W, H - 24], fill=BG)
    draw.line([panel_x, 62, panel_x, H - 24], fill=BORDER)

    y = 72
    if show_ai_section:
        # GroupBox
        draw.rounded_rectangle([panel_x + 8, y, W - 8, y + 55], radius=6, fill=GROUPBOX_BG, outline=BORDER)
        draw.text((panel_x + 16, y + 4), "Ask AI", fill=TEXT_DIM, font=FONT_SM)
        # Buttons
        draw.rounded_rectangle([panel_x + 16, y + 22, panel_x + 145, y + 42], radius=4, fill=(60, 60, 60), outline=BORDER)
        draw.text((panel_x + 22, y + 26), "Ask AI (Perplexity)", fill=TEXT, font=FONT_SM)
        draw.rounded_rectangle([panel_x + 150, y + 22, panel_x + 195, y + 42], radius=4, fill=(60, 60, 60), outline=BORDER)
        draw.text((panel_x + 158, y + 26), "Open", fill=TEXT, font=FONT_SM)
        y += 65

    draw.line([panel_x + 8, y, W - 8, y], fill=BORDER)
    y += 8

    ts, level, proc, pid, sub, cat, msg = entry
    fields = [
        ("Message", msg),
        ("Level", level),
        ("Process", f"{proc} ({pid})"),
        ("Subsystem", sub),
    ]
    for label, val in fields:
        if val:
            draw.text((panel_x + 12, y), label, fill=TEXT_DIM, font=FONT_SM)
            y += 14
            draw.text((panel_x + 12, y), val, fill=level_color(level) if label == "Level" else TEXT, font=FONT)
            y += 18

def draw_browser_mockup(draw):
    """Draw a simplified browser window showing Perplexity."""
    bx, by = 100, 60
    bw, bh = 600, 380
    # Window
    draw.rounded_rectangle([bx, by, bx + bw, by + bh], radius=8, fill=(25, 25, 25), outline=BORDER)
    # Title bar
    draw.rounded_rectangle([bx, by, bx + bw, by + 36], radius=8, fill=(50, 50, 50), outline=BORDER)
    draw.rectangle([bx, by + 20, bx + bw, by + 36], fill=(50, 50, 50))
    # Traffic lights
    draw.ellipse([bx + 10, by + 10, bx + 20, by + 20], fill=RED_DOT)
    draw.ellipse([bx + 26, by + 10, bx + 36, by + 20], fill=YELLOW_DOT)
    draw.ellipse([bx + 42, by + 10, bx + 52, by + 20], fill=GREEN_DOT)
    # URL bar
    draw.rounded_rectangle([bx + 80, by + 6, bx + bw - 20, by + 28], radius=4, fill=(35, 35, 35))
    draw.text((bx + 90, by + 10), "perplexity.ai/search?q=This+is+a+log+entry...", fill=TEXT_DIM, font=FONT_SM)
    # Content
    cy = by + 50
    draw.text((bx + 30, cy), "Perplexity", fill=WHITE, font=FONT_TITLE)
    cy += 30
    # The prompt
    draw.rounded_rectangle([bx + 20, cy, bx + bw - 20, cy + 120], radius=6, fill=(35, 35, 35))
    prompt_lines = [
        "This is a log entry from a macOS unified log (macOS 15.4.0).",
        "",
        "Level: Error",
        "Process: coreauthd (PID 198)",
        "Subsystem: com.apple.security",
        "Message: Failed to verify credential: errSecAuthFailed",
        "",
        "Can you explain what this log message means...?",
    ]
    for i, line in enumerate(prompt_lines):
        draw.text((bx + 30, cy + 8 + i * 14), line[:70], fill=TEXT if line else TEXT_DIM, font=FONT_SM)
    cy += 135
    # AI response
    draw.text((bx + 30, cy), "Answer", fill=ACCENT, font=FONT_BOLD)
    cy += 22
    response_lines = [
        "This error indicates an authentication failure in macOS's",
        "Core Authentication daemon. The error code -25293",
        "(errSecAuthFailed) means the credential verification failed,",
        "typically due to an incorrect password or expired token.",
        "",
        "Common causes:",
        "  - Incorrect Keychain password after password change",
        "  - Corrupted login keychain",
        "  - Expired authentication token",
    ]
    for i, line in enumerate(response_lines):
        color = ACCENT if line.startswith("  -") else TEXT
        draw.text((bx + 30, cy + i * 15), line, fill=color, font=FONT_SM)

def draw_caption(draw, text):
    """Draw a caption bar at the bottom."""
    draw.rectangle([0, H - 36, W, H], fill=(20, 20, 20))
    draw.text((W // 2 - len(text) * 3.5, H - 28), text, fill=ACCENT, font=FONT_BOLD)

def base_frame(selected_row=-1):
    """Draw the base app frame with log table."""
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)
    draw_title_bar(draw)
    draw_toolbar(draw)
    draw_table_header(draw)

    table_y = 84
    for i, entry in enumerate(LOG_ENTRIES):
        draw_log_row(draw, table_y + i * 20, entry, selected=(i == selected_row))

    draw_status_bar(draw)
    return img, draw

def frame1():
    """Log table with entries streaming in."""
    img, draw = base_frame()
    draw_caption(draw, "Viewing live log stream...")
    return img

def frame2():
    """Error row highlighted."""
    img, draw = base_frame(selected_row=3)
    draw_detail_panel(draw, LOG_ENTRIES[3])
    draw_caption(draw, "Select the error entry to see details")
    return img

def frame3():
    """Right-click context menu appearing."""
    img, draw = base_frame(selected_row=3)
    draw_detail_panel(draw, LOG_ENTRIES[3])
    menu_items = ["Ask AI About This...", "Copy AI Prompt", "---", "Copy Message", "Copy Row"]
    draw_context_menu(draw, 250, 150, menu_items, hover_idx=-1)
    draw_caption(draw, "Right-click to open context menu")
    return img

def frame4():
    """Hovering over Ask AI."""
    img, draw = base_frame(selected_row=3)
    draw_detail_panel(draw, LOG_ENTRIES[3])
    menu_items = ["Ask AI About This...", "Copy AI Prompt", "---", "Copy Message", "Copy Row"]
    draw_context_menu(draw, 250, 150, menu_items, hover_idx=0)
    draw_caption(draw, 'Click "Ask AI About This..."')
    return img

def frame5():
    """Browser opens with Perplexity showing the prompt and response."""
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)
    draw_browser_mockup(draw)
    draw_caption(draw, "AI analyzes the log entry and explains the error")
    return img

def save_gif(frames, durations, path):
    """Save frames as animated GIF using Pillow."""
    # Convert to P mode for GIF
    gif_frames = []
    for f in frames:
        # Quantize to 256 colors
        f_rgba = f.convert("RGBA")
        f_p = f_rgba.quantize(colors=256, method=2, dither=1)
        gif_frames.append(f_p)

    gif_frames[0].save(
        path,
        save_all=True,
        append_images=gif_frames[1:],
        duration=durations,
        loop=0,
        optimize=True,
    )

def main():
    project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    frames = [frame1(), frame2(), frame3(), frame4(), frame5()]
    durations = [2000, 2000, 1500, 2000, 4000]  # ms per frame

    out_path = os.path.join(project_dir, "docs", "demo.gif")
    save_gif(frames, durations, out_path)
    print(f"Demo GIF saved to {out_path}")
    print(f"Size: {os.path.getsize(out_path) / 1024:.0f} KB")

if __name__ == "__main__":
    main()
