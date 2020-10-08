using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ElusionX.Web.Models
{
    public class ApplicationConfig
    {
        public int ApplicationConfigId { get; set; }
        public string ApplicationName { get; set; }
        public int MinCommandTimeOut { get; set; }
        public int MaxCommandTimeOut { get; set; }
        public int NumberOfOrders { get; set; }
        public int NumberOfUsers{ get; set; }
    }
}