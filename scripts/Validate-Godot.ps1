[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ProjectPath = "."
)

$ErrorActionPreference = "Stop"
$ProjectPath = (Resolve-Path $ProjectPath).Path
$ProjectFile = Join-Path $ProjectPath "project.godot"
$LogDir = Join-Path $ProjectPath ".godot/agent-logs"
$EnvFile = Join-Path $ProjectPath ".agent/godot-agent.env"

if (-not (Test-Path $ProjectFile)) {
    throw "project.godot not found in $ProjectPath"
}

# Load simple KEY=value lines. Shell expressions are intentionally not evaluated.
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith("#") -or -not $line.Contains("=")) { return }
        $parts = $line.Split("=", 2)
        $name = $parts[0].Trim()
        $value = $parts[1].Trim().Trim('"').Trim("'")
        [Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}

function Find-Godot {
    if ($env:GODOT_BIN) {
        if (Test-Path $env:GODOT_BIN) { return (Resolve-Path $env:GODOT_BIN).Path }
        $cmd = Get-Command $env:GODOT_BIN -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }

    foreach ($candidate in @("godot", "godot4", "godot-mono", "godot4-mono")) {
        $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    throw "Godot editor binary not found. Set GODOT_BIN or add Godot to PATH."
}

$Godot = Find-Godot
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
Get-ChildItem $LogDir -Filter "*.log" -ErrorAction SilentlyContinue | Remove-Item -Force

$script:Failures = 0
$script:Steps = [System.Collections.Generic.List[string]]::new()

function Invoke-Step {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    Write-Host "`n== $Name =="
    try {
        & $Action
        if ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) {
            throw "Exit code $LASTEXITCODE"
        }
        $script:Steps.Add("PASS: $Name")
    }
    catch {
        $script:Steps.Add("FAIL: $Name - $($_.Exception.Message)")
        $script:Failures++
    }
}

