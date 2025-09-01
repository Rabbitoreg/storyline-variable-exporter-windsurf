# Storyline Variable Exporter (SVE)

**Goal**

Build a modern web application that ingests **Articulate Storyline `.story` project files** (and, if needed, **published output folders**), extracts **variables** (name, type, default value, scope, etc.), discovers **where each variable is used** (scenes/slides + trigger context), detects **JavaScript trigger usage** (Get/Set/Both), and exports/maintains a **single-row-per-variable CSV** suitable for documentation and ongoing synchronization.

---

## Fundamentals

- **Single Source of Truth (SSOT):** Variables live in Storyline; descriptions/documentation live in CSV. Sync routine preserves descriptions while updating technical metadata from Storyline.
- **Deterministic & Repeatable:** Re-running exporter on the same `.story` and CSV yields the same output (modulo changes in the source project).
- **Safety First:** Analyze project files **read-only**; never mutate the `.story` file.
- **Transparent Diff:** Every run shows adds/updates/removals before writing the CSV.
- **Accessibility:** UI is keyboard-first, screen-reader-friendly, high-contrast compliant.
- **Extensible:** Parser is modular to support future Storyline versions and alternate inputs (published output).

---

## Core Requirements

### R1 — Variable Extraction
- Parse `.story` to list **all variables** with:
  - `variableName` (case-sensitive string)
  - `dataType` (Text, Number, True/False, etc.)
  - `defaultValue`
  - `scope` (Project/Wider scope if identifiable)
  - `definedIn` (file/section where definition found, for traceability)
  - `internalId` (if discoverable; otherwise blank)

### R2 — Usage Discovery (Non-JS)
- For each variable, collect **usage locations** across **Scenes/Slides/Objects/Triggers** where the variable is read/written by Storyline trigger types (e.g., *Adjust variable*, *Show layer if variable*, *Conditionals*).
- Output a **multi-line field** for usage, each line: `Scene > Slide > Object (TriggerType: Read|Write|Both)`.

### R3 — JavaScript Trigger Analysis
- Detect **Execute JavaScript** triggers and parse the JS payload to find occurrences of:
  - `player.GetVar("<name>")` ⇒ **Get**
  - `player.SetVar("<name>", ...)` ⇒ **Set**
- For each variable, output a **JS Usage** multi-line field, each line: `Scene > Slide (JS Trigger: Get|Set|Both)`.

### R4 — CSV Export (Single Row Per Variable)
- Produce CSV with headers (see **CSV Schema**). Fields with newlines must be quoted.
- Guarantee **one row per variable**.

### R5 — CRUD Sync Against Existing CSV
- On re-runs, perform a three-way sync:
  - **Add** new Storyline variables to CSV.
  - **Remove** variables no longer present in Storyline.
  - **Update** changed type/default/scope while **preserving user-authored `description`** (and other documentation-only fields) in CSV.
- Show a **Diff Preview** (Adds/Updates/Removals) before user confirms write.

### R6 — Modern Web UI
- Upload area for `.story` file **(and optional published output zip/folder)**.
- Progress + results table (virtualized for large projects).
- Inline editing for `description`, `tags`, `owner` (doc-only fields).
- Export/Download CSV; Import existing CSV for sync.
- Diff viewer with filters (only changes, only removals, etc.).

### R7 — CLI (Optional, Phase 2)
- `sve parse project.story --csv existing.csv --out updated.csv --json report.json` for CI pipelines.

---

## CSV Schema (Initial)

| Column | Type | Purpose |
|---|---|---|
| `variableName` | string | Unique variable name from Storyline (case-sensitive). |
| `dataType` | enum(`Text`,`Number`,`True/False`,`Unknown`) | Storyline type. |
| `defaultValue` | string | Default value from definition. |
| `scope` | enum(`Project`,`Unknown`) | Scope if discoverable; else `Unknown`. |
| `usageLocations` | multi-line string | Non-JS usages. One per line: `Scene > Slide > Object (TriggerType: Read|Write|Both)` |
| `jsUsage` | multi-line string | JS trigger usages. One per line: `Scene > Slide (JS Trigger: Get|Set|Both)` |
| `description` | string | **User-authored** docs (preserved across sync). |
| `tags` | comma-separated | Free-form labels (preserved). |
| `owner` | string | Person/team responsible (preserved). |
| `definedIn` | string | File/section where variable definition found (traceability). |
| `internalId` | string | Stable ID if found; otherwise blank. **Non-author field.** |

> CSV Formatting: Use UTF-8, CRLF or LF accepted. Quote fields containing commas or newlines. Newlines in multi-line columns must be literal `\n` or actual line breaks (both supported).

---

## System Overview

