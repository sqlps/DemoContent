using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Mvc;
using ElusionX.Web.DataModel;
using System.IO;
using System.Threading;
using ElusionX.Web.Providers;

namespace ElusionX.Web.Controllers
{
    public class AppConfigController : Controller
    {
        private ElusionX_ProdDBEntities db = new ElusionX_ProdDBEntities();

        public ActionResult Settings()
        {
            ApplicationConfiguration applicationConfiguration = db.ApplicationConfiguration.FirstOrDefault();
            if (applicationConfiguration == null)
            {
                var appConfiguration = new ApplicationConfiguration()
                {
                    Name = "Northwind Traders",
                    MaxCommandTimeOut = 60,
                    MinCommandTimeOut = 15,
                    NumberOfOrders = 100,
                    NumberOfUsers = 100
                };
                db.ApplicationConfiguration.Add(appConfiguration);
                db.SaveChanges();
                applicationConfiguration = db.ApplicationConfiguration.First();
            }
            ViewBag.Name = applicationConfiguration.Name;
            return View("Edit", applicationConfiguration);
        }

        // POST: AppConfig/Edit/5
        // To protect from overposting attacks, please enable the specific properties you want to bind to, for 
        // more details see http://go.microsoft.com/fwlink/?LinkId=317598.
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Settings([Bind(Include =
            "ApplicationConfigurationID,Name,MinCommandTimeOut,MaxCommandTimeOut,NumberOfOrders,NumberOfUsers")]
        ApplicationConfiguration applicationConfiguration, HttpPostedFileBase file)
        {
            try
            {
                if (file != null && file.ContentLength > 0)
                {
                    var fileName = Path.GetFileName(file.FileName);
                    var path = Path.Combine(Server.MapPath("~/Images/"), "logo.png");
                    file.SaveAs(path);
                }
                if (ModelState.IsValid)
                {
                    db.Entry(applicationConfiguration).State = EntityState.Modified;
                    db.SaveChanges();
                    return RedirectToAction("Settings", "AppConfig");
                }
                return View(applicationConfiguration);
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db.Dispose();
            }
            base.Dispose(disposing);
        }

        [ActionName("getrtoasettings")]
        public JsonResult GetRTOASettings()
        {
            var rtoaSettings = db.ApplicationConfiguration.FirstOrDefault(a => a.Name == "RTOASettings");
            if (rtoaSettings == null)
            {
                db.ApplicationConfiguration.Add(new ApplicationConfiguration()
                {
                    Name = "RTOASettings",
                    Iterations = 50,
                    NumberOfOrders = 200,
                    NumberOfUsers = 200,
                    MinCommandTimeOut = 4
                });
                db.SaveChanges();
                rtoaSettings = db.ApplicationConfiguration.FirstOrDefault(a => a.Name == "RTOASettings");
            }
            return new JsonResult{ Data = new { data = rtoaSettings } , JsonRequestBehavior = JsonRequestBehavior.AllowGet };
        }

        [ActionName("savertoasettings")]
        public JsonResult saveRTOASettings(int numberOfUsers, int iterations, int ordersperuser, int yoyiterations)
        {
            var rtoaSettings = db.ApplicationConfiguration.FirstOrDefault(a => a.Name == "RTOASettings");
            if (rtoaSettings == null)
            {
                db.ApplicationConfiguration.Add(new ApplicationConfiguration()
                {
                    Name = "RTOASettings",
                    Iterations = 50,
                    NumberOfOrders = 200,
                    NumberOfUsers = 200,
                    MinCommandTimeOut = 4
                });
                db.SaveChanges();
                rtoaSettings = db.ApplicationConfiguration.FirstOrDefault(a => a.Name == "RTOASettings");
            }
            rtoaSettings.NumberOfOrders = ordersperuser;
            rtoaSettings.NumberOfUsers = numberOfUsers;
            rtoaSettings.Iterations = iterations;
            rtoaSettings.MinCommandTimeOut = yoyiterations;
            Thread.Sleep(2000);
            db.SaveChanges();
            return new JsonResult { Data = new { data = rtoaSettings }, JsonRequestBehavior = JsonRequestBehavior.AllowGet };
        }

        [ActionName("dropcleanbuffers")]
        public JsonResult DropCleanBuffers()
        {
            SQLProvider provider = new SQLProvider();
            provider.RunSQLConsoleCommand("DBCC DROPCLEANBUFFERS");
            Thread.Sleep(2000);
            return new JsonResult { Data = new { data = true }, JsonRequestBehavior = JsonRequestBehavior.AllowGet };
        }


        [ActionName("freeproccache")]
        public JsonResult FreeProcCache()
        {
            SQLProvider provider = new SQLProvider();
            provider.RunSQLConsoleCommand("DBCC FREEPROCCACHE");
            Thread.Sleep(2000);
            return new JsonResult { Data = new { data = true }, JsonRequestBehavior = JsonRequestBehavior.AllowGet };
        }
    }
}
