#!/usr/bin/env python3
"""Regenerates add-on/<id>/manifest.json and addons.json from the files that
exist under add-on/<id>/bin/<platform>/. Run by CI after the builds; safe to
run locally. A platform is listed only if its binary is really present."""
import hashlib, json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

META = {
    "clip": {
        "name": "Clip Recorder",
        "description": "Save video clips from the player (FFmpeg, stream copy, no re-encode).",
        "binary": "ffmpeg",
    },
}

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()

def main():
    index = {"schema": 1, "addons": []}
    for addon_id, meta in META.items():
        d = os.path.join(ROOT, "add-on", addon_id)
        version = open(os.path.join(d, "build", "VERSION")).read().strip()
        files = {}
        bin_dir = os.path.join(d, "bin")
        for platform in sorted(os.listdir(bin_dir)) if os.path.isdir(bin_dir) else []:
            for name in (meta["binary"], meta["binary"] + ".exe"):
                p = os.path.join(bin_dir, platform, name)
                if os.path.isfile(p):
                    files[platform] = {
                        "path": f"bin/{platform}/{name}",
                        "sha256": sha256(p),
                        "size": os.path.getsize(p),
                        "executable": True,
                    }
        manifest = {
            "schema": 1, "id": addon_id, "version": version,
            "notes": "FFmpeg " + open(os.path.join(d, "build", "FFMPEG_TAG")).read().strip() + ", LGPL, remux only",
            "files": files,
        }
        with open(os.path.join(d, "manifest.json"), "w") as f:
            json.dump(manifest, f, indent=2); f.write("\n")
        index["addons"].append({
            "id": addon_id, "name": meta["name"], "description": meta["description"],
            "version": version, "path": f"add-on/{addon_id}",
            "manifest": f"add-on/{addon_id}/manifest.json",
            "platforms": sorted(files),
        })
    with open(os.path.join(ROOT, "addons.json"), "w") as f:
        json.dump(index, f, indent=2); f.write("\n")
    print(json.dumps(index, indent=2))

if __name__ == "__main__":
    sys.exit(main())
