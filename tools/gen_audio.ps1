# tools/gen_audio.ps1
# Generates Super-Micro Heroes' sound assets as 16-bit PCM mono 22050 Hz WAV files.
# Every tone is synthesized here from scratch -- no external audio files.
#
#   tick / win / fail  short SFX, unchanged since Phase 1.
#   music_title        "Micro Heroes March"   D minor  120 BPM  8 bars  16.000 s
#   music_gauntlet     "Gauntlet Run"       A minor  150 BPM  8 bars  12.800 s
#   music_danger       "Redline"            A minor  180 BPM  4 bars   5.333 s
#                      same chord roots as music_gauntlet, 1.2x tempo, denser kit
#   music_intermission "Sting"              A minor  150 BPM  2 bars   3.200 s
#                      one-shot build-up, linear (non-wrapping) render
#
# All four music tracks are original compositions written as note tables below.
#
# ---------------------------------------------------------------------------
# HOW THE LOOPS ARE MADE SEAMLESS
# ---------------------------------------------------------------------------
# Not by trimming. Every voice is rendered into a CIRCULAR buffer whose length
# is an exact whole number of bars and mixed with Mix-Wrapped, which writes a
# note's tail past the end of the buffer back around to index 0. The sample just
# before the loop point and the sample just after it are therefore two ordinary
# neighbours of one continuous periodic waveform -- nothing is chopped and
# nothing is doubled. A note that begins on the final bar is heard at the top of
# the next pass, which is exactly what you want.
#
# Measure-Loop then proves it instead of asserting it. The jump from the last
# sample to the first is compared against the largest sample-to-sample jump found
# in the 4096 samples surrounding the seam. A click is by definition an outlier
# at the join; if the join is not louder than the audio next to it, there is
# nothing to hear. Bars are checked to be whole to within 1e-6, and the peak is
# checked for clipping. The script exits non-zero if any loop fails.
# ---------------------------------------------------------------------------
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

# =============================================================================
# Music machinery
# =============================================================================

# 8192-entry sine table. Linear interpolation error is ~1e-7 (-140 dB), far below
# anything audible, and it is far cheaper than [Math]::Sin per sample.
$MusicLutSize = 8192
$MusicLut = New-Object 'float[]' $MusicLutSize
for ($i = 0; $i -lt $MusicLutSize; $i++) {
    $MusicLut[$i] = [Math]::Sin(2 * [Math]::PI * $i / $MusicLutSize)
}

# Equal-tempered MIDI note number -> Hz.
function Convert-ToMidi([double]$Midi) {
    return 440.0 * [Math]::Pow(2.0, ($Midi - 69.0) / 12.0)
}

# Samples per beat. Every tempo below divides 60 * 22050 exactly, so bars are an
# exact whole number of samples and Measure-Loop's bar check is meaningful.
function Get-BeatSamples([double]$Bpm) {
    return [int][Math]::Round(60.0 * $SampleRate / $Bpm)
}

# Additive mix with WRAP-AROUND. Writes $Src into $Buf from $StartSample onward,
# continuing from index 0 when it reaches the end. This is what makes the loops
# seamless -- see the header.
function Mix-Wrapped([float[]]$Buf, [float[]]$Src, [int]$StartSample) {
    $n = $Buf.Length
    $m = $Src.Length
    if ($m -eq 0 -or $n -eq 0) { return }
    $p = $StartSample % $n
    if ($p -lt 0) { $p += $n }
    $i = 0
    while ($i -lt $m) {
        $chunk = [Math]::Min($n - $p, $m - $i)
        for ($k = 0; $k -lt $chunk; $k++) {
            $Buf[$p + $k] = $Buf[$p + $k] + $Src[$i + $k]
        }
        $p = 0
        $i += $chunk
    }
}

# Plain additive mix, clipped at the buffer end. Used for the one-shot sting,
# which must resolve and stop rather than loop.
function Mix-Linear([float[]]$Buf, [float[]]$Src, [int]$StartSample) {
    $n = $Buf.Length
    $m = $Src.Length
    if ($m -eq 0 -or $StartSample -lt 0 -or $StartSample -ge $n) { return }
    $count = [Math]::Min($m, $n - $StartSample)
    for ($k = 0; $k -lt $count; $k++) {
        $Buf[$StartSample + $k] = $Buf[$StartSample + $k] + $Src[$k]
    }
}

