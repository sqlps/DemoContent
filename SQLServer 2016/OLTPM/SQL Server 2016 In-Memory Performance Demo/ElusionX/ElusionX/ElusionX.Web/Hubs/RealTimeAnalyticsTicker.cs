using ElusionX.Web.Models;
using ElusionX.Web.Providers;
using Microsoft.AspNet.SignalR;
using Microsoft.AspNet.SignalR.Hubs;
using System;
using System.Linq;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;

namespace ElusionX.Web.Hubs
{
    public class RealTimeAnalyticsTicker
    {
        private readonly static Lazy<RealTimeAnalyticsTicker> instance = new Lazy<RealTimeAnalyticsTicker>(() =>
        new RealTimeAnalyticsTicker(GlobalHost.ConnectionManager.GetHubContext<RealTimeAnalyticsHub>().Clients));
        private readonly object _updateMessagesLock = new object();
        //private readonly TimeSpan _dayProfitInterval = TimeSpan.FromMilliseconds(1000);
        //private Timer _dayProfitTimer;
        private readonly TimeSpan _oltpCPUUsageMetrics = TimeSpan.FromMilliseconds(1000);
        private readonly TimeSpan _rtoaCPUUsageMetrics = TimeSpan.FromMilliseconds(1000);
        private Timer _oltpMetricsTimer;
        private Timer _rtoaMetricsTimer;

        private RealTimeAnalyticsTicker(IHubConnectionContext<dynamic> clients)
        {
            Clients = clients;
            //_dayProfitTimer= new Timer(UpdateOrderCount, null, _dayProfitInterval, _dayProfitInterval);
            _oltpMetricsTimer = new Timer(UpdateOLTPCPUMetrics, null, _oltpCPUUsageMetrics, _oltpCPUUsageMetrics);
            _rtoaMetricsTimer = new Timer(UpdateRTOACPUMetrics, null, _rtoaCPUUsageMetrics, _rtoaCPUUsageMetrics);
        }

        public static RealTimeAnalyticsTicker Instance
        {
            get
            {

                return instance.Value;
            }
        }

        private IHubConnectionContext<dynamic> Clients
        {
            get;
            set;
        }

        private void UpdateOLTPCPUMetrics(object state)
        {
            //var cpu = new PerformanceCounter("Processor", "% Processor Time", "_Total"); 
            var cpu = new PerformanceCounter("SQLServer:Resource Pool Stats", "CPU usage %", "OLTPPool");
            double cpuper = cpu.NextValue();
            Thread.Sleep(1000);
            cpuper = Math.Round(cpu.NextValue(), 2);
            RealTimeMetrics metrics = new RealTimeMetrics();
            metrics.CPU = cpuper;
            try
            {
                lock (RTOALoadEngine.queryOutQueue)
                {
                    var queue = RTOALoadEngine.queryOutQueue.ToList();
                    metrics.Orders = queue.Count * RTOALoadEngine.NumberOfOrders;
                }
            }
            catch (Exception)
            {
            }
            Clients.All.sendOLTPCPUMetrics(metrics);
        }

        private void UpdateRTOACPUMetrics(object state)
        {
            //var cpu = new PerformanceCounter("Processor", "% Processor Time", "_Total");
            var cpu = new PerformanceCounter("SQLServer:Resource Pool Stats", "CPU usage %", "RTOAPool");
            double cpuper = cpu.NextValue();
            Thread.Sleep(1000);
            cpuper = Math.Round(cpu.NextValue(), 2);
            RealTimeMetrics metrics = new RealTimeMetrics();
            metrics.CPU = cpuper;
            try
            {
                lock (RTOALoadEngine.queryOutQueue)
                {
                    var queue = RTOALoadEngine.queryOutQueue.ToList();
                    metrics.Orders = queue.Count * RTOALoadEngine.NumberOfOrders;
                }
            }
            catch (Exception)
            {
            }
            Clients.All.sendRTOACPUMetrics(metrics);
        }

        private void UpdateOrderCount(object state)
        {
            SQLProvider provider = new SQLProvider();
            var orderCount = provider.GetOrderCount("MAIN");
            BroadcastDayProfit(orderCount);
        }

        public void BroadcastDayProfit(int orderCount)
        {
            Clients.All.sendOrderCount(orderCount);
        }
    }
}