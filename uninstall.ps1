<#
.SYNOPSIS
  Remove the Presentation_skills skill/plugin from local AI agents.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
  powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -Targets antigravity,claude-code
#>
[CmdletBinding()]
param(
    [ValidateSet('antigravity', 'gemini-cli', 'claude-code', 'codex', 'agents')]
    [string[]]$Targets = @('antigravity')
)

$ErrorActionPreference = 'Stop'
$Name      = 'presentation-skills'
$StartMark = '<!-- presentation-skills:start -->'
$EndMark   = '<!-- presentation-skills:end -->'
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

$Map = @{
    'antigravity' = @{ Dest = "$HOME\.gemini\config\plugins\$Name"; Rule = $null }
    'gemini-cli'  = @{ Dest = "$HOME\.gemini\skills\$Name";         Rule = "$HOME\.gemini\GEMINI.md" }
    'claude-code' = @{ Dest = "$HOME\.claude\skills\$Name";         Rule = "$HOME\.claude\CLAUDE.md" }
    'codex'       = @{ Dest = "$HOME\.codex\skills\$Name";          Rule = "$HOME\.codex\AGENTS.md" }
    'agents'      = @{ Dest = "$HOME\.agents\skills\$Name";         Rule = $null }
}

foreach ($t in $Targets) {
    $cfg = $Map[$t]
    Write-Host "[$t]"
    if (Test-Path $cfg.Dest) {
        $item = Get-Item $cfg.Dest -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { $item.Delete() }
        else { Remove-Item $cfg.Dest -Recurse -Force }
        Write-Host "  removed   $($cfg.Dest)"
    } else {
        Write-Host "  (not installed) $($cfg.Dest)"
    }
    if ($cfg.Rule -and (Test-Path $cfg.Rule)) {
        $text = [IO.File]::ReadAllText($cfg.Rule, [Text.Encoding]::UTF8)
        $pattern = '(\r?\n)*' + [regex]::Escape($StartMark) + '[\s\S]*?' + [regex]::Escape($EndMark) + '(\r?\n)?'
        $new = [regex]::Replace($text, $pattern, "`r`n").Trim()
        if ($new.Length -eq 0) {
            Remove-Item $cfg.Rule -Force
            Write-Host "  removed   $($cfg.Rule) (was only the rule block)"
        } elseif ($new -ne $text.Trim()) {
            [IO.File]::WriteAllText($cfg.Rule, $new + "`r`n", $Utf8NoBom)
            Write-Host "  cleaned   $($cfg.Rule)"
        }
    }
}
Write-Host "Done."
