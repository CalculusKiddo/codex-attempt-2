# Operation Rheinübung — Hunt for Bismarck

A five-minute **2D** documentary animation with detailed original overhead ship artwork, fast map moves, brief captions, ship specifications and an original dramatic score.

[Download the full-quality MP4](https://github.com/CalculusKiddo/codex-attempt-2/releases/download/bismarck-2d-v2/bismarck-timeline.mp4). The video is distributed as a GitHub Release asset so it can retain full quality beyond the repository file-size limit.

- 1920 × 1080, 24 fps, H.264 MP4, stereo AAC audio.
- Fifty six-second shots, with ship plans rendered from original native drawing code at 4096-pixel source width.
- Planked decks, anchor chains, hatches, ventilation grilles, boats, cranes, rangefinders, secondary batteries and independently trained main turrets.
- 250.5 m overall length, 36 m beam, eight 380 mm guns, 320 mm main belt and approximately 30-knot trial speed are shown in the specifications sequence.
- No AI-generated imagery is used in this revision.

## Gunnery treatment

Shells fire in discrete groups with brief muzzle flashes, lingering smoke, travel time, target lead and clustered fall of shot. They are small projectiles rather than continuous glowing beams. Main turrets train toward target bearings; masked aft batteries are excluded from firing.

The Denmark Strait sequence advances at **30×** speed and uses approximately **32 seconds of real shell-flight time at 20 km**. The final engagement presents selected moments at **10×** speed, with shorter flights as ranges close. Rodney's alternating five- and four-gun groups are reduced when the third turret cannot bear. The Prince of Wales illustration uses a reduced forward battery.

This is an illustrative reconstruction, not a complete shot-by-shot simulation. Exact individual firing times, every malfunction, projectile dispersion and all maneuver tracks are not known or reproduced. Ship symbols are enlarged for legibility; weapon distances are compressed on the tactical diagram. Key event times, firing-group logic and ballistic delays are distinguished from those display choices. The route on the geographic map is schematic between known waypoints.

## Visual reference and research

[BazBattles — Operation Rheinübung: Hunt for the Bismarck 1941](https://www.youtube.com/watch?v=zuG4qFXPMmk) informed the use of overhead ship symbols, wakes, leader labels and map-based transitions. All artwork and audio in this project are original except the public-domain coastline data.

Historical and technical references:

- [KBismarck: technical characteristics](https://www.kbismarck.com/genedata.html).
- [KBismarck: armament](https://www.kbismarck.com/armament.html), including turret locations and firing arcs.
- [38 cm range table](https://kbismarck.com/38cm.html), extrapolated from original German projectile curves; approximately 32 seconds at 20,000 m.
- [HMS Rodney preliminary gunnery report, 27 May 1941](https://www.kbismarck.com/rodney-gunnery-report.html), especially the 5/4 salvo method and restrictions on X turret.
- [KBismarck: operational chronology](https://www.kbismarck.com/histoperi.html).
- [Royal Navy: Swordfish attack](https://www.royalnavy.mod.uk/news/2021/may/26/20210526-bismarck-hit).
- [Bismarck appearance and paint schemes](https://kbismarck.com/drawings.html).
- [Heller Bismarck model assembly/plan reference](https://www.super-hobby.co.no/zdjecia/8/9/2/55841_instruction.pdf). Consulted for general layout; its artwork is not embedded.
- [Natural Earth 1:110m land](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_110m_land.geojson), public-domain coastline data in `land.geojson`.

## Edit and render

Requires macOS with Xcode Command Line Tools and Python 3.9+.

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python ocean.py
swiftc -O render.swift -o render
FFMPEG=$(.venv/bin/python -c 'import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())')
./render . "$FFMPEG"
.venv/bin/python soundtrack.py
```

Use `./render . --stills` for review images without replacing the video. Edit the `captions`, `denmark`, `finalBattle`, `makePlan` and camera functions in `render.swift` to change the sequence. The source includes an optional `--patch` render mode for the final engagement section; normal rendering exports the entire final revision.

`ocean.py` creates the sea texture procedurally. `soundtrack.py` synthesizes the original score and effects, then combines the stereo audio with the silent video. These scripts require no API keys.
