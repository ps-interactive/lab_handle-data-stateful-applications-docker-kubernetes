using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using WiredBrain.Web.Models;
using WiredBrain.Web.Services;

namespace WiredBrain.Web.Controllers
{
    public class HomeController : Controller
    {
        private readonly IConfiguration _config;
        private readonly ILogger<HomeController> _logger;
        private readonly ProductService _productsService;
        private readonly StockService _stockService;

        public HomeController(ProductService productsService, StockService stockService, IConfiguration config, ILogger<HomeController> logger)
        {
            _productsService = productsService;
            _stockService = stockService;
            _config = config;
            _logger = logger;
        }

        public async Task<IActionResult> Index()
        {
            var stopwatch = Stopwatch.StartNew();
            _logger.LogDebug($"Loading products & stock");
            
            var model = new ProductViewModel();
            model.Products = await _productsService.GetProducts();
            foreach (var product in model.Products)
            {
                var productStock = await _stockService.GetStock(product.Id);
                product.Stock = productStock.Stock;
            }

            _logger.LogDebug($"Products & stock load took: {stopwatch.Elapsed.TotalMilliseconds}ms");

            if (_config.GetValue<bool>("Debug:ShowHost"))
            {
                ViewData["Environment"] = $"{_config["Environment"]} @ {Dns.GetHostName()}";
            }
            else
            {
                ViewData["Environment"] = $"{_config["Environment"]}";
            }

            return View(model);
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
