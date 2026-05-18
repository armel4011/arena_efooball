"""
ARENA — Adaptive Icons Android 8+
Foreground (chevrons + dots, transparent) + Background (dégradé) séparés.
Safe zone : le contenu central de 432×432 sur 1024×1024 sera toujours visible.
"""

from PIL import Image, ImageDraw
import os

OUT = "/home/claude/arena/icons/final/adaptive"

SIGNAL_BLUE = (76, 122, 255)
NEON_RED = (255, 45, 85)
VOID = (10, 10, 15)
WHITE = (255, 255, 255)
USER_MID = (26, 45, 92)
ADMIN_MID = (92, 26, 45)

# Adaptive icons doivent être 432×432 dans un canvas 1024×1024
# (le reste sert de "padding" pour les masques système)
CANVAS_SIZE = 1024
SAFE_ZONE = 432  # zone garantie visible

# Pour adaptive icons : on doit recentrer le symbole dans la zone visible
# Le symbole prend la zone safe à l'intérieur du canvas

def create_gradient_bg(color1, color2, color3):
    """Background : dégradé F2 plein canvas."""
    img = Image.new("RGB", (CANVAS_SIZE, CANVAS_SIZE), color1)
    pixels = img.load()
    for y in range(CANVAS_SIZE):
        for x in range(CANVAS_SIZE):
            t = (x + y) / (2 * CANVAS_SIZE)
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


def create_foreground(role="user"):
    """Foreground : chevrons + dots sur fond transparent, centré dans la safe zone."""
    img = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Le symbole doit tenir dans la safe zone 432×432, centrée
    # Donc on remappe les coordonnées 1024→432, centrées
    # Centre du canvas = 512, taille zone = 432, donc start = 296

    safe_offset = (CANVAS_SIZE - SAFE_ZONE) // 2  # 296
    scale = SAFE_ZONE / 1024.0  # facteur d'échelle

    def remap(x, y):
        """Remappe des coords 1024 vers la safe zone."""
        return (
            int(x * scale + safe_offset),
            int(y * scale + safe_offset)
        )

    # Speed dots
    dots = [(120, 340, 9), (95, 410, 11), (70, 480, 13), (95, 550, 11), (120, 620, 9)]
    for cx, cy, r in dots:
        cx_s, cy_s = remap(cx, cy)
        r_s = max(1, int(r * scale))
        draw.ellipse([cx_s - r_s, cy_s - r_s, cx_s + r_s, cy_s + r_s], fill=(255, 255, 255, 102))

    # 3 chevrons agrandis (version compacte sans texte)
    chev1 = [(180, 330), (360, 330), (580, 520), (360, 710), (180, 710), (400, 520)]
    chev2 = [(360, 330), (520, 330), (740, 520), (520, 710), (360, 710), (580, 520)]
    chev3 = [(520, 330), (680, 330), (900, 520), (680, 710), (520, 710), (740, 520)]

    accent = NEON_RED if role == "user" else SIGNAL_BLUE

    chev1_s = [remap(*p) for p in chev1]
    chev2_s = [remap(*p) for p in chev2]
    chev3_s = [remap(*p) for p in chev3]

    draw.polygon(chev1_s, fill=(255, 255, 255, 255))
    draw.polygon(chev2_s, fill=accent + (255,))
    draw.polygon(chev3_s, fill=(255, 255, 255, 140))

    return img


def export_adaptive(role):
    """Génère foreground + background pour un rôle."""
    role_dir = os.path.join(OUT, role)
    os.makedirs(role_dir, exist_ok=True)

    # Background
    if role == "user":
        bg = create_gradient_bg(SIGNAL_BLUE, USER_MID, VOID)
    else:
        bg = create_gradient_bg(NEON_RED, ADMIN_MID, VOID)

    bg_path = os.path.join(role_dir, "ic_launcher_background.png")
    bg.save(bg_path, "PNG", optimize=True)

    # Foreground
    fg = create_foreground(role)
    fg_path = os.path.join(role_dir, "ic_launcher_foreground.png")
    fg.save(fg_path, "PNG", optimize=True)

    # Aussi : un version monochrome pour Android 13+ themed icons
    # (silhouette blanche du symbole)
    mono = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    draw_mono = ImageDraw.Draw(mono)

    safe_offset = (CANVAS_SIZE - SAFE_ZONE) // 2
    scale = SAFE_ZONE / 1024.0

    def remap(x, y):
        return (int(x * scale + safe_offset), int(y * scale + safe_offset))

    # Pour mono : tous les chevrons en blanc
    chev1 = [(180, 330), (360, 330), (580, 520), (360, 710), (180, 710), (400, 520)]
    chev2 = [(360, 330), (520, 330), (740, 520), (520, 710), (360, 710), (580, 520)]
    chev3 = [(520, 330), (680, 330), (900, 520), (680, 710), (520, 710), (740, 520)]

    for chev in [chev1, chev2, chev3]:
        pts = [remap(*p) for p in chev]
        draw_mono.polygon(pts, fill=(255, 255, 255, 255))

    mono_path = os.path.join(role_dir, "ic_launcher_monochrome.png")
    mono.save(mono_path, "PNG", optimize=True)

    print(f"  ✓ {role}/ic_launcher_background.png  (1024×1024, gradient)")
    print(f"  ✓ {role}/ic_launcher_foreground.png  (1024×1024, transparent)")
    print(f"  ✓ {role}/ic_launcher_monochrome.png  (1024×1024, Android 13+ themed)")


if __name__ == "__main__":
    print("🎨 ARENA Adaptive Icons (Android 8+)")
    print("="*60)
    print("\n=== USER ===")
    export_adaptive("user")
    print("\n=== ADMIN ===")
    export_adaptive("admin")
    print("\n" + "="*60)
    print("✅ Adaptive icons générées.")
