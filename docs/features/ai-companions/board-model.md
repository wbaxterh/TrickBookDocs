---
sidebar_position: 4
title: "The Board Model"
---

# The Board Model

Status: **Audited against code 2026-07-12** · file: `TrickList/src/components/companion/KaoriStage.tsx`

How Kaori's snowboard is generated, how it moves during tricks, and the path to per-design board files (which is also the path to board unlockables and to skateboarding).

:::tip Related pages
Animation internals: [Animation System](/docs/features/ai-companions/animation-system) · Board unlocks in the business model: [Monetization](/docs/roadmap/monetization) · Board tracks for mocap clips: [Motion Capture Pipeline](/docs/features/ai-companions/motion-pipeline)
:::

## How the board is generated: 100% procedural, zero asset files

The snowboard is **not a 3D model file**. It is generated in JavaScript at mount inside `KaoriStage.tsx` — a segmented `THREE.BoxGeometry` that gets vertex-warped into a deck shape:

```ts
function makeBoardGeometry(length, thickness, width, kick): THREE.BufferGeometry {
  const geometry = new THREE.BoxGeometry(length, thickness, width, 48, 1, 8);
  const positions = geometry.attributes.position;
  const half = length / 2;
  const tipStart = 0.74; // outline starts rounding here (fraction of half-length)
  const kickStart = 0.62; // tips start curving up here
  for (let i = 0; i < positions.count; i++) {
    const u = Math.abs(positions.getX(i)) / half;
    if (u > tipStart) {                       // circular outline taper → rounded nose/tail
      const v = (u - tipStart) / (1 - tipStart);
      positions.setZ(i, positions.getZ(i) * Math.sqrt(Math.max(0, 1 - v * v)));
    }
    if (u > kickStart) {                      // quadratic Y lift → rocker / kicked tips
      const k = (u - kickStart) / (1 - kickStart);
      positions.setY(i, positions.getY(i) + kick * k * k);
    }
  }
  geometry.computeVertexNormals();
  return geometry;
}
```

The `TrickBoard` component assembles two of these plus binding hints:

| Part | Geometry | Material |
|------|----------|----------|
| Topsheet | `makeBoardGeometry(1.15, 0.03, 0.27, 0.09)` | sakura pink `#f48fb8`, roughness 0.35, transparent |
| Base | `makeBoardGeometry(1.19, 0.014, 0.3, 0.09)`, offset −4mm | white `#f4f6fb` — 4cm longer/3cm wider so a white rail rim peeks around the pink deck |
| Bindings ×2 | plain boxes `0.16 × 0.04 × 0.2` at x = ±0.24 | near-black `#101319` — purely cosmetic, the feet are **not** attached to them |

The pink was chosen to match Kaori's jacket and pop against the dark floor. Everything above — dimensions, taper/kick fractions, colors, binding spacing — is a hardcoded literal.

## How it moves: no attachment, just shared state

The board is **not parented to the character** anywhere in the scene graph. `<TrickBoard>` and the VRM are siblings in the Canvas, synchronized only through the shared `TrickDemoState` ref each frame:

- `group.rotation.y = rootYaw` — the same yaw (stance + trick spin) is applied to the board group and to `vrm.scene`, so they stay locked through rotations.
- `group.position.y = boardY + 0.045` — the deck rides at ankle height.
- Materials fade with `boardOpacity` — the board fades in/out with the smoothed on-board stance weight.

The subtle part that makes it read correctly:

```ts
state.rootY  = pose.height - hipDropFor(effectiveCrouch);  // character sinks with knee bend
state.boardY = pose.height;                                // board follows only the jump arc
```

**The board follows the jump arc; the character additionally sinks by the hip drop** — so knee bends keep her soles planted on the deck, and in the air both share `pose.height`, which makes the board look strapped to her feet. That "strapped" assumption is load-bearing: it's correct for snowboarding and **architecturally wrong for skateboarding**, where the board separates from the feet and rotates on its own axes. `TrickDemoState` has no independent board channels today — a kickflip cannot be expressed ([animation audit](/docs/features/ai-companions/animation-system#whats-hardcoded)).

## Should the board be a separate file? Yes — in two steps

The founder's instinct is right, and the coupling analysis says it's cheap: **nothing outside `TrickBoard` reads the geometry** — the whole system touches the board only through `boardY / rootYaw / boardOpacity`. Two recommended steps, in build order:

### Step 1 — extract a `BoardSpec` (data, not assets) — do this first

Move the hardcoded literals into a per-design data object:

```ts
interface BoardSpec {
  length: number; width: number; thickness: number; kick: number;
  tipStart: number; kickStart: number;
  deckColor: string; baseColor: string; bindingColor: string;
  bindingSpacing: number;
}
```

This costs an afternoon, keeps the zero-asset-bytes advantage, and immediately unlocks **colorway/shape unlocks** (the monetization build order starts with board designs) and per-companion boards — a skateboard deck is the same warp with different proportions plus wheels/trucks meshes. Procedural = every design is a few hundred bytes of JSON, CDN-free.

### Step 2 — `.glb` board props for premium designs

For real graphics (artwork topsheets, sponsor decks), swap the two procedural meshes inside `TrickBoard` for a loaded `.glb` — the frame logic stays identical. Requirements discovered in the audit:

- **Registration convention:** board long axis = local X, deck top at y ≈ 0.045 + thickness; document it for every asset or a differently-sized model breaks stance visuals (binding spacing ±0.24 matches the character's foot splay only visually).
- **Fade plumbing:** the fade-in/out uses per-frame material `opacity` — a glb's materials need `transparent = true` forced and opacity plumbed per material (or replace fade with a different reveal).
- **Texture constraints:** same rules as the character — PNG/JPEG only on expo-gl, and expect to route textures through the stage's rebake path.
- **Delivery:** per-design glbs reintroduce asset delivery — fold them into the planned CDN move (models off the app binary) rather than bundling.

### And for skateboarding: the board becomes "another character"

Studio precedent (Reallusion's Vicon-captured skateboard pack) is explicit: *never parent the board to a foot bone* — the board is captured and animated as a separate object with its own motion track, synchronized with the rider. The generalization of our current design:

- Add independent board channels to the trick data (`boardRotX/Y/Z`, or a keyframe track per trick — for clip-based tricks, a non-humanoid node track in the same `.vrma`/glTF file).
- Constrain the board to the feet-midpoint **only during grounded phases** (read the VRM foot bones' world positions), release it during flip phases.
- The current follow-the-demo-state pattern already is this system with the constraint permanently on — it extends rather than rewrites.