# Detuned multi-oscillator voice: linear attack, optional exponential decay,
# linear release so no note can ever end on a step. $DecayTau = 0 gives a
# sustained pad. Passing two slightly detuned frequencies per chord tone gives
# the slow beating that stops a pad sounding like a test tone.
function Render-Pluck {
    param(
        [double[]]$Freqs,
        [double[]]$Gains,
        [double]$DurSec,
        [double]$Amp = 1.0,
        [double]$AttackSec = 0.005,
        [double]$DecayTau = 0.0,
        [double]$ReleaseSec = 0.05
    )
    $n = [int][Math]::Ceiling($DurSec * $SampleRate)
    if ($n -le 0 -or $Freqs.Length -eq 0) { return ,(New-Object 'float[]' 1) }
    $out = New-Object 'float[]' $n
    $nOsc = $Freqs.Length
    $ph = New-Object 'double[]' $nOsc
    $dph = New-Object 'double[]' $nOsc
    for ($o = 0; $o -lt $nOsc; $o++) { $dph[$o] = $Freqs[$o] / $SampleRate }

    $atk = [Math]::Max(1, [int]($AttackSec * $SampleRate))
    $rel = [Math]::Max(1, [int]($ReleaseSec * $SampleRate))
    $relStart = $n - $rel
    $atkInc = 1.0 / $atk
    $useDecay = $DecayTau -gt 0.0
    if ($useDecay) { $decMul = [Math]::Exp(-1.0 / ($DecayTau * $SampleRate)) }

    $dec = 1.0
    for ($i = 0; $i -lt $n; $i++) {
        $env = 1.0
        if ($i -lt $atk) { $env = $i * $atkInc }
        if ($i -ge $relStart) {
            $r = ($n - $i) / $rel
            if ($r -lt $env) { $env = $r }
        }
        $acc = 0.0
        for ($o = 0; $o -lt $nOsc; $o++) {
            $p = $ph[$o] + $dph[$o]
            if ($p -ge 1.0) { $p -= 1.0 }
            $ph[$o] = $p
            $t = $p * $MusicLutSize
            $i0 = [int]$t
            $w = $t - $i0
            $i1 = $i0 + 1
            if ($i1 -ge $MusicLutSize) { $i1 = 0 }
            $a = $MusicLut[$i0]
            $acc += $Gains[$o] * ($a + ($MusicLut[$i1] - $a) * $w)
        }
        $out[$i] = $Amp * $env * $dec * $acc
        if ($useDecay) { $dec *= $decMul }
    }
    return ,$out
}

# Kick with a pitch drop (the common case); $F1 must be below $F0.
function Render-Kick {
    param([double]$DurSec, [double]$Amp, [double]$F0, [double]$F1, [double]$PitchTau)
    $n = [int][Math]::Ceiling($DurSec * $SampleRate)
    $out = New-Object 'float[]' $n
    $ph = 0.0
    $f = $F0
    $steps = [Math]::Max(1, [int]($PitchTau * $SampleRate))
    $df = ($F1 - $F0) / $steps
    $dec = 1.0
    $decMul = [Math]::Exp(-1.0 / (0.09 * $SampleRate))
    $rel = [Math]::Max(1, [int](0.010 * $SampleRate))
    $relStart = $n - $rel
    for ($i = 0; $i -lt $n; $i++) {
        $ph += $f / $SampleRate
        if ($ph -ge 1.0) { $ph -= 1.0 }
        $t = $ph * $MusicLutSize
        $i0 = [int]$t
        $w = $t - $i0
        $i1 = $i0 + 1
        if ($i1 -ge $MusicLutSize) { $i1 = 0 }
        $a = $MusicLut[$i0]
        $v = $Amp * $dec * ($a + ($MusicLut[$i1] - $a) * $w)
        if ($i -ge $relStart) { $v = $v * (($n - $i) / $rel) }
        $out[$i] = $v
        $dec *= $decMul
        $f += $df
        if ($f -lt $F1) { $f = $F1 }
    }
    return ,$out
}

# Snare: one-pole highpassed noise plus a short 185 Hz body tone.
function Render-Snare {
    param([double]$DurSec, [double]$Amp, [int]$Seed)
    $n = [int][Math]::Ceiling($DurSec * $SampleRate)
    $out = New-Object 'float[]' $n
    $rng = New-Object System.Random($Seed)
    $lp = 0.0
    $nd = 1.0
    $bd = 1.0
    $ndMul = [Math]::Exp(-1.0 / (0.055 * $SampleRate))
    $bdMul = [Math]::Exp(-1.0 / (0.030 * $SampleRate))
    $dph = 185.0 / $SampleRate
    $ph = 0.0
    $rel = [Math]::Max(1, [int](0.010 * $SampleRate))
    $relStart = $n - $rel
    for ($i = 0; $i -lt $n; $i++) {
        $w = $rng.NextDouble() * 2.0 - 1.0
        $lp += 0.35 * ($w - $lp)
        $ph += $dph
        if ($ph -ge 1.0) { $ph -= 1.0 }
        $t = $ph * $MusicLutSize
        $i0 = [int]$t
        $w2 = $t - $i0
        $i1 = $i0 + 1
        if ($i1 -ge $MusicLutSize) { $i1 = 0 }
        $a = $MusicLut[$i0]
        $v = $Amp * (0.75 * ($w - $lp) * $nd + 0.45 * ($a + ($MusicLut[$i1] - $a) * $w2) * $bd)
        if ($i -ge $relStart) { $v = $v * (($n - $i) / $rel) }
        $out[$i] = $v
        $nd *= $ndMul
        $bd *= $bdMul
    }
    return ,$out
}

