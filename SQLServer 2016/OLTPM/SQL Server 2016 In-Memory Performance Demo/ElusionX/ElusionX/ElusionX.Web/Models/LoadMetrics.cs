using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ElusionX.Web.Models
{
    public class LoadMetrics
    {
        public int Exceptions { get; set; }
        public double TotalLoad { get; set; }
        public double TotalCompleted { get; set; }
    }
}