"""
ARENA — Générateur de PNG pour iOS et Android
Recrée les icônes Vector Strike F2 directement en pixels via Pillow.

Tailles iOS : 1024, 180, 167, 152, 120, 87, 80, 76, 60, 58, 40, 29, 20
Tailles Android : 512 (Play Store), 192, 144, 96, 72, 48
"""

from PIL import Image, ImageDraw, ImageFont
import os
import math

# ─────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────
OUTPUT_IOS = "/home/claude/arena/icons/final/png_ios"
OUTPUT_ANDROID = "/home/claude/arena/icons/final/png_android"

IOS_SIZES = [
    (1024, "Icon-App-1024x1024@1x.png", "App Store"),
    (180, "Icon-App-60x60@3x.png", "iPhone @3x"),
    (167, "Icon-App-83.5x83.5@2x.png", "iPad Pro"),
    (152, "Icon-App-76x76@2x.png", "iPad @2x"),
    (120, "Icon-App-60x60@2x.png", "iPhone @2x"),
    (87, "Icon-App-29x29@3x.png", "Settings @3x"),
    (80, "Icon-App-40x40@2x.png", "Spotlight @2x"),
    (76, "Icon-App-76x76@1x.png", "iPad @1x"),
    (60, "Icon-App-20x20@3x.png", "Notif @3x"),
    (58, "Icon-App-29x29@2x.png", "Settings @2x"),
    (40, "Icon-App-40x40@1x.png", "Spotlight @1x"),
    (29, "Icon-App-29x29@1x.png", "Settings @1x"),
    (20, "Icon-App-20x20@1x.png", "Notif @1x"),
]

ANDROID_SIZES = [
    (512, "playstore-icon.png", "Play Store"),
    (192, "mipmap-xxxhdpi/ic_launcher.png", "xxxhdpi"),
    (144, "mipmap-xxhdpi/ic_launcher.png", "xxhdpi"),
    (96, "mipmap-xhdpi/ic_launcher.png", "xhdpi"),
    (72, "mipmap-hdpi/ic_launcher.png", "hdpi"),
    (48, "mipmap-mdpi/ic_launcher.png", "mdpi"),
]

# Seuil au-dessus duquel on inclut le texte ARENA
TEXT_THRESHOLD = 96  # pixels

# ─────────────────────────────────────────────────────────────
# COULEURS DESIGN_KIT
# ─────────────────────────────────────────────────────────────
SIGNAL_BLUE = (76, 122, 255)     # #4C7AFF
NEON_RED = (255, 45, 85)         # #FF2D55
VOID = (10, 10, 15)              # #0A0A0F
WHITE = (255, 255, 255)

# Couleurs intermédiaires gradient
USER_MID = (26, 45, 92)          # #1A2D5C
ADMIN_MID = (92, 26, 45)         # #5C1A2D

# ─────────────────────────────────────────────────────────────
# GÉNÉRATION DU FOND DÉGRADÉ
# ─────────────────────────────────────────────────────────────
def create_gradient_bg(size, color1, color2, color3):
    """Crée un fond dégradé diagonal 3 couleurs (F2 style)."""
    img = Image.new("RGB", (size, size), color1)
    pixels = img.load()

    for y in range(size):
        for x in range(size):
            # Position normalisée 0->1 sur la diagonale
            t = (x + y) / (2 * size)

            if t < 0.55:
                # color1 → color2
                local_t = t / 0.55
                r = int(color1[0] + (color2[0] - color1[0]) * local_t)
                g = int(color1[1] + (color2[1] - color1[1]) * local_t)
                b = int(color1[2] + (color2[2] - color1[2]) * local_t)
            else:
                # color2 → color3
                local_t = (t - 0.55) / 0.45
                r = int(color2[0] + (color3[0] - color2[0]) * local_t)
                g = int(color2[1] + (color3[1] - color2[1]) * local_t)
                b = int(color2[2] + (color3[2] - color2[2]) * local_t)

            pixels[x, y] = (r, g, b)

    return img

