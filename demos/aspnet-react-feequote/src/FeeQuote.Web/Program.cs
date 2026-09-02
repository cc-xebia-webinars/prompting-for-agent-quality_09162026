using FeeQuote.Web.Domain.Clients;
using FeeQuote.Web.Domain.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllersWithViews();
builder.Services.AddProblemDetails();
builder.Services.AddSingleton<IPaymentClient, PaymentClient>();
builder.Services.AddSingleton<TransferService>();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler();
}

// The React build lands in wwwroot/app, so /app/ resolves to its index.html.
app.UseDefaultFiles();
app.UseStaticFiles();
app.UseRouting();

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));
app.MapControllers();
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();

// Exposes the implicit Program type to WebApplicationFactory in the test project.
public partial class Program
{
}
