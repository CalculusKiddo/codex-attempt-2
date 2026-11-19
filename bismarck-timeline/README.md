# Operation Rheinübung — silent script-cue edition

A seven-and-a-half-minute original 2D documentary animation: **1920 × 1080, 24 fps, H.264 MP4, no audio stream**. All artwork is drawn in native code; no AI-generated imagery is used.

[Download the current full-quality MP4](https://github.com/CalculusKiddo/codex-attempt-2/releases/download/bismarck-2d-v13-final-stations/bismarck-timeline-v13.mp4).

The action fills the frame. The old header, footer, progress bar and large explanatory captions are removed. Compact ship-name leaders are restored specifically for the final action, as requested. Small bottom-left cues identify shots for a separate script. The cruiser contact, zigzag and search cues explicitly name **HMS Suffolk** and **HMS Norfolk**. `script-cues.csv` lists those cues and timecodes.

## Continuity and staging

Bismarck and Prinz Eugen remain in view together during departure and the horizontal inspection. The camera accommodates both hulls; the companion is not hidden for a close-up. Ships continue on evaluated tracks when offscreen. Departure, geographic passage, tactical battles and later dates use different drawing coordinate systems; explicit changes of place or date are not a claim that the whole operation occurs in one local ocean square.

`tracked-ships.json` registers 17 ships, including Suffolk, Norfolk, Victorious, Ark Royal, Sheffield, Rodney, King George V, Dorsetshire and the five named night destroyers. `ship-state-ledger.csv` records their on-screen, offscreen, sunk or other-location state every half-second during the active chapters. Empty coordinates mean that the ship is at another location, not that its position is known to be zero or that it has ceased to exist.

Reported historical positions are separated from animation coordinates. `reported-position-anchors.csv` transcribes a selection of King George V positions from the official despatch appendix, retaining the source's time basis. The film uses enlarged geographic symbols, compressed tactical ranges, interpolated tracks and accelerated time. It is **not an exact continuous navigation log** for every vessel; surviving sources do not establish every intermediate position. The tracked identities and documented relative stations are preserved without inventing that precision.

Suffolk shadows on the starboard quarter, while Norfolk and Prince of Wales cover the port quarter. Prince of Wales remains in the shadowing view and then turns away to rejoin the fleet; it is not removed between those shots. The escape shows cruiser zigzags near radar range and Bismarck's starboard turn astern. Returns become intermittent, then disappear, while the ship itself remains visible to the viewer. Radar-style acquisition and search pulses are explanatory graphics, not a reproduction of a 1941 display.

The Catalina is a distinct flying-boat drawing. Its water takeoff is from Lough Erne, not an aircraft carrier. The widening search view retains Ark Royal; the later visual sighting uses a contact pulse and is captioned as visual contact.

## Denmark Strait approach and fuel damage

The 01:12 passage now opens into a full minute of British approach: a Scapa Flow route marker, Hood leading Prince of Wales, the parallel course, the turn in at 28 knots and sighting before opening fire. The camera ends at the exact projected hull positions and scales used by the battle. These tracks illustrate the documented sequence, not precise reported fixes throughout the approach. Prinz Eugen moves into the German lead with lateral passing clearance.

The battle lasts 72 seconds. Prince of Wales scores a bow hit and a below-belt hit; the bow projectile passes through without detonating. Oil trails the moving ship. The aftermath includes a small section showing flooded bow compartments, isolated forward fuel and a separate below-belt flood. Fuel leaking out and fuel made inaccessible by flooding are different problems. Reduced speed and endurance lead into a planned French repair-port route, followed by the existing pursuit. No exact lost-fuel tonnage is asserted.

## Aircraft and weapons

The geographic Ark Royal and its close-up share projected position, scale and heading at the start of the zoom. Three representative Swordfish roll out in order, fly toward Sheffield, drop their carried torpedoes, circle back on separated landing approaches, brake on deck, rearm and launch again. The second launch continues directly into the final approach. Aircraft are not replaced by newly appearing airframes mid-flight. The representative aircraft count is not the historical strength of every strike.

Torpedoes start at the same leading-tip position as their underslung carried bodies, drop slightly into the sea, decelerate through water entry and run unguided. The Sheffield sequence shows a premature water detonation and running torpedoes evaded during the turn, without Sheffield firing at the friendly aircraft. The final attack has an amidships hit, a miss and a stern hit. Tip contacts use the actual rendered hull polygon and swept intersections; foam persists after the body reaches contact. The separate Victorious night attack likewise has one representative hit and two misses. At 04:27–04:35 a live enlargement follows the actual carried torpedo and its hull contact at approximately 04:30. A waterline flash, spray, persistent foam and a small surface scar make the impact visible while the hull keeps moving. The main belt resists penetration; the brief captions explain why the hit did not stop the ship. The carrier, other aircraft and shadowers remain on their existing map tracks. The older five-minute cut placed this episode around 02:09.

At approximately 03:01, a selected Prince of Wales return salvo now visibly travels toward Bismarck while German fire continues. This is representative staging of the documented exchange after Hood’s loss, not a claim to an exact salvo log. Withdrawal smoke originates at the moving funnel, with fixed emission births, asymmetric contours, size and shade variation, wind drift and finite lifetimes. Gun smoke likewise starts at the rendered muzzle. During the Swordfish approach from 05:27, nine staggered representative AA rounds show a mount flash, short shell path and airburst; each smoke cloud has that visible cause. The aircraft continue on their tracks without invented losses.

Selected salvos replace the earlier continuous volume of fire. Battle formations move, gun mounts train, and shell launch points agree with the rendered muzzle positions. A live close-up follows the decisive shell toward Hood. The probable penetration and aft-magazine explosion are explained with a small unlabelled section diagram and a short script cue. Hood's hull breaks and submerges; it is not restored later.

The final action (06:30–07:18) now uses north-up, chart-derived schematic tracks for Bismarck, HMS Rodney, HMS King George V, HMS Norfolk and HMS Dorsetshire. All five carry explicit moving name labels. Rodney and King George V approach from WNW, separate, make independent closing passes and then retire north-east; offscreen retirement markers preserve their names. Norfolk maintains a separate flank station, and Dorsetshire approaches from the opposite quarter before moving around the bow. The final three representative torpedoes use swept hull contacts: two against the starboard side and one against the port side. British gunfire stops before the closing Dorsetshire sequence.

Selected stations are interpreted from the British track chart reproduced by INRO/NavWeaps and checked against Tovey’s and Patterson’s reports. Symbols are enlarged and intermediate turns/spacing are interpolated for readable hull separation. These drawing coordinates do not establish exact bearings, ranges, speeds or geographic fixes at every frame. Contemporary reports differ on details and times. `final-action-stations.csv` records the source-supported relations used in the staging. The night destroyers are not relocated into an invented close gunfire ring; Maori’s later rescue role remains documented, and ships elsewhere retain their registry identities.

Bismarck progressively scorches, rolls and submerges in the final sequence. **Only Bismarck sinks there**. Rodney, King George V, Norfolk and Dorsetshire remain afloat and continue moving. The stern steering section is an explanatory reconstruction; precise impact side, plate deformation and failure geometry remain uncertain.

## Art and water

Detailed original overhead plans are rendered at 4096-pixel source width. Class transforms, decks, fittings, turret mounts, railings and gun endpoints share a hull boundary. Destroyers have a separate narrow, twin-funnel plan. The hull constraint on barrel endpoints is a presentation choice for this film, not a statement that real guns could never overhang the side.

Ark Royal has planked deck detail, lifts, arresting wires, runway markings, island glazing, funnel and edge fittings. Swordfish have ribs, bracing, roundels, propellers and visible underslung torpedoes; the Catalina has a boat hull, parasol wing, twin engines and floats.

Animated wave crests overlay the procedural sea. Wakes follow past stern positions through turns, use a consistent age and distance fade and respect each hull's dimensions. Restrained rain streaks are a separate wind-driven screen layer. Explosions combine expanding shock rings, water columns, fire, sparks and drifting smoke instead of stacks of identical white circles.

## Ending

- **07:18:** fade to black begins while the surviving British ships remain afloat.
- **07:19–07:24:** human cost, `2,000+ DEAD` and `~100 SURVIVORS`.
- **07:24–07:30:** only `OPERATION RHEINÜBUNG` and `18–27 MAY 1941`.

The survivor figure is deliberately approximate, as requested.

## Validation

`continuity-audit.txt` checks aircraft spacing, carried-to-released torpedo continuity, Sheffield's evasion, hull separation during manoeuvres, paired opening framing, matched carrier zoom and unchanged ship membership within each scene. Its ledger is generated from actual renderer draw calls.

`final-action-audit.txt` samples the new five-ship tracks at 24 fps for hull separation, opening framing, motion alignment, relative stations, north-east retirement and the side of all three Dorsetshire contacts.

`weapon-contact-audit.txt` records the corrected Victorious impact at local hull x ≈ 20.03, y ≈ +17.70 (starboard amidships), with the other two representative torpedoes missing. The launch heading and carrier station are adjusted together, preserving the carried-to-released weapon position.

`long-edit-audit.txt` checks the added approach for coastline intersections, hull overlaps, framing, sideslip and a matched battle handoff, and exports the extended ledger.

`hull-audit.txt` checks 18,360 muzzle positions across 360 degrees and 4.89 million visible raster pixels across 144 ship/bearing combinations. Only subpixel antialias coverage crosses a mathematical edge. `hull-fit-review.png` shows the six ship plan types. `video-verification.json` records the final duration, frame count, video-only stream layout, file size and SHA-256 digest. The exported MP4 is decoded end to end with ffmpeg's error-stop option before release.

## Historical sources and limits

- [Captain Patterson’s final-action report](https://www.kbismarck.com/patterson-bismarck-report.html): Rodney’s opening station relative to King George V, courses, phases, retirement and ceasefire.
- [British final-action track chart reproduced by INRO/NavWeaps](https://www.navweaps.com/index_inro/no21993-pic3.jpg): selected schematic stations and the broad shapes of the independent tracks; the chart is referenced, not embedded as artwork.
- [Admiral Tovey's official despatch, ADM 234/509](https://www.hmshood.org.uk/reference/official/adm234/adm234-509tovey.htm): shadowing stations, loss of contact during zigzags, Force H, Sheffield's evasion and withdrawal, the night destroyers, and King George V's reported positions.
- [NHHC British–American cooperation account](https://www.history.navy.mil/research/library/online-reading-room/title-list-alphabetically/s/sinking-of-the-bismarck/british-american-cooperation.html): fuel leakage, saltwater contamination and the decision to seek a French port.
- [Admiralty war diary](https://www.kbismarck.com/admiralty-war-diary.html): contemporary operational reports and Force H chronology.
- [Leonard B. Smith's Catalina report, NHHC](https://www.history.navy.mil/research/library/online-reading-room/title-list-alphabetically/s/sinking-of-the-bismarck/the-scouting-and-search-for-bismarck.html): the flying-boat search and contact. The contact graphic does not imply Catalina radar detected the ship.
- [Coastal Command operations report](https://www.kbismarck.com/coastal-command-bismarck.html): search patrols, Lough Erne and subsequent shadowing.
- [Hood loss enquiry, ADM 116/4351](https://www.hmshood.org.uk/reference/official/adm116/adm116-4351_to59.htm): probable shell penetration and aft-magazine explosion. The exact shell path in the section is illustrative.
- [Bismarck survivor interrogation reports, ADM 267/137](https://www.kbismarck.com/archives/survivor-reports.pdf), and [Garzke/Dulin forensic discussion](https://www.navweaps.com/index_inro/INRO_Bismarck.php): bow and below-belt damage, flooding, inaccessible forward fuel, steering damage and competing interpretations.
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
./render . --final-audit
./render . --long-audit
./render . --export-cues
./render . --hull-audit
./render . --stills
./render . "$FFMPEG"
```

The render produces `bismarck-silent.mp4`; this release asset is named `bismarck-timeline-v13.mp4`. No soundtrack is generated or mixed. The older optional score source is not used.
