using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ElusionX.Web.Models
{
    public class TechnicalMetrics
    {
        public long BatchRequests { get; set; }
        public int Sessions { get; set; }
        public int Requests { get; set; }
        public int Exceptions { get; set; }
        public long LatchWaits { get; set; }
        public int TotalOrders { get; set; }
        public int TotalValue { get; set; }
        public double CPU { get; set; }
        public long ContextSwitchPerSec { get; set; }
    }
}