# Closed hat: bright highpassed noise, very fast decay.
function Render-Hat {
    param([double]$DurSec, [double]$Amp, [int]$Seed)
    $n = [int][Math]::Ceiling($DurSec * $SampleRate)
    $out = New-Object 'float[]' $n
    $rng = New-Object System.Random($Seed)
    $lp = 0.0
    $dec = 1.0
    $decMul = [Math]::Exp(-1.0 / (0.016 * $SampleRate))
    $rel = [Math]::Max(1, [int](0.006 * $SampleRate))
    $relStart = $n - $rel
    for ($i = 0; $i -lt $n; $i++) {
        $w = $rng.NextDouble() * 2.0 - 1.0
        $lp += 0.80 * ($w - $lp)
        $v = $Amp * $dec * ($w - $lp)
        if ($i -ge $relStart) { $v = $v * (($n - $i) / $rel) }
        $out[$i] = $v
        $dec *= $decMul
    }
    return ,$out
}

# Crash: long highpassed noise with two quiet inharmonic partials for shimmer.
function Render-Crash {
    param([double]$DurSec, [double]$Amp, [int]$Seed)
    $n = [int][Math]::Ceiling($DurSec * $SampleRate)
    $out = New-Object 'float[]' $n
    $rng = New-Object System.Random($Seed)
    $lp = 0.0
    $dec = 1.0
    $decMul = [Math]::Exp(-1.0 / (0.42 * $SampleRate))
    $rel = [Math]::Max(1, [int](0.020 * $SampleRate))
    $relStart = $n - $rel
    $p1 = 0.0; $p2 = 0.0
    $d1 = 2411.0 / $SampleRate
    $d2 = 3173.0 / $SampleRate
    for ($i = 0; $i -lt $n; $i++) {
        $w = $rng.NextDouble() * 2.0 - 1.0
        $lp += 0.55 * ($w - $lp)
        $p1 += $d1; if ($p1 -ge 1.0) { $p1 -= 1.0 }
        $p2 += $d2; if ($p2 -ge 1.0) { $p2 -= 1.0 }
        $t1 = $p1 * $MusicLutSize; $a1 = [int]$t1; $f1 = $t1 - $a1; $b1 = $a1 + 1
        if ($b1 -ge $MusicLutSize) { $b1 = 0 }
        $t2 = $p2 * $MusicLutSize; $a2 = [int]$t2; $f2 = $t2 - $a2; $b2 = $a2 + 1
        if ($b2 -ge $MusicLutSize) { $b2 = 0 }
        $s1 = $MusicLut[$a1] + ($MusicLut[$b1] - $MusicLut[$a1]) * $f1
        $s2 = $MusicLut[$a2] + ($MusicLut[$b2] - $MusicLut[$a2]) * $f2
        $v = $Amp * $dec * (($w - $lp) * 0.85 + $s1 * 0.10 + $s2 * 0.08)
        if ($i -ge $relStart) { $v = $v * (($n - $i) / $rel) }
        $out[$i] = $v
        $dec *= $decMul
    }
    return ,$out
}

# Rising noise + tone for the sting's first bar.
function Render-Riser {
    param([double]$DurSec, [double]$Amp, [int]$Seed)
    $n = [int][Math]::Ceiling($DurSec * $SampleRate)
    $out = New-Object 'float[]' $n
    $rng = New-Object System.Random($Seed)
    $lp = 0.0
    $ph = 0.0
    $f = 300.0
    $df = 2100.0 / $n
    for ($i = 0; $i -lt $n; $i++) {
        $r = $i / $n
        $w = $rng.NextDouble() * 2.0 - 1.0
        $lp += (0.10 + 0.75 * $r) * ($w - $lp)
        $ph += $f / $SampleRate
        if ($ph -ge 1.0) { $ph -= 1.0 }
        $t = $ph * $MusicLutSize
        $i0 = [int]$t
        $w2 = $t - $i0
        $i1 = $i0 + 1
        if ($i1 -ge $MusicLutSize) { $i1 = 0 }
        $a = $MusicLut[$i0]
        $env = $r * $r
        $out[$i] = $Amp * $env * (0.80 * ($w - $lp) + 0.50 * ($a + ($MusicLut[$i1] - $a) * $w2))
        $f += $df
    }
    return ,$out
}

function Normalize-Peak([float[]]$Buf, [double]$Peak) {
    $m = 0.0
    foreach ($v in $Buf) {
        $a = [Math]::Abs($v)
        if ($a -gt $m) { $m = $a }
    }
    if ($m -le 0.0) { return ,$Buf }
    $g = $Peak / $m
    for ($i = 0; $i -lt $Buf.Length; $i++) { $Buf[$i] = $Buf[$i] * $g }
    return ,$Buf
}

