# Storyline XML: How `story.xml` and a `slide.xml` Work Together

This guide explains how the **main project file** (`story.xml`) connects to an individual **slide file** (`slide.xml`) in an Articulate Storyline project, and how to determine the **scene name** for a given slide.

> **TL;DR**
> - Each slide has a **slide GUID** (globally unique ID) in its own `slide.xml`.
> - `story.xml` contains a **scene list** and a **table of contents (TOC)** that map scenes to slides.
> - To get a slide’s scene name, match the slide’s GUID to a TOC entry in `story.xml`, then read the parent scene’s GUID and look up that scene’s `name` in the scene list.

---

## 1) Roles of the two files

- **`story.xml` (project root):**
  - Owns **global metadata**: variables, media, quiz settings, etc.
  - Defines the **scene list** (`sceneLst`), each `<scene>` having a scene GUID and a human-readable `name`.
  - Provides a **Table of Contents** (`toc`) with entries that **bind scenes to slides** via GUIDs.

- **`slide.xml` (one slide):**
  - Contains a single `<sld ...>` element with the **slide GUID** (`g="..."`) and slide-level metadata (e.g., `name="..."`, layout, triggers, objects).

---

## 2) Key identifiers you’ll see

- **Slide GUID** — The unique identity of the slide.  
  Example (from the provided `slide.xml`):  
  ```xml
  <sld g="01642ff1-fb08-483c-a8a6-c1340c0b8ae7" name="Calcy Groove" ...>
  ```

- **Scene GUID** — The unique identity of a scene, defined in `story.xml`.  
  Example scene element (the project’s scene list):  
  ```xml
  <scene g="c947bcce-2f63-4757-b9f8-50b27cf91dc1" name="Calcy AI" ...>
    <sldIdLst>
      <sldId>R6CWNc9DblRZ</sldId>
      <sldId>R5tBLrsArxPe</sldId>
      <sldId>R5lnTBthZOn1</sldId>
    </sldIdLst>
  </scene>
  ```

- **TOC entries** — In `story.xml`, `<tocSceneEntry>` references a **scene GUID** and contains `<tocSlideEntry>` children that reference **slide GUIDs**. This is the **authoritative mapping** from a slide to its parent scene.
  ```xml
  <tocSceneEntry refG="c947bcce-2f63-4757-b9f8-50b27cf91dc1">
    <tocSlideEntry refG="01642ff1-fb08-483c-a8a6-c1340c0b8ae7" />
    ...
  </tocSceneEntry>
  ```

> Note: The `sldIdLst` under a scene shows slide **short IDs** (like `R6CWNc9DblRZ`). These help Storyline order slides, but the **TOC’s `refG` values** (full GUIDs) are what you’ll use to **bind a slide file to its scene**.

---

## 3) How `story.xml` defines an individual slide

There are two complementary structures in `story.xml`:

1. **Scene List (`sceneLst`)** – Defines each scene and lists its slides by **short IDs**:
   ```xml
   <scene ... name="Calcy AI">
     <sldIdLst>
       <sldId>R6CWNc9DblRZ</sldId>
       <sldId>R5tBLrsArxPe</sldId>
       <sldId>R5lnTBthZOn1</sldId>
     </sldIdLst>
   </scene>
   ```

2. **Table of Contents (`toc`)** – Provides a **scene → slide** hierarchy using **GUIDs**:
   ```xml
   <toc>
     <entryLst>
       <tocSceneEntry refG="c947bcce-...">  <!-- scene GUID -->
         <entryLst>
           <tocSlideEntry refG="01642ff1-..."/> <!-- slide GUID -->
           <!-- other slides -->
         </entryLst>
       </tocSceneEntry>
     </entryLst>
   </toc>
   ```

**Why this matters:** A slide file (`slide.xml`) does **not** store its parent scene’s name. Instead, you **join** the slide to its scene **via GUIDs** in `story.xml` (using the TOC).

---

## 4) How to get a slide’s scene *name* from `slide.xml`

Given just the slide file:

1. **Read the slide’s GUID from `slide.xml`:**
   ```xml
   <sld g="01642ff1-fb08-483c-a8a6-c1340c0b8ae7" ... />
   ```

