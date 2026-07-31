---
sidebar_position: 5
title: "Motion Capture Pipeline"
---

# Learning Real Trick Movements — the Motion Pipeline

Status: **Researched 2026-07-12** · sources cited inline; costs verified against vendor pricing pages

The question this page answers: *"We need some way to easily learn and model the proper movements for each trick — should I green-screen videos of people performing them?"* Short answer: **film video, yes; green screen, no** — and deliver the results as `.vrma` clips layered over the procedural fundamentals we already have.

:::tip[Related pages]
Current system + scaling audit: [Animation System](/docs/features/ai-companions/animation-system) · Board tracks: [Board Model](/docs/features/ai-companions/board-model) · Hub: [AI Companions](/docs/features/ai-companions)
:::

## Green screen: skip it

Modern video-to-animation tools run **AI pose estimation directly on the pixels** — they detect the person with learned models, not chroma matting. No vendor capture guide (DeepMotion, Move.ai, Rokoko) asks for a green screen; a plain contrasting background (a wall, an empty lot) gives the same benefit for free.

**What actually improves capture quality** (vendor + practitioner consensus):

- **≥60 fps** — 120/240 slow-mo for airs; fast tricks at 30fps lose joints to motion blur
- **Fast shutter** (1/500s+) — shoot in sunlight; blur = smeared limbs = lost tracking
- **Full body in frame the entire trick** — unframed feet ruin the output; frame wide
- **Static tripod camera**, perpendicular or 3/4 angle
- **Fitted, contrasting clothing** — baggy snow gear and solid black are the enemy (a real conflict for on-snow footage; capture mechanics off-snow where possible)
- **More cameras** is the single biggest quality lever if we ever need it

## The hard case: board tricks are the worst case for mocap

