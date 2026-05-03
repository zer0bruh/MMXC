# MMXC

Godot-first rebuild project for a Mega Man X collection, starting with the SNES trilogy.

The current plan is to use the GameMaker MMXE project as a reference archive for systems, metadata, and placeholder assets, while rebuilding the runtime cleanly in Godot instead of trying to port GameMaker code directly.

## First focus

- Build one strong vertical slice before attempting a full collection shell.
- Keep engine code, game data, and imported assets separated.
- Treat MMX1/MMX2/MMX3 as content packs on top of a shared core.

## Asset inventory

Generate a first-pass inventory from the GameMaker source with:

```powershell
python tools/mmxe_inventory.py --source C:\Users\Francois\Downloads\mmxe-main
```

That writes `data/external/mmxe_inventory.json`, which the Godot bootstrap scene will detect.

## Important note

If any extracted Capcom assets are used, keep them as private placeholder material unless you have the rights to distribute them. The safest long-term path is to use them for reference and replace what needs replacing before any public release.
