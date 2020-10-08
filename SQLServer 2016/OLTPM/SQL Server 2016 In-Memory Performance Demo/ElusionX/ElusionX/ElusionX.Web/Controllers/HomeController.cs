using ElusionX.Web.DataModel;
using ElusionX.Web.Models;
using ElusionX.Web.Providers;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Mvc;

namespace ElusionX.Web.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            ApplicationConfiguration appConfig = null;
            using (var appConfigContext = new ElusionX_ProdDBEntities())
            {
                AppConfigController controller = new AppConfigController();
                controller.Settings();
                appConfig = appConfigContext.ApplicationConfiguration.FirstOrDefault();
                ViewBag.Name = appConfig.Name;
            }
            return View();
        }

        public ActionResult RealTimeAnalytics(int id)
        {
            ApplicationConfiguration appConfig = null;
            using (var appConfigContext = new ElusionX_ProdDBEntities())
            {
                AppConfigController controller = new AppConfigController();
                appConfig = appConfigContext.ApplicationConfiguration.FirstOrDefault();
                ViewBag.Name = appConfig.Name;
            }
            RTOALoadEngine.queryOutQueue.Clear();
            return id == 0 ? View("realtimeanalytics") : View("realtimeanalyticsv1");
        }

        [ActionName("getoperationalanalytics")]
        public JsonResult GetOperationalAnalytics(int flag)
        {
            SQLProvider sqlProvider = new SQLProvider();
            var oaModels = sqlProvider.GetOrderRevenue(flag);
            var trdayProfit = sqlProvider.GetDayProfit(0);
            var rtdayProfit = sqlProvider.GetDayProfit(1);
            var oaModelsMin = sqlProvider.GetOrderRevenuePerMinute();
            var orderCount = sqlProvider.GetOrderCount(flag == 0 ? "TRADITIONAL" : "REALTIME");
            return new JsonResult
            {
                Data = new { oaModel = oaModels, trdayProfit = trdayProfit, rtdayProfit = rtdayProfit, orderCount = orderCount, ordersrevenuepermin = oaModelsMin },
                JsonRequestBehavior = JsonRequestBehavior.AllowGet
            };
        }

        public ActionResult About()
        {
            ApplicationConfiguration appConfig = null;
            using (var appConfigContext = new ElusionX_ProdDBEntities())
            {
                AppConfigController controller = new AppConfigController();
                controller.Settings();
                appConfig = appConfigContext.ApplicationConfiguration.FirstOrDefault();
                ViewBag.Name = appConfig.Name;
            }
            return View("home");
        }

        public ActionResult ColumnStore()
        {
            ApplicationConfiguration appConfig = null;
            using (var appConfigContext = new ElusionX_ProdDBEntities())
            {
                AppConfigController controller = new AppConfigController();
                controller.Settings();
                appConfig = appConfigContext.ApplicationConfiguration.FirstOrDefault();
                ViewBag.Name = appConfig.Name;
            }
            return View("columnstore");
        }

        [ActionName("executeoa")]
        public void ExecuteOASetup()
        {
            SQLProvider sqlProvider = new SQLProvider();
            sqlProvider.ExecuteOA();
        }

        [ActionName("executeetl")]
        public void ExecuteETL()
        {
            SQLProvider sqlProvider = new SQLProvider();
            sqlProvider.ExecuteETL();
        }

        [ActionName("getmetricswithoutcolumnstore")]
        public JsonResult GetMetricsWithoutColumnStore(string year = "")
        {
            SQLProvider sqlProvider = new SQLProvider();
            List<ColumnStoreDataModel> data = sqlProvider.GetMetricsWithoutColumnStore(year);
            return GetColumnStoreData(year, data);
        }

        [ActionName("getmetricswithcolumnstore")]
        public JsonResult GetMetricsWithColumnStore(string year = "")
        {
            SQLProvider sqlProvider = new SQLProvider();
            List<ColumnStoreDataModel> data = sqlProvider.GetMetricsWithColumnStore(year);
            return GetColumnStoreData(year, data);
        }

        [ActionName("getrowcounts")]
        public JsonResult GetRowCounts()
        {
            SQLProvider sqlProvider = new SQLProvider();
            int ciRowCount = sqlProvider.GetRowCounts(0);
            int csRowCount = sqlProvider.GetRowCounts(1);
            return new JsonResult
            {
                Data = new { cirowcount = ciRowCount, csrowcount = csRowCount },
                JsonRequestBehavior = JsonRequestBehavior.AllowGet
            };
        }

        private static JsonResult GetColumnStoreData(string year, List<ColumnStoreDataModel> data)
        {
            if (!string.IsNullOrEmpty(year))
            {
                var productGroups = from d in data
                                    select new { year = d.Name, values = d.Price };
                return new JsonResult { Data = new { result = productGroups }, JsonRequestBehavior = JsonRequestBehavior.AllowGet };
            }
            var grps = from d in data
                       group d by d.Year into yeargroups
                       orderby yeargroups.Key descending
                       select new { year = yeargroups.Key, values = yeargroups.Sum(g => g.Price) };
            return new JsonResult { Data = new { result = grps }, JsonRequestBehavior = JsonRequestBehavior.AllowGet };
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [ActionName("executequery")]
        public JsonResult ExecuteQuery(int queryFlag)
        {
            try
            {
                SQLProvider sqlQueryProvider = new SQLProvider();
                var query = sqlQueryProvider.GetQuery(queryFlag);
                ApplicationConfiguration appConfig = null;
                using (var appConfigContext = new ElusionX_ProdDBEntities())
                {
                    appConfig = appConfigContext.ApplicationConfiguration.FirstOrDefault();
                }
                LoadEngine engine = new LoadEngine(appConfig.NumberOfUsers, appConfig.NumberOfOrders,
                    queryFlag, appConfig.MinCommandTimeOut, query, true, true, true);
                Task.Factory.StartNew(engine.StartLoad);
                return new JsonResult { Data = new { result = true }, JsonRequestBehavior = JsonRequestBehavior.AllowGet };
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        [ActionName("executertoa")]
        public JsonResult ExecuteRTOA(string queryType)
        {
            try
            {
                ApplicationConfiguration appConfig = null;
                using (var appConfigContext = new ElusionX_ProdDBEntities())
                {
                    AppConfigController controller = new AppConfigController();
                    appConfig = appConfigContext.ApplicationConfiguration.FirstOrDefault(a=>a.Name == "RTOASettings");
                }
                RTOALoadEngine engine = new RTOALoadEngine(appConfig.NumberOfUsers, appConfig.Iterations.Value, appConfig.NumberOfOrders,
                    queryType);
                engine.StartLoad();
                return new JsonResult { Data = new { result = true }, JsonRequestBehavior = JsonRequestBehavior.AllowGet };
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        [ActionName("executeyoysales")]
        public JsonResult ExecuteYOYSales(int queryType)
        {
            try
            {
                ApplicationConfiguration appConfig = null;
                SQLProvider provider = new SQLProvider();
                using (var appConfigContext = new ElusionX_ProdDBEntities())
                {
                    AppConfigController controller = new AppConfigController();
                    appConfig = appConfigContext.ApplicationConfiguration.FirstOrDefault(a => a.Name == "RTOASettings");
                }
                var yoysales = provider.GetYoYSales(queryType);
                Thread.Sleep(1000);
                return new JsonResult { Data = new { result = true, data = yoysales, iterations = appConfig.MinCommandTimeOut }, JsonRequestBehavior = JsonRequestBehavior.AllowGet };
            }
            catch (Exception)
            {
                throw;
            }
        }
    }
}
