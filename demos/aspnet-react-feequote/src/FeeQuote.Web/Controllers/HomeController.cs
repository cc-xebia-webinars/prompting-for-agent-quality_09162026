using FeeQuote.Web.Domain.Config;
using Microsoft.AspNetCore.Mvc;

namespace FeeQuote.Web.Controllers;

/// <summary>Landing page. The interactive quote form lives in the React app under /app/.</summary>
public sealed class HomeController : Controller
{
    public IActionResult Index()
    {
        ViewData["Currencies"] = string.Join(", ", Settings.Currencies);
        ViewData["Countries"] = string.Join(", ", Settings.Countries);
        return View();
    }
}