Fast acrobatic rotation is the documented failure mode of every single-camera tool: limb identity swaps mid-spin, depth ambiguity at profile, and foot-locking that assumes flat ground (a rider's "floor" is the deck). Two mitigations matter, and one of them we already built:

1. **Capture body mechanics without the full rotation, keep spin procedural.** Our trick system already separates `pose.spin` (progress) from bone poses and applies `totalSpin` at the scene root — so we film the coil-pop-tuck-land sequence on a **trampoline training board or carpet** (established snowboard practice; our FS360 timeline already cites Snowboard Addiction technique material), and the spin count stays a parameter. One capture serves the 180/360/540 variants.
2. **Treat the board as a separate object, never parented to a foot.** Reallusion's professional skateboard capture concluded "the skateboard is like another character" — rider and board captured as separate tracked objects. Our board already follows its own state ([board model](/docs/features/ai-companions/board-model)).

## Tool landscape (2026, indie budgets)

| Tool | Input | Output | Fast-motion features | Price | Notes |
|------|-------|--------|---------------------|-------|-------|
| **DeepMotion Animate 3D** | single video, cloud | FBX/BVH/GLB, **accepts our VRM directly** | physics filter, foot-lock, slow-mo support | $15–39/mo, commercial license on paid plans | **Primary pick** — best feature fit |
| **QuickMagic** | single video | FBX/BVH/VMD | manual 2D keypoint refinement (great for board-occluded feet) | free tier; $9.9/mo starter | Budget fallback; best cost/quality per reviews |
| **Move.ai (Move One)** | iPhone app, ≤60s takes | FBX/USD | multi-cam tier is the real flip solution | $18/mo+ | Single-cam output jittery per reviews |
| **Rokoko Video/Vision** | webcam/video, free | FBX/BVH | dual-cam mode | free | Blocking quality only; weakest on flips |
| **Plask** | browser | BVH/FBX | — | ~$40/mo pro | Mid-pack |
| **Autodesk Flow Studio** | video | FBX/USD | improved grounding | free tier, $10/mo lite | VFX-oriented, cheap to test |
| **FreeMoCap** (OSS) | 3–4 calibrated cameras | CSV/FBX/.blend | — | $0 | Single-cam unreliable by its own docs; high setup cost — skip for production |
| **Cascadeur** | hand-keyframe + AutoPhysics | FBX/glTF | physics-correct flip trajectories | $19/mo indie | For hero tricks + mocap cleanup; stylized anime timing fits Kaori |
| **ActorCore "Skateboard" pack** | — (buy) | FBX/BVH, 26 Vicon-captured flatground tricks | pro optical capture | ~tens of $ | **Buy first** — validates the whole pipeline; no snow/surf/BMX equivalents exist |

## Delivery format: `.vrma` + three-vrm-animation

The **VRM Animation** spec (`VRMC_vrm_animation` 1.0, `.vrma` files) is the right clip format:

- **Humanoid-normalized by design** — one clip retargets onto *any* VRM at load. Learn a trick once, play it on Kaori, Tony, and every future companion.
- **Same package family we already ship** — `@pixiv/three-vrm-animation` (sibling of our pinned `@pixiv/three-vrm@3.5.2`) provides `VRMAnimationLoaderPlugin` + `createVRMAnimationClip(vrmAnimation, vrm)` → a standard `THREE.AnimationClip` for `AnimationMixer`. Pure three.js — it avoids the expo-gl shader/texture minefield entirely (only the `.vrma` fetch path needs one physical-device verification).
- **Coexists with the speech/face system for free** — our `driveFace` layer only touches VRM expressions, never bones ([why that matters](/docs/features/ai-companions/animation-system#architecture-two-layers-one-owner-at-a-time)). Clips own the skeleton; lip-sync, blink, and emotion keep running on top. For finer mixing later: track-filtered partial clips (three.js has no mask API; filtering `clip.tracks` is the standard approach) and `AnimationUtils.makeClipAdditive` for additive layers.
- **Authoring**: Blender VRM add-on exports `.vrma`; UniVRM converts BVH → `.vrma` (needs T-pose initial pose; drops finger motion).

**Known gotchas (all documented upstream):** clips must follow the VRM T-pose convention (Mixamo conversions fail with hips at floor level otherwise); hips is the only translated bone and must be height-scaled to the target VRM; VRM 0.x clips need a 180° yaw fix (Kaori is VRM 1.0, current spec). Budget 2–3 days once to debug this retarget chain — it's the pipeline's one genuinely fiddly part.

## The hybrid architecture: fundamentals + clips

Keep both motion sources, each doing what it's good at:

| | Procedural fundamentals (keep) | `.vrma` clips (add) |
|---|---|---|
| Used for | Coaching segments (wind-up/pop/land), stance idles, parameterized drills ("sink deeper") | Full-trick showcases with real style |
| Strengths | Speech-cueable, loopable, parametric, zero assets | Fidelity, authoring speed at scale, real rider motion |
| Registry entry | `{ kind: 'procedural', poseAt }` | `{ kind: 'clip', vrmaUrl, totalSpin, phaseMarkers }` |

`phaseMarkers` (setup/pop/air/land timestamps, same shape as today's FS360 phase constants) keep the [sentence-cue system](/docs/features/ai-companions/animation-system#sentence-cues) and the board renderer working identically against clips. Per-sport **fundamentals stay parametric** (surf stance is wider/lower; BMX needs new arm appliers and its own prop system) while **tricks become retargetable clips**.

## The production pipeline (recommended rollout)

**Phase 0 — validate the pipeline (~$50, a weekend):** buy the ActorCore skateboard pack (26 pro-captured flatground tricks) and push one trick end-to-end: FBX → Blender retarget → `.vrma` export → Bunny CDN → `createVRMAnimationClip` on the stage, phaseMarkers wired to sentence cues. This debugs the T-pose/hips-scale chain on known-good data before any filming, and hands Tony a launch trick library as a side effect.

**Phase 1 — the filming pipeline (steady state ≈ 1.5–4 h/trick):**

```
film rider (60–240fps, checklist above; trampoline board for spins)
  → DeepMotion Animate 3D (upload Kaori's VRM directly; foot-lock + physics on)
  → Blender cleanup (feet contacts, jitter, zero out root yaw, trim)
  → VRM add-on export .vrma → Bunny CDN → TRICKS registry entry
```

**Phase 2 — hero tricks & style passes:** Cascadeur Indie for hand-keyframed signature moves and for cleaning rough mocap into stylized anime timing (8–24 h/trick initially; spin variants become duplicate-and-edit jobs).

**Running cost:** ~$40–60/mo tooling (DeepMotion + Cascadeur) + one-time pack purchases — covers all five sports. Hand-keyframing everything instead would run 8–24 h/trick; DIY MediaPipe/FreeMoCap would add multi-camera setup and all the filtering/retargeting engineering, and is only worth revisiting as the substrate for a future in-app "analyze *your* trick" feature — which is a different product on the same technology.
