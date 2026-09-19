<#
    Entry point: opens an administrator window (UAC prompt) that downloads and
    runs Invoke-Bootstrap.ps1, which does the actual setup. Run from any
    PowerShell prompt:
        irm https://raw.githubusercontent.com/Turnerj/winsetup-bootstrap/main/bootstrap.ps1 | iex

    Deliberately tiny, with no variables and no `exit`: run through iex it
    shares the caller's session, so either would leak into it or close their
    terminal.
#>

try {
    Start-Process powershell.exe -Verb RunAs -ErrorAction Stop -ArgumentList '-NoExit', '-NoProfile', '-Command', 'irm https://raw.githubusercontent.com/Turnerj/winsetup-bootstrap/main/Invoke-Bootstrap.ps1 | iex'
}
catch {
    Write-Error "Administrator approval is needed to run the setup, and wasn't given."
}
