<#
.SYNOPSIS
  Install the Presentation_skills skill/plugin into local AI agents.

.DESCRIPTION
  Source of truth: .\presentation-skills\  (an Antigravity plugin that bundles
  skills\presentation-skills\SKILL.md + references, and rules\AGENTS.md).

  Targets:
    antigravity  -> ~/.gemini/config/plugins/presentation-skills   (whole plugin; rule ships inside it)
    gemini-cli   -> ~/.gemini/skills/presentation-skills            (+ rule block in ~/.gemini/GEMINI.md)
    claude-code  -> ~/.claude/skills/presentation-skills            (+ rule block in ~/.claude/CLAUDE.md)
    codex        -> ~/.codex/skills/presentation-skills             (+ rule block in ~/.codex/AGENTS.md)
    agents       -> ~/.agents/skills/presentation-skills            (generic Agent Skills location, no rule file)

  Re-running is safe: the old copy is replaced and the rule block is updated in place.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\install.ps1
  powershell -ExecutionPolicy Bypass -File .\install.ps1 -Targets antigravity,claude-code
  powershell -ExecutionPolicy Bypass -File .\install.ps1 -Link      # directory junction instead of copy
#>
[CmdletBinding()]
param(
    [ValidateSet('antigravity', 'gemini-cli', 'claude-code', 'codex', 'agents')]
    [string[]]$Targets = @('antigravity'),
    [switch]$Link,
    [switch]$NoRules
)

$ErrorActionPreference = 'Stop'
$Name       = 'presentation-skills'
$PluginSrc  = Join-Path $PSScriptRoot $Name
$SkillSrc   = Join-Path $PluginSrc "skills\$Name"
$RuleSrc    = Join-Path $PluginSrc 'rules\AGENTS.md'
$StartMark  = '<!-- presentation-skills:start -->'
$EndMark    = '<!-- presentation-skills:end -->'
$Utf8NoBom  = New-Object System.Text.UTF8Encoding $false

if (-not (Test-Path (Join-Path $SkillSrc 'SKILL.md'))) { throw "SKILL.md not found under $SkillSrc" }

$Map = @{
    'antigravity' = @{ Dest = "$HOME\.gemini\config\plugins\$Name"; Src = $PluginSrc; Rule = $null }
    'gemini-cli'  = @{ Dest = "$HOME\.gemini\skills\$Name";         Src = $SkillSrc;  Rule = "$HOME\.gemini\GEMINI.md" }
    'claude-code' = @{ Dest = "$HOME\.claude\skills\$Name";         Src = $SkillSrc;  Rule = "$HOME\.claude\CLAUDE.md" }
    'codex'       = @{ Dest = "$HOME\.codex\skills\$Name";          Src = $SkillSrc;  Rule = "$HOME\.codex\AGENTS.md" }
    'agents'      = @{ Dest = "$HOME\.agents\skills\$Name";         Src = $SkillSrc;  Rule = $null }
}

function Remove-Existing([string]$Path) {
    if (-not (Test-Path $Path)) { return }
    $item = Get-Item $Path -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        $item.Delete()            # remove junction only, never the target contents
    } else {
        Remove-Item $Path -Recurse -Force
    }
}

function Set-RuleBlock([string]$File) {
    $body  = [IO.File]::ReadAllText($RuleSrc, [Text.Encoding]::UTF8).Trim()
    $block = "$StartMark`r`n$body`r`n$EndMark"
    $dir = Split-Path $File -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    $text = if (Test-Path $File) { [IO.File]::ReadAllText($File, [Text.Encoding]::UTF8) } else { '' }
    $pattern = [regex]::Escape($StartMark) + '[\s\S]*?' + [regex]::Escape($EndMark)
    if ($text -match $pattern) {
        $text = [regex]::Replace($text, $pattern, { param($m) $block })
    } elseif ($text.Trim().Length -gt 0) {
        $text = $text.TrimEnd() + "`r`n`r`n" + $block + "`r`n"
    } else {
        $text = $block + "`r`n"
    }
    [IO.File]::WriteAllText($File, $text, $Utf8NoBom)
    Write-Host "  rule block -> $File"
}

foreach ($t in $Targets) {
    $cfg = $Map[$t]
    Write-Host "[$t]"
    $parent = Split-Path $cfg.Dest -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force $parent | Out-Null }
    Remove-Existing $cfg.Dest
    if ($Link) {
        New-Item -ItemType Junction -Path $cfg.Dest -Target $cfg.Src | Out-Null
        Write-Host "  junction  -> $($cfg.Dest)"
    } else {
        Copy-Item -Path $cfg.Src -Destination $cfg.Dest -Recurse -Force
        Write-Host "  copied    -> $($cfg.Dest)"
    }
    if ($cfg.Rule -and -not $NoRules) { Set-RuleBlock $cfg.Rule }
}

Write-Host "Done. Start a new conversation in the agent to pick up the skill."
