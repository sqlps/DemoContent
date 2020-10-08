using ElusionX.Web.DataModel;
using ElusionX.Web.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace ElusionX.Web.Providers
{
    public class SQLProvider
    {
        string connStringProducts;
        string connStringDW;
        string connStringOADB;
        string connStringRTOA;
        string dbcc = @"DBCC DROPCLEANBUFFERS;";

        public SQLProvider()
        {
            this.connStringProducts = ConfigurationManager.ConnectionStrings["proddbconnection"].ToString();
            this.connStringDW = ConfigurationManager.ConnectionStrings["dwconnection"].ToString();
            this.connStringOADB = ConfigurationManager.ConnectionStrings["oadbconnection"].ToString();
            this.connStringRTOA = ConfigurationManager.ConnectionStrings["oadbconnection_rtoa"].ToString();
        }

        #region Operational Analytics

        internal void ExecuteOA()
        {
            using (var conn = new SqlConnection(connStringOADB))
            {
                conn.Open();
                SqlCommand sqlCommand = new SqlCommand();
                sqlCommand.CommandText = "dbo.OASetup";
                sqlCommand.Connection = conn;
                sqlCommand.CommandTimeout = 5 * 60;
                sqlCommand.CommandType = System.Data.CommandType.StoredProcedure;
                sqlCommand.ExecuteNonQuery();
            }
        }

        internal List<OAModel> GetOrderRevenue(int flag)
        {
            List<OAModel> oaModels = null;
            try
            {
                using (var conn = new SqlConnection(connStringOADB))
                {
                    conn.Open();
                    using (SqlCommand sqlCommand = new SqlCommand())
                    {
                        if (flag == 0)
                            sqlCommand.CommandText = ";WITH X AS (SELECT DATEPART(HOUR,o.OrderDate) AS OrderHour,	CAST(SUM(o.OrderQuantity * (p.ProductSalePrice + o.OrderTax)) AS INT) AS OrderRevenue,	CASE WHEN DATEPART(HOUR, OrderDate) <= DATEPART(HOUR, GETDATE()) THEN DATEPART(HOUR, OrderDate)	ELSE -1 * (24 - DATEPART(HOUR, OrderDate)) END	AS OrderKey FROM ordersDW o INNER JOIN DimProducts p ON o.ProductID = p.ProductID WHERE o.OrderDate > DATEADD(HOUR, DATEDIFF(HOUR,0,GETDATE()) + 1,-1) GROUP BY DATEPART(HOUR,o.OrderDate)),Y AS (SELECT OrderHour, OrderRevenue, OrderKey FROM X UNION ALL SELECT number, 0, 24 FROM master.dbo.spt_values WHERE type = 'P' AND number BETWEEN (SELECT TOP 1 OrderHour+1 FROM X ORDER BY OrderKey DESC) AND DATEPART(HOUR, GETDATE())) SELECT OrderHour, OrderRevenue FROM Y ORDER BY OrderKey, OrderHour";
                        else
                            sqlCommand.CommandText = ";WITH X AS (SELECT DATEPART(HOUR,o.OrderDate) AS OrderHour,	CAST(SUM(o.OrderQuantity * (p.ProductSalePrice + o.OrderTax)) AS INT) AS OrderRevenue,	CASE WHEN DATEPART(HOUR, OrderDate) <= DATEPART(HOUR, GETDATE()) THEN DATEPART(HOUR, OrderDate)	ELSE -1 * (24 - DATEPART(HOUR, OrderDate)) END	AS OrderKey FROM orders o INNER JOIN DimProducts p ON o.ProductID = p.ProductID WHERE o.OrderDate > DATEADD(HOUR, DATEDIFF(HOUR,0,GETDATE()) + 1,-1) GROUP BY DATEPART(HOUR,o.OrderDate)), Y AS (SELECT OrderHour, OrderRevenue, OrderKey FROM X UNION ALL SELECT number, 0, 24 FROM master.dbo.spt_values WHERE type = 'P' AND number BETWEEN (SELECT TOP 1 OrderHour+1 FROM X ORDER BY OrderKey DESC) AND DATEPART(HOUR, GETDATE())) SELECT OrderHour, OrderRevenue FROM Y ORDER BY OrderKey, OrderHour";
                        sqlCommand.Connection = conn;
                        sqlCommand.CommandTimeout = 5 * 60;
                        sqlCommand.CommandType = System.Data.CommandType.Text;
                        using (var reader = sqlCommand.ExecuteReader())
                        {
                            oaModels = new List<OAModel>();
                            while (reader.Read())
                            {
                                OAModel oaModel = new OAModel();
                                oaModel.OrderMinute = int.Parse(reader["OrderHour"].ToString());
                                oaModel.OrderRevenue = int.Parse(reader["OrderRevenue"].ToString());
                                oaModels.Add(oaModel);
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
            return oaModels;
        }

        internal int GetDayProfit(int flag)
        {
            int orderCount = 0;
            using (var conn = new SqlConnection(connStringOADB))
            {
                conn.Open();
                using (SqlCommand sqlCommand = new SqlCommand())
                {
                    sqlCommand.Connection = conn;
                    if (flag == 0)
                        sqlCommand.CommandText = "SELECT CAST(SUM(o.OrderQuantity * (p.ProductSalePrice - p.ProductPurchasePrice)) AS INT) AS DayProfit FROM ordersDW o INNER JOIN DimProducts p ON o.ProductID = p.ProductID WHERE o.OrderDate > DATEADD(DAY, DATEDIFF(DAY,0,GETDATE()),0)";
                    else
                        sqlCommand.CommandText = "SELECT CAST(SUM(o.OrderQuantity * (p.ProductSalePrice - p.ProductPurchasePrice)) AS INT) AS DayProfit FROM orders o INNER JOIN DimProducts p ON o.ProductID = p.ProductID WHERE o.OrderDate > DATEADD(DAY, DATEDIFF(DAY,0,GETDATE()),0)";
                    sqlCommand.CommandTimeout = 5 * 60;
                    sqlCommand.CommandType = System.Data.CommandType.Text;
                    using (var reader = sqlCommand.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            orderCount = int.Parse(reader["DayProfit"].ToString());
                        }
                    }
                }
            }
            return orderCount;
        }

        internal void RunSQLConsoleCommand(string command)
        {
            try
            {
                using (var conn = new SqlConnection(connStringDW))
                {
                    conn.Open();
                    using (SqlCommand sqlCommand = new SqlCommand())
                    {
                        sqlCommand.Connection = conn;
                        sqlCommand.CommandTimeout = 10 * 60;
                        sqlCommand.CommandType = System.Data.CommandType.Text;
                        sqlCommand.CommandText = command;
                        sqlCommand.ExecuteNonQuery();
                    }
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        internal List<OAModel> GetOrderRevenuePerMinute()
        {
            List<OAModel> oaModels = null;
            try
            {
                using (var conn = new SqlConnection(connStringOADB))
                {
                    conn.Open();
                    using (SqlCommand sqlCommand = new SqlCommand())
                    {
                        sqlCommand.CommandText = ";WITH X AS (SELECT DATEPART(MINUTE,o.OrderDate) AS OrderMinute,	CAST(SUM(o.OrderQuantity * (p.ProductSalePrice + o.OrderTax)) AS INT) AS OrderRevenue, CASE WHEN DATEPART(MINUTE, OrderDate) <= DATEPART(MINUTE, GETDATE()) THEN DATEPART(MINUTE, OrderDate) ELSE -1 * (60 - DATEPART(MINUTE, OrderDate)) END AS OrderKey FROM orders o INNER JOIN DimProducts p ON o.ProductID = p.ProductID WHERE o.OrderDate >DATEADD(HOUR,-1,DATEADD(MINUTE, DATEDIFF(MINUTE,0,GETDATE()),-1)) GROUP BY DATEPART(MINUTE,o.OrderDate)) SELECT OrderMinute, OrderRevenue FROM X ORDER BY OrderKey";
                        sqlCommand.Connection = conn;
                        sqlCommand.CommandTimeout = 5 * 60;
                        sqlCommand.CommandType = System.Data.CommandType.Text;
                        using (var reader = sqlCommand.ExecuteReader())
                        {
                            oaModels = new List<OAModel>();
                            while (reader.Read())
                            {
                                OAModel oaModel = new OAModel();
                                oaModel.OrderMinute = int.Parse(reader["OrderMinute"].ToString());
                                oaModel.OrderRevenue = int.Parse(reader["OrderRevenue"].ToString());
                                oaModels.Add(oaModel);
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
            return oaModels;
        }

        internal List<ColumnStoreDataModel> GetYoYSales(int queryType)
        {
            try
            {
                ElusionX_ProdDBEntities db = new ElusionX_ProdDBEntities();
                var rtoaSettings = db.ApplicationConfiguration.FirstOrDefault(a => a.Name == "RTOASettings");
                int yoyIterations = rtoaSettings !=null ? rtoaSettings.MinCommandTimeOut : 4; // this property is used to store yoy iterations
                var yoysales = new List<ColumnStoreDataModel>();
                for (int i = 0; i < yoyIterations ; i++)
                {
                    yoysales = new List<ColumnStoreDataModel>();
                    using (SqlConnection connection = new SqlConnection(connStringRTOA))
                    {
                        connection.Open();
                        using (SqlCommand sqlCommand = new SqlCommand())
                        {
                            sqlCommand.Connection = connection;
                            //DBCC DROPCLEANBUFFERS;
                            sqlCommand.CommandText = "exec SP_RECOMPILE OACSCall;";
                            sqlCommand.CommandType = System.Data.CommandType.Text;
                            sqlCommand.ExecuteNonQuery();
                            sqlCommand.CommandType = System.Data.CommandType.StoredProcedure;
                            sqlCommand.CommandText = "dbo.OACSCall";
                            sqlCommand.Parameters.AddWithValue("@isinMem", queryType);
                            using (var reader = sqlCommand.ExecuteReader())
                            {
                                while (reader.Read())
                                {
                                    var columnStoreModel = new ColumnStoreDataModel();
                                    columnStoreModel.Year = reader["OrderMonth"].ToString();
                                    columnStoreModel.Price = double.Parse(reader["SaleProfit"].ToString());
                                    yoysales.Add(columnStoreModel);
                                }
                            }
                        }
                    }
                }
                return yoysales;
            }
            catch (Exception)
            {
                throw;
            }
        }

        internal int GetOrderCount(string flag)
        {
            int orderCount = 0;
            string sqlCommandString = string.Empty;
            switch (flag)
            {
                case "MAIN":
                    sqlCommandString = "SELECT COUNT(1) AS Orders FROM Orders";
                    break;
                case "TRADITIONAL":
                    sqlCommandString = "SELECT COUNT(1) AS Orders FROM OrdersDW";
                    break;
                case "REALTIME":
                    sqlCommandString = "SELECT COUNT(1) AS Orders FROM Orders";
                    break;
            }
            using (var conn = new SqlConnection(connStringOADB))
            {
                conn.Open();
                using (SqlCommand sqlCommand = new SqlCommand())
                {
                    sqlCommand.Connection = conn;
                    sqlCommand.CommandText = sqlCommandString;
                    sqlCommand.CommandTimeout = 5 * 60;
                    sqlCommand.CommandType = System.Data.CommandType.Text;
                    using (var reader = sqlCommand.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            orderCount = int.Parse(reader["Orders"].ToString());
                        }
                    }
                }
            }
            return orderCount;
        }

        internal void ExecuteETL()
        {
            using (var conn = new SqlConnection(connStringOADB))
            {
                conn.Open();
                SqlCommand sqlCommand = new SqlCommand();
                sqlCommand.CommandText = "dbo.OADataLoad";
                sqlCommand.Connection = conn;
                sqlCommand.CommandTimeout = 5 * 60;
                sqlCommand.CommandType = System.Data.CommandType.StoredProcedure;
                sqlCommand.ExecuteNonQuery();
            }
        }

        #endregion

        #region Diskbased/In-Memory Dashboard
        public string GetQuery(int queryFlag = 0)
        {
            return "dbo.GenerateOrders";
        }

        public int GetActiveConnections()
        {
            int activeConnections = 0;
            using (var conn = new SqlConnection(connStringProducts))
            {
                conn.Open();
                using (SqlCommand sqlCommand = new SqlCommand("SELECT count(1) AS connections FROM sys.dm_exec_sessions WHERE login_name = 'sa'", conn))
                {
                    sqlCommand.CommandTimeout = 5 * 60;
                    sqlCommand.CommandType = System.Data.CommandType.Text;
                    using (var reader = sqlCommand.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            activeConnections = int.Parse(reader["connections"].ToString());
                        }
                    }
                }
            }
            return activeConnections;
        }

        public int GetActiveRequests()
        {
            int activeRequests = 0;
            try
            {
                using (var conn = new SqlConnection(connStringProducts))
                {
                    conn.Open();
                    using (SqlCommand sqlCommand = new SqlCommand("SELECT count(1) AS active_requests FROM sys.dm_exec_requests r INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id WHERE login_name = 'sa'", conn))
                    {
                        sqlCommand.CommandTimeout = 5 * 60;
                        sqlCommand.CommandType = System.Data.CommandType.Text;
                        using (var reader = sqlCommand.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                activeRequests = int.Parse(reader["active_requests"].ToString());
                            }
                        }
                    }
                }
            }
            catch (Exception) { }
            return activeRequests;
        }

        public long GetTotalOrders(int orderType)
        {
            long totalOrders = 0;
            try
            {
                var completedUsers = LoadEngine.queryOutQueue.Where(q => q.e == null).ToList().Count();
                totalOrders = completedUsers * LoadEngine.OrderCount;
            }
            catch (Exception) { }
            return totalOrders;
        }

        public decimal GetTotalValue()
        {
            decimal totalValue = 0;
            try
            {
                totalValue = LoadEngine.queryOutQueue.Sum(q => q.TotalValue);
            }
            catch (Exception) { }
            return totalValue;
        }

        internal int GenerateRandomNumber()
        {
            int randomNumber = 0;
            try
            {
                using (var conn = new SqlConnection(connStringProducts))
                {
                    conn.Open();
                    using (SqlCommand sqlCommand = new SqlCommand("select ABS(Checksum(NewID()) % 10) + 6 as randomnumber", conn))
                    {
                        sqlCommand.CommandTimeout = 5 * 60;
                        sqlCommand.CommandType = System.Data.CommandType.Text;
                        using (var reader = sqlCommand.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                randomNumber = int.Parse(reader["randomnumber"].ToString());
                            }
                        }
                    }
                }
            }
            catch (Exception) { }
            return randomNumber;
        }

        #endregion

        #region Column Store Reports
        internal int GetRowCounts(int flag)
        {
            int rowCount = 0;
            try
            {
                using (var conn = new SqlConnection(connStringDW))
                {
                    conn.Open();
                    using (SqlCommand sqlCommand = new SqlCommand())
                    {
                        sqlCommand.Connection = conn;
                        sqlCommand.CommandTimeout = 10 * 60;
                        sqlCommand.CommandType = System.Data.CommandType.Text;
                        if (flag == 0)
                        {
                            sqlCommand.CommandText = "SELECT COUNT(1) as rowscount FROM OrdersDW";
                        }
                        else
                        {
                            sqlCommand.CommandText = "SELECT COUNT(1) as rowscount FROM OrdersDW_CS";
                        }
                        using (var reader = sqlCommand.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                rowCount = int.Parse(reader["rowscount"].ToString());
                            }
                        }
                    }
                }
            }
            catch (Exception ex) { }
            return rowCount;
        }

        public List<ColumnStoreDataModel> GetMetricsWithoutColumnStore(string selectedYear = "")
        {
            List<ColumnStoreDataModel> models = null;
            try
            {
                using (var conn = new SqlConnection(connStringDW))
                {
                    conn.Open();
                    using (SqlCommand sqlCommand = new SqlCommand())
                    {
                        sqlCommand.Connection = conn;
                        sqlCommand.CommandTimeout = 10 * 60;
                        sqlCommand.CommandType = System.Data.CommandType.Text;
                        if (string.IsNullOrEmpty(selectedYear))
                        {
                            sqlCommand.CommandText = dbcc + " SELECT DATEPART(YEAR, o.OrderDate) AS OrderYear, SUM(OrderPrice - (o.OrderQuantity * (p.ProductPurchasePrice + o.OrderTax))) AS SaleProfit FROM ordersDW o INNER JOIN DimProducts p ON o.ProductID = p.ProductID INNER JOIN DimCategories c ON o.CategoryID = c.CategoryID INNER JOIN DimManufacturers m ON o.ManufacturerID = m.ManufacturerID GROUP BY DATEPART(YEAR, o.OrderDate) ORDER BY DATEPART(YEAR, o.OrderDate)";
                            using (var reader = sqlCommand.ExecuteReader())
                            {
                                models = new List<ColumnStoreDataModel>();
                                while (reader.Read())
                                {
                                    //var name = reader["Name"].ToString();
                                    var year = reader["OrderYear"].ToString();
                                    var price = double.Parse(reader["SaleProfit"].ToString());
                                    ColumnStoreDataModel model = new ColumnStoreDataModel();
                                    //model.Name = name;
                                    model.Price = Math.Round(price, 2);
                                    model.Year = year;
                                    models.Add(model);
                                }
                            }
                        }
                        else
                        {
                            sqlCommand.CommandText = dbcc + string.Format(" SELECT DATEPART(MONTH, o.OrderDate) AS OrderMonth, SUM(OrderPrice - (o.OrderQuantity * (p.ProductPurchasePrice + o.OrderTax))) AS SaleProfit FROM ordersDW o INNER JOIN DimProducts p ON o.ProductID = p.ProductID INNER JOIN DimCategories c ON o.CategoryID = c.CategoryID INNER JOIN DimManufacturers m ON o.ManufacturerID = m.ManufacturerID Where DATEPART(YEAR, o.OrderDate) = {0} GROUP BY DATEPART(MONTH, o.OrderDate) ORDER BY DATEPART(MONTH, o.OrderDate)", selectedYear);
                            using (var reader = sqlCommand.ExecuteReader())
                            {
                                models = new List<ColumnStoreDataModel>();
                                while (reader.Read())
                                {
                                    var name = reader["OrderMonth"].ToString();
                                    var price = double.Parse(reader["SaleProfit"].ToString());
                                    ColumnStoreDataModel model = new ColumnStoreDataModel();
                                    model.Name = name;
                                    model.Price = Math.Round(price, 2);
                                    models.Add(model);
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception) { }
            return models;
        }

        public List<ColumnStoreDataModel> GetMetricsWithColumnStore(string selectedYear = "")
        {
            List<ColumnStoreDataModel> models = null;
            try
            {
                using (var conn = new SqlConnection(connStringDW))
                {
                    conn.Open();
                    using (SqlCommand sqlCommand = new SqlCommand())
                    {
                        sqlCommand.Connection = conn;
                        sqlCommand.CommandTimeout = 10 * 60;
                        sqlCommand.CommandType = System.Data.CommandType.Text;
                        if (string.IsNullOrEmpty(selectedYear))
                        {
                            sqlCommand.CommandText = dbcc + " SELECT DATEPART(YEAR, o.OrderDate) AS OrderYear, SUM(OrderPrice - (o.OrderQuantity * (p.ProductPurchasePrice + o.OrderTax))) AS SaleProfit FROM ordersDW_CS o INNER JOIN DimProducts p ON o.ProductID = p.ProductID INNER JOIN DimCategories c ON o.CategoryID = c.CategoryID INNER JOIN DimManufacturers m ON o.ManufacturerID = m.ManufacturerID GROUP BY DATEPART(YEAR, o.OrderDate) ORDER BY DATEPART(YEAR, o.OrderDate)";
                            using (var reader = sqlCommand.ExecuteReader())
                            {
                                models = new List<ColumnStoreDataModel>();
                                while (reader.Read())
                                {
                                    //var name = reader["Name"].ToString();
                                    var year = reader["OrderYear"].ToString();
                                    var price = double.Parse(reader["SaleProfit"].ToString());
                                    ColumnStoreDataModel model = new ColumnStoreDataModel();
                                    //model.Name = name;
                                    model.Price = Math.Round(price, 2);
                                    model.Year = year;
                                    models.Add(model);
                                }
                            }
                        }
                        else
                        {
                            sqlCommand.CommandText = dbcc + string.Format(" SELECT DATEPART(MONTH, o.OrderDate) AS OrderMonth, SUM(OrderPrice - (o.OrderQuantity * (p.ProductPurchasePrice + o.OrderTax))) AS SaleProfit FROM ordersDW_CS o INNER JOIN DimProducts p ON o.ProductID = p.ProductID INNER JOIN DimCategories c ON o.CategoryID = c.CategoryID INNER JOIN DimManufacturers m ON o.ManufacturerID = m.ManufacturerID Where DATEPART(YEAR, o.OrderDate) = {0} GROUP BY DATEPART(MONTH, o.OrderDate) ORDER BY DATEPART(MONTH, o.OrderDate)", selectedYear);
                            using (var reader = sqlCommand.ExecuteReader())
                            {
                                models = new List<ColumnStoreDataModel>();
                                while (reader.Read())
                                {
                                    var name = reader["OrderMonth"].ToString();
                                    var price = double.Parse(reader["SaleProfit"].ToString());
                                    ColumnStoreDataModel model = new ColumnStoreDataModel();
                                    model.Name = name;
                                    model.Price = Math.Round(price, 2);
                                    models.Add(model);
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception) { }
            return models;
        }
        #endregion
    }
}