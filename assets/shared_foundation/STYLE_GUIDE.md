# Iron-Mario pixel style

## Read the game first

Use warm paper `#faf3df`, dark ink `#29263d`, pale architectural marks `#dedbcc`, blue rails `#4d94e4`, coral hazards `#f16458`, and gold, teal, and violet accents. The current arcade boards have a large quiet playfield, clear center, simple bold silhouettes, and playful detail near their edges. Preserve that language.

## Pixel craft

- Draw at 320×180 or at a 16×16 sprite scale. Scale only by integer factors with nearest-neighbor filtering.
- Use crisp stepped silhouettes, two or three flat tones, and deliberate highlight pixels. Avoid gradients, blur, photographic texture, antialiasing, and the generic navy dashboard treatment.
- Keep the center readable for each game's existing controls. Put dense decoration around the perimeter.
- Use the six town residents: Milo, Jun, Bea, Nia, Ash and Pip. The former cinematic superhero identities are retired from the active selector. Character choices are cosmetic.
- Use restrained animated effects: short readable frames plus a quiet static/reduced-motion state.

## Source policy

Selected full Modern Interiors, complete Fantasy Battlers and Fungus Cave artwork uses LimeZu credit. The complete Battlers and Cave commercial-use declarations were checked on the author's product pages on 2026-10-10. Free/demo versions remain reference-only. Applications and raw source packs are not game exports. Source decisions are recorded in `source_inventory.json`.

## Animation and placement

- Character cells are 16×32, with a bottom-centre anchor (8,32).
- The source guide labels y=32 as animated idle and y=64 as walking. Run uses walk poses at a faster rate, not an invented separate source animation.
- Clean cast exports have static idle, walk, animated idle, hit and hurt strips. Missing jump/landing/defeated and accessory work remains explicitly tracked.
- Room previews are 320×180. Library contact sheets are review aids, not assets to stretch into gameplay.
- Sprite PNG imports use lossless compression, no mipmaps, and nearest-neighbour filtering on consuming Godot nodes.
