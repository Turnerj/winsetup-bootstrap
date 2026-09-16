# winsetup-bootstrap

Entry point for setting up a new Windows machine. Installs PowerShell 7 and
GitHub CLI, authenticates with GitHub, clones the private `winsetup-core`
repo, and hands off to its `run.ps1`.

## Usage

From an elevated Windows PowerShell prompt:

```
irm https://raw.githubusercontent.com/Turnerj/winsetup-bootstrap/main/bootstrap.ps1 | iex
```
