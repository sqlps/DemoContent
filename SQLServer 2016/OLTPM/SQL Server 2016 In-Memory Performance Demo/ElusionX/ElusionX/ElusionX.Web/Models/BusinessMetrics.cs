using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ElusionX.Web.Models
{
    public class BusinessMetrics
    {
        public long TotalOrders { get; set; }
        public string TotalValue { get; set; }
        public decimal AvgValue { get; set; }
        public double AvgTimetakenPerOrder { get; set; }
        public long FailedOrders { get; set; }
        public string EstimatedLoss { get; set; }
        public long Users { get; set; }
        public decimal ProfitPercentage { get; set; }
        public decimal LossPercentage { get; set; }
        public long Orders { get; set; }
        public int TotalUsers { get; set; }
        public decimal TotalOrderValue { get; set; }
    }
}