# ─────────────────────────────────────────────────────────────
# DESSIN D'UN CHEVRON
# ─────────────────────────────────────────────────────────────
def draw_chevron(draw, scale, x1, x2, y_top, y_mid, y_bottom, fill, alpha=255):
    """Dessine un chevron (forme < > orientée à droite)."""
    # Points du chevron à l'échelle 1024
    # 280,300 480,300 712,512 480,724 280,724 512,512
    # Mais on prend les points en paramètre

    points_1024 = [
        (x1, y_top),
        (x2, y_top),
        (x2 + (y_mid - y_top), y_mid),
        (x2, y_bottom),
        (x1, y_bottom),
        (x1 + (y_mid - y_top), y_mid)
    ]

    points_scaled = [(int(p[0] * scale), int(p[1] * scale)) for p in points_1024]

    if alpha < 255:
        # Pour les chevrons translucides, on utilise un overlay
        overlay = Image.new("RGBA", draw._image.size, (0, 0, 0, 0))
        overlay_draw = ImageDraw.Draw(overlay)
        overlay_draw.polygon(points_scaled, fill=fill + (alpha,))
        draw._image.paste(overlay, (0, 0), overlay)
    else:
        draw.polygon(points_scaled, fill=fill)


def draw_chevrons_user(img, scale, include_text=True):
    """Dessine les 3 chevrons + speed dots + (optionnellement) texte ARENA."""
    # Pour la transparence on travaille en RGBA
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # ─── Speed dots (5 points à gauche, opacité 40%) ───
    dots = [
        (120, 340, 9),
        (95, 410, 11),
        (70, 480, 13),
        (95, 550, 11),
        (120, 620, 9),
    ]
    for cx, cy, r in dots:
        cx_s, cy_s, r_s = int(cx * scale), int(cy * scale), int(r * scale)
        if r_s < 1:
            r_s = 1
        draw.ellipse(
            [cx_s - r_s, cy_s - r_s, cx_s + r_s, cy_s + r_s],
            fill=(255, 255, 255, 102)  # 40% opacity
        )

    if include_text:
        # ─── 3 chevrons taille standard (texte présent) ───
        # Chevron 1 (blanc plein)
        chev1 = [(180, 260), (340, 260), (540, 420), (340, 580), (180, 580), (380, 420)]
        chev1_s = [(int(p[0] * scale), int(p[1] * scale)) for p in chev1]
        draw.polygon(chev1_s, fill=(255, 255, 255, 255))

        # Chevron 2 (rouge plein)
        chev2 = [(340, 260), (480, 260), (680, 420), (480, 580), (340, 580), (540, 420)]
        chev2_s = [(int(p[0] * scale), int(p[1] * scale)) for p in chev2]
        draw.polygon(chev2_s, fill=NEON_RED + (255,))

        # Chevron 3 (blanc translucide 55%)
        chev3 = [(480, 260), (620, 260), (820, 420), (620, 580), (480, 580), (680, 420)]
        chev3_s = [(int(p[0] * scale), int(p[1] * scale)) for p in chev3]
        draw.polygon(chev3_s, fill=(255, 255, 255, 140))
    else:
        # ─── 3 chevrons agrandis (sans texte, version compacte) ───
        chev1 = [(180, 330), (360, 330), (580, 520), (360, 710), (180, 710), (400, 520)]
        chev1_s = [(int(p[0] * scale), int(p[1] * scale)) for p in chev1]
        draw.polygon(chev1_s, fill=(255, 255, 255, 255))

        chev2 = [(360, 330), (520, 330), (740, 520), (520, 710), (360, 710), (580, 520)]
        chev2_s = [(int(p[0] * scale), int(p[1] * scale)) for p in chev2]
        draw.polygon(chev2_s, fill=NEON_RED + (255,))

        chev3 = [(520, 330), (680, 330), (900, 520), (680, 710), (520, 710), (740, 520)]
        chev3_s = [(int(p[0] * scale), int(p[1] * scale)) for p in chev3]
        draw.polygon(chev3_s, fill=(255, 255, 255, 140))

    # Compositer overlay sur image principale
    img_rgba = img.convert("RGBA")
    img_rgba.alpha_composite(overlay)
    img = img_rgba.convert("RGB")

    # ─── Texte ARENA (seulement si taille suffisante) ───
    if include_text:
        draw_text(img, "ARENA", scale, font_size_1024=140, letter_spacing=14)

    return img