# ---------------------------------------------------------------------------
# Loop verification. Reports numbers, returns $true/$false. Nothing here trusts
# the composer's intent -- it reads the samples that are about to hit the disk.
# ---------------------------------------------------------------------------
function Measure-Loop {
    param(
        [float[]]$Samples,
        [string]$Label,
        [double]$Bpm,
        [int]$ExpectedBars
    )
    $n = $Samples.Length
    $barSamples = (Get-BeatSamples $Bpm) * 4
    $barsExact = $n / $barSamples

    $peak = 0.0
    $sumSq = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $v = $Samples[$i]
        $a = [Math]::Abs($v)
        if ($a -gt $peak) { $peak = $a }
        $sumSq += $v * $v
    }
    $rms = [Math]::Sqrt($sumSq / $n)
    $crest = if ($rms -gt 0.0) { 20.0 * [Math]::Log10($peak / $rms) } else { 0.0 }

    # The seam itself: last sample -> first sample.
    $wrapDelta = [Math]::Abs($Samples[$n - 1] - $Samples[0])

    # Largest adjacent-sample jump in the 2048 steps either side of the seam.
    # If the join were audible it would be a bigger step than anything next to it.
    $W = 2048
    $maxNear = 0.0
    $sumAbs = 0.0
    for ($i = 0; $i -lt $n - 1; $i++) {
        $d = [Math]::Abs($Samples[$i + 1] - $Samples[$i])
        $sumAbs += $d
        if (($i -lt $W) -or ($i -ge ($n - 1 - $W))) {
            if ($d -gt $maxNear) { $maxNear = $d }
        }
    }
    $meanAbs = $sumAbs / ($n - 1)

    $barsWhole = [Math]::Abs($barsExact - [Math]::Round($barsExact)) -lt 1.0e-6
    $barsMatch = ([int][Math]::Round($barsExact)) -eq $ExpectedBars
    $seamOk = $wrapDelta -le ($maxNear * 1.5)
    $clipOk = $peak -le 1.0
    $ok = $barsWhole -and $barsMatch -and $seamOk -and $clipOk

    $verdict = if ($ok) { 'PASS' } else { 'FAIL' }
    $checks = @()
    if (-not $barsWhole) { $checks += 'BARS-NOT-WHOLE' }
    if (-not $barsMatch) { $checks += "BARS-NOT-$ExpectedBars" }
    if (-not $seamOk) { $checks += 'SEAM-OUTLIER' }
    if (-not $clipOk) { $checks += 'CLIPPING' }

    $extra = if ($checks.Count -gt 0) { '  <-- ' + ($checks -join ',') } else { '' }
    # Write-Host, not Write-Output: the caller does `$results += Measure-Loop ...`
    # and would otherwise capture the report line as an array element instead of
    # printing it, so the numbers below would never reach the console.
    Write-Host ('  [{0}] {1,-22} bars={2:F6}  dur={3:F3}s  peak={4:F3}  rms={5:F3}  crest={6:F1}dB  seam={7:F4}  localMax={8:F4}  mean={9:F4}{10}' -f `
        $verdict, $Label, $barsExact, ($n / $SampleRate), $peak, $rms, $crest, $wrapDelta, $maxNear, $meanAbs, $extra)
    return $ok
}

# One-shot: confirm the tail has actually decayed to silence.
function Measure-Tail {
    param([float[]]$Samples, [string]$Label, [double]$WindowSec = 0.25)
    $n = $Samples.Length
    $w = [Math]::Min($n, [int]($WindowSec * $SampleRate))
    $sumSq = 0.0
    for ($i = $n - $w; $i -lt $n; $i++) { $sumSq += $Samples[$i] * $Samples[$i] }
    $tailRms = [Math]::Sqrt($sumSq / $w)
    $ok = $tailRms -lt 0.01
    $verdict = if ($ok) { 'PASS' } else { 'FAIL' }
    Write-Host ('  [{0}] {1,-22} one-shot, last {2:F2}s rms={3:F5} (must be < 0.0100){4}' -f `
        $verdict, $Label, $WindowSec, $tailRms, $(if ($ok) { '' } else { '  <-- TAIL-AUDIBLE' }))
    return $ok
}

# =============================================================================
# SFX (unchanged since Phase 1)
# =============================================================================
$tick = Add-Envelope (New-Tone 880.0 0.06 0.30) 0.004 0.05
Write-WavFile $tick (Join-Path $OutDir 'tick.wav')

$win = Concat-Samples @(
    (Add-Envelope (New-Tone 523.25 0.15 0.30) 0.01 0.05),
    (Add-Envelope (New-Tone 659.25 0.15 0.30) 0.01 0.05),
    (Add-Envelope (New-Tone 783.99 0.15 0.30) 0.01 0.05)
)
Write-WavFile $win (Join-Path $OutDir 'win.wav')

$fail = Concat-Samples @(
    (Add-Envelope (New-Tone 329.63 0.20 0.30) 0.01 0.06),
    (Add-Envelope (New-Tone 220.00 0.20 0.30) 0.01 0.10)
)
Write-WavFile $fail (Join-Path $OutDir 'fail.wav')

