# Art Samples V01

Created: 2026-10-11.
Generation method: built-in image_gen through the imagegen skill; no CLI/API fallback.

## Scope

First visual direction sample for the top-down survivor / combat VFX practice project.
Smooth, non-pixel, simplified hand-painted cartoon artwork, a neutral gray stone floor,
a teal mage, and bright orange/yellow fire shapes.

These were originally review samples. On 2026-10-12 the selected mage, floor and
four-stage flame atlas were installed in the main game. The original PNGs are preserved.
The overall preview is an AI-composed style mockup, not an actual gameplay screenshot.
Object scale in the mockup is illustrative. The practice dummy and blue crystals appear
only in this mockup; the game now uses a separately generated target and code-drawn crystals.
See ../../art/fire_v01/README.md for the new target, enemy and ground-fire assets,
and ../../../docs/art_style_fire_v01.md for the style guide and rendered game screenshots.

## Files

| File | Purpose | Size | Alpha |
| --- | --- | --- | --- |
| player_mage.png | Isolated idle character sample | 1254 x 1254 | Transparent |
| stone_floor.png | Stone floor material candidate | 1254 x 1254 | Opaque |
| fire_vfx_samples.png | Four fire attack stage samples, 2 x 2 atlas | 1254 x 1254 | Transparent |
| overall_preview.png | Composed arena style mockup | 1672 x 941 | Opaque |

Fire atlas layout: top-left casting flash, top-right travelling fireball,
bottom-left impact burst, bottom-right ember remnants. Each cell is 627 x 627.
These are four distinct stages, not a finished animation strip.

## Review Notes

- Player silhouette and flame direction are readable in the composed preview.
- The character currently leans toward a cute, soft hand-painted style.
- Floor detail can be reduced further to give combat VFX more visual priority.
- The original review required tile, small-sprite, hitbox and animation validation.
  The first integration now has gameplay and actual-render regression checks; it still
  uses a single idle character sprite and procedural animation, not authored walk frames.
- PNGs were decoded successfully. Player and fire PNGs contain both transparent and visible pixels.

## Exact Generation Prompts

### Player

```text
Use case: stylized-concept
Asset type: one production-style 2D game character sprite sample for a Godot top-down survivor game, square canvas.
Primary request: a small friendly hooded spellcaster, full body, alone, on a truly transparent background. A rounded but distinct hood, warm ivory face with two tiny expressive eyes, muted turquoise/teal robe, pale gray cloth trim, small brass clasp and leather belt, simple dark boots, one short staff with an unlit small pale crystal. Strong readable silhouette. Neutral idle pose facing slightly toward the right, viewed from a high top-down three-quarter game camera (approximately 55 degrees downward); compact body proportions, feet visible below robe. Character should occupy about 78 percent of canvas height with transparent padding all around.
Style/medium: clean non-pixel hand-painted 2D cartoon game sprite, crisp smooth contour, restrained dark outline, broad flat painted color areas and two or three shading values, no fine texture. Appealing modest detail, not a realistic render, not anime splash art, not vector geometry. Lighting from upper left. Must still read clearly when displayed at 48 pixels high.
Constraints: ONE character only, isolated without terrain, no ground shadow, no cast magic, no glow cloud, no text, no logo, no watermark, no border, no sprite sheet, no platform, no realistic proportions.
```

### Floor

```text
Use case: stylized-concept
Asset type: seamless square top-down stone floor texture sample for a 2D Godot combat arena.
Primary request: a tileable medium-dark neutral gray stone floor with broad irregular rectangular flagstones, a few subdued cracks and occasional quiet desaturated green moss in joints. True overhead orthographic view, flat floor only. Pattern is seamless on all four edges. Many broad stone slabs across the tile, softly worn corners and understated hand-painted bevels. Low contrast, restrained detail, readable open surfaces on which small characters and bright elemental VFX will be shown.
Style/medium: non-pixel hand-painted 2D cartoon game background matching smooth simplified character sprites. Crisp but soft-edged brush shading, flat broad painted areas. Ambient even lighting without directional cast shadows. Palette: graphite gray, medium neutral gray, small desaturated sage accents; balanced gray, no dominant blue, purple, beige, or brown. Surface is moderately lit, not black, and no vignette.
Constraints: exactly one seamless floor material texture filling the entire square canvas, no perspective, no walls, no objects, no props, no foliage clusters, no symbols, no runes, no glow, no text, no watermark, no frame.
```

