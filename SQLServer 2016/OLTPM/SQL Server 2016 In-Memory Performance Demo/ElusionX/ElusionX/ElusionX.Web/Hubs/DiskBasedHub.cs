using ElusionX.Web.Models;
using ElusionX.Web.Providers;
using Microsoft.AspNet.SignalR;
using Microsoft.AspNet.SignalR.Hubs;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Threading;
using System.Web;

namespace ElusionX.Web.Hubs
{
    public class DiskBasedHub : Hub
    {
        private readonly DiskTicker messageTicker;
        public DiskBasedHub() : this(DiskTicker.Instance) { }
        public DiskBasedHub(DiskTicker messageTicker)
        {
            this.messageTicker = messageTicker;
        }

        public TechnicalMetrics GetTechnicalMetrics()
        {
            return messageTicker.GetTechnicalMetrics();
        }

        public LoadMetrics GetLoadMetrics()
        {
            return messageTicker.GetLoadMetrics();
        }

        public BusinessMetrics GetBusinessMetrics()
        {
            return messageTicker.GetBusinessMetrics();
        }
    }
    
}


