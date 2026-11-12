
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;

namespace ClienteApp.Tests.Api;

[Trait("Categoria", "Api")]
public class ClientesApiTests
{
    [Fact]
    public async Task ObtenerPorId_ClienteExistente_DebeRetornar200YClienteEsperado()
    {
        // Arrange: registrar mediante HTTP en la API con SQLite de prueba.
        using var factory = new ClienteApiFactory();
        using var client = factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            BaseAddress = new Uri("https://localhost"),
            AllowAutoRedirect = false
        });
        var esperado = await RegistrarClienteAsync(client);

        // Act: consultar el identificador devuelto por la API, sin asumir su valor.
        using var response = await client.GetAsync($"/api/Clientes/{esperado.Id}");

        // Assert: verificar tanto el código HTTP como el contenido del cliente.
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var resultado = await response.Content.ReadFromJsonAsync<ClienteRespuesta>();
        Assert.NotNull(resultado);
        Assert.Equal(esperado, resultado);
    }

    [Fact]
    public async Task ObtenerPorId_ClienteInexistente_DebeRetornar404()
    {
        // Arrange: la base contiene otro cliente para evitar un caso trivial vacío.
        using var factory = new ClienteApiFactory();
        using var client = factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            BaseAddress = new Uri("https://localhost"),
            AllowAutoRedirect = false
        });
        var existente = await RegistrarClienteAsync(client);
        var idInexistente = existente.Id + 1;

        // Act: consultar un identificador que no se ha registrado.
        using var response = await client.GetAsync($"/api/Clientes/{idInexistente}");

        // Assert: debe ser el 404 del controlador de clientes.
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        var error = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Cliente no encontrado.", error.GetProperty("mensaje").GetString());
    }

    [Fact]
    public async Task Registrar_ClienteValido_DebeRetornar201()
    {
        // Arrange
        using var factory = new ClienteApiFactory();
        using var client = factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            BaseAddress = new Uri("https://localhost"),
            AllowAutoRedirect = false
        });

        var solicitud = new
        {
            Nombre = "Ana López",
            Correo = $"ana_{Guid.NewGuid():N}@example.com"
        };

        // Act
        using var response = await client.PostAsJsonAsync(
            "/api/Clientes",
            solicitud);

        // Assert
        Assert.Equal(
            HttpStatusCode.Created,
            response.StatusCode);

        var cliente = await response.Content
            .ReadFromJsonAsync<ClienteRespuesta>();

        Assert.NotNull(cliente);
        Assert.Equal(solicitud.Nombre, cliente.Nombre);
        Assert.Equal(solicitud.Correo, cliente.Correo);
    }

    [Fact]
    public async Task Registrar_NombreVacio_DebeRetornar400()
    {
        // Arrange
        using var factory = new ClienteApiFactory();
        using var client = factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            BaseAddress = new Uri("https://localhost"),
            AllowAutoRedirect = false
        });

        var solicitud = new
        {
            Nombre = "",
            Correo = $"correo_{Guid.NewGuid():N}@example.com"
        };

        // Act
        using var response = await client.PostAsJsonAsync(
            "/api/Clientes",
            solicitud);

        // Assert
        Assert.Equal(
            HttpStatusCode.BadRequest,
            response.StatusCode);
    }

    private static async Task<ClienteRespuesta> RegistrarClienteAsync(HttpClient client)
    {
        var solicitud = new
        {
            Nombre = "Ana López",
            Correo = "ana@example.com"
        };
        using var response = await client.PostAsJsonAsync("/api/Clientes", solicitud);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var cliente = await response.Content.ReadFromJsonAsync<ClienteRespuesta>();
        Assert.NotNull(cliente);
        Assert.True(cliente.Id > 0);
        Assert.Equal(solicitud.Nombre, cliente.Nombre);
        Assert.Equal(solicitud.Correo, cliente.Correo);
        return cliente;
    }

    private sealed record ClienteRespuesta(
        int Id,
        string Nombre,
        string Correo);
}

public sealed class ClienteApiFactory : WebApplicationFactory<Program>
{
    private readonly string _dbPath = Path.Combine(
        Path.GetTempPath(),
        $"clientes_api_test_{Guid.NewGuid():N}.db");

    protected override void ConfigureWebHost(
        IWebHostBuilder builder)
    {
        builder.ConfigureAppConfiguration((context, configuration) =>
        {
            configuration.AddInMemoryCollection(
                new Dictionary<string, string?>
                {
                    ["ConnectionStrings:ClientesDb"] =
                        $"Data Source={_dbPath};Pooling=False"
                });
        });
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);

        if (disposing && File.Exists(_dbPath))
        {
            File.Delete(_dbPath);
        }
    }
}
