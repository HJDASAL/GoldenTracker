using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using GoldenTracker.Models;

using Microsoft.Extensions.FileProviders;
using System.IO;

namespace GoldenTracker.Controllers
{
    public class HomeController(IFileProvider fileProvider) : Controller
    {
        private readonly IFileProvider _fileProvider = fileProvider;

        [HttpGet("{*url}")]
        public IActionResult CatchAll(string url)
        {
            var indexPath = Path.Combine(Directory.GetCurrentDirectory(), "..", "golden_tracker_enterprise", "build", "web", "index.html");
            return PhysicalFile(indexPath, "text/html");
        }

        [HttpGet("/flutter/{**path}")]
        public IActionResult FlutterAssets(string path)
        {
            var filePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot/flutter", path ?? string.Empty);
            if (!System.IO.File.Exists(filePath))
            {
                return NotFound();
            }

            // Determine MIME type (optional)
            var mimeType = "application/octet-stream";
            if (Path.GetExtension(filePath) == ".html") mimeType = "text/html";
            else if (Path.GetExtension(filePath) == ".js") mimeType = "application/javascript";
            else if (Path.GetExtension(filePath) == ".css") mimeType = "text/css";

            return PhysicalFile(filePath, mimeType);
        }
    }
}
