using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ElusionX.Web.Models
{
    public class ColumnStoreDataModel
    {
        public string Name { get; set; }
        public string Year { get; set; }
        public double Price { get; set; }
    }

    public class ColumnStoreJsonModel
    {
        public ColumnStoreJsonModel()
        {
            Years = new List<string>();
            Revenues = new List<ColumnStoreRevenueModel>();
        }
        public List<string> Years { get; set; }
        public List<ColumnStoreRevenueModel> Revenues { get; set; }
    }

    public class ColumnStoreRevenueModel
    {
        public ColumnStoreRevenueModel()
        {
            Prices = new List<double>();
        }
        public string Name { get; set; }
        public List<double> Prices { get; set; }
    }
}