param()

$ErrorActionPreference = 'Stop'
$repoPath = Split-Path -Parent $PSScriptRoot
Push-Location $repoPath
try {
    $evidencePath = Join-Path $repoPath 'evidencias'
    $resultsPath = Join-Path $evidencePath 'resultados'
    New-Item -ItemType Directory -Path $resultsPath -Force | Out-Null
    $logPath = Join-Path $evidencePath 'ejecucion.txt'
    $started = [DateTimeOffset]::Now
    $revision = (git rev-parse HEAD).Trim()
    $sdk = (dotnet --version).Trim()
    @(
        'EXAMEN FINAL - PRUEBAS DE SOFTWARE'
        "Inicio: $($started.ToString('o'))"
        "Revision de codigo: $revision"
        "SDK .NET: $sdk"
        "Sistema: $([Environment]::OSVersion.VersionString)"
        ''
    ) | Set-Content -LiteralPath $logPath -Encoding utf8

    function Invoke-DotNet {
        param([string[]]$Arguments)
        "`n> dotnet $($Arguments -join ' ')" | Tee-Object -FilePath $logPath -Append
        & dotnet @Arguments 2>&1 | Tee-Object -FilePath $logPath -Append
        if ($LASTEXITCODE -ne 0) {
            throw "dotnet termino con codigo $LASTEXITCODE. Consultar $logPath"
        }
    }

    Invoke-DotNet -Arguments @('restore', 'DemoTesting.slnx', '--verbosity', 'minimal')
    Invoke-DotNet -Arguments @('build', 'DemoTesting.slnx', '--configuration', 'Release', '--no-restore', '--warnaserror')
    Invoke-DotNet -Arguments @(
        'test', 'DemoTesting.slnx', '--configuration', 'Release', '--no-build', '--no-restore',
        '--logger', 'console;verbosity=normal', '--logger', 'trx;LogFileName=resultados.trx',
        '--results-directory', $resultsPath, '--collect', 'XPlat Code Coverage'
    )

    [xml]$trx = Get-Content -LiteralPath (Join-Path $resultsPath 'resultados.trx') -Raw
    $ns = [Xml.XmlNamespaceManager]::new($trx.NameTable)
    $ns.AddNamespace('t', 'http://microsoft.com/schemas/VisualStudio/TeamTest/2010')
    $counters = $trx.SelectSingleNode('//t:ResultSummary/t:Counters', $ns)
    $tests = @($trx.SelectNodes('//t:Results/t:UnitTestResult', $ns) | Sort-Object testName)
    $summary = [ordered]@{
        inicio = $started.ToString('o')
        fin = [DateTimeOffset]::Now.ToString('o')
        revisionCodigo = $revision
        sdk = $sdk
        total = [int]$counters.total
        correctas = [int]$counters.passed
        fallidas = [int]$counters.failed
        omitidas = [int]$counters.notExecuted
        unitarias = @($tests | Where-Object testName -like '*.Unitarias.*').Count
        integracion = @($tests | Where-Object testName -like '*.Integracion.*').Count
        api = @($tests | Where-Object testName -like '*.Api.*').Count
    }
    $summary | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $evidencePath 'resumen.json') -Encoding utf8

    function ConvertTo-HtmlText([string]$Value) { [Net.WebUtility]::HtmlEncode($Value) }
    $rows = foreach ($test in $tests) {
        $name = $test.testName -replace '^ClienteApp.Tests\.', ''
        $class = if ($name -like '*ObtenerPorId*') { ' class="nuevo"' } else { '' }
        '<tr{0}><td>{1}</td><td>{2}</td><td>{3}</td></tr>' -f $class,
            (ConvertTo-HtmlText $name), (ConvertTo-HtmlText $test.outcome),
            (ConvertTo-HtmlText $test.duration)
    }
    $rawLog = ConvertTo-HtmlText (Get-Content -LiteralPath $logPath -Raw)
    $date = ConvertTo-HtmlText $started.ToString('yyyy-MM-dd HH:mm:ss zzz')
    $html = @"
<!doctype html>
<html lang="es"><head><meta charset="utf-8"><title>Evidencias - ExamenFinalAnalisis2</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#edf2f7;color:#172539;font:16px 'Segoe UI',sans-serif}
main{max-width:1480px;margin:26px auto;padding:30px;background:white;border:1px solid #d3dce8;border-radius:14px}
h1{margin:0 0 8px;font-size:30px}h2{font-size:23px;margin:26px 0 12px}.muted{color:#52647b}
.stats{display:flex;gap:14px;margin:22px 0}.stat{flex:1;padding:16px;background:#edf8f3;border:1px solid #a9d4bd;border-radius:8px}
.stat strong{font-size:32px;display:block;color:#12673d}.command{background:#172539;color:white;padding:14px;border-radius:8px;font:14px Consolas,monospace}
table{width:100%;border-collapse:collapse;font-size:14px}th,td{text-align:left;padding:10px;border-bottom:1px solid #e0e6ed}
th{background:#eff3f8}td:nth-child(2){color:#12673d;font-weight:600}.nuevo{background:#edf8f3}
pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#101b2c;color:#e1ecf5;padding:22px;border-radius:9px;font:13px/1.5 Consolas,monospace}
a{color:#1558b0}.meta{font:13px Consolas,monospace;overflow-wrap:anywhere}
</style></head><body><main>
<h1>Examen final · Pruebas de software</h1>
<p class="muted">FredyCardona/ExamenFinalAnalisis2 · Ejecución real: $date</p>
<p class="meta">Código probado: $revision · SDK .NET $sdk · Release</p>
<div class="stats"><div class="stat"><strong>$($summary.total)</strong>Pruebas ejecutadas</div><div class="stat"><strong>$($summary.correctas)</strong>Correctas</div><div class="stat"><strong>$($summary.fallidas)</strong>Fallidas</div><div class="stat"><strong>$($summary.omitidas)</strong>Omitidas</div></div>
<div class="command">dotnet test DemoTesting.slnx --configuration Release --no-build --no-restore --logger "console;verbosity=normal" --logger "trx;LogFileName=resultados.trx" --results-directory evidencias/resultados --collect "XPlat Code Coverage"</div>
<h2>Resultados de toda la suite</h2>
<p class="muted">$($summary.unitarias) unitarias · $($summary.integracion) de integración con SQLite · $($summary.api) de API con HttpClient y WebApplicationFactory.<br>Las cuatro filas verdes corresponden a los casos nuevos del examen. Datos extraídos directamente del archivo TRX.</p>
<table><thead><tr><th>Prueba</th><th>Resultado TRX</th><th>Duración</th></tr></thead><tbody>$($rows -join "`n")</tbody></table>
<p><a href="resultados/resultados.trx">Resultado TRX original</a> · <a href="ejecucion.txt">Registro completo</a> · <a href="resumen.json">Resumen JSON</a></p>
<h2 id="ejecucion">Salida real de restauración, compilación y pruebas</h2>
<pre>$rawLog</pre>
</main></body></html>
"@
    $html | Set-Content -LiteralPath (Join-Path $evidencePath 'reporte.html') -Encoding utf8
    if ($summary.total -eq 0 -or $summary.correctas -ne $summary.total) {
        throw 'Hay pruebas fallidas u omitidas. Revisar el TRX.'
    }
    Write-Host "Evidencias guardadas: $evidencePath"
}
finally {
    Pop-Location
}
