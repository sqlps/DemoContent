using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Optimization;

namespace ElusionX.Web
{
    public class BundleConfig
    {
        // For more information on bundling, visit http://go.microsoft.com/fwlink/?LinkId=301862
        public static void RegisterBundles(BundleCollection bundles)
        {
            bundles.Add(new ScriptBundle("~/bundles/jquery").Include(
                "~/Scripts/jquery-{version}.js",
                "~/Scripts/jquery.signalR-2.2.0.min.js",
                "~/Scripts/jquery.blockUI.js",
                "~/Scripts/jquery.flexslider.js"));

            bundles.Add(new ScriptBundle("~/bundles/jqueryval").Include(
                "~/Scripts/jquery.unobtrusive*",
                "~/Scripts/jquery.validate*"));

            bundles.Add(new ScriptBundle("~/bundles/knockout").Include(
                "~/Scripts/knockout-{version}.js",
                "~/Scripts/knockout.validation.js"));

            bundles.Add(new ScriptBundle("~/bundles/app").Include(
                "~/Scripts/sammy-{version}.js",
                "~/Scripts/app/common.js",
                "~/Scripts/app/app.datamodel.js",
                "~/Scripts/app/app.viewmodel.js",
                "~/Scripts/app/home.viewmodel.js",
                "~/Scripts/app/_run.js"));

            // Use the development version of Modernizr to develop with and learn from. Then, when you're
            // ready for production, use the build tool at http://modernizr.com to pick only the tests you need.
            bundles.Add(new ScriptBundle("~/bundles/modernizr").Include(
                "~/Scripts/modernizr-*"));

            bundles.Add(new ScriptBundle("~/bundles/bootstrap").Include(
                "~/Scripts/bootstrap.js",
                "~/Scripts/bootstrap-switch.js",
                "~/Scripts/respond.js"));

            bundles.Add(new StyleBundle("~/Content/css").Include(
                 "~/Content/bootstrap.min.css",
                 //"~/Content/bootstrap-switch.css",
                 "~/Content/flexslider.css",
                 "~/Content/font-style.css",
                 "~/Content/fullcalendar.css",
                 "~/Content/fullcalendar.print.css",
                 "~/Content/login.css",
                 "~/Content/main.css",
                 "~/Content/register.css",
                 "~/Content/table.css",
                 "~/Content/Site.css"));

            bundles.Add(new ScriptBundle("~/bundles/uijavascripts").Include(
                "~/Scripts/highcharts.js",
                 "~/Scripts/dash-charts.js",
                 "~/Scripts/home.js",
               "~/Scripts/guage.js"
                ));

            bundles.Add(new ScriptBundle("~/bundles/columnstorejavascripts").Include(
               "~/Scripts/highcharts.js",
               "~/Scripts/dash-charts.js",
              "~/Scripts/columnstore.js"
               ));

            bundles.Add(new ScriptBundle("~/bundles/realtimejavascripts").Include(
             "~/Scripts/highcharts.js",
             "~/Scripts/funnel.js",
             "~/Scripts/dash-charts.js",
            "~/Scripts/realtime.js"
             ));

            bundles.Add(new ScriptBundle("~/bundles/realtimejavascriptsv1").Include(
             "~/Scripts/highcharts.js",
             "~/Scripts/funnel.js",
             "~/Scripts/dash-charts.js",
            "~/Scripts/realtime1.js"
             ));

            bundles.Add(new ScriptBundle("~/bundles/notyjavascripts").Include(
                   "~/Scripts/noty/jquery.noty.js",
                   "~/Scripts/noty/layouts/top.js",
                   "~/Scripts/noty/layouts/topLeft.js",
                   "~/Scripts/noty/layouts/topRight.js",
                   "~/Scripts/noty/layouts/topCenter.js",
                   "~/Scripts/noty/themes/default.js"
                ));


        }
    }
}
