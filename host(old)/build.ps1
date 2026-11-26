param(
    [Parameter(Position = 0)]
    [string] $Shader,

    [Parameter(Position = 1)]
    [string] $Output
)

$ErrorActionPreference = 'Stop'
$hostDir = $PSScriptRoot
$source = Join-Path $hostDir 'runshd.c'

if ($Shader) {
    $shaderPath = (Resolve-Path -LiteralPath $Shader).Path
    if ([IO.Path]::GetExtension($shaderPath) -ine '.glsl') {
        throw "Input shader must have a .glsl extension: $shaderPath"
    }
    if ($Output) {
        $outputPath = if ([IO.Path]::IsPathRooted($Output)) {
            [IO.Path]::GetFullPath($Output)
        } else {
            [IO.Path]::GetFullPath((Join-Path $hostDir $Output))
        }
    } else {
        $outputPath = Join-Path $hostDir (([IO.Path]::GetFileNameWithoutExtension($shaderPath)) + '.exe')
    }
} else {
    if ($Output) {
        $outputPath = if ([IO.Path]::IsPathRooted($Output)) {
            [IO.Path]::GetFullPath($Output)
        } else {
            [IO.Path]::GetFullPath((Join-Path $hostDir $Output))
        }
    } else {
        $outputPath = Join-Path $hostDir 'runshd.exe'
    }
}

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path -LiteralPath $vswhere)) {
    throw "Visual Studio Installer was not found: $vswhere"
}
$vsRoot = (& $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath | Select-Object -First 1)
if (-not $vsRoot) {
    throw 'Visual Studio C++ x64 Build Tools were not found.'
}
$vcvars = Join-Path $vsRoot 'VC\Auxiliary\Build\vcvars64.bat'
if (-not (Test-Path -LiteralPath $vcvars)) {
    throw "The x64 compiler environment script was not found: $vcvars"
}

$workDir = Join-Path ([IO.Path]::GetTempPath()) ('runshd-build-' + [Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($workDir) | Out-Null
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($outputPath)) | Out-Null
try {
    $mainObject = Join-Path $workDir 'runshd.obj'
    $commands = [Collections.Generic.List[string]]::new()
    $commands.Add('@echo off')
    $commands.Add(('call "' + $vcvars + '" >nul'))
    $commands.Add('if errorlevel 1 exit /b 1')
    $commonFlags = '/nologo /c /O1 /Os /GS- /Gs65536 /Zl /Oi- /Gy /Gw'
    if ($Shader) {
        $shaderBytes = [IO.File]::ReadAllBytes($shaderPath)
        if ($shaderBytes.Length -eq 0) { throw 'The shader file is empty.' }
        $embeddedSource = Join-Path $workDir 'shader_blob.c'
        $builder = [Text.StringBuilder]::new()
        [void]$builder.AppendLine('const unsigned char embeddedShader[] =')
        for ($offset = 0; $offset -lt $shaderBytes.Length; $offset += 32) {
            $limit = [Math]::Min($offset + 32, $shaderBytes.Length)
            $escaped = [Text.StringBuilder]::new()
            for ($index = $offset; $index -lt $limit; $index++) {
                [void]$escaped.Append('\')
                [void]$escaped.Append([Convert]::ToString([int]$shaderBytes[$index], 8).PadLeft(3, '0'))
            }
            [void]$builder.AppendLine(('    "' + $escaped.ToString() + '"'))
        }
        [void]$builder.AppendLine(';')
        [void]$builder.AppendLine(('const unsigned long embeddedShaderSize = ' + $shaderBytes.Length + 'UL;'))
        [IO.File]::WriteAllText($embeddedSource, $builder.ToString(), [Text.Encoding]::ASCII)

        $blobObject = Join-Path $workDir 'shader_blob.obj'
        $commands.Add(('cl.exe ' + $commonFlags + ' /DEMBED_SHADER /Fo"' + $mainObject + '" "' + $source + '"'))
        $commands.Add('if errorlevel 1 exit /b 1')
        $commands.Add(('cl.exe /nologo /c /O1 /Os /GS- /Zl /Fo"' + $blobObject + '" "' + $embeddedSource + '"'))
        $commands.Add('if errorlevel 1 exit /b 1')
        $objects = @($mainObject, $blobObject)
    } else {
        $commands.Add(('cl.exe ' + $commonFlags + ' /Fo"' + $mainObject + '" "' + $source + '"'))
        $commands.Add('if errorlevel 1 exit /b 1')
        $objects = @($mainObject)
    }

    $importLibrary = Join-Path $workDir 'runshd.lib'
    $objectList = ($objects | ForEach-Object { '"' + $_ + '"' }) -join ' '
    $commands.Add(('link.exe /nologo ' + $objectList + ' /out:"' + $outputPath + '" /entry:entry /subsystem:windows /nodefaultlib /opt:ref /opt:icf /incremental:no /filealign:512 /implib:"' + $importLibrary + '" kernel32.lib user32.lib gdi32.lib opengl32.lib shell32.lib'))
    $commands.Add('if errorlevel 1 exit /b 1')
    $commands.Add('exit /b 0')
    $commandFile = Join-Path $workDir 'build.cmd'
    [IO.File]::WriteAllLines($commandFile, $commands, [Text.Encoding]::ASCII)
    & $env:ComSpec /d /c ('call "' + $commandFile + '"')
    if ($LASTEXITCODE -ne 0) { throw 'The Visual Studio compile/link command failed.' }

    $built = Get-Item -LiteralPath $outputPath
    if ($Shader) {
        Write-Host "Built embedded shader executable ($($shaderBytes.Length) shader bytes): $($built.Length) bytes"
        Write-Host "Output: $outputPath"
    } else {
        Write-Host "Built: $($built.Length) bytes: $outputPath"
    }
} finally {
    Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction SilentlyContinue
}
