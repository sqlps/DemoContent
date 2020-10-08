using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ElusionX.Web.Models
{
    public class QueryOutput
    {
        public Exception e;
        public TimeSpan time;
        public bool finished;
        public int LogicalReads;
        public int CPUTime;
        public int ElapsedTime;
        public decimal TotalValue;
    }
}