# =============================================================================
# music_title.wav -- "Micro Heroes March", D minor, 120 BPM, 8 bars (16.000 s)
# Epic, moderate tempo. i - VI - III - VII (Dm - Bb - F - C) and back to Dm, so
# the turnaround is V -> i and the loop joins on a resolution.
# =============================================================================
$titleBpm = 120.0
$titleBars = 8
$TBeat = Get-BeatSamples $titleBpm
$TBar = $TBeat * 4
$title = New-Object 'float[]' ($TBar * $titleBars)

$titleChords = @(
    @(50, 53, 57),   # Dm : D3 F3 A3
    @(46, 50, 53),   # Bb : Bb2 D3 F3
    @(53, 57, 60),   # F  : F3 A3 C4
    @(48, 52, 55)    # C  : C3 E3 G3
)
$titleRoots = @(38, 34, 41, 36)   # D2 Bb1 F2 C2

# Sustained pad, two detuned oscillators per chord tone for slow beating.
for ($c = 0; $c -lt 4; $c++) {
    $freqs = New-Object 'double[]' 6
    $gains = New-Object 'double[]' 6
    for ($v = 0; $v -lt 3; $v++) {
        $f = Convert-ToMidi $titleChords[$c][$v]
        $freqs[$v * 2] = $f
        $freqs[$v * 2 + 1] = $f * 1.0035
        $gains[$v * 2] = 0.150
        $gains[$v * 2 + 1] = 0.125
    }
    $pad = Render-Pluck -Freqs $freqs -Gains $gains -DurSec 4.0 -Amp 1.0 `
        -AttackSec 0.060 -DecayTau 0.0 -ReleaseSec 0.140
    Mix-Wrapped $title $pad ($c * 2 * $TBar)
}

# Bass: sustained root plus an eighth-note octave pulse for definition on
# laptop speakers, where a 73 Hz fundamental alone is too quiet.
for ($c = 0; $c -lt 4; $c++) {
    $f = Convert-ToMidi $titleRoots[$c]
    $held = Render-Pluck -Freqs @($f, ($f * 2.0)) -Gains @(0.280, 0.095) -DurSec 4.0 `
        -AttackSec 0.020 -DecayTau 0.0 -ReleaseSec 0.100
    Mix-Wrapped $title $held ($c * 2 * $TBar)
    for ($e = 0; $e -lt 16; $e++) {
        $pulse = Render-Pluck -Freqs @(($f * 2.0), ($f * 4.0)) -Gains @(0.150, 0.055) `
            -DurSec 0.26 -AttackSec 0.004 -DecayTau 0.070 -ReleaseSec 0.050
        Mix-Wrapped $title $pulse ($c * 2 * $TBar + [int]($e * $TBeat / 2))
    }
}

# Lead: an original 8-bar tune in D natural minor, 0 = rest. Rests on the last
# eighth let the loop breathe before the crash comes back around.
$titleMelody = @(
     69, 0, 74, 0, 77, 0, 74, 0,
     72, 0, 0,  0, 69, 0, 0,  0,
     70, 0, 65, 0, 62, 0, 65, 0,
     69, 0, 0,  0, 0,  0, 0,  0,
     65, 0, 69, 0, 72, 0, 69, 0,
     74, 0, 72, 0, 69, 0, 0,  0,
     72, 0, 76, 0, 79, 0, 76, 0,
     74, 0, 72, 0, 74, 0, 0,  0
)
for ($i = 0; $i -lt 64; $i++) {
    $m = $titleMelody[$i]
    if ($m -le 0) { continue }
    $f = Convert-ToMidi $m
    $note = Render-Pluck -Freqs @($f, ($f * 2.0)) -Gains @(0.200, 0.070) -DurSec 0.30 `
        -AttackSec 0.006 -DecayTau 0.110 -ReleaseSec 0.060
    Mix-Wrapped $title $note ([int]($i * $TBeat / 2))
}

# Kit: kick 1 and 3, snare 2 and 4, eighth hats, crash on the downbeat.
for ($bar = 0; $bar -lt $titleBars; $bar++) {
    $b0 = $bar * $TBar
    foreach ($b in @(0, 2)) {
        Mix-Wrapped $title (Render-Kick -DurSec 0.34 -Amp 0.600 -F0 130.0 -F1 45.0 -PitchTau 0.045) ($b0 + $b * $TBeat)
    }
    foreach ($b in @(1, 3)) {
        Mix-Wrapped $title (Render-Snare -DurSec 0.20 -Amp 0.330 -Seed (1000 + $bar * 10 + $b)) ($b0 + $b * $TBeat)
    }
    for ($e = 0; $e -lt 8; $e++) {
        $a = if ($e % 2 -eq 0) { 0.105 } else { 0.065 }
        Mix-Wrapped $title (Render-Hat -DurSec 0.055 -Amp $a -Seed (2000 + $bar * 10 + $e)) ($b0 + [int]($e * $TBeat / 2))
    }
}
Mix-Wrapped $title (Render-Crash -DurSec 1.50 -Amp 0.190 -Seed 4242) 0

$title = Normalize-Peak $title 0.89
Write-WavFile $title (Join-Path $OutDir 'music_title.wav')

# =============================================================================
# music_gauntlet.wav -- "Gauntlet Run", A minor, 150 BPM, 8 bars (12.800 s)
# Driving. i - VI - III - VII (Am - F - C - G), same roots reused by the danger
# track so the two read as one piece at two tempos.
# =============================================================================
$ganBpm = 150.0
$ganBars = 8
$GBeat = Get-BeatSamples $ganBpm
$GBar = $GBeat * 4
$ganBeats = $ganBars * 4
$gan = New-Object 'float[]' ($GBar * $ganBars)

# Smooth voice leading: two of the three tones hold across each change.
$ganChords = @(
    @(57, 60, 64),   # Am : A3 C4 E4
    @(57, 60, 65),   # F  : A3 C4 F4
    @(55, 60, 64),   # C  : G3 C4 E4
    @(55, 59, 62)    # G  : G3 B3 D4
)
$ganRoots = @(45, 41, 48, 43)   # A2 F2 C3 G2

# Quiet sustained body under the stabs.
for ($c = 0; $c -lt 4; $c++) {
    $freqs = New-Object 'double[]' 6
    $gains = New-Object 'double[]' 6
    for ($v = 0; $v -lt 3; $v++) {
        $f = Convert-ToMidi $ganChords[$c][$v]
        $freqs[$v * 2] = $f
        $freqs[$v * 2 + 1] = $f * 1.0040
        $gains[$v * 2] = 0.070
        $gains[$v * 2 + 1] = 0.058
    }
    $body = Render-Pluck -Freqs $freqs -Gains $gains -DurSec 3.2 -Amp 1.0 `
        -AttackSec 0.030 -DecayTau 0.0 -ReleaseSec 0.110
    Mix-Wrapped $gan $body ($c * 2 * $GBar)
}

# Offbeat power-chord stabs: the engine of the loop.
for ($c = 0; $c -lt 4; $c++) {
    $tone = $ganChords[$c]
    $freqs = New-Object 'double[]' ($tone.Length * 2)
    $gains = New-Object 'double[]' ($tone.Length * 2)
    for ($v = 0; $v -lt $tone.Length; $v++) {
        $f = Convert-ToMidi $tone[$v]
        $freqs[$v * 2] = $f
        $freqs[$v * 2 + 1] = $f * 1.0060
        $gains[$v * 2] = 0.105
        $gains[$v * 2 + 1] = 0.085
    }
    for ($bar = 0; $bar -lt 2; $bar++) {
        $b0 = ($c * 2 + $bar) * $GBar
        foreach ($e in @(1, 3, 5, 7)) {
            $stab = Render-Pluck -Freqs $freqs -Gains $gains -DurSec 0.24 `
                -AttackSec 0.004 -DecayTau 0.055 -ReleaseSec 0.050
            Mix-Wrapped $gan $stab ($b0 + [int]($e * $GBeat / 2))
        }
    }
}

