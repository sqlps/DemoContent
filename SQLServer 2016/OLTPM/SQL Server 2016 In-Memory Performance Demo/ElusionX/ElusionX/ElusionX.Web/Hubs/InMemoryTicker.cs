using ElusionX.Web.Models;
using ElusionX.Web.Providers;
using Microsoft.AspNet.SignalR;
using Microsoft.AspNet.SignalR.Hubs;
using System;
using System.Diagnostics;
using System.Linq;
using System.Threading;

namespace ElusionX.Web.Hubs
{
    public class InMemoryTicker
    {
        private readonly static Lazy<InMemoryTicker> instance = new Lazy<InMemoryTicker>(() =>
        new InMemoryTicker(GlobalHost.ConnectionManager.GetHubContext<InMemoryHub>().Clients));
        private readonly object _updateMessagesLock = new object();
        private readonly TimeSpan _businessMetricsupdateInterval = TimeSpan.FromMilliseconds(250);
        private readonly TimeSpan _loadTimerUpdateInterval = TimeSpan.FromMilliseconds(250);
        private readonly TimeSpan _technicalMetricsUpdateInterval = TimeSpan.FromMilliseconds(250);
        private readonly Timer _loadtimer;
        private readonly Timer _businesstimer;
        private readonly Timer _technicaltimer;
        private string sqlStatisticsCategory = @"SQLServer:SQL Statistics";
        private string batchRequestsCounter = "Batch Requests/sec";

        private InMemoryTicker(IHubConnectionContext<dynamic> clients)
        {
            Clients = clients;
            _loadtimer = new Timer(UpdateLoadMetrics, null, _technicalMetricsUpdateInterval, _technicalMetricsUpdateInterval);
            _businesstimer = new Timer(UpdateBusinessMetrics, null, _technicalMetricsUpdateInterval, _technicalMetricsUpdateInterval);
            _technicaltimer = new Timer(UpdateTechnicalMetrics, null, _technicalMetricsUpdateInterval, _technicalMetricsUpdateInterval);
        }

        public static InMemoryTicker Instance
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

        private void UpdateLoadMetrics(object state)
        {
            var metrics = GetLoadMetrics();
            BroadcastLoadMetrics(metrics);
        }

        private void UpdateTechnicalMetrics(object state)
        {
            var metrics = GetTechnicalMetrics();
            BroadcastTechnicalMetrics(metrics);
        }


        private void UpdateBusinessMetrics(object state)
        {
            var metrics = GetBusinessMetrics();
            BroadcastBusinessMetrics(metrics);
        }


        public TechnicalMetrics GetTechnicalMetrics()
        {
            TechnicalMetrics technicalMetrics = new TechnicalMetrics();
            try
            {
                SQLProvider sqlProvider = new SQLProvider();
                var activeConnections = sqlProvider.GetActiveConnections();
                var activeRequests = sqlProvider.GetActiveRequests();
                var batchRequests = new PerformanceCounter(sqlStatisticsCategory, batchRequestsCounter);
                var contextswitchpersec = new PerformanceCounter("Thread", "Context Switches/sec", "_Total");
                var pageIOLatchWaits = new PerformanceCounter("SQLServer:Wait Statistics", "Page IO latch waits", "Cumulative wait time (ms) per second");
                var latchWaits = new PerformanceCounter("SQLServer:Latches", "Latch Waits/sec");
                var cpu = new PerformanceCounter("Processor", "% Processor Time", "_Total");
                technicalMetrics.BatchRequests = (long)batchRequests.NextValue();
                technicalMetrics.LatchWaits = (long)latchWaits.NextValue();
                technicalMetrics.ContextSwitchPerSec = (long)contextswitchpersec.NextValue();
                technicalMetrics.CPU = cpu.NextValue();
                Thread.Sleep(1000);
                technicalMetrics.ContextSwitchPerSec = (long)contextswitchpersec.NextValue();
                technicalMetrics.LatchWaits = (long)latchWaits.NextValue();
                technicalMetrics.BatchRequests = (long)batchRequests.NextValue();
                technicalMetrics.CPU = Math.Round(cpu.NextValue(), 2);
                technicalMetrics.Requests = activeRequests;
                technicalMetrics.Sessions = activeConnections;
            }
            catch (Exception)
            {
            }
            return technicalMetrics;
        }

        public LoadMetrics GetLoadMetrics()
        {
            var loadMetrics = new LoadMetrics();
            try
            {
                var threads = LoadEngine.usersThreadPool;
                var users = LoadEngine.Users;
                var exceptions = LoadEngine.queryOutQueue.Where(o => o.e != null).ToList().Count();
                loadMetrics.Exceptions = exceptions;
                var queueCount = LoadEngine.queryOutQueue.ToList().Count;
                loadMetrics.TotalCompleted = Math.Round(((double)queueCount / threads.Count) * 100, 0);
                loadMetrics.TotalLoad = 100 - loadMetrics.TotalCompleted;
                if (loadMetrics.TotalCompleted == 100)
                {
                    LoadEngine.loadEngineEndTime = DateTime.UtcNow;
                    //LoadEngine.CancelThreads();
                }
            }
            catch (Exception)
            {
            }
            return loadMetrics;
        }

        public BusinessMetrics GetBusinessMetrics()
        {
            var businessMetrics = new BusinessMetrics();
            try
            {
                var users = LoadEngine.queryOutQueue.Where(o => o.e == null).ToList().Count;
                var sqlProvider = new SQLProvider();
                var orders = sqlProvider.GetTotalOrders(LoadEngine.QueryFlag);
                var totalValue = sqlProvider.GetTotalValue();
                decimal avgValue = 0;
                double avgTimePerOrder = 0;
                if (orders > 0)
                {
                    avgValue = totalValue / orders;
                    var seconds = (DateTime.UtcNow - LoadEngine.loadEngineStartTime).Milliseconds;
                    var failedOrders = LoadEngine.queryOutQueue.Where(o => o.e != null).ToList().Count();
                    var estimatedLoss = failedOrders * avgValue;
                    avgTimePerOrder = Math.Round(((double)seconds / orders), 2);
                    businessMetrics.ProfitPercentage = Math.Round(totalValue, 2);// Math.Round((totalValue / (totalValue + estimatedLoss)) * 100, 2);
                    businessMetrics.LossPercentage = Math.Round(estimatedLoss, 0);// Math.Round((estimatedLoss / (totalValue + estimatedLoss)) * 100, 2);
                    businessMetrics.TotalOrderValue = Math.Round(avgValue * LoadEngine.OrderCount * LoadEngine.Users, 2);
                    businessMetrics.FailedOrders = failedOrders * LoadEngine.OrderCount;
                    businessMetrics.EstimatedLoss = estimatedLoss.ToCurrency();
                }
                businessMetrics.Users = users;
                businessMetrics.TotalOrders = LoadEngine.OrderCount * LoadEngine.Users;
                businessMetrics.TotalValue = "$ " + totalValue.ToMillion();
                businessMetrics.AvgValue = Math.Round(avgValue, 0);
                businessMetrics.AvgTimetakenPerOrder = avgTimePerOrder;
                businessMetrics.Orders = orders;
                businessMetrics.TotalUsers = LoadEngine.Users;
            }
            catch (Exception)
            {
            }
            return businessMetrics;
        }

        public void BroadcastLoadMetrics(LoadMetrics loadMetrics)
        {
            Clients.All.sendInMemoryLoadEngineMetrics(loadMetrics);
        }


        public void BroadcastBusinessMetrics(BusinessMetrics businessMetrics)
        {
            Clients.All.sendInMemoryBusinessMetrics(businessMetrics);
        }

        public void BroadcastTechnicalMetrics(TechnicalMetrics technicalMetrics)
        {
            Clients.All.sendInMemoryTechnicalMetrics(technicalMetrics);
        }
    }
}