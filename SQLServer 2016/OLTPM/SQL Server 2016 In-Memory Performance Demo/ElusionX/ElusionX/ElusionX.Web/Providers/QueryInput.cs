using ElusionX.Web.Models;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using System.Web;

namespace ElusionX.Web.Providers
{
    public class QueryInput
    {

        [ThreadStatic]
        private static QueryOutput outInfo;
        private readonly SqlCommand statisticsCommand;
        private readonly SqlCommand sqlCommand;
        private static bool runCancelled;
        private int numberOfOrders { get; set; }

        public static bool RunCancelled
        {
            set
            {
                runCancelled = value;
            }
        }

        public SqlCommand StatisticsCommand
        {
            get
            {
                return statisticsCommand;
            }
        }

        private Stopwatch sw = new Stopwatch();

        public QueryInput(
            SqlCommand statisticsCommand,
            SqlCommand sqlCommand, int numberOfOrders)
        {
            this.statisticsCommand = statisticsCommand;
            this.sqlCommand = sqlCommand;
            this.numberOfOrders = numberOfOrders;
        }

        public void startLoadThread()
        {
            try
            {
                decimal totalValue = 0;
                //do the work
                using (SqlConnection conn = sqlCommand.Connection)
                {
                    int connectionHashCode = conn.GetHashCode();
                    Exception outException = null;
                    try
                    {
                        //initialize the outInfo structure
                        QueryInput.outInfo = new QueryOutput();
                        conn.Open();
                        //set up the statistics gathering
                        if (statisticsCommand != null)
                        {
                            statisticsCommand.ExecuteNonQuery();
                            Thread.Sleep(0);
                        }
                        sw.Start();

                        sqlCommand.CommandType = System.Data.CommandType.StoredProcedure;
                        sqlCommand.Parameters.AddWithValue("@batchSize", this.numberOfOrders);
                        sqlCommand.Parameters.AddWithValue("@isInMem", LoadEngine.QueryFlag);
                        SqlParameter outParameter = new SqlParameter();
                        outParameter.ParameterName = "@TotalPrice";
                        outParameter.SqlDbType = System.Data.SqlDbType.Decimal;
                        outParameter.Direction = System.Data.ParameterDirection.Output;
                        sqlCommand.Parameters.Add(outParameter);
                        sqlCommand.ExecuteNonQuery();
                        totalValue = Math.Round((decimal)outParameter.Value, 2);
                        Thread.Sleep(0);
                        sw.Stop();
                    }
                    catch (Exception e)
                    {
                        outException = e;
                        if (sw.IsRunning)
                        {
                            sw.Stop();
                        }
                    }
                    finally
                    {
                        //Clean up the connection
                        conn.Close();
                        sqlCommand.Dispose();
                    }
                    outInfo.e = outException;
                    outInfo.time = sw.Elapsed;
                    outInfo.finished = true;
                    outInfo.TotalValue = totalValue;
                    lock (LoadEngine.queryOutQueue)
                    {
                        LoadEngine.queryOutQueue.Enqueue(outInfo);
                        Monitor.Pulse(LoadEngine.queryOutQueue);
                    }
                    sw.Reset();
                }
            }
            catch
            {
                throw;
            }
        }

    }
}