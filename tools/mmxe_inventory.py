from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


TRAILING_COMMA_RE = re.compile(r",(\s*[}\]])")


def discover_default_source() -> Path | None:
    downloads = Path.home() / "Downloads"
    candidates = [
        downloads / "mmxe-main",
        downloads / "MMXE-main",
        downloads / "mmxe",
        downloads / "MMXE",
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    return None


def load_gamemaker_json(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8-sig")
    cleaned = text
    while True:
        updated = TRAILING_COMMA_RE.sub(r"\1", cleaned)
        if updated == cleaned:
            break
        cleaned = updated
    return json.loads(cleaned)


def relative_to_root(path: Path, root: Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()


def collect_sprite_entries(source_root: Path) -> list[dict[str, Any]]:
    sprites_root = source_root / "sprites"
    if not sprites_root.exists():
        return []

    entries: list[dict[str, Any]] = []
    for sprite_dir in sorted(path for path in sprites_root.iterdir() if path.is_dir()):
        yy_candidates = sorted(sprite_dir.glob("*.yy"))
        if not yy_candidates:
            continue

        yy_path = yy_candidates[0]
        data = load_gamemaker_json(yy_path)
        sequence = data.get("sequence", {})
        frame_names = [frame.get("name", "") for frame in data.get("frames", []) if frame.get("name")]

        png_paths: list[str] = []
        for frame_name in frame_names:
            png_path = sprite_dir / f"{frame_name}.png"
            if png_path.exists():
                png_paths.append(relative_to_root(png_path, source_root))

        if not png_paths:
            png_paths = [
                relative_to_root(path, source_root)
                for path in sorted(sprite_dir.glob("*.png"))
            ]

        entries.append(
            {
                "name": data.get("name", sprite_dir.name),
                "directory": relative_to_root(sprite_dir, source_root),
                "yy_path": relative_to_root(yy_path, source_root),
                "width": data.get("width"),
                "height": data.get("height"),
                "origin": {
                    "x": sequence.get("xorigin", 0),
                    "y": sequence.get("yorigin", 0),
                },
                "bbox": {
                    "left": data.get("bbox_left"),
                    "top": data.get("bbox_top"),
                    "right": data.get("bbox_right"),
                    "bottom": data.get("bbox_bottom"),
                },
                "collision_kind": data.get("collisionKind"),
                "frame_count": len(frame_names) if frame_names else len(png_paths),
                "playback_speed": sequence.get("playbackSpeed"),
                "png_paths": png_paths,
            }
        )

    return entries


def collect_tileset_entries(source_root: Path) -> list[dict[str, Any]]:
    tilesets_root = source_root / "tilesets"
    if not tilesets_root.exists():
        return []

    entries: list[dict[str, Any]] = []
    for tileset_dir in sorted(path for path in tilesets_root.iterdir() if path.is_dir()):
        yy_candidates = sorted(tileset_dir.glob("*.yy"))
        if not yy_candidates:
            continue

        yy_path = yy_candidates[0]
        data = load_gamemaker_json(yy_path)
        output_tileset = tileset_dir / "output_tileset.png"

        entries.append(
            {
                "name": data.get("name", tileset_dir.name),
                "directory": relative_to_root(tileset_dir, source_root),
                "yy_path": relative_to_root(yy_path, source_root),
                "tile_width": data.get("tileWidth"),
                "tile_height": data.get("tileHeight"),
                "tile_count": data.get("tile_count"),
                "columns": data.get("out_columns"),
                "sprite_name": data.get("spriteId", {}).get("name"),
                "output_tileset_path": (
                    relative_to_root(output_tileset, source_root)
                    if output_tileset.exists()
                    else None
                ),
            }
        )

    return entries


def build_inventory(source_root: Path) -> dict[str, Any]:
    sprites = collect_sprite_entries(source_root)
    tilesets = collect_tileset_entries(source_root)

    sprite_png_count = sum(len(sprite["png_paths"]) for sprite in sprites)

    return {
        "source_root": str(source_root),
        "summary": {
            "sprite_count": len(sprites),
            "tileset_count": len(tilesets),
            "sprite_png_count": sprite_png_count,
        },
        "sprites": sprites,
        "tilesets": tilesets,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create a first-pass asset inventory from a GameMaker MMXE source tree."
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=discover_default_source(),
        help="Path to the MMXE GameMaker source directory.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("data/external/mmxe_inventory.json"),
        help="Where to write the generated JSON inventory.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.source is None:
        raise SystemExit(
            "Could not find a default MMXE source folder. Pass --source explicitly."
        )

    source_root = args.source.expanduser().resolve()
    if not source_root.exists():
        raise SystemExit(f"Source path does not exist: {source_root}")

    inventory = build_inventory(source_root)

    output_path = args.output.expanduser()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(inventory, indent=2), encoding="utf-8")

    summary = inventory["summary"]
    print(
        "Inventory written to {path} | sprites={sprites} tilesets={tilesets} pngs={pngs}".format(
            path=output_path,
            sprites=summary["sprite_count"],
            tilesets=summary["tileset_count"],
            pngs=summary["sprite_png_count"],
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