def draw_chevrons_admin(img, scale, include_text=True):
    """Idem pour ADMIN avec inversion couleurs."""
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Speed dots
    dots = [(120, 340, 9), (95, 410, 11), (70, 480, 13), (95, 550, 11), (120, 620, 9)]
    for cx, cy, r in dots:
        cx_s, cy_s, r_s = int(cx * scale), int(cy * scale), int(r * scale)
        if r_s < 1: r_s = 1
        draw.ellipse([cx_s - r_s, cy_s - r_s, cx_s + r_s, cy_s + r_s], fill=(255, 255, 255, 102))

    if include_text:
        chev1 = [(180, 260), (340, 260), (540, 420), (340, 580), (180, 580), (380, 420)]
        chev1_s = [(int(p[0] * scale), int(p[1] * scale)) for p in chev1]
        draw.polygon(chev1_s, fill=(255, 255, 255, 255))

        chev2 = [(340, 260), (480, 260), (680, 420), (480, 580), (340, 580), (540, 420)]
        chev2_s = [(int(p[0] * scale), int(p[1] * scale)) for p in chev2]
        draw.polygon(chev2_s, fill=SIGNAL_BLUE + (255,))

        chev3 = [(480, 260), (620, 260), (820, 420), (620, 580), (480, 580), (680, 420)]
        chev3_s = [(int(p[0] * scale), int(p[1] * scale)) for p in chev3]
        draw.polygon(chev3_s, fill=(255, 255, 255, 140))
    else:
        chev1 = [(180, 330), (360, 330), (580, 520), (360, 710), (180, 710), (400, 520)]
        chev1_s = [(int(p[0] * scale), int(p[1] * scale)) for p in chev1]
        draw.polygon(chev1_s, fill=(255, 255, 255, 255))

        chev2 = [(360, 330), (520, 330), (740, 520), (520, 710), (360, 710), (580, 520)]
        chev2_s = [(int(p[0] * scale), int(p[1] * scale)) for p in chev2]
        draw.polygon(chev2_s, fill=SIGNAL_BLUE + (255,))

        chev3 = [(520, 330), (680, 330), (900, 520), (680, 710), (520, 710), (740, 520)]
        chev3_s = [(int(p[0] * scale), int(p[1] * scale)) for p in chev3]
        draw.polygon(chev3_s, fill=(255, 255, 255, 140))

    img_rgba = img.convert("RGBA")
    img_rgba.alpha_composite(overlay)
    img = img_rgba.convert("RGB")

    if include_text:
        draw_text(img, "ADMIN", scale, font_size_1024=120, letter_spacing=10)

    return img


def draw_text(img, text, scale, font_size_1024, letter_spacing):
    """Dessine le texte ARENA/ADMIN au bon endroit."""
    draw = ImageDraw.Draw(img)

    # Essayer de charger une police bold disponible
    font_paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf",
    ]

    font_size = int(font_size_1024 * scale * 0.85)  # ajustement perceptuel
    font = None
    for path in font_paths:
        if os.path.exists(path):
            try:
                font = ImageFont.truetype(path, font_size)
                break
            except Exception:
                pass

    if font is None:
        font = ImageFont.load_default()
        return img  # impossible de dessiner du texte propre sans police

    # Avec letter-spacing manuel : on dessine lettre par lettre
    spacing_px = int(letter_spacing * scale * 0.85)
    chars = list(text)

    # Calculer la largeur totale
    widths = []
    for c in chars:
        bbox = draw.textbbox((0, 0), c, font=font)
        widths.append(bbox[2] - bbox[0])

    total_width = sum(widths) + spacing_px * (len(chars) - 1)

    # Position de départ : centré horizontalement, à 780 sur 1024 (axe Y)
    img_size = img.size[0]
    x = (img_size - total_width) // 2
    # Centre du texte à y=780, mais textbbox top-left ; on ajuste
    y_center = int(780 * scale * 0.85)
    bbox_full = draw.textbbox((0, 0), text, font=font)
    text_height = bbox_full[3] - bbox_full[1]
    y = y_center - text_height // 2

    for i, c in enumerate(chars):
        draw.text((x, y), c, font=font, fill=WHITE)
        x += widths[i] + spacing_px

    return img