2. **In `story.xml`, find the TOC slide entry whose `refG` matches the slide GUID.**  
   Then read its **ancestor scene** entry (`tocSceneEntry`) and grab the **scene GUID** (`refG="..."`).

3. **Still in `story.xml`, find the `<scene>` element in the `sceneLst` whose `g="..."` equals that scene GUID.**  
   Read its **`name="..."`** attribute — that’s the **scene name** (e.g., `Calcy AI`).

### Example resolution (with the provided files)

- Slide file → GUID: `01642ff1-fb08-483c-a8a6-c1340c0b8ae7`
- `story.xml` TOC has:
  ```xml
  <tocSceneEntry refG="c947bcce-2f63-4757-b9f8-50b27cf91dc1">
    <tocSlideEntry refG="01642ff1-fb08-483c-a8a6-c1340c0b8ae7" />
  </tocSceneEntry>
  ```
  ⇒ **Scene GUID** is `c947bcce-2f63-4757-b9f8-50b27cf91dc1`

- `story.xml` scene list has:
  ```xml
  <scene g="c947bcce-2f63-4757-b9f8-50b27cf91dc1" name="Calcy AI" ... />
  ```
  ⇒ **Scene name** = **Calcy AI**

---

## 5) Practical XPath / pseudo‑code

**XPath approach:**

```xpath
(: 1. From slide.xml: get slide GUID :)
/sld/@g

(: 2. In story.xml: find the TOC slide entry that matches :)
/story/toc//tocSlideEntry[@refG = $slideGuid]

(: 3. Get ancestor scene’s GUID :)
ancestor::tocSceneEntry/@refG

(: 4. Find the scene by GUID and read its name :)
/story/sceneLst/scene[@g = $sceneGuid]/@name
```

**Pseudo‑code:**

```pseudo
slideGuid = readAttribute("slide.xml", "/sld/@g")

sceneGuid = readAttribute("story.xml",
  "/story/toc//tocSlideEntry[@refG = slideGuid]/ancestor::tocSceneEntry/@refG")

sceneName = readAttribute("story.xml",
  "/story/sceneLst/scene[@g = sceneGuid]/@name")
```

---

## 6) Notes & gotchas

- The **TOC (`toc`) is the reliable glue** between slides and scenes because it uses full **GUIDs** on both levels.
- The **`sldIdLst` short IDs** are useful for ordering and internal references but don’t directly give you the slide GUID. If you only have short IDs, you’ll need Storyline’s internal mapping (not always exposed) to get the slide GUID.
- Triggers and actions in `slide.xml` often contain self-closing `<scene />` elements **inside action payloads** (for example, “jump to slide in scene …”). These elements **do not** identify the slide’s parent scene; they’re part of action schemas.

---

## 7) Checklist

- [x] Read slide GUID from `slide.xml` (`<sld g="...">`).
- [x] Use `story.xml` → `toc` to map **slide GUID → scene GUID**.
- [x] Use `story.xml` → `sceneLst` to map **scene GUID → scene name**.
- [x] (Optional) Use `sldIdLst` for scene ordering, not for resolving GUIDs.

---

### Appendix: What you’ll see in the provided files

- **slide.xml** top‑level:
  ```xml
  <sld g="01642ff1-fb08-483c-a8a6-c1340c0b8ae7" name="Calcy Groove" ... />
  ```

- **story.xml** scene list excerpt:
  ```xml
  <scene g="c947bcce-2f63-4757-b9f8-50b27cf91dc1" name="Calcy AI" ...>
    <sldIdLst>
      <sldId>R6CWNc9DblRZ</sldId>
      <sldId>R5tBLrsArxPe</sldId>
      <sldId>R5lnTBthZOn1</sldId>
    </sldIdLst>
  </scene>
  ```

- **story.xml** TOC excerpt connecting the two:
  ```xml
  <tocSceneEntry refG="c947bcce-2f63-4757-b9f8-50b27cf91dc1">
    <tocSlideEntry refG="01642ff1-fb08-483c-a8a6-c1340c0b8ae7"/>
  </tocSceneEntry>
  ```