```mermaid
flowchart LR
  U[User (Browser)] -->|Upload .story/zip| UI[React UI]
  UI --> API[/Parser API (Node/TS)/]
  API --> ZIP[Zip & FS Reader]
  API --> DETECT[Format Detection]
  DETECT -->|.story| STORY[Story Parser]
  DETECT -->|published output| PUB[Published Parser]
  STORY --> XVAR[Extract Variables]
  STORY --> XUSE[Extract Non-JS Usages]
  STORY --> XJS[Extract JS Triggers]
  PUB --> PJS[Scan JS payloads]
  PUB --> PMAP[Map Slides/Scenes]
  XVAR & XUSE & XJS & PJS & PMAP --> AGG[Aggregator]
  UI --> CSVIN[CSV Import]
  AGG --> DIFF[Diff Engine]
  CSVIN --> DIFF
  DIFF -->|Preview| UI
  DIFF --> CSVOUT[(CSV Writer)]
  CSVOUT --> UI
```

---

## Parsing Strategy

> **Primary Input:** `.story` project file. **Fallback/Assist:** published output folder (HTML5) when `.story` internals are insufficient or differ by version.

1. **Open & Inspect**
   - Try to read `.story` as a **ZIP container** (some Storyline versions store project contents in a package-like structure). If not a standard zip, switch to **binary extraction strategy** with signatures; if fully opaque, prompt to also upload the **published output**.
2. **Locate Definition Artifacts**
   - Search for likely XML/JSON files (`story.xml`, `document.xml`, `slides/*.xml`, `player.xml`, etc.).
   - Identify **Variables section** (e.g., a `Variables` node with children containing `Name`, `Type`, `Default`, possibly `Id`).
3. **Extract Non-JS Usages**
   - Parse slide/scene XML files and enumerate triggers referencing variables (e.g., *Adjust variable*, *Conditions*). Record **read/write** by trigger type.
   - Build path strings using slide/scene titles: `Scene > Slide > Object (TriggerType)`.
4. **Extract JS Triggers**
   - Identify triggers of type **ExecuteJavaScript**. Extract code payload as text.
   - Parse code with an AST parser (Acorn/Esprima) and detect calls:
     - `player.GetVar("<name>")` ⇒ **Get**
     - `player.SetVar("<name>", ...)` ⇒ **Set**
   - Consolidate to **Both** when both found in same slide.
5. **Published Output Fallback**
   - If `.story` structure is opaque, scan **published** `story.html` / `story_content/*` and any embedded JSON/JS config for variable definitions (heuristics), plus all JS for `GetVar`/`SetVar` usage.
6. **Aggregation**
   - Attach usages (non-JS + JS) to each known variable. If a usage references an unknown variable (e.g., JS-only variable), add it as `dataType=Unknown` with a flag `source=JS-only`.

> **Assumptions & Heuristics:** Storyline internal structure can vary by version. The parser is **defensive**: it degrades gracefully to published assets and static analysis of JS where necessary.

---

## Diff & Sync Logic

- **Key Matching:** Prefer `internalId` if present; else `variableName` (case-sensitive). If both missing, treat as **new**.
- **Rename Handling:** If `internalId` stable but `variableName` changed, treat as **rename** (update name, preserve docs). Without IDs, renames appear as **remove + add**.
- **Doc Fields Preservation:** `description`, `tags`, `owner` are **never overwritten** by parser output.
- **Update Rules:** Update `dataType`, `defaultValue`, `scope`, `usageLocations`, `jsUsage`, `definedIn`.
- **Removal Rules:** Variables absent from current parse are marked **Removed**; user can exclude removals in UI.

---

## UI/UX Plan

- **Stack:** React + TypeScript, Vite, Tailwind; TanStack Table for grid; Zustand for state.
- **Screens:**
  1. **Upload**: drag-drop `.story` (and optional published zip). Validation + parsing progress.
  2. **Explorer**: table of variables; inline edit of doc fields; column filters; full-text search.
  3. **Diff Preview**: grouped by Adds/Updates/Removals with per-item details.
  4. **Export**: download CSV; optional JSON report.
- **A11y:** semantic markup, keyboard shortcuts (e.g., `e` to edit cell), ARIA roles, focus outlines, large hit targets.

---

## API Surface (Node/TypeScript)

```
POST /parse            # multipart: project.story (+ optional published.zip)
POST /diff             # body: { parsed: ParsedModel, csv: ExistingCsv }
POST /export/csv       # body: { merged: MergedModel } -> text/csv
POST /import/csv       # multipart: existing.csv -> JSON rows
```

**Core Types (simplified):**
```ts
type Variable = {
  variableName: string;
  dataType: 'Text'|'Number'|'True/False'|'Unknown';
  defaultValue: string;
  scope: 'Project'|'Unknown';
  usageLocations: string[];   // Non-JS usages
  jsUsage: string[];          // JS usages
  description?: string;       // preserved
  tags?: string[];            // preserved
  owner?: string;             // preserved
  definedIn?: string;
  internalId?: string;
};

type ParseResult = {
  variables: Variable[];
  meta: { source: 'story'|'published'|'both'; versionHint?: string };
};
```

