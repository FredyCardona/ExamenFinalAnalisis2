# Examen final: pruebas unitarias, de integración y de API

Entrega de **Fredy Cardona**. Proyecto DemoTesting basado en [eruanoc5/PruebasSoftware](https://github.com/eruanoc5/PruebasSoftware), con el historial original conservado y las cuatro pruebas solicitadas implementadas. Copia independiente en [FredyCardona/ExamenFinalAnalisis2](https://github.com/FredyCardona/ExamenFinalAnalisis2).

## Requisitos del examen implementados

| Requisito | Prueba nueva | Comprobación |
| --- | --- | --- |
| Unitaria con Moq | `ObtenerPorId_ClienteExistente_DebeRetornarClienteYConsultarUnaVez` | `Assert.Same` comprueba el cliente esperado; `Verify(..., Times.Once)` verifica una consulta con el ID correcto; `VerifyNoOtherCalls` descarta llamadas adicionales. |
| Integración con SQLite real | `ObtenerPorId_ClienteInexistente_DebeRetornarNullDesdeSQLite` | Registra un cliente real, comprueba que puede recuperarlo y consulta otro ID a través de `ClienteService` y `ClienteRepository`: `Assert.Null`. |
| API: cliente existente | `ObtenerPorId_ClienteExistente_DebeRetornar200YClienteEsperado` | Registra un cliente por HTTP, hace GET al ID devuelto y comprueba `200 OK` y los datos del cliente. |
| API: cliente inexistente | `ObtenerPorId_ClienteInexistente_DebeRetornar404` | Consulta un ID no registrado y comprueba `404 Not Found` y el mensaje del controlador. |

Se conservaron las pruebas originales de validación, registro y persistencia. **Resultado local: 18 correctas, 0 fallidas y 0 omitidas**: 11 unitarias, 3 de integración y 4 de API.

## Evidencias de ejecución

Las capturas, el registro de consola, el TRX y la cobertura están en [evidencias](evidencias/README.md). Las capturas muestran la ejecución automática en GitHub Actions y la salida real de `dotnet test` publicada en este repositorio.

![Ejecución automática en GitHub Actions](evidencias/01-resultados.png)

![Salida de compilación y ejecución](evidencias/02-ejecucion.png)

## Ejecutar el proyecto

Requisito: **SDK .NET 10**. Las dependencias se obtienen de NuGet. No se requiere instalar un servidor de bases de datos: se utiliza SQLite.

```bash
git clone https://github.com/FredyCardona/ExamenFinalAnalisis2.git
cd ExamenFinalAnalisis2
dotnet restore DemoTesting.slnx
dotnet build DemoTesting.slnx --configuration Release --no-restore --warnaserror
dotnet test DemoTesting.slnx --configuration Release --no-build --no-restore --logger "console;verbosity=normal"
```

Para ejecutar por categoría:

```bash
dotnet test DemoTesting.slnx --filter "Categoria=Unitaria"
dotnet test DemoTesting.slnx --filter "Categoria=Integracion"
dotnet test DemoTesting.slnx --filter "Categoria=Api"
```

Para regenerar las evidencias de resultados en Windows con PowerShell 7:

```powershell
pwsh -NoProfile -File ./scripts/Verificar-Pruebas.ps1
```

El script restaura, compila tratando las advertencias como errores, ejecuta toda la suite con cobertura y genera `evidencias/reporte.html`, `ejecucion.txt`, `resumen.json` y `resultados/`. Devuelve un error si falla un comando o quedan pruebas fallidas u omitidas. Las capturas PNG corresponden a la ejecución entregada; después de regenerar los resultados, abrir el HTML y tomar nuevas capturas.

Para iniciar la API y abrir Swagger en `http://localhost:5097/swagger`:

```bash
dotnet run --project ClienteApp.Api --launch-profile http
```

La API dispone de `POST /api/Clientes` y `GET /api/Clientes/{id}`. En ejecución normal crea `clientes.db`. Cada prueba de integración y cada instancia de `ClienteApiFactory` crea su propio archivo SQLite temporal con nombre único y `Pooling=False`, y lo elimina al finalizar. Los clientes HTTP de prueba utilizan HTTPS y tienen las redirecciones automáticas desactivadas.

## Organización y corrección del proyecto base

- `ClienteApp/`: modelos, servicio, repositorio y acceso a SQLite.
- `ClienteApp.Api/`: API ASP.NET Core y Swagger.
- `ClienteApp.Tests/Unitarias/`: pruebas de servicio con Moq.
- `ClienteApp.Tests/Integracion/`: servicio y repositorio reales con SQLite.
- `ClienteApp.Tests/Api/`: pruebas HTTP con `WebApplicationFactory<Program>`.
- `scripts/Verificar-Pruebas.ps1`: generación reproducible de evidencias.
- `.github/workflows/pruebas.yml`: restauración, compilación y pruebas automáticas; publica TRX y cobertura como artefactos.

Se corrigió la lectura anticipada de la conexión en `Program.cs`: ahora la inicialización usa la configuración final después de `Build`, y el repositorio resuelve la configuración mediante inyección de dependencias. Esto permite que `ConfigureAppConfiguration` de la fábrica sustituya la conexión y evita que las pruebas usen la base predeterminada. La disponibilidad de esa configuración después de construir la aplicación está documentada en [Microsoft Learn: pruebas de integración](https://learn.microsoft.com/aspnet/core/test/integration-tests?view=aspnetcore-10.0).

Moq se referencia desde el proyecto de pruebas y Swagger desde la API. El repositorio excluye archivos de usuario, bases locales y salidas de compilación. Los commits originales `99fe72c` y `9ec6217` permanecen en el historial; los nuevos cambios se separan por preparación, prueba unitaria, integración, corrección de configuración, pruebas de API y documentación/evidencias.

## Entrega

Enlace del repositorio: **https://github.com/FredyCardona/ExamenFinalAnalisis2**. Adjuntar también las capturas [01-resultados.png](evidencias/01-resultados.png) y [02-ejecucion.png](evidencias/02-ejecucion.png), incluidas en el propio repositorio.