# ─────────────────────────────────────────────────────────────
# GÉNÉRATION DE L'ICÔNE
# ─────────────────────────────────────────────────────────────
def generate_icon(size, role="user"):
    """Génère une icône à la taille demandée."""
    # Couleurs selon le rôle
    if role == "user":
        bg = create_gradient_bg(size, SIGNAL_BLUE, USER_MID, VOID)
    else:
        bg = create_gradient_bg(size, NEON_RED, ADMIN_MID, VOID)

    scale = size / 1024.0
    include_text = size >= TEXT_THRESHOLD

    if role == "user":
        img = draw_chevrons_user(bg, scale, include_text=include_text)
    else:
        img = draw_chevrons_admin(bg, scale, include_text=include_text)

    return img


# ─────────────────────────────────────────────────────────────
# EXPORT MAIN
# ─────────────────────────────────────────────────────────────
def export_ios():
    """Génère toutes les tailles iOS pour USER (l'app principale)."""
    os.makedirs(OUTPUT_IOS, exist_ok=True)
    print(f"\n=== iOS USER ({len(IOS_SIZES)} tailles) ===")
    for size, filename, desc in IOS_SIZES:
        img = generate_icon(size, role="user")
        path = os.path.join(OUTPUT_IOS, filename)
        img.save(path, "PNG", optimize=True)
        print(f"  ✓ {filename:40} ({size}×{size}) — {desc}")


def export_ios_admin():
    """Génère toutes les tailles iOS pour ADMIN."""
    os.makedirs(OUTPUT_IOS + "_admin", exist_ok=True)
    print(f"\n=== iOS ADMIN ({len(IOS_SIZES)} tailles) ===")
    for size, filename, desc in IOS_SIZES:
        img = generate_icon(size, role="admin")
        path = os.path.join(OUTPUT_IOS + "_admin", filename)
        img.save(path, "PNG", optimize=True)
        print(f"  ✓ {filename:40} ({size}×{size}) — {desc}")


def export_android():
    """Génère toutes les tailles Android pour USER."""
    os.makedirs(OUTPUT_ANDROID, exist_ok=True)
    print(f"\n=== Android USER ({len(ANDROID_SIZES)} tailles) ===")
    for size, filename, desc in ANDROID_SIZES:
        # Créer le sous-dossier mipmap si besoin
        full_path = os.path.join(OUTPUT_ANDROID, filename)
        os.makedirs(os.path.dirname(full_path), exist_ok=True) if "/" in filename else None
        img = generate_icon(size, role="user")
        img.save(full_path, "PNG", optimize=True)
        print(f"  ✓ {filename:40} ({size}×{size}) — {desc}")


def export_android_admin():
    """Idem ADMIN."""
    out = OUTPUT_ANDROID + "_admin"
    os.makedirs(out, exist_ok=True)
    print(f"\n=== Android ADMIN ({len(ANDROID_SIZES)} tailles) ===")
    for size, filename, desc in ANDROID_SIZES:
        full_path = os.path.join(out, filename)
        os.makedirs(os.path.dirname(full_path), exist_ok=True) if "/" in filename else None
        img = generate_icon(size, role="admin")
        img.save(full_path, "PNG", optimize=True)
        print(f"  ✓ {filename:40} ({size}×{size}) — {desc}")


if __name__ == "__main__":
    print("🎨 ARENA Icon Generator — Vector Strike F2")
    print("="*60)

    export_ios()
    export_ios_admin()
    export_android()
    export_android_admin()

    print("\n" + "="*60)
    print("✅ Génération terminée.")