---

## Implementation Plan

### Backend
- **Language:** Node.js + TypeScript.
- **Parsing:** `yauzl` or `adm-zip` for containers, `fast-xml-parser` for XML, `acorn` for JS AST.
- **Heuristics:** pluggable detectors for different Storyline versions.
- **Security:** Files processed **in-memory** when feasible; never execute embedded JS; timeouts and size limits.

### Frontend
- **Language:** React + TS
- **Components:** `FileDropzone`, `ParseProgress`, `VariableGrid`, `DiffViewer`, `CsvToolbar`.
- **State:** App store for parsed model, imported CSV, merged model, diff stats.

### Packaging & DevOps
- **Monorepo:** `apps/web`, `packages/parser` (pure TS, reusable), `packages/csv`.
- **Testing:** Jest + `@testing-library/react`; fixtures of sample `.story` & published outputs.
- **CI:** Lint, typecheck, unit tests; optionally run CLI on fixtures to ensure stable CSV snapshots.

---

## Project Structure

```
storyline-variable-exporter/
├─ apps/
│  └─ web/               # React app (Vite)
├─ packages/
│  ├─ parser/            # Node/TS parsing lib (no DOM deps)
│  └─ csv/               # CSV import/export + diff/merge
├─ fixtures/             # Sample .story & published outputs
├─ docs/                 # Design notes, mapping tables
└─ README.md
```

---

## Quick Start (Windsurf)

1. **Create Workspace**
   - Open this repo in Windsurf; select the `apps/web` workspace to preview UI.
2. **Install**
   ```bash
   pnpm i
   ```
3. **Run Dev**
   ```bash
   pnpm --filter @sve/web dev
   ```
4. **Parser Unit Tests**
   ```bash
   pnpm --filter @sve/parser test
   ```
5. **Try It**
   - Upload a `.story` file (and optionally a published zip). Review variables and export CSV.

---

## Example Output (CSV snippet)

```csv
variableName,dataType,defaultValue,scope,usageLocations,jsUsage,description,tags,owner,definedIn,internalId
Score,Number,0,Project,"Scene 1 > Slide 1 > Button (Adjust: Write)\nScene 2 > Slide 3 > Layer (Condition: Read)","Scene 2 > Slide 3 (JS Trigger: Get)","Total score shown on results screen","metrics,reporting","L&D Team","slides/slide1.xml","{GUID-123}"
UserName,Text,,Project,"Scene 1 > Slide 2 > Submit (Adjust: Write)","Scene 3 > Slide 1 (JS Trigger: Set)","Captured at intro form","profile","Ops","slides/slide2.xml","{GUID-456}"
```

---

## Edge Cases & Notes

- Variables referenced **only** in JS triggers (not declared) ⇒ create row with `dataType=Unknown` and `source=JS-only` flag (implicit via `definedIn`).
- Multi-line CSV fields must be properly quoted; UI shows each entry as a bullet list for readability.
- If Storyline internals differ across versions, the parser selects the best-known mapping and logs a **version hint**.
- Name collisions differing only by case are treated as **distinct** unless evidence of a single internal ID exists.

---

## Testing Strategy

- Fixtures with known variables and usages; snapshot expected CSV.
- Fuzz tests for large projects (1000+ variables).
- AST unit tests for `GetVar`/`SetVar` detection across whitespace/concatenation/template literals.

---

## Roadmap

- **Phase 1:** Parser + UI + CSV export + Diff/Sync.
- **Phase 2:** CLI tool; JSON report; artifact upload to S3; shareable links.
- **Phase 3:** Deeper Storyline mapping (layers, states), variable flow graph, cross-project compare.

---

## Coding Standards (Vibe-Coding)

- **Naming:** `camelCase` for vars/functions, `PascalCase` for React components, `UPPER_SNAKE` for consts.
- **Types:** Prefer explicit TypeScript types; no `any`.
- **Errors:** Never throw raw strings; include context and actionable hints.
- **Logs:** `debug` for dev-only details, `info` for user-relevant, `warn` for recoverable, `error` for failures.
- **Docs:** TSDoc on public functions; examples in `/docs`.

---

## Open Questions

1. Are Storyline variable **internal IDs** accessible/stable across saves? (If yes, we support robust rename detection.)
2. Which Storyline versions must be supported initially? (e.g., Storyline 360 current channel.)
3. Should we store and surface **conditions** details (e.g., `if Score >= 80`)?
4. Is **published output** guaranteed alongside `.story` when internals are not accessible?

---

## License & Attribution

- Project is MIT-licensed unless specified otherwise.
- “Articulate Storyline” is a trademark of its respective owner; this project is an independent, read-only analysis tool.

