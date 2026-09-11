---
sidebar_position: 7
title: "Motion Fitter — Video → RiderPose"
---

# The Motion Fitter — Fitting Real Motion to the 14 Channels

Status: **Design draft — 2026-08-02** · target: offline authoring tool + `TrickList/src/components/companion/`

How we turn a captured performance (a phone video → pose estimation) into a `RiderPose` timeline that speaks Kaori's *existing* motion language — so real riding drives her body through the same appliers, board-lock, head-spotting, and sentence cues the hand-authored tricks already use.

:::tip[Related pages]
Upstream capture: [Motion Capture Pipeline](/docs/features/ai-companions/motion-pipeline) · The channels we fit to: [Animation System](/docs/features/ai-companions/animation-system) · Metadata & scaling: [Motion Framework](/docs/features/ai-companions/motion-framework) · Why skate is out of scope: [Board Model](/docs/features/ai-companions/board-model)
:::

## Why fit, instead of just playing a clip

The [Motion Capture Pipeline](/docs/features/ai-companions/motion-pipeline) plan ends at a `.vrma` clip dropped into the registry as `kind: 'clip'`. That is the fast win, and we should ship it. But a clip is a **black box**: Kaori replays motion she can't reason about, retune, or blend with the fundamentals — the moment it plays, the 14 coaching parameters (`sink deeper`, `wind up more`) go dark.

The fitter takes the other road. Instead of *playing* the captured motion, it **projects the captured skeleton onto our 14 `RiderPose` channels**. The output is procedural-equivalent data: a `poseAt(t)` that behaves exactly like a hand-authored trick, but its shape comes from real riding. Everything downstream is unchanged because the representation is unchanged:

- `applyRiderPose` / `applyLegs` / `applyTorsoAndHead` / `applyArms` — reused verbatim.
- `lockBoardToFeet`, the rotation-split at the scene root, head-spotting — reused verbatim.
- Sentence cues and phase segments — still fire, because we emit `phaseMarkers`.
- **Retargeting is free** — the channels are normalized angles and length-fractions, so any VRM (Kaori today, the separate skateboarder character tomorrow) is driven identically. No per-rig retarget hop.

This is the component that turns *"video turned into an animation"* into *"the system understands the motion."*

## Pipeline

```mermaid
flowchart LR
    vid["phone video"] --> pose["pose estimation<br/>WHAM or MediaPipe<br/>joints + root per frame"]
    pose --> norm["normalize & align<br/>axes, scale, stance mirror"]
    norm --> split["root split<br/>swing-twist yaw + pitch"]
    split --> solve["staged channel solve<br/>invert applyRiderPose"]
    solve --> filt["filter & clamp<br/>one-euro on 14 channels"]
    filt --> seg["phase segmentation<br/>pop / air / land markers"]
    seg --> out["FittedTrick<br/>channels + totals + markers"]
    out --> reg["TRICKS registry"]
```

## The core idea: re-derive the rotation-split from data

Kaori's system deliberately separates **gross whole-body rotation** (`rootYaw = totalSpin × spin`, `rootPitch = totalFlip × pitch`, composed at the scene root) from **local articulation** (crouch, coil, tuck…). The fitter's job is to perform the *same* decomposition on captured motion:

