using System.Diagnostics;
using System.Text;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.FileProviders;

var startInfo = new ProcessStartInfo("python3", new[] { "-m", "luoxu" })
{
    // WorkingDirectory = "/app",
    UseShellExecute = false,
    RedirectStandardOutput = true,
    RedirectStandardInput = true,
    StandardInputEncoding = Encoding.UTF8
};
var luoxuProcess = Process.Start(startInfo);
if (luoxuProcess is null)
{
    throw new Exception("Failed to start luoxu");
}

var builder = WebApplication.CreateSlimBuilder(args);

builder.WebHost.ConfigureKestrel(opt => { opt.ListenAnyIP(5000); });

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.TypeInfoResolverChain.Insert(0, AppJsonSerializerContext.Default);
});

var app = builder.Build();

var fileProvider = new PhysicalFileProvider(Environment.GetEnvironmentVariable("LUOXU_WEB_DIR") ?? "/wwwroot");
app.UseDefaultFiles(new DefaultFilesOptions { FileProvider = fileProvider });
app.UseStaticFiles(new StaticFileOptions { FileProvider = fileProvider });

var enableStdInApi =
    (Environment.GetEnvironmentVariable("ENABLE_STDIN_API") ?? "false").Equals("true",
        StringComparison.CurrentCultureIgnoreCase);
if (enableStdInApi)
{
    var stdinApi = app.MapGroup("/stdin");
    stdinApi.MapPost("/", ([FromBody] string input) =>
    {
        // write request body to stdin of luoxu
        var stdin = luoxuProcess.StandardInput;
        stdin.WriteLine(input);
        return Results.Ok();
    });
}

app.Run();

luoxuProcess.StandardOutput.BaseStream.CopyToAsync(Console.OpenStandardOutput(), app.Lifetime.ApplicationStopping);
app.Lifetime.ApplicationStopped.Register(() => { luoxuProcess.Kill(); });

[JsonSerializable(typeof(string))]
internal partial class AppJsonSerializerContext : JsonSerializerContext;