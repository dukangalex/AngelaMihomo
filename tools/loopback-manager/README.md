# AngelaMihomo Loopback Manager

Clean-room replacement for the loopback exemption tool bundled with the
Windows build. Windows AppContainer (UWP) apps cannot connect to the
loopback address by default; this tool lists the app containers on the
machine and lets the user grant or revoke the loopback exemption that
allows selected apps to reach the local AngelaMihomo proxy port.

It is an original implementation written against Microsoft's public
Network Isolation API documentation (netfw.h: `NetworkIsolationEnumAppContainers`,
`NetworkIsolationGetAppContainerConfig`, `NetworkIsolationSetAppContainerConfig`,
`NetworkIsolationFreeAppContainers`). No third-party tool's code, text, or
assets were used.

## Behavior

- No arguments: opens a single-window GUI (check the apps to exempt, Save).
- `list`: prints one line per container:
  `exempt|blocked <TAB> package-family-name <TAB> SID <TAB> display-name`
- `add <name|SID>` / `remove <name|SID>`: change one container's exemption
  and print its resulting state line. Both are idempotent.
- Exit codes: 0 success, 1 usage error, 2 target not found, 3 system call
  failed.
- The enumeration API reports most packaged apps' display names and
  descriptions as indirect resource strings
  (`@{Package_...?ms-resource://...}`). Both the GUI and the CLI resolve
  those through `SHLoadIndirectString` (shlwapi.dll), so the last `list`
  field is the readable app name (for example `Notepad`). When resolution
  fails or yields nothing, the raw string is kept; a container with no
  display name at all is shown under its package family name.
- The executable requests administrator elevation via its manifest, because
  the exemption configuration is machine-wide.
- UI text is bilingual: Simplified Chinese on Chinese UI cultures, English
  everywhere else.

Writing the configuration always preserves existing exemptions the user
did not touch (including entries whose container is not currently
enumerated), as required by the API contract for
`NetworkIsolationSetAppContainerConfig`.

## Build

Targets .NET Framework 4.8 (in-box on Windows 10/11, so users install no
runtime). The SDK-style project restores
`Microsoft.NETFramework.ReferenceAssemblies`, so a plain .NET SDK can
build it anywhere:

```powershell
dotnet build tools/loopback-manager/AngelaMihomoLoopbackManager.csproj -c Release
# -> tools/loopback-manager/bin/Release/net48/AngelaMihomoLoopbackManager.exe
```

CI: `.github/workflows/loopback-manager.yaml` builds the exe on
`windows-latest` and uploads it as an artifact.

## Delivery

The binary is a build product and is not committed (the path is listed
in `.gitignore`). The main build workflow (`.github/workflows/build.yaml`)
compiles this project on its Windows legs and stages the exe at
`windows/AngelaMihomoLoopbackManager.exe`, where the existing
`windows/CMakeLists.txt` install rule places it next to the main
executable; the Tools page launches it elevated with no arguments.
Building the Windows app locally therefore needs the same `dotnet build`
step first: without the staged exe, the CMake install step fails on the
missing file.
