# winsetup-bootstrap

Entry point for setting up a new Windows machine. Installs PowerShell 7, Git
and GitHub CLI, sets the git identity, authenticates with GitHub, clones the
private `winsetup-core` repo, and hands off to its `run.ps1`.

## Usage

From any PowerShell prompt (it asks for administrator approval itself):

```
irm https://raw.githubusercontent.com/Turnerj/winsetup-bootstrap/main/bootstrap.ps1 | iex
```
