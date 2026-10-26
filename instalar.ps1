# Instalador de la traduccion al espanol de Tree of Savior (Steam). No necesita Python.
# Crea languageData\Spanish copiando tu languageData\English y reemplazando solo la columna de
# texto. No modifica English ni ningun otro archivo del juego.
#
#   .\instalar.ps1                     instala
#   .\instalar.ps1 -Juego "RUTA"       ruta a ...\TreeOfSavior\release\languageData
#   .\instalar.ps1 -Desinstalar        borra la carpeta Spanish
param(
    [string]$Juego = "",
    [switch]$Desinstalar,
    [switch]$SinPausa
)
$ErrorActionPreference = "Stop"
$utf8 = New-Object System.Text.UTF8Encoding($false)
$parche = Join-Path $PSScriptRoot "parche"
$rutas = @(
    "C:\Program Files (x86)\Steam\steamapps\common\TreeOfSavior\release\languageData",
    "C:\Program Files\Steam\steamapps\common\TreeOfSavior\release\languageData",
    "D:\SteamLibrary\steamapps\common\TreeOfSavior\release\languageData",
    "E:\SteamLibrary\steamapps\common\TreeOfSavior\release\languageData"
)

function Buscar-Juego([string]$arg) {
    $cands = @()
    if ($arg) { $cands += $arg } else { $cands += $rutas }
    foreach ($c in $cands) {
        $c = $c.Trim('"')
        # acepta languageData, release o TreeOfSavior
        foreach ($sub in @("", "languageData", "release\languageData")) {
            $p = if ($sub) { Join-Path $c $sub } else { $c }
            if (Test-Path (Join-Path $p "English")) { return $p }
        }
    }
    return $null
}

$lang = Buscar-Juego $Juego
if (-not $lang -and -not $Juego) {
    Write-Host "No encontre el juego en las rutas normales de Steam."
    $r = Read-Host "Pega la ruta de la carpeta TreeOfSavior (o de languageData) y pulsa Enter"
    $lang = Buscar-Juego $r
}
if (-not $lang) {
    Write-Host "No encontre la carpeta languageData\English. Revisa la ruta."
    exit 1
}
$dst = Join-Path $lang "Spanish"

if ($Desinstalar) {
    if (Test-Path $dst) {
        Remove-Item -Recurse -Force $dst
        Write-Host "Borrada $dst"
        Write-Host "Si el juego estaba en Spanish, elige otro idioma en los Ajustes."
    } else {
        Write-Host "No hay carpeta Spanish instalada."
    }
    exit 0
}

if (-not (Test-Path $parche)) { Write-Host "Falta la carpeta 'parche' junto a instalar.ps1."; exit 1 }
Write-Host "Juego: $lang"
Write-Host "Cierra Tree of Savior antes de instalar."

New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item -Path (Join-Path $lang "English\*") -Destination $dst -Recurse -Force

$nl = [char]10; $cr = [char]13; $tab = [char]9
foreach ($f in (Get-ChildItem -Path $parche -Filter "*.es.tsv" | Sort-Object Name)) {
    $nombre = $f.Name.Substring(0, $f.Name.Length - ".es.tsv".Length)
    if ($nombre -eq "BADWORDS") { continue }
    $src = Join-Path $lang "English\$nombre.tsv"
    if (-not (Test-Path $src)) { Write-Host "  ${nombre}: no existe en tu juego, omitido"; continue }

    # traducciones: ID -> texto
    $trans = New-Object 'System.Collections.Generic.Dictionary[string,string]'
    $txt = $utf8.GetString([IO.File]::ReadAllBytes($f.FullName)).Replace("$cr$nl", "$nl")
    $lineas = $txt.Split($nl)
    for ($i = 1; $i -lt $lineas.Length; $i++) {
        $l = $lineas[$i]
        if ($l.Length -eq 0) { continue }
        $p = $l.IndexOf($tab)
        if ($p -gt 0) { $trans[$l.Substring(0, $p)] = $l.Substring($p + 1) }
    }

    # aplicar sobre el ingles del jugador (solo columna 2)
    $en = $utf8.GetString([IO.File]::ReadAllBytes($src)).Split($nl)
    $out = New-Object 'System.Collections.Generic.List[string]' $en.Length
    $n = 0
    foreach ($raw in $en) {
        $tieneCr = $raw.EndsWith("$cr")
        $linea = if ($tieneCr) { $raw.Substring(0, $raw.Length - 1) } else { $raw }
        $cols = $linea.Split($tab)
        if ($cols.Length -ge 2 -and $trans.ContainsKey($cols[0])) {
            $cols[1] = $trans[$cols[0]]
            $n++
        }
        $nuevo = [string]::Join("$tab", $cols)
        if ($tieneCr) { $nuevo += "$cr" }
        $out.Add($nuevo)
    }
    [IO.File]::WriteAllBytes((Join-Path $dst "$nombre.tsv"), $utf8.GetBytes([string]::Join("$nl", $out)))
    Write-Host ("  {0}: {1} textos traducidos" -f $nombre, $n)
}
Write-Host ""
Write-Host "Listo. Abre el juego y elige Spanish en Ajustes > Graficos > Seleccionar idioma (reinicia el juego)."