# Driving eighth-note bass.
for ($b = 0; $b -lt $ganBeats; $b++) {
    $f = Convert-ToMidi $ganRoots[[Math]::Floor($b / 8) % 4]
    $onBeat = ($b % 2 -eq 0)
    $amp = if ($onBeat) { 0.330 } else { 0.215 }
    $note = Render-Pluck -Freqs @($f, ($f * 2.0)) -Gains @($amp, ($amp * 0.35)) -DurSec 0.30 `
        -AttackSec 0.003 -DecayTau 0.075 -ReleaseSec 0.050
    Mix-Wrapped $gan $note ($b * $GBeat)
}

# Lead: original urgent riff, again i - VI - III - VII.
$ganMelody = @(
     69, 0, 69, 72, 69, 0, 64, 0,
     69, 0, 69, 72, 74, 0, 72, 0,
     65, 0, 65, 69, 65, 0, 60, 0,
     65, 0, 69, 72, 69, 0, 65, 0,
     67, 0, 72, 76, 72, 0, 67, 0,
     72, 0, 76, 79, 76, 0, 72, 0,
     74, 0, 71, 74, 79, 0, 74, 0,
     74, 0, 71, 67, 62, 0, 59, 0
)
for ($i = 0; $i -lt 64; $i++) {
    $m = $ganMelody[$i]
    if ($m -le 0) { continue }
    $f = Convert-ToMidi $m
    $note = Render-Pluck -Freqs @($f, ($f * 2.0)) -Gains @(0.195, 0.065) -DurSec 0.30 `
        -AttackSec 0.004 -DecayTau 0.080 -ReleaseSec 0.055
    Mix-Wrapped $gan $note ([int]($i * $GBeat / 2))
}

