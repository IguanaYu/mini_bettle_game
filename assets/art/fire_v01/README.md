# Fire Art V01

Created: 2026-10-12.
Generation method: built-in image_gen through the imagegen skill, with the approved sample artwork as style references. No CLI/API fallback, no replacement of the original samples.

## Files and References

| File | Purpose | Reference | Background |
| --- | --- | --- | --- |
| practice_target.png | Wooden practice target | ../../art_samples/v01/overall_preview.png | Real PNG alpha |
| soot_enemy.png | Small charcoal/burgundy enemy | ../../art_samples/v01/player_mage.png | Real PNG alpha |
| burning_ground.png | Sustained fire pool | ../../art_samples/v01/fire_vfx_samples.png | Real PNG alpha |

All three files are used by the actual game. GameArt caches AtlasTexture regions to trim transparent padding without modifying the original PNGs. The mage, floor and four-stage flame atlas remain in assets/art_samples/v01/ and are now also used by the game. The overall_preview.png is still a generated concept mockup, not a game screenshot.

The four flame atlas cells represent casting, travel, impact and embers. They are not sequential animation frames. The first playable version animates them through time-driven scaling, rotation, opacity, trails and deterministic sparks. Character animation uses the idle sprite, horizontal flipping, bobbing and hit/death feedback, not a hand-authored directional animation sheet.

Style guide and real rendered screenshots: ../../../docs/art_style_fire_v01.md.

## Exact Generation Prompts

### Wooden Target

Reference image: assets/art_samples/v01/overall_preview.png.

```text
Use case: stylized-concept
Asset type: one isolated transparent 2D game training target sprite.
Input images: image 1 is a style reference only, the approved overall game art preview. Preserve its modest wooden training target design; extract and redraw only the target as a new clean sprite.
Primary request: one compact wooden freestanding round practice target, off-white and muted terracotta concentric bullseye rings, thick slightly worn gray-brown wooden rim, two short sturdy wooden feet. Viewed from a high top-down three-quarter game camera, about 55 degrees downward. Entire object fully visible centered with transparent padding, no projectiles, no fire, no damage. Match the simple softly hand-painted cartoon style of the mage and stone floor. Broad painted shapes, restrained dark contour, minimal wood-grain detail. Readable at 48 pixels tall. Uniform soft upper-left light.
Constraints: one target only, real alpha transparency, no floor, no shadow, no pedestal scene, no text, no numbers, no watermark, no frame, no sprite sheet. Do not copy the whole reference arena. Deliver the isolated intact target.
```

### Soot Enemy

Reference image: assets/art_samples/v01/player_mage.png.

```text
Use case: stylized-concept
Asset type: one isolated transparent 2D game enemy sprite for a top-down survivor prototype.
Input images: image 1 is a style reference only, the approved teal-hooded mage. Match its clean softly hand-painted non-pixel cartoon rendering, compact proportions, smooth silhouette, muted body colors, restrained dark contour and broad painted shadow planes.
Primary request: one small hostile soot creature, squat rounded charcoal-gray body, two short pointed horns, short arms and stubby dark feet, pale ivory eyebrow-like eye shapes above two small ember-red eyes. A slightly grumpy expression, cute but clearly distinct from the friendly teal mage. A few dark muted burgundy patches on the body. No clothing, no weapons. High top-down three-quarter camera around 55 degrees down. Neutral standing pose facing slightly left, compact strong silhouette. Entire body visible centered at 75 percent canvas height, transparent padding. Must read at 40 pixels tall.
Constraints: real alpha transparency, one creature only, no environment, no ground shadow, no glow cloud, no text, no logo, no border, no sheet, no realistic fur, no photorealistic material, no huge grin, no cinematic view. This is a new enemy asset, do not modify or reproduce the reference mage.
```

### Burning Ground

Reference image: assets/art_samples/v01/fire_vfx_samples.png.

```text
Use case: stylized-concept
Asset type: one isolated transparent top-down 2D game burning ground area texture for a fire magic spell.
Input images: image 1 is the approved fire VFX atlas, a style and flame palette reference only.
Primary request: a compact circular burning patch on the ground, viewed exactly from overhead. Scorched charcoal ground visible in the center with a few orange glowing thin irregular fissures, a broken irregular ring of small curling orange/gold flame tongues around the perimeter. A few small ember flecks within the circle. Bright yellow cores restricted to flame tips. The center remains relatively calm and transparent enough to suggest dark ground, rather than a white explosion. All visible flame tips stay within a circular footprint, with ample fully transparent padding beyond it. This represents sustained ground fire, not an explosion or a blast hole. Match smooth non-pixel hand-painted cartoon flame shapes, restrained soft glow and crisp ragged outlines from the reference. Readable when the entire patch is rendered at 80 pixels diameter.
Constraints: real alpha transparency, isolated circular effect only, no rectangular stone floor, no background, no character, no props, no smoke cloud, no huge tall flame, no vignette, no text, no watermark, no border, no grid. One single texture, not a sheet.
```
