# Evidencias de ejecución

Resultados reales de la suite completa del proyecto, ejecutada en configuración Release.

La ejecución remota del flujo actualizado terminó correctamente: [GitHub Actions, ejecución #3](https://github.com/FredyCardona/ExamenFinalAnalisis2/actions/runs/43151740726). La primera captura corresponde a esta ejecución; la segunda muestra el registro local completo publicado en el repositorio.

| Archivo | Contenido |
| --- | --- |
| [01-resultados.jpg](01-resultados.jpg) | Captura de la ejecución automática satisfactoria en GitHub Actions. |
| [02-ejecucion.jpg](02-ejecucion.jpg) | Captura del registro real de pruebas publicado en GitHub, con el resumen de 18 pruebas correctas. |
| [ejecucion.txt](ejecucion.txt) | Salida original de los comandos, SDK y revisión del código probado. |
| [resultados/resultados.trx](resultados/resultados.trx) | Reporte original emitido por VSTest, que puede abrirse en Visual Studio. |
| [resumen.json](resumen.json) | Conteos y metadatos extraídos del TRX. |
| [reporte.html](reporte.html) | Reporte para abrir localmente en un navegador. |
| `resultados/*/coverage.cobertura.xml` | Cobertura emitida por Coverlet durante la misma ejecución. |

Las capturas se tomaron en un navegador mostrando GitHub Actions y el archivo de salida real de consola publicado en el repositorio. La revisión indicada en los reportes corresponde al código y al flujo probado; los commits posteriores agregan documentación y evidencias.

Regenerar desde la raíz del repositorio con PowerShell 7 y SDK .NET 10:

```powershell
pwsh -NoProfile -File ./scripts/Verificar-Pruebas.ps1
```

El script reemplaza los reportes de resultados. El archivo `reporte.html` permite revisar localmente las 18 pruebas y los cuatro casos nuevos resaltados. Para actualizar las capturas de la entrega, subir los resultados actualizados y capturar la ejecución de GitHub Actions y el registro de pruebas.
