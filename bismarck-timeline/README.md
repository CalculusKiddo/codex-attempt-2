# Operation Rheinübung — silent script-cue edition

A five-minute original 2D documentary animation: **1920 × 1080, 24 fps, H.264 MP4, no audio stream**. All artwork is drawn in native code; no AI-generated imagery is used.

[Download the current full-quality MP4](https://github.com/CalculusKiddo/codex-attempt-2/releases/download/bismarck-2d-v7-continuity/bismarck-timeline.mp4).

The action fills the frame. The old header, footer, progress bar, ship-name leaders and large explanatory captions are removed. Small bottom-left cues identify shots for a separate script. `script-cues.csv` lists those cues and timecodes.

## Continuity and staging

Bismarck and Prinz Eugen remain in view together during departure and the horizontal inspection. The camera accommodates both hulls; the companion is not hidden for a close-up. Ships continue on evaluated tracks when offscreen. Departure, geographic passage, tactical battles and later dates use different drawing coordinate systems; explicit changes of place or date are not a claim that the whole operation occurs in one local ocean square.

`tracked-ships.json` registers 17 ships, including Suffolk, Norfolk, Victorious, Ark Royal, Sheffield, Rodney, King George V, Dorsetshire and the five named night destroyers. `ship-state-ledger.csv` records their on-screen, offscreen, sunk or other-location state every half-second during the active chapters. Empty coordinates mean that the ship is at another location, not that its position is known to be zero or that it has ceased to exist.

Reported historical positions are separated from animation coordinates. `reported-position-anchors.csv` transcribes a selection of King George V positions from the official despatch appendix, retaining the source's time basis. The film uses enlarged geographic symbols, compressed tactical ranges, interpolated tracks and accelerated time. It is **not an exact continuous navigation log** for every vessel; surviving sources do not establish every intermediate position. The tracked identities and documented relative stations are preserved without inventing that precision.

Suffolk shadows on the starboard quarter, while Norfolk and Prince of Wales cover the port quarter. The escape shows cruiser zigzags near radar range and Bismarck's starboard turn astern. Returns become intermittent, then disappear, while the ship itself remains visible to the viewer. Radar-style acquisition and search pulses are explanatory graphics, not a reproduction of a 1941 display.

The Catalina is a distinct flying-boat drawing. Its water takeoff is from Lough Erne, not an aircraft carrier. The widening search view retains Ark Royal; the later visual sighting uses a contact pulse and is captioned as visual contact.

## Aircraft and weapons

The geographic Ark Royal and its close-up share projected position, scale and heading at the start of the zoom. Three representative Swordfish roll out in order, fly toward Sheffield, drop their carried torpedoes, circle back on separated landing approaches, brake on deck, rearm and launch again. The second launch continues directly into the final approach. Aircraft are not replaced by newly appearing airframes mid-flight. The representative aircraft count is not the historical strength of every strike.

Torpedoes start at the same leading-tip position as their underslung carried bodies, drop slightly into the sea, decelerate through water entry and run unguided. The Sheffield sequence shows a premature water detonation and running torpedoes evaded during the turn, without Sheffield firing at the friendly aircraft. The final attack has an amidships hit, a miss and a stern hit. Tip contacts use the actual rendered hull polygon and swept intersections; foam persists after the body reaches contact. The separate Victorious night attack likewise has one representative hit and two misses.

Selected salvos replace the earlier continuous volume of fire. Battle formations move, gun mounts train, and shell launch points agree with the rendered muzzle positions. A live close-up follows the decisive shell toward Hood. The probable penetration and aft-magazine explosion are explained with a small unlabelled section diagram and a short script cue. Hood's hull breaks and submerges; it is not restored later.

Bismarck progressively scorches, rolls and submerges in the final sequence. **Only Bismarck sinks there**. Rodney, King George V, Norfolk and Dorsetshire remain afloat and continue moving. The stern steering section is an explanatory reconstruction; precise impact side, plate deformation and failure geometry remain uncertain.

## Art and water

Detailed original overhead plans are rendered at 4096-pixel source width. Class transforms, decks, fittings, turret mounts, railings and gun endpoints share a hull boundary. Destroyers have a separate narrow, twin-funnel plan. The hull constraint on barrel endpoints is a presentation choice for this film, not a statement that real guns could never overhang the side.

Ark Royal has planked deck detail, lifts, arresting wires, runway markings, island glazing, funnel and edge fittings. Swordfish have ribs, bracing, roundels, propellers and visible underslung torpedoes; the Catalina has a boat hull, parasol wing, twin engines and floats.

Animated wave crests overlay the procedural sea. Wakes follow past stern positions through turns, use a consistent foam lifetime and respect each hull's dimensions. Restrained rain streaks are a separate wind-driven screen layer. Explosions combine expanding shock rings, water columns, fire, sparks and drifting smoke instead of stacks of identical white circles.

## Ending

- **04:48:** fade to black begins while the surviving British ships remain afloat.
- **04:49–04:54:** human cost, `2,000+ DEAD` and `~100 SURVIVORS`.
- **04:54–05:00:** only `OPERATION RHEINÜBUNG` and `18–27 MAY 1941`.

The survivor figure is deliberately approximate, as requested.

## Validation

`continuity-audit.txt` checks aircraft spacing, carried-to-released torpedo continuity, Sheffield's evasion, hull separation during manoeuvres, paired opening framing, matched carrier zoom and unchanged ship membership within each scene. Its ledger is generated from actual renderer draw calls.

`hull-audit.txt` checks 18,360 muzzle positions across 360 degrees and 4.89 million visible raster pixels across 144 ship/bearing combinations. Only subpixel antialias coverage crosses a mathematical edge. `hull-fit-review.png` shows the six ship plan types. `video-verification.json` records the final duration, frame count, video-only stream layout, file size and SHA-256 digest. The exported MP4 is decoded end to end with ffmpeg's error-stop option before release.

## Historical sources and limits

- [Admiral Tovey's official despatch, ADM 234/509](https://www.hmshood.org.uk/reference/official/adm234/adm234-509tovey.htm): shadowing stations, loss of contact during zigzags, Force H, Sheffield's evasion and withdrawal, the night destroyers, and King George V's reported positions.
- [Admiralty war diary](https://www.kbismarck.com/admiralty-war-diary.html): contemporary operational reports and Force H chronology.
- [Leonard B. Smith's Catalina report, NHHC](https://www.history.navy.mil/research/library/online-reading-room/title-list-alphabetically/s/sinking-of-the-bismarck/the-scouting-and-search-for-bismarck.html): the flying-boat search and contact. The contact graphic does not imply Catalina radar detected the ship.
- [Coastal Command operations report](https://www.kbismarck.com/coastal-command-bismarck.html): search patrols, Lough Erne and subsequent shadowing.
- [Hood loss enquiry, ADM 116/4351](https://www.hmshood.org.uk/reference/official/adm116/adm116-4351_to59.htm): probable shell penetration and aft-magazine explosion. The exact shell path in the section is illustrative.
- [Bismarck survivor interrogation reports, ADM 267/137](https://www.kbismarck.com/archives/survivor-reports.pdf), and [Garzke/Dulin forensic discussion](https://www.navweaps.com/index_inro/INRO_Bismarck.php): steering damage and competing interpretations.
- [Bismarck technical characteristics](https://www.kbismarck.com/genedata.html), [armament](https://www.kbismarck.com/armament.html), [38 cm range table](https://kbismarck.com/38cm.html), and [Rodney's preliminary gunnery report](https://www.kbismarck.com/rodney-gunnery-report.html): plan proportions, gun arrangements and representative salvo/flight treatment.
- [BazBattles reference video](https://www.youtube.com/watch?v=zuG4qFXPMmk): overhead documentary presentation only; its artwork is not embedded.
- Public-domain Natural Earth [1:10m land](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_10m_land.geojson), [1:50m lakes](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_50m_lakes.geojson), and [rivers](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_50m_rivers_lake_centerlines.geojson).

Contemporary accounts contain conflicting times, estimates and mistaken identifications. A cinematic path, selected salvo or section illustration should not be read as a proven frame-by-frame forensic reconstruction. Scuttling and torpedo contributions to Bismarck's final loss are not adjudicated by the sinking animation.

## Edit and render

Requires macOS, Xcode Command Line Tools and Python 3.9+.

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python ocean.py
swiftc -O render.swift -o render
FFMPEG=$(.venv/bin/python -c 'import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())')
./render . --continuity-audit
./render . --hull-audit
./render . --stills
./render . "$FFMPEG"
```

The render produces `bismarck-silent.mp4`; the release asset is named `bismarck-timeline.mp4`. No soundtrack is generated or mixed. The older optional score source is not used.
