using Microsoft.Extensions.FileProviders;
var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();
builder.Services.AddRazorPages();   // optional

builder.Services.AddSingleton<IFileProvider>(
    new PhysicalFileProvider(Path.Combine(Directory.GetCurrentDirectory(), "..", "golden_tracker_enterprise", "build"))
);

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
// Serve Flutter web build files from build\web folder
var flutterBuildPath = Path.Combine(Directory.GetCurrentDirectory(), "..", "golden_tracker_enterprise", "build", "web");
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(flutterBuildPath),
    RequestPath = string.Empty,
    ServeUnknownFileTypes = true
});


app.UseRouting();

// Map API controllers
app.MapControllers(); // For API routes

// Fallback to Flutter web app
app.MapFallbackToFile("web/index.html");

// app.UseAuthorization();

// app.MapControllerRoute(
//     name: "default",
//     pattern: "{controller=Home}/{action=Index}/{id?}"
// );

app.Run();