# Kit: four-on-the-floor, snare on 2 and 4, eighth hats.
for ($b = 0; $b -lt $ganBeats; $b++) {
    $b0 = $b * $GBeat
    Mix-Wrapped $gan (Render-Kick -DurSec 0.30 -Amp 0.560 -F0 140.0 -F1 48.0 -PitchTau 0.035) $b0
    if ($b % 2 -eq 1) {
        Mix-Wrapped $gan (Render-Snare -DurSec 0.19 -Amp 0.350 -Seed (5000 + $b)) $b0
    }
    for ($e = 0; $e -lt 2; $e++) {
        $a = if ($e -eq 0) { 0.115 } else { 0.080 }
        Mix-Wrapped $gan (Render-Hat -DurSec 0.050 -Amp $a -Seed (6000 + $b * 4 + $e)) ($b0 + [int]($e * $GBeat / 2))
    }
}

$gan = Normalize-Peak $gan 0.89
Write-WavFile $gan (Join-Path $OutDir 'music_gauntlet.wav')

# =============================================================================
# music_danger.wav -- "Redline", A minor, 180 BPM, 4 bars (5.333 s)
# Same chord roots as music_gauntlet, 1.2x the tempo, sixteenth-note bass and lead
# an octave up, double-time hats. Short enough to loop under a 3-second warning.
# =============================================================================
$danBpm = 180.0
$danBars = 4
$DBeat = Get-BeatSamples $danBpm
$DBar = $DBeat * 4
$danBeats = $danBars * 4
$dan = New-Object 'float[]' ($DBar * $danBars)

# One chord per bar, taken from the gauntlet voicings.
for ($c = 0; $c -lt 4; $c++) {
    $tone = $ganChords[$c]
    $freqs = New-Object 'double[]' ($tone.Length * 2)
    $gains = New-Object 'double[]' ($tone.Length * 2)
    for ($v = 0; $v -lt $tone.Length; $v++) {
        $f = Convert-ToMidi $tone[$v]
        $freqs[$v * 2] = $f
        $freqs[$v * 2 + 1] = $f * 1.0050
        $gains[$v * 2] = 0.055
        $gains[$v * 2 + 1] = 0.045
    }
    $body = Render-Pluck -Freqs $freqs -Gains $gains -DurSec 1.34 -Amp 1.0 `
        -AttackSec 0.020 -DecayTau 0.0 -ReleaseSec 0.080
    Mix-Wrapped $dan $body ($c * $DBar)
    # Stabs on every offbeat eighth.
    foreach ($e in @(1, 3, 5, 7)) {
        $stab = Render-Pluck -Freqs $freqs -Gains @(0.085, 0.070, 0.070, 0.070, 0.070, 0.058) `
            -DurSec 0.18 -AttackSec 0.003 -DecayTau 0.040 -ReleaseSec 0.040
        Mix-Wrapped $dan $stab ($c * $DBar + [int]($e * $DBeat / 2))
    }
}

