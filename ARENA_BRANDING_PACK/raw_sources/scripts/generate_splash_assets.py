"""
ARENA — PNG splash natif pour Splash D (version corrigée)
Logo proprement compose sur fond dégradé sans carré noir.
"""

from PIL import Image, ImageDraw
import os

OUT = "/home/claude/arena/splash_d/assets"
os.makedirs(OUT, exist_ok=True)

SIGNAL_BLUE = (76, 122, 255)
NEON_RED = (255, 45, 85)
VOID = (10, 10, 15)
USER_MID = (26, 45, 92)
ADMIN_MID = (92, 26, 45)


def create_gradient_bg(size, color1, color2, color3):
    """Fond dégradé diagonal F2 — RGB."""
    img = Image.new("RGB", (size, size), color1)
    pixels = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size)
            if t < 0.55:
                lt = t / 0.55
                r = int(color1[0] + (color2[0] - color1[0]) * lt)
                g = int(color1[1] + (color2[1] - color1[1]) * lt)
                b = int(color1[2] + (color2[2] - color1[2]) * lt)
            else:
                lt = (t - 0.55) / 0.45
                r = int(color2[0] + (color3[0] - color2[0]) * lt)
                g = int(color2[1] + (color3[1] - color2[1]) * lt)
                b = int(color2[2] + (color3[2] - color2[2]) * lt)
            pixels[x, y] = (r, g, b)
    return img


def draw_logo_on_image(img, role, logo_size_ratio=0.4):
    """Dessine le logo directement sur l'image principale via overlay RGBA.
    Pas de paste avec fond noir."""
    size = img.size[0]
    img_rgba = img.convert("RGBA")
    
    # Overlay transparent pour le logo
    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    
    # Calculer l'échelle pour le logo (40% de l'image)
    logo_area = int(size * logo_size_ratio)
    scale_factor = logo_area / 1024.0  # le logo dessiné en coordonnées 1024
    
    # Centrer le logo
    offset_x = (size - logo_area) // 2
    offset_y = (size - logo_area) // 2 - int(size * 0.03)  # légèrement au-dessus
    
    def to_canvas(x, y):
        return (
            int(x * scale_factor + offset_x),
            int(y * scale_factor + offset_y)
        )
    
    # Speed dots
    dots = [(120, 340, 9), (95, 410, 11), (70, 480, 13), (95, 550, 11), (120, 620, 9)]
    for cx, cy, r in dots:
        cx_s, cy_s = to_canvas(cx, cy)
        r_s = max(1, int(r * scale_factor))
        draw.ellipse(
            [cx_s - r_s, cy_s - r_s, cx_s + r_s, cy_s + r_s],
            fill=(255, 255, 255, 100)
        )
    
    accent = NEON_RED if role == "user" else SIGNAL_BLUE
    
    # 3 chevrons
    chev1 = [(180, 260), (340, 260), (540, 420), (340, 580), (180, 580), (380, 420)]
    chev2 = [(340, 260), (480, 260), (680, 420), (480, 580), (340, 580), (540, 420)]
    chev3 = [(480, 260), (620, 260), (820, 420), (620, 580), (480, 580), (680, 420)]
    
    draw.polygon([to_canvas(*p) for p in chev1], fill=(255, 255, 255, 255))
    draw.polygon([to_canvas(*p) for p in chev2], fill=accent + (255,))
    draw.polygon([to_canvas(*p) for p in chev3], fill=(255, 255, 255, 140))
    
    # Composer
    img_rgba.alpha_composite(overlay)
    return img_rgba.convert("RGB")


def generate_native_splash(role="user"):
    print(f"\n=== {role.upper()} ===")
    
    # ─── 1. Splash plein écran (dégradé + logo, sans transparence) ───
    full_size = 1024
    accent = SIGNAL_BLUE if role == "user" else NEON_RED
    mid = USER_MID if role == "user" else ADMIN_MID
    
    bg = create_gradient_bg(full_size, accent, mid, VOID)
    img = draw_logo_on_image(bg, role)
    
    splash_path = os.path.join(OUT, f"splash_{role}.png")
    img.save(splash_path, "PNG", optimize=True)
    print(f"  ✓ splash_{role}.png            (1024×1024, plein dégradé + logo)")
    
    # ─── 2. Splash icon (Android 12+, logo sur transparent) ─────────
    icon_size = 1024
    safe_zone_ratio = 432 / 1024  # safe zone Android 12 = 43% central
    
    # Image transparente
    icon = Image.new("RGBA", (icon_size, icon_size), (0, 0, 0, 0))
    
    overlay = Image.new("RGBA", (icon_size, icon_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    
    logo_area = int(icon_size * safe_zone_ratio)
    scale_factor = logo_area / 1024.0
    offset = (icon_size - logo_area) // 2
    
    def to_canvas_icon(x, y):
        return (int(x * scale_factor + offset), int(y * scale_factor + offset))
    
    # Speed dots
    dots = [(120, 340, 9), (95, 410, 11), (70, 480, 13), (95, 550, 11), (120, 620, 9)]
    for cx, cy, r in dots:
        cx_s, cy_s = to_canvas_icon(cx, cy)
        r_s = max(1, int(r * scale_factor))
        draw.ellipse([cx_s - r_s, cy_s - r_s, cx_s + r_s, cy_s + r_s], fill=(255, 255, 255, 100))
    
    accent_color = NEON_RED if role == "user" else SIGNAL_BLUE
    chev1 = [(180, 260), (340, 260), (540, 420), (340, 580), (180, 580), (380, 420)]
    chev2 = [(340, 260), (480, 260), (680, 420), (480, 580), (340, 580), (540, 420)]
    chev3 = [(480, 260), (620, 260), (820, 420), (620, 580), (480, 580), (680, 420)]
    
    draw.polygon([to_canvas_icon(*p) for p in chev1], fill=(255, 255, 255, 255))
    draw.polygon([to_canvas_icon(*p) for p in chev2], fill=accent_color + (255,))
    draw.polygon([to_canvas_icon(*p) for p in chev3], fill=(255, 255, 255, 140))
    
    icon.alpha_composite(overlay)
    
    icon_path = os.path.join(OUT, f"splash_icon_{role}.png")
    icon.save(icon_path, "PNG", optimize=True)
    print(f"  ✓ splash_icon_{role}.png       (1024×1024, logo transparent)")


if __name__ == "__main__":
    print("🎬 ARENA Native Splash Assets (v2 corrigée)")
    print("=" * 60)
    generate_native_splash("user")
    generate_native_splash("admin")
    print("\n" + "=" * 60)
    print("✅ Assets natifs corrigés.")
