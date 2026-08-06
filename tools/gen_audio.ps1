# tools/gen_audio.ps1
# Generates Iron-Mario's sound assets as 16-bit PCM mono 22050 Hz WAV files.
# Every tone is synthesized here from scratch -- no external audio files.
# SFX peak is kept around -10 dB; the BGM is a 16-note original loop (6.4 s)
# with a 3rd harmonic for a square-ish retro timbre.
$ErrorActionPreference = 'Stop'

$SampleRate = 22050
$OutDir = Join-Path (Join-Path (Join-Path $PSScriptRoot '..') 'assets') 'audio'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Write-WavFile([float[]]$Samples, [string]$Path) {
    $count = $Samples.Length
    $dataBytes = $count * 2
    $fs = [System.IO.File]::Create($Path)
    $bw = New-Object System.IO.BinaryWriter($fs)
    try {
        $bw.Write([System.Text.Encoding]::ASCII.GetBytes('RIFF'))
        $bw.Write([int](36 + $dataBytes))
        $bw.Write([System.Text.Encoding]::ASCII.GetBytes('WAVE'))
        $bw.Write([System.Text.Encoding]::ASCII.GetBytes('fmt '))
        $bw.Write([int]16)
        $bw.Write([int16]1)               # PCM
        $bw.Write([int16]1)               # mono
        $bw.Write([int]$SampleRate)
        $bw.Write([int]($SampleRate * 2)) # byte rate
        $bw.Write([int16]2)               # block align
        $bw.Write([int16]16)              # bits per sample
        $bw.Write([System.Text.Encoding]::ASCII.GetBytes('data'))
        $bw.Write([int]$dataBytes)
        for ($i = 0; $i -lt $count; $i++) {
            $v = [Math]::Max(-1.0, [Math]::Min(1.0, $Samples[$i]))
            $bw.Write([int16]([Math]::Round($v * 32767.0)))
        }
    } finally {
        $bw.Dispose()
        $fs.Dispose()
    }
}

# Quick attack, release-to-silence envelope.
function Add-Envelope([float[]]$Samples, [float]$AttackSec, [float]$ReleaseSec) {
    $n = $Samples.Length
    $atk = [Math]::Max(1, [int]($AttackSec * $SampleRate))
    $rel = [Math]::Max(1, [int]($ReleaseSec * $SampleRate))
    for ($i = 0; $i -lt $n; $i++) {
        $env = 1.0
        if ($i -lt $atk) { $env = $i / $atk }
        $tail = $n - $i
        if ($tail -le $rel) {
            $release = $tail / $rel
            if ($release -lt $env) { $env = $release }
        }
        $Samples[$i] = $Samples[$i] * $env
    }
    return ,$Samples
}

# Sine tone; $Harmonic3 adds a 3rd harmonic for a square-ish timbre.
function New-Tone([float]$Freq, [float]$DurSec, [float]$Amp, [float]$Harmonic3 = 0.0) {
    $n = [int]($DurSec * $SampleRate)
    $s = New-Object 'float[]' $n
    if ($Freq -gt 0.0) {
        for ($i = 0; $i -lt $n; $i++) {
            $t = $i / $SampleRate
            $s[$i] = $Amp * ([Math]::Sin(2 * [Math]::PI * $Freq * $t) + $Harmonic3 * [Math]::Sin(2 * [Math]::PI * 3 * $Freq * $t))
        }
    }
    return ,$s
}

function Concat-Samples([float[][]]$Parts) {
    $total = 0
    foreach ($p in $Parts) { $total += $p.Length }
    $out = New-Object 'float[]' $total
    $pos = 0
    foreach ($p in $Parts) {
        [System.Array]::Copy($p, 0, $out, $pos, $p.Length)
        $pos += $p.Length
    }
    return ,$out
}

# --- tick.wav: 880 Hz blip, 0.06 s -------------------------------------------
$tick = Add-Envelope (New-Tone 880.0 0.06 0.30) 0.004 0.05
Write-WavFile $tick (Join-Path $OutDir 'tick.wav')

# --- win.wav: rising arpeggio 523 -> 659 -> 784 Hz, 0.45 s -------------------
$win = Concat-Samples @(
    (Add-Envelope (New-Tone 523.25 0.15 0.30) 0.01 0.05),
    (Add-Envelope (New-Tone 659.25 0.15 0.30) 0.01 0.05),
    (Add-Envelope (New-Tone 783.99 0.15 0.30) 0.01 0.05)
)
Write-WavFile $win (Join-Path $OutDir 'win.wav')

# --- fail.wav: descending 330 -> 220 Hz, 0.4 s -------------------------------
$fail = Concat-Samples @(
    (Add-Envelope (New-Tone 329.63 0.20 0.30) 0.01 0.06),
    (Add-Envelope (New-Tone 220.00 0.20 0.30) 0.01 0.10)
)
Write-WavFile $fail (Join-Path $OutDir 'fail.wav')

# --- bgm.wav: 16-note original loop, 6.4 s (0.4 s per note) ------------------
# C-E-G-A flavored riff around C major, ending on a rest so the loop breathes.
$melody = @(523.25, 659.25, 783.99, 880.00, 783.99, 659.25, 523.25, 587.33,
            659.25, 783.99, 880.00, 1046.50, 880.00, 783.99, 659.25, 0.0)
$notes = @()
foreach ($f in $melody) {
    $notes += ,(Add-Envelope (New-Tone $f 0.40 0.24 0.25) 0.01 0.12)
}
$bgm = Concat-Samples $notes
Write-WavFile $bgm (Join-Path $OutDir 'bgm.wav')

Write-Output "Generated audio files in ${OutDir}:"
Get-ChildItem $OutDir -Filter '*.wav' | ForEach-Object { Write-Output ("  {0}  {1} bytes" -f $_.Name, $_.Length) }