function Test-Log {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $true }

    $pattern = 'SCRIPT ERROR:|Parse Error:|(^|\s)ERROR:|Failed loading resource|Cannot open file|Invalid call|Invalid access|Unhandled exception|Build FAILED|Tests failed'
    $matches = Select-String -Path $Path -Pattern $pattern -CaseSensitive:$false
    if ($env:GODOT_ALLOWED_LOG_REGEX) {
        $matches = $matches | Where-Object { $_.Line -notmatch $env:GODOT_ALLOWED_LOG_REGEX }
    }
    if ($matches) {
        Write-Error "Detected failure-like log lines in $Path`n$($matches -join "`n")" -ErrorAction Continue
        return $false
    }
    return $true
}

Write-Host "Project: $ProjectPath"
Write-Host "Godot: $Godot"
& $Godot --version

$git = Get-Command git -ErrorAction SilentlyContinue
$inGit = $false
if ($git) {
    Push-Location $ProjectPath
    try {
        & git rev-parse --is-inside-work-tree *> $null
        $inGit = ($LASTEXITCODE -eq 0)
    }
    finally { Pop-Location }
}

if ($inGit) {
    Invoke-Step "git diff --check" { & git -C $ProjectPath diff --check }
    & git -C $ProjectPath status --short
}
else {
    $script:Steps.Add("SKIP: git diff check (not a Git worktree)")
}

if ($env:GODOT_FORMAT_CHECK_COMMAND) {
    Invoke-Step "format check" { Push-Location $ProjectPath; try { Invoke-Expression $env:GODOT_FORMAT_CHECK_COMMAND } finally { Pop-Location } }
}
else { $script:Steps.Add("SKIP: format check (not configured)") }

if ($env:GODOT_LINT_COMMAND) {
    Invoke-Step "lint" { Push-Location $ProjectPath; try { Invoke-Expression $env:GODOT_LINT_COMMAND } finally { Pop-Location } }
}
else { $script:Steps.Add("SKIP: lint (not configured)") }

$importLog = Join-Path $LogDir "import.log"
Invoke-Step "Godot import" { & $Godot --headless --path $ProjectPath --import --verbose --log-file $importLog }
if (-not (Test-Log $importLog)) { $script:Steps.Add("FAIL: import log scan"); $script:Failures++ }
else { $script:Steps.Add("PASS: import log scan") }

$changedGd = @()
if ($inGit) {
    $changedGd += & git -C $ProjectPath diff --name-only --diff-filter=ACMRT -- '*.gd'
    $changedGd += & git -C $ProjectPath diff --cached --name-only --diff-filter=ACMRT -- '*.gd'
    $changedGd += & git -C $ProjectPath ls-files --others --exclude-standard -- '*.gd'
    $changedGd = $changedGd | Where-Object { $_ } | Sort-Object -Unique
}

if ($changedGd.Count -gt 0) {
    foreach ($relativePath in $changedGd) {
        $scriptPath = Join-Path $ProjectPath $relativePath
        if (-not (Test-Path $scriptPath)) { continue }
        $safeName = $relativePath -replace '[\\/: ]', '_'
        $parseLog = Join-Path $LogDir "parse-$safeName.log"
        Invoke-Step "parse $relativePath" { & $Godot --headless --path $ProjectPath --script $scriptPath --check-only --log-file $parseLog }
        if (-not (Test-Log $parseLog)) { $script:Steps.Add("FAIL: parse log scan $relativePath"); $script:Failures++ }
    }
}
else { $script:Steps.Add("SKIP: changed GDScript parse (no changed .gd files detected)") }

$hasCSharp = Get-ChildItem $ProjectPath -Recurse -Depth 2 -Include *.csproj,*.sln -File -ErrorAction SilentlyContinue | Select-Object -First 1
if ($hasCSharp) {
    $buildLog = Join-Path $LogDir "csharp-build.log"
    Invoke-Step "Godot C# solution build" { & $Godot --headless --path $ProjectPath --editor --build-solutions --quit --log-file $buildLog }
    if (-not (Test-Log $buildLog)) { $script:Steps.Add("FAIL: C# build log scan"); $script:Failures++ }
}
else { $script:Steps.Add("SKIP: C# build (no .csproj/.sln detected)") }

if ($env:GODOT_TEST_COMMAND) {
    Invoke-Step "automated tests" { Push-Location $ProjectPath; try { Invoke-Expression $env:GODOT_TEST_COMMAND } finally { Pop-Location } }
}
else { $script:Steps.Add("SKIP: automated tests (GODOT_TEST_COMMAND not configured)") }

$smokeFrames = if ($env:GODOT_SMOKE_FRAMES) { $env:GODOT_SMOKE_FRAMES } else { "3" }
$smokeLog = Join-Path $LogDir "runtime-smoke.log"
if ($env:GODOT_SMOKE_SCENE) {
    Invoke-Step "runtime smoke: $($env:GODOT_SMOKE_SCENE)" { & $Godot --headless --path $ProjectPath --scene $env:GODOT_SMOKE_SCENE --quit-after $smokeFrames --log-file $smokeLog }
}
elseif ((Get-Content $ProjectFile -Raw) -match '(?m)^run/main_scene=("[^"]+"|uid://\S+)') {
    Invoke-Step "runtime smoke: Main Scene" { & $Godot --headless --path $ProjectPath --quit-after $smokeFrames --log-file $smokeLog }
}
else { $script:Steps.Add("SKIP: runtime smoke (Main Scene and GODOT_SMOKE_SCENE are unset)") }

if (Test-Path $smokeLog) {
    if (-not (Test-Log $smokeLog)) { $script:Steps.Add("FAIL: runtime smoke log scan"); $script:Failures++ }
    else { $script:Steps.Add("PASS: runtime smoke log scan") }
}

Write-Host "`n== Summary =="
$script:Steps | ForEach-Object { Write-Host $_ }
Write-Host "`nLogs: $LogDir"

if ($script:Failures -gt 0) {
    throw "Validation failed with $($script:Failures) failing check(s)."
}

Write-Host "Validation completed without detected failures. Review skipped checks and add visual/interaction verification when required."
