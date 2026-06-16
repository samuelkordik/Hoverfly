# Recovered research payloads

Raw structured output from the multi-agent research workflow that produced the
[firmware review](../firmware-review/index.html), [Orca Slicer guide](../../Orca_Slicer/index.html),
and [calibration guide](../../Calibration_Guide/index.html). Kept here as the source data behind those
guides — the guides are the curated output; these are the unedited findings.

## Why these exist

The workflow ran **10 research agents** (each doing real WebSearch/WebFetch across Marlin docs, Ellis'
Print Tuning Guide, Teaching Tech, RepRap wiki, and vendor/community sources) before the build phase.
The session hit its limit mid-run: only **3** research results were captured and fed the build agents;
the other **7** finished their work but their results were lost when the orchestrator stopped. All 10
were later **recovered from the agent transcripts** and the genuinely-new findings folded back into the
guides (see [the firmware review changelog of findings](../firmware-review/firmware-review.md)).

| File | Topic | Recs | Into build? |
|------|-------|-----:|:-----------:|
| [`firmware.json`](firmware.json) | Prioritized Marlin firmware review | 12 | recovered |
| [`orca.json`](orca.json) | Orca setup, Elegoo PLA, Speed + Quality profiles | 16 | recovered |
| [`cal-esteps-flow.json`](cal-esteps-flow.json) | E-steps / extrusion-multiplier (flow) | 6 | ✅ captured |
| [`cal-pid.json`](cal-pid.json) | Hotend PID autotune (M303) | summary | recovered |
| [`cal-zoffset-firstlayer.json`](cal-zoffset-firstlayer.json) | CRTouch Z-offset / first layer | summary | recovered |
| [`cal-temp-tower.json`](cal-temp-tower.json) | Temperature tower (Elegoo PLA) | 6 | ✅ captured |
| [`cal-retraction-pa.json`](cal-retraction-pa.json) | Retraction + pressure/linear advance | 7 | recovered |
| [`cal-speed-accel.json`](cal-speed-accel.json) | Max speed / acceleration / junction deviation | 7 | ✅ captured |
| [`cal-input-shaping.json`](cal-input-shaping.json) | Ringing / Input Shaping (M593) | 6 | recovered |
| [`cal-bed-mesh.json`](cal-bed-mesh.json) | Bed leveling / mesh (G29) | 6 | recovered |

## Schema

Each file is one research topic:

```jsonc
{
  "topic": "…",
  "summary": "concise overview of findings",
  "recommendations": [
    {
      "title": "…",
      "priority": "High | Medium | Low",
      "currentValue": "current config/slicer value or n/a",
      "recommendedValue": "…",
      "rationale": "why",
      "howToApply": "exact #define / M-code / slicer setting",
      "sources": ["https://…"]
    }
  ],
  "procedure": "step-by-step test + pass/fail (calibration topics only)",
  "imageNeeds": ["…"],
  "stlModel": "test model used, or empty"
}
```

> These are **point-in-time** web-research artifacts (gathered mid-2026). Treat the guides as the
> reviewed, deduplicated version; consult these for the full rationale and source URLs behind a
> recommendation. `cal-pid` and `cal-zoffset-firstlayer` are summary-only (no structured
> recommendations array) — that's how they were returned.
