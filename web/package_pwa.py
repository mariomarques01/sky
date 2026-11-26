"""Package a Godot Web export with an installable, versioned browser shell."""

import argparse
import json
import re
import shutil
from pathlib import Path

SOURCE = Path(__file__).resolve().parent
ICONS = {"icon-192.png": 192, "icon-512.png": 512, "icon-maskable-512.png": 512,
         "apple-touch-icon.png": 180}


def package(output: Path, version: str) -> None:
    if not re.fullmatch(r"[A-Za-z0-9_-]{1,80}", version):
        raise ValueError("Use uma versão com letras, dígitos, hífens ou underscores.")

    shell_path = output / "index.html"
    shell = shell_path.read_text(encoding="utf-8")
    if '<meta name="skybound-version"' in shell:
        raise ValueError("Exporte o jogo no Godot antes de empacotar uma nova versão.")
    for filename in ("index.js", "index.wasm", "index.pck"):
        if (output / filename).stat().st_size == 0:
            raise ValueError(f"Exportação vazia: {filename}")

    release = output / "releases" / version
    release.mkdir(parents=True, exist_ok=True)
    for artifact in sorted(output.glob("index.*")):
        if artifact != shell_path and artifact.is_file():
            shutil.move(artifact, release / artifact.name)

    extra_head = f"""
        <base href="./releases/{version}/">
        <meta name="skybound-version" content="{version}">
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
        <meta name="theme-color" content="#142536">
        <meta name="apple-mobile-web-app-capable" content="yes">
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
        <link rel="manifest" href="../../manifest.webmanifest">
        <link rel="icon" type="image/png" href="../../icons/icon-192.png">
        <link rel="apple-touch-icon" href="../../icons/apple-touch-icon.png">
        <script src="pwa-client.js" defer></script>
        <style>
            html, body {{ position: fixed; inset: 0; width: 100%; height: 100%; overflow: hidden; overscroll-behavior: none; }}
            #canvas {{ position: fixed; inset: 0; width: 100%; height: 100%; height: 100dvh; }}
            #skybound-safe-area {{
                position: fixed;
                inset: env(safe-area-inset-top, 0px) env(safe-area-inset-right, 0px)
                    env(safe-area-inset-bottom, 0px) env(safe-area-inset-left, 0px);
                visibility: hidden;
                pointer-events: none;
            }}
        </style>
"""
    shell = re.sub(r'<meta\s+name="viewport"[^>]*>', "", shell)
    shell = re.sub(r'<link\b[^>]*\brel="(?:icon|apple-touch-icon)"[^>]*>', "", shell)
    shell = shell.replace('<html lang="en">', '<html lang="pt-BR">', 1)
    if "<head>" not in shell:
        raise ValueError("Cabeçalho do HTML do Godot ausente.")
    shell = shell.replace("<head>", "<head>" + extra_head, 1)
    shell = shell.replace("<body>", '<body><div id="skybound-safe-area" aria-hidden="true"></div>', 1)
    shell_path.write_text(shell, encoding="utf-8")
    (release / "index.html").write_text(shell, encoding="utf-8")
    shutil.copyfile(SOURCE / "pwa-client.js", release / "pwa-client.js")

    manifest = {
        "id": "./",
        "name": "Skybound — Ilhas Perdidas",
        "short_name": "Skybound",
        "description": "Explore ilhas flutuantes com o coelho aventureiro de Skybound.",
        "lang": "pt-BR",
        "start_url": "./",
        "scope": "./",
        "display": "standalone",
        "display_override": ["fullscreen", "standalone"],
        "background_color": "#142536",
        "theme_color": "#142536",
        "icons": [
            {"src": f"icons/{name}", "sizes": f"{size}x{size}", "type": "image/png",
             "purpose": "maskable" if "-maskable-" in name else "any"}
            for name, size in ICONS.items() if name != "apple-touch-icon.png"
        ],
    }
    (output / "manifest.webmanifest").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    (output / "icons").mkdir(exist_ok=True)
    for name in ICONS:
        shutil.copyfile(SOURCE / "icons" / name, output / "icons" / name)

    precache = sorted(path.relative_to(output).as_posix() for path in release.iterdir() if path.is_file())
    precache.extend(["manifest.webmanifest", *(f"icons/{name}" for name in ICONS)])
    worker = (SOURCE / "service-worker.js").read_text(encoding="utf-8")
    worker = worker.replace("/* BUILD_VERSION */ null", json.dumps(version), 1)
    worker = worker.replace("/* PRECACHE_FILES */ []", json.dumps(precache), 1)
    (output / "service-worker.js").write_text(worker, encoding="utf-8")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("version")
    arguments = parser.parse_args()
    package(arguments.output, arguments.version)
