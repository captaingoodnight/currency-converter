# Ada Demo — Project Notes

This file is used to track context, decisions, and conventions for this project across conversations with Claude Code.

## Project Overview

A command-line currency converter written in Ada, also used as a **GNAT SAS static analysis demo**.

- Prompts the user for a source currency (3-letter code), an amount, and a target currency
- Fetches live exchange rates from **api.frankfurter.dev** (free, no API key required)
- HTTP calls are made via `curl` through a C `system()` binding — no external Ada HTTP library needed
- JSON response is parsed with basic string search (`Ada.Strings.Fixed.Index`)
- Keeps a rolling history of the last 10 conversions per session
- Loops after each conversion, asking the user if they want to convert again

## Files

| File | Purpose |
|------|---------|
| `ada_demo.gpr` | GNAT project file |
| `src/currency_converter.adb` | Main program (single-file) |
| `README.md` | Build, run, and VS Code setup instructions |

## Build & Run

```bash
gprbuild -P ada_demo.gpr
./currency_converter
```

Requires: `gnat` / `gprbuild`, and `curl` on the PATH.

Clean rebuild:

```bash
gprclean -P ada_demo.gpr && gprbuild -P ada_demo.gpr
```

## Decisions & Conventions

- **Single `.adb` file** — kept simple for a demo; no separate spec files
- **`Float` type** — sufficient precision (7 sig figs) for displaying 2 d.p. results
- **`api.frankfurter.dev/v1/latest`** — open API, free, no key required
- **C `system()` binding** — avoids pulling in AWS or other Ada HTTP libs
- **`use type Interfaces.C.int`** — required to make comparison operators (`/=`, `=`) visible for the C.int return type of `C_System`; without it the compiler raises "operator not directly visible"
- Currency list sourced from currencies supported by the Frankfurter API

## GNAT SAS Demo — Intentional Issues

The history buffer (`Add_To_History`, `Print_History`, and the declarations of
`H`, `N`, `Last_Rate`) contains deliberate poor coding practices. All eight
issues are fully documented in the comment block at the top of
`src/currency_converter.adb`.

| # | Issue | Caught by |
|---|-------|-----------|
| 1 | `Last_Rate` assigned but never read | GNAT `-gnatwm`, SAS |
| 2 | `H(10) := H(10)` self-assignment | GNAT `-gnatwr`, SAS |
| 3 | `if N > 0 then null; end if;` — no-op, condition always true | GNAT `-gnatwr`, SAS |
| 4 | `Count` could be `constant` | GNAT `-gnatwk`, SAS |
| 5 | `Prev_N` uninitialised on else-path | **GNAT SAS only** (path-sensitive) |
| 6 | Redundant intermediate variable `I` | Code quality observation |
| 7 | Magic numbers `10`, `9`, `1` | GNAT SAS (requires coding-std config) |
| 8 | Non-descriptive names `H`, `N`, `F`, `T` | GNAT SAS (requires naming config) |

Issue 5 is the headline finding: the compiler does not flag it because `Prev_N`
is assigned on at least one path. GNAT SAS's full path-sensitive data-flow
analysis catches the uninitialised read on the else-path. This is the clearest
demonstration of what SAS adds beyond compiler warnings.

Issues 7 and 8 require coding-standard and naming rules to be enabled in the
GNAT SAS project configuration — they are not on by default.

## VS Code Setup

`README.md` contains full instructions including:

- A `tasks.json` snippet for `Ctrl+Shift+B` build with Ada problem matcher
- A `launch.json` snippet for `F5` run/debug via `cppdbg` with `externalConsole: true`
  (required so interactive prompts are visible)
- Recommended extension: **Language Ada** (`AdaCore.ada`)

## Lessons from this session

- Always ask about the **purpose** of a demo project upfront — knowing this was
  a GNAT SAS demo would have shaped the design from the start
- `use type Interfaces.C.int` is always needed when comparing a C binding's
  return value — include it by default
- README.md should be created as part of the initial deliverable, not added later
- When writing intentional bad-practice demos, draft a spec of the issues first,
  then write the code to match — cleaner than retrofitting
- Issue 3's original comment description was wrong (mentioned a non-existent
  else-branch); comment blocks should be reviewed before committing