# Sixteenth-note bass on the same roots.
for ($b = 0; $b -lt $danBeats; $b++) {
    $f = Convert-ToMidi $ganRoots[[Math]::Floor($b / 4) % 4]
    for ($s = 0; $s -lt 4; $s++) {
        $amp = if ($s -eq 0) { 0.310 } else { 0.165 }
        $note = Render-Pluck -Freqs @($f, ($f * 2.0)) -Gains @($amp, ($amp * 0.40)) -DurSec 0.16 `
            -AttackSec 0.002 -DecayTau 0.035 -ReleaseSec 0.035
        Mix-Wrapped $dan $note ($b * $DBeat + [int]($s * $DBeat / 4))
    }
}

# Lead: the gauntlet riff up an octave, on sixteenths. Same notes, so the two
# tracks are recognisably the same song rather than two unrelated tunes.
for ($i = 0; $i -lt 64; $i++) {
    $m = $ganMelody[$i]
    if ($m -le 0) { continue }
    $f = Convert-ToMidi ($m + 12)
    $note = Render-Pluck -Freqs @($f, ($f * 2.0)) -Gains @(0.160, 0.075) -DurSec 0.13 `
        -AttackSec 0.002 -DecayTau 0.030 -ReleaseSec 0.030
    Mix-Wrapped $dan $note ([int]($i * $DBeat / 4))
}

# Denser kit: kick on every beat, snare on 2 and 4, sixteenth hats, crash on top.
for ($b = 0; $b -lt $danBeats; $b++) {
    $b0 = $b * $DBeat
    Mix-Wrapped $dan (Render-Kick -DurSec 0.26 -Amp 0.500 -F0 150.0 -F1 50.0 -PitchTau 0.030) $b0
    if ($b % 2 -eq 1) {
        Mix-Wrapped $dan (Render-Snare -DurSec 0.17 -Amp 0.390 -Seed (7000 + $b)) $b0
    }
    for ($s = 0; $s -lt 4; $s++) {
        $a = if ($s % 2 -eq 0) { 0.110 } else { 0.072 }
        Mix-Wrapped $dan (Render-Hat -DurSec 0.042 -Amp $a -Seed (8000 + $b * 4 + $s)) ($b0 + [int]($s * $DBeat / 4))
    }
}
Mix-Wrapped $dan (Render-Crash -DurSec 1.10 -Amp 0.150 -Seed 4343) 0

$dan = Normalize-Peak $dan 0.89
Write-WavFile $dan (Join-Path $OutDir 'music_danger.wav')

# =============================================================================
# music_intermission.wav -- "Sting", A minor, 150 BPM, 2 bars (3.200 s)
# One-shot, not a loop: bar 1 builds, bar 2 lands, tail decays to silence. Sized
# to the 3.0 s intermission countdown plus the GO flash. Rendered with
# Mix-Linear so nothing wraps back to the top.
# =============================================================================
$stgBpm = 150.0
$IBar = (Get-BeatSamples $stgBpm) * 4
$stg = New-Object 'float[]' ($IBar * 2)

$barSec = $IBar / $SampleRate
Mix-Linear $stg (Render-Riser -DurSec $barSec -Amp 0.300 -Seed 31337) 0

# Pulsing low A, rising each beat.
for ($b = 0; $b -lt 4; $b++) {
    $f = Convert-ToMidi 45
    $amp = 0.100 + 0.070 * $b
    $pulse = Render-Pluck -Freqs @($f, ($f * 2.0)) -Gains @($amp, ($amp * 0.40)) -DurSec 0.34 `
        -AttackSec 0.010 -DecayTau 0.100 -ReleaseSec 0.050
    Mix-Linear $stg $pulse ([int]($b * $IBar / 4))
}

# Snare roll: eighths for two beats, then sixteenths, each hit louder.
$rollSeed = 9100
for ($b = 0; $b -lt 4; $b++) {
    $steps = if ($b -lt 2) { 2 } else { 4 }
    $stepLen = $IBar / ($steps * 4)
    for ($s = 0; $s -lt $steps; $s++) {
        $rollSeed++
        $amp = 0.100 + 0.055 * ($b * 2 + $s)
        Mix-Linear $stg (Render-Snare -DurSec 0.13 -Amp $amp -Seed $rollSeed) `
            ([int]($b * $IBar / 4 + $s * $stepLen))
    }
}

# The landing: crash, Am chord stab, low boom, and a bright sparkle on top.
$hit = $IBar
Mix-Linear $stg (Render-Crash -DurSec 1.40 -Amp 0.330 -Seed 5150) $hit
Mix-Linear $stg (Render-Pluck `
    -Freqs @((Convert-ToMidi 45), (Convert-ToMidi 57), (Convert-ToMidi 60), (Convert-ToMidi 64)) `
    -Gains @(0.300, 0.160, 0.150, 0.150) -DurSec 0.85 `
    -AttackSec 0.004 -DecayTau 0.220 -ReleaseSec 0.120) $hit
Mix-Linear $stg (Render-Kick -DurSec 0.55 -Amp 0.500 -F0 155.0 -F1 42.0 -PitchTau 0.050) $hit
Mix-Linear $stg (Render-Pluck `
    -Freqs @((Convert-ToMidi 76), (Convert-ToMidi 81)) -Gains @(0.100, 0.080) -DurSec 0.50 `
    -AttackSec 0.003 -DecayTau 0.120 -ReleaseSec 0.100) $hit

$stg = Normalize-Peak $stg 0.89
Write-WavFile $stg (Join-Path $OutDir 'music_intermission.wav')

# =============================================================================
# Verification
# =============================================================================
Write-Output ''
Write-Output 'Loop verification (seam = last->first sample step; localMax = largest step in the 4096 samples around the seam):'
$results = @()
$results += Measure-Loop $title 'music_title.wav'      $titleBpm $titleBars
$results += Measure-Loop $gan   'music_gauntlet.wav'   $ganBpm   $ganBars
$results += Measure-Loop $dan   'music_danger.wav'     $danBpm   $danBars
$results += Measure-Tail $stg   'music_intermission.wav'

$passCount = ($results | Where-Object { $_ }).Count
Write-Output ''
Write-Output ("Verified {0}/{1} checks passed." -f $passCount, $results.Count)

Write-Output ''
Write-Output "Generated audio files in ${OutDir}:"
Get-ChildItem $OutDir -Filter '*.wav' | Sort-Object Name | ForEach-Object {
    Write-Output ("  {0,-24} {1,8} bytes" -f $_.Name, $_.Length)
}

if ($passCount -ne $results.Count) {
    # Write-Host, not Write-Error: $ErrorActionPreference is 'Stop', so
    # Write-Error would throw before reaching exit 1 and the exit code would be
    # an incidental 1 rather than this deliberate one.
    Write-Host 'Audio verification FAILED -- see the FAIL lines above.'
    exit 1
}
Write-Output 'Audio generation complete: all loops verified.'
exit 0