### Fire Samples

```text
Use case: stylized-concept
Asset type: one transparent 2D game fire VFX sample atlas, square canvas arranged in an exact 2 by 2 grid of equal-size cells, no grid lines.
Primary request: four coordinated stages of a stylized orange fireball attack. Top-left cell: small compact casting flash with a few short forward sparks. Top-right cell: a fireball travelling RIGHT, a compact yellow-white core on the right and a curling ragged orange-red flame tail extending to the left. Bottom-left cell: brief impact burst, an irregular expanding broken circular fire splash around a bright small core, several sharp short flame tongues, controlled size. Bottom-right cell: dissipating impact with a handful of small scattered ember flecks and two fading detached curling flame fragments. Every effect centered within its own equal cell, plenty of truly transparent padding between effects. Effects must not cross cell boundaries. These are four sample states, not a looping animation.
Style/medium: non-pixel hand-painted 2D cartoon game effects, bold readable flame shapes and irregular torn contours, clear yellow-white inner core, warm golden orange midtones, coral-red outer flame, smooth crisp silhouette and limited soft transparency only around tiny glow edges. Avoid fluffy uniform orange blobs; flame flow direction and expanding impact silhouette should be immediately clear at small in-game sizes.
Constraints: actual transparent background, no black backdrop, no opaque rectangular patch, no checkerboard drawn into image, no labels, no text, no watermark, no frames, no grid marks, no terrain, no characters, no excessive bloom, no smoke cloud.
```

### Overall Preview

Reference images, in order: stone_floor.png, player_mage.png, fire_vfx_samples.png.

```text
Use case: compositing
Asset type: wide 16:9 in-game visual style preview mockup for an existing Godot top-down 2D survivor prototype. This is a practical gameplay-view art sample, not a promotional illustration.
Input images: Image 1 is the exact stone floor texture sample to use for the arena surface. Image 2 is the exact isolated teal-hooded mage character sprite to use for the player. Image 3 is the fire VFX sample atlas containing casting flash, right-travelling fireball, impact burst, and ember fragments. Preserve the reference artwork's style, palette, and silhouettes.
Primary request: compose these samples into a clean top-down game-camera view of a small rectangular stone-floor combat practice arena, the entire arena visible. Reuse image 1 at a natural repeating floor texture scale, with subdued surface detail, neutral gray and a little sage moss. Thin simple low gray stone border around arena, uniform overhead game lighting. Place ONE instance of the image 2 mage slightly left of center, as an actual small playable character, around 72 pixels tall relative to a 1280x720 gameplay viewport, with a small faint grounding shadow. Face the mage to the right. A modest wooden practice target with an off-white concentric bullseye and two short legs stands further right, matching the cartoon style, at a similar visual scale. Demonstrate a fireball using the top-right atlas sample halfway between player and target, travelling right with the brilliant core forward and curling tail behind. Use a compact impact burst from the bottom-left atlas sample at the target, with a few small ember fragments. These are simultaneous illustrative samples of the attack stages for visual review. Total fire VFX must stay compact: projectile length about 45-65 pixels and impact diameter about 50-65 pixels in that viewport. Keep ample unobstructed floor around every subject. Add three very small blue experience crystals on the floor in the lower middle, simple faceted shapes. No other characters.
Style/medium: authentic non-pixel hand-painted 2D game graphics. Characters and VFX must look like the actual supplied raster assets placed on a floor, avoid painterly scene reinterpretation. Crisp smooth contours, simple shapes, restrained surface texture; maximum contrast reserved for the yellow-white and orange fire effects, mage teal clearly distinct from floor. The shot should look usable and readable, quiet but attractive.
Constraints: orthographic overhead gameplay camera with character sprites in high top-down three-quarter perspective. No cinematic perspective, no landscape scenery, no architecture beyond the thin border, no dramatic lighting, no camera blur, no depth of field, no vignette, no decorative frame, no oversized character illustration, no extreme bloom. No labels, no text, no UI, no logo, no watermark. Show the full 16:9 horizontal arena, not a cropped close-up. Preserve exact supplied player appearance, colors and fire direction.
```

