# Operation Rheinübung — Hunt for Bismarck

A five-minute **2D** documentary animation with detailed overhead ships, continuous camera choreography, path-following vessel motion, brief captions, ship specifications and no audio track.

[Download the full-quality MP4](https://github.com/CalculusKiddo/codex-attempt-2/releases/download/bismarck-2d-v5-realism/bismarck-timeline.mp4). The video is distributed as a GitHub Release asset so it can retain full quality beyond the repository file-size limit.

- 1920 × 1080, 24 fps, H.264 MP4, no audio track.
- Eleven sequences with fifty brief caption cues. Ship plans are rendered from original native drawing code at 4096-pixel source width.
- Camera paths preserve position, velocity and acceleration across internal keyframes. Caption changes do not reset the camera.
- The film opens with Operation Rheinübung, then follows the pair out of the Skagerrak. The camera pulls back, then zooms into the same moving Bismarck and rotates until its hull is horizontal for the specifications. The torpedo strike continues into the steering-damage sequence. Chapter changes use animated scene-to-scene pans rather than opacity fades.
- Moving ships and aircraft face the tangent of their travel paths. The opening pair follows one arc-length route at equal speed with fixed spacing; both hull outlines are checked against the detailed land polygons. Stern wakes follow sampled past positions through turns. The water and ships share the same world-space camera.
- Labels enter with a short slide and eased opacity, leave at chapter boundaries, and avoid ship silhouettes and each other. Timestamps stay fixed in the header. The opening dotted journey line disappears before the close-up.
- Planked decks, anchor chains, hatches, ventilation grilles, boats, cranes, rangefinders, secondary batteries and independently trained main turrets.
- 250.5 m overall length, 36 m beam, eight 380 mm guns, 320 mm main belt are shown in the specifications sequence. The length line grows from one end and places its value beside the line.
- No AI-generated imagery is used in this revision.

The current release has **no audio stream**: no music, effects, narration or other sounds.

## Opening order

- 00:00–00:06: Operation Rheinübung title.
- 00:06–00:36: Bismarck and Prinz Eugen leave the narrow European waters together; the camera slowly pulls back over detailed coastlines.
- 00:36–00:42: the camera zooms into Bismarck and rotates it into a horizontal view.
- 00:42–01:00: animated overall-length measurement, main armament, beam and main belt. The camera pulls out at the end.
- 01:00–01:12: dated map progression toward the Denmark Strait.

## Torpedoes, wakes and steering

Every aircraft shown in the final attack has its own carried torpedo, release time and straight unguided run. Three representative runs show an amidships hit, a miss and the decisive stern hit; they are not a complete recreation of all fifteen attacking aircraft or all recorded drops. The underwater bodies are drawn at approximately 6.9 m by 0.45 m in the tactical drawing scale. Air entry decelerates into the underwater run. Persistent foam trails decay after an impact instead of vanishing with the projectile.

Torpedo tips intersect the same polygon used to draw Bismarck's hull. Swept intersections account for ship movement, stop the torpedo at its first contact and place the splash there. Shell fall-of-shot effects likewise distinguish hull impacts from water using the rendered hull outlines, rather than the sprite or label rectangles.

Ship wakes are continuous sampled stern tracks with expanding propeller wash and feathered shoulders. They have no randomly re-seeded turn textures. The attack and damaged-ship shots share one global path and wake history. Close-up water texture is rendered at screen density.

The camera tracks the decisive run into the stern and then presents a side section and a twin-rudder plan. Flooding, distorted stern structure and blocked steering illustrate the failure. The panel is explicitly marked **schematic reconstruction**: surviving accounts and later forensic interpretations differ about the precise impact side and detailed mechanism. The drawn plate shape, flooding pattern, blade angle and linkage are explanatory, not measurements from the wreck. The old “rudders jammed” overlay has been removed.

## Gunnery treatment

Shells fire in discrete groups with brief muzzle flashes, lingering smoke, travel time, target lead and clustered fall of shot. They are small projectiles rather than continuous glowing beams. Main turrets train toward target bearings; masked aft batteries are excluded from firing.

The Denmark Strait sequence advances at **30×** speed and uses approximately **32 seconds of real shell-flight time at 20 km**. The final engagement presents selected moments at **10×** speed, with shorter flights as ranges close. Rodney's alternating five- and four-gun groups are reduced when the third turret cannot bear. The Prince of Wales illustration uses a reduced forward battery.

This is an illustrative reconstruction, not a complete shot-by-shot simulation. Exact individual firing times, every malfunction, projectile dispersion and all maneuver tracks are not known or reproduced. Ship symbols and splash offsets are enlarged for legibility; weapon distances are compressed on the tactical diagram. Key event times, firing-group logic and ballistic delays are distinguished from those display choices. The route on the geographic map is schematic between known waypoints.

## Visual reference and research

[BazBattles — Operation Rheinübung: Hunt for the Bismarck 1941](https://www.youtube.com/watch?v=zuG4qFXPMmk) informed the use of overhead ship symbols, wakes, leader labels and map-based transitions. All visible artwork is original except the public-domain geographic data. The current video is silent.

Historical and technical references:

- [KBismarck: technical characteristics](https://www.kbismarck.com/genedata.html).
- [KBismarck: armament](https://www.kbismarck.com/armament.html), including turret locations and firing arcs.
- [38 cm range table](https://kbismarck.com/38cm.html), extrapolated from original German projectile curves; approximately 32 seconds at 20,000 m.
- [HMS Rodney preliminary gunnery report, 27 May 1941](https://www.kbismarck.com/rodney-gunnery-report.html), especially the 5/4 salvo method and restrictions on X turret.
- [KBismarck: operational chronology](https://www.kbismarck.com/histoperi.html).
- [Royal Navy: Swordfish attack](https://www.royalnavy.mod.uk/news/2021/may/26/20210526-bismarck-hit).
- [Bismarck appearance and paint schemes](https://kbismarck.com/drawings.html).
- [Heller Bismarck model assembly/plan reference](https://www.super-hobby.co.no/zdjecia/8/9/2/55841_instruction.pdf). Consulted for general layout; its artwork is not embedded.
- [Natural Earth 1:10m land](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_10m_land.geojson), public-domain detailed coastline data in `land-detail.geojson`.
- [Natural Earth 1:50m lakes](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_50m_lakes.geojson) and [rivers](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_50m_rivers_lake_centerlines.geojson), in `lakes.geojson` and `rivers.geojson`.
- [ADM 267/137 survivor interrogation reports](https://www.kbismarck.com/archives/survivor-reports.pdf), primary evidence for damage and attempted repairs.
- [Garzke and Dulin: Bismarck forensic analysis](https://www.navweaps.com/index_inro/INRO_Bismarck.php), for later interpretation of the stern and steering damage.

## Edit and render

Requires macOS with Xcode Command Line Tools and Python 3.9+.

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python ocean.py
swiftc -O render.swift -o render
FFMPEG=$(.venv/bin/python -c 'import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())')
./render . "$FFMPEG"
```

Use `./render . --audit` to check bow/velocity alignment, offshore opening hulls, equal formation speed, horizontal inspection, torpedo contacts and camera continuity. Use `./render . --stills` for review frames, or `./render . "$FFMPEG" --preview` for a 112-second review of the opening and torpedo/steering sequence. Edit `cameraKeys`, `drawWorld`, `routePose`, `attackPlane`, `denmark`, `finalBattle` and `makePlan` to change the sequence. Normal rendering exports the full film.

`ocean.py` creates the sea texture procedurally. `soundtrack.py` is retained only as an optional source from the earlier version; it is not used for the current silent release. These scripts require no API keys.
