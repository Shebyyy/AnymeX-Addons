# AnymeX Add-ons

Optional add-ons for AnymeX. The app reads this repository directly (raw
GitHub URLs, no releases), so installing an add-on never grows the app itself.

```
addons.json                       index of add-ons (id, version, platforms)
add-on/<id>/manifest.json         version + per-platform files + SHA-256
add-on/<id>/bin/<platform>/...    the downloadable files
add-on/<id>/build/...             scripts CI uses to produce them
tools/gen_manifest.py             regenerates both JSON files from bin/
.github/workflows/                CI that builds and commits the binaries
```

Platform keys: `android-arm64-v8a`, `android-armeabi-v7a`, `android-x86_64`,
`windows-x64`, `linux-x64`, `macos-arm64`, `macos-x64`. iOS is intentionally
absent: iOS cannot run downloaded code, so add-ons must work there with code
that ships inside the app (the clip add-on does).

## addons.json

```json
{ "schema": 1,
  "addons": [ { "id": "clip", "name": "Clip Recorder", "version": "1.0.0",
                "path": "add-on/clip", "manifest": "add-on/clip/manifest.json",
                "platforms": ["linux-x64"] } ] }
```

## add-on/<id>/manifest.json

```json
{ "schema": 1, "id": "clip", "version": "1.0.0",
  "files": { "linux-x64": { "path": "bin/linux-x64/ffmpeg",
             "sha256": "...", "size": 3615608, "executable": true } } }
```

The app compares `version` with the installed one to offer updates, downloads
`path` relative to `add-on/<id>/`, refuses the file if the SHA-256 differs,
and (for executables) marks it runnable.

## Adding another add-on

1. Create `add-on/<newid>/` with `bin/<platform>/<file>` and `build/VERSION`.
2. Add an entry for it in `META` in `tools/gen_manifest.py`.
3. Run `python3 tools/gen_manifest.py` and commit.
4. In the app, add a class extending `RemoteAddon` with the same `id`.

## Clip add-on binaries

`add-on/clip/build/build-ffmpeg.sh` builds FFmpeg (tag in `FFMPEG_TAG`) with the
flags in `configure-flags.txt`: LGPL 2.1+ only, no encoders, no TLS (the app's
loopback proxy handles https), stream copy and remux only. FFmpeg source:
https://github.com/FFmpeg/FFmpeg (tag recorded in `FFMPEG_TAG`); the configure
flags used are the ones in this folder.
