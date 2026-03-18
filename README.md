# Ada Currency Converter

A command-line currency converter written in Ada.  Prompts for a source
currency, an amount, and a target currency, then fetches the latest exchange
rate from [api.frankfurter.dev](https://api.frankfurter.dev) and displays the
converted result.  A rolling history of the last 10 conversions is kept for
the duration of the session.

The project also serves as a **GNAT SAS static analysis demo** — the history
buffer contains intentional coding issues documented in the source file header.

---

## Prerequisites

| Tool | Purpose | Install (Ubuntu / Debian) |
|------|---------|--------------------------|
| `gnat` | Ada compiler (GNAT) | `sudo apt-get install gnat` |
| `gprbuild` | GNAT project build tool | `sudo apt-get install gprbuild` |
| `curl` | HTTP requests at runtime | `sudo apt-get install curl` |

Verify the tools are available:

```bash
gnat --version
gprbuild --version
curl --version
```

---

## Project structure

```
ada-demo/
├── ada_demo.gpr               # GNAT project file
├── src/
│   └── currency_converter.adb # Main program (single source file)
└── obj/                       # Object files (created by gprbuild)
```

---

## Build

```bash
gprbuild -P ada_demo.gpr
```

The compiled binary `currency_converter` is placed in the project root.

To do a clean rebuild:

```bash
gprclean -P ada_demo.gpr
gprbuild -P ada_demo.gpr
```

---

## Run

```bash
./currency_converter
```

The program will:

1. Display the list of supported currency codes.
2. Prompt for a **source currency** (e.g. `USD`).
3. Prompt for an **amount**.
4. Prompt for a **target currency** (e.g. `EUR`).
5. Fetch the live exchange rate and print the converted amount.
6. Ask whether to perform another conversion (`y` to continue, any other key
   to exit).  The last 10 successful conversions are shown at the top of each
   subsequent prompt.

---

## Build and run in VS Code

### Recommended extensions

- **Language Ada** (`AdaCore.ada`) — syntax highlighting, navigation, and
  GNAT SAS integration.

### Building from the VS Code terminal

1. Open the project folder in VS Code (`File → Open Folder`, select `ada-demo`).
2. Open the integrated terminal (`` Ctrl+` ``).
3. Run the build command:

   ```bash
   gprbuild -P ada_demo.gpr
   ```

### Adding a build task

Add the following to `.vscode/tasks.json` (create the file if it does not
exist) to get a one-key build:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build Ada Demo",
      "type": "shell",
      "command": "gprbuild -P ada_demo.gpr",
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "presentation": {
        "reveal": "always",
        "panel": "shared"
      },
      "problemMatcher": {
        "owner": "ada",
        "fileLocation": ["relative", "${workspaceFolder}"],
        "pattern": {
          "regexp": "^(.+):(\\d+):(\\d+):\\s+(warning|error):\\s+(.*)$",
          "file": 1,
          "line": 2,
          "column": 3,
          "severity": 4,
          "message": 5
        }
      }
    },
    {
      "label": "Clean",
      "type": "shell",
      "command": "gprclean -P ada_demo.gpr",
      "group": "build"
    }
  ]
}
```

Press `Ctrl+Shift+B` to run the default build task.

### Running from VS Code

Add a launch configuration to `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Run currency_converter",
      "type": "cppdbg",
      "request": "launch",
      "program": "${workspaceFolder}/currency_converter",
      "args": [],
      "stopAtEntry": false,
      "cwd": "${workspaceFolder}",
      "externalConsole": true,
      "MIMode": "gdb",
      "preLaunchTask": "Build Ada Demo"
    }
  ]
}
```

Press `F5` to build and launch.  Use `externalConsole: true` so the
interactive prompts are visible in a separate terminal window.

---

## GNAT SAS static analysis demo

The history buffer (`Add_To_History`, `Print_History`, and the associated
declarations near the top of `src/currency_converter.adb`) contains eight
deliberate coding issues described in the comment block at the top of the
source file.  Running GNAT SAS on the project will surface all eight; four of
them are also reported by the GNAT compiler itself when built with `-gnatwa`.
