param([string]$Engine = ".\windows\language-engine.ps1")
$ErrorActionPreference = "Stop"

$engineUtf8 = [IO.File]::ReadAllText($Engine,[Text.Encoding]::UTF8)
$EngineBom = Join-Path $env:TEMP ("ocl_engine_test_"+[guid]::NewGuid().ToString("N")+".ps1")
[IO.File]::WriteAllText($EngineBom,$engineUtf8,[Text.UTF8Encoding]::new($true))

function Run-Engine([string]$Mode,[string]$Text) {
    $id=[guid]::NewGuid().ToString("N")
    $in=Join-Path $env:TEMP ("ocl_in_"+$id+".txt")
    $out=Join-Path $env:TEMP ("ocl_out_"+$id+".txt")
    [IO.File]::WriteAllText($in,$Text,[Text.UTF8Encoding]::new($false))
    & powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File $EngineBom -Mode $Mode -InputFile $in -OutputFile $out
    $r=[IO.File]::ReadAllText($out,[Text.Encoding]::UTF8)
    Remove-Item $in,$out -Force -ErrorAction SilentlyContinue
    return $r
}

$tests=@(
    @{Name="English spelling"; Mode="fix"; Input="hello my frend"; Expect="hello my friend"},
    @{Name="English grammar"; Mode="fix"; Input="I has a car"; Expect="I have a car"},
    @{Name="Arabic spelling"; Mode="fix"; Input="هاذا كلام خطء"; Expect="هذا كلام خطأ"}
)

foreach($t in $tests){
    $actual=Run-Engine $t.Mode $t.Input
    if($actual -ne $t.Expect){ throw "$($t.Name) failed. Expected [$($t.Expect)] got [$actual]" }
    Write-Host "PASS: $($t.Name) -> $actual"
}

$enToAr=Run-Engine "translate" "hello my friend"
if($enToAr.StartsWith("__ERROR__:") -or -not [regex]::IsMatch($enToAr,'صديق')){
    throw "English->Arabic translation failed quality check: $enToAr"
}
Write-Host "PASS: English->Arabic -> $enToAr"

$arToEn=Run-Engine "translate" "مرحبا يا صديقي"
if($arToEn.StartsWith("__ERROR__:") -or -not [regex]::IsMatch($arToEn,'(?i)friend')){
    throw "Arabic->English translation failed quality check: $arToEn"
}
Write-Host "PASS: Arabic->English -> $arToEn"


Remove-Item $EngineBom -Force -ErrorAction SilentlyContinue