1. **Extract the root.** Per frame, build a body frame from the pelvis (SMPL gives `global_orient` directly; from MediaPipe, derive it from the hip line × shoulder line). Decompose that root rotation as `R = Ryaw(worldUp) · Rpitch(boardLongAxis) · Rresidual` — a swing-twist decomposition where the twist axis is the foot-to-foot line (Kaori's local `+X`). This matches her `q = qYaw · qPitch` composition exactly.
2. **Unwrap & normalize.** Accumulate yaw and pitch across frames past `±π` to get continuous totals. `totalSpin` = net yaw between takeoff and landing (snap to the nearest clean `k·2π·dir`); `spin(t)` = the normalized cumulative-yaw progress `0→1`. Same for `totalFlip` / `pitch(t)`.
3. **De-rotate.** Remove the root rotation so the remaining articulation is read in the body-local frame — the frame the appliers assume.

Because the appliers **mix** channels (coil feeds hips → spine → chest → neck; crouch feeds spine + chest; tuck feeds spine + neck + arms), reading a channel off a single bone double-counts. The correct inverse is a **staged solve** that undoes the appliers in dependency order — legs → torso → head → arms — each stage mostly *linear* in its channels given the previous stages, so each is a small, well-conditioned least-squares fit.

## Channel-by-channel mapping

Ranges are taken straight from `riderFundamentals.ts`. "Applier cross-terms" is what must be subtracted so the fitted channel doesn't double-count what another channel already drives.

| Channel | Range (code) | Captured signal | Estimator (after de-rotation) | Applier cross-terms to back out |
|---|---|---|---|---|
| `spin` | `0→1` | body yaw about world-up | unwrapped cumulative yaw, normalized between pop→land | — (this drives the root, not a bone) |
| `pitch` | `0→1` | body tumble about board long axis | swing-twist pitch component, normalized | — |
| `dir` | `±1` | rotation sense | `sign(totalSpin)`, or `sign(totalFlip)` for flips | set once per trick |
| `crouch` | `0.18 → ~0.72` | knee flexion / hip sink | invert `hipDropFor` from hip-to-ankle shortening, cross-checked vs. mean knee angle | — (source of truth for the legs) |
| `height` | `~0 → 0.6` | pelvis rise on the jump arc | `(pelvisY − standingY) × (KaoriHip / subjectHip)`, **minus** the `crouch` hip-drop | disentangle from `crouch` (see below) |
| `coil` | `−0.7 → +0.5` | axial wind of chest vs. hips | `chestYaw_local − hipYaw_local`, scaled by the ~0.45 chest gain; keep **frontside-signed** and let `dir` carry the wind direction | keep timing curve; do not fold `dir` into the sign |
| `tuck` | `0 → ~0.9` | knees toward chest, airborne | normalized knee-height rel. to hips during the air phase | feeds spine.x, neck.x, arms — solve after crouch |
| `balance` | `0 → ~0.8` | arms flung wide on landing | mean shoulder abduction, gated to the land phase | solve after `spin`/`tuck` (arm bells depend on them) |
| `headLead` | rad (yaw) | neck yaw rel. chest | `neckYaw_local − 0.4·(coil·dir)` | subtract the coil-driven `wind·0.4` the applier adds |
| `headSpot` | rad (pitch, + = chin down) | neck pitch rel. chest | `neckPitch_local + 0.15·tuck` | add back the `−tuck·0.15` the applier subtracts |
| `headRoll` | rad (roll) | neck roll rel. chest | `neckRoll_local` | maps ~1:1 to `neck.rotation.z` |
| `backLegLift` | `0 → ~0.9` | back (right) knee-up / foot-lift | normalized right-foot height + knee raise vs. a symmetric baseline | only nonzero when asymmetric (stylish) |
| `frontLegLift` | `0 → ~0.7` | front (left) knee-up / foot-lift | normalized left-foot height + knee raise | regular stance: left = front |
| `boardTilt` | `0` (reserved) | — | leave `0`; the deck derives its angle from the feet | skate needs a real board channel — out of scope, see [Board Model](/docs/features/ai-companions/board-model) |

### The one subtle coupling: `height` vs. `crouch`

Both lower the pelvis, so they must be separated or a deep crouch reads as "sinking through the snow." Because `crouch` is measured independently from **knee angle**, `height` falls out cleanly:

```
observedPelvisDrop = jumpHeightContribution + hipDropFor(crouch)
height ≈ (pelvisY − standingPelvisY) + hipDropFor(crouch)     // add the crouch drop back
```

Solve `crouch` from the knees first; then `height` is whatever vertical is left over.

## Phase segmentation

The five-phase skeleton (setup → pop → air → land → settle) and the `phaseMarkers` the cue system needs come from two signals:

- **Foot contact** — both feet leave the ground → **pop**; first foot re-contacts → **land**. (Foot height + a contact threshold.)
- **Pelvis vertical velocity** — zero-crossing at the top → **apex**; the setup/settle bounds are the crouch-in and stand-up around them.

These markers are exactly what `startAction` and the sentence-cue regexes key off, so a fitted trick stays speech-synced with zero changes to the choreography layer.

## Two methods (ship A, keep B for polish)

- **A — Analytic read-off (v1, recommended).** The staged geometric solve above. Fast, fully interpretable, no training, no dependencies beyond linear algebra. Good enough to *author* from, because the channels are forgiving coaching parameters, not exact bone transforms.
- **B — Optimization by inverting `applyRiderPose` (refinement).** Port the appliers to a differentiable forward model (they're cheap: mostly linear combinations with a few `sin`/clamps). Then per frame, solve for the 14 channels that minimize joint-position error between the **Kaori-posed** skeleton and the **captured** skeleton. This handles every cross-term at once and is the principled inverse; use A as its initial guess so it converges in a few iterations.

## Normalization, retargeting & stance

- **Scale-free by construction.** Every channel except `height` is an angle or a length-*fraction*, so subject-vs-Kaori proportion differences wash out — the headline advantage over fitting raw bone transforms. `height` takes a single hip-height ratio.
- **Axis alignment.** Map the estimator's frame (WHAM/SMPL and MediaPipe world-landmarks differ in up-axis and handedness) to Kaori's convention: `+Z` forward, `+X` her left, `+Y` up.
- **Regular vs. goofy.** If the captured rider is goofy, mirror left↔right and flip `dir` so the fit lands in Kaori's regular-stance assumption.

## Output & integration

```ts
interface FittedTrick {
  id: TrickId;
  duration: number;
  totalSpin: number;              // net yaw, snapped
  totalFlip?: number;             // net pitch for flips
  phaseMarkers: PhaseMarkers;     // pop / apex / land times
  channels: Float32Array[];       // [14][N] baked per-frame RiderPose channels
}
```

A generated `poseAt(t)` samples/interpolates `channels` and returns a `RiderPose` — so a fitted trick becomes a `TRICKS` entry indistinguishable from a hand-authored one. This slots into the discriminated union from the [Animation System](/docs/features/ai-companions/animation-system) audit as a third arm (or simply a `kind: 'procedural'` whose `poseAt` is data-backed):

```ts
type TrickSource =
  | { kind: 'procedural'; poseAt: (t: number) => RiderPose }
  | { kind: 'clip'; vrmaUrl: string; totalSpin: number; phaseMarkers: PhaseMarkers }
  | { kind: 'fitted'; poseAt: (t: number) => RiderPose; totalSpin: number; totalFlip?: number; phaseMarkers: PhaseMarkers };
```

The fitter module stays **three-free** like `trickAnimations.ts` — it emits plain channel arrays; only the runtime `poseAt` touches `RiderPose`.

## Validation

- **Reconstruction error** — RMS distance between captured joints and the Kaori-posed skeleton, per frame. The objective for method B; a regression guard for method A.
- **Visual preview via Blender + `blender-mcp`** — pose the Kaori VRM (or any humanoid) by the fitted channels and render alongside the source clip. This reuses the exact Blender + AI-agent toolchain built for the THPS project, so no new authoring rig is needed.
- **On-device** — the real bar; the fitted `poseAt` runs in `KaoriStage` like any trick.

## Scope & non-goals (v1)

- **Snowboard rotations & flips first** — matches what ships today (`frontside-360`, `backside-360`, stylish, `wildcat`, `tamedog`).
- **Skate tricks are OUT.** A kickflip's board rotates independently of the feet, and **no human-pose estimator captures the board** — it isn't a joint. Skate needs the board tracked as a separate rigid object (object-pose estimation) or its own procedural channels. See [Board Model](/docs/features/ai-companions/board-model).
- **Single camera, single rider.** No multi-person, no occlusion recovery beyond what the estimator provides.
- **Offline authoring, not a runtime feature.** This produces trick assets; it is not the future in-app "analyze *your* trick" coach (same tech, different product — see [Motion Capture Pipeline](/docs/features/ai-companions/motion-pipeline)).

## Build stack

Pose estimation runs in Python (WHAM for dynamic accuracy; MediaPipe for a lightweight path) and dumps a normalized **joints JSON**. The fitter is TypeScript so it can import the real `RiderPose` type, the channel ranges, and (for method B) a port of the appliers. It ships as an offline CLI in the repo's tooling — never in the app bundle.

## Open questions

- **Estimator choice:** does WHAM's world-grounded root hold up on airborne, motion-blurred trick footage where MediaPipe's per-frame root drifts? Bake-off needed on real clips.
- **Coil observability:** is chest-vs-hip axial twist recovered reliably from a single view, or does it need the method-B optimization to be trustworthy?
- **How many source clips per trick** to average into one clean fit vs. shipping a single best take?
- **`totalSpin` snapping:** auto-snap to the nearest clean rotation, or keep the measured under-rotation as authentic style?
