using ElusionX.Web.Models;
using System;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Threading;

namespace ElusionX.Web.Providers
{
    public class RTOAThread
    {
        [ThreadStatic]
        private static QueryOutput outInfo;
        private static bool runCancelled;
        private SqlCommand sqlCommand;
        private int numberOfOrders;
        private Stopwatch sw = new Stopwatch();
        private string QueryType;

        public static bool RunCancelled
        {
            set
            {
                runCancelled = value;
            }
        }

        public RTOAThread(int numberOfOrders, SqlCommand sqlCommand, string queryType)
        {
            this.numberOfOrders = numberOfOrders;
            this.sqlCommand = sqlCommand;
            this.QueryType = queryType;
        }

        public void startLoadThread()
        {
            try
            {
                Exception outException = null;
                int result = 0;
                using (SqlConnection conn = sqlCommand.Connection)
                {
                    RTOAThread.outInfo = new QueryOutput();
                    conn.Open();
                    sqlCommand.Parameters.AddWithValue("@batchSize", this.numberOfOrders);
                    try
                    {
                        sqlCommand.Parameters.AddWithValue("@isCS", QueryType == "OLTP" ? 0 : 1);
                        SqlParameter outParameter = new SqlParameter();
                        outParameter.ParameterName = "@TotalPrice";
                        outParameter.SqlDbType = System.Data.SqlDbType.Decimal;
                        outParameter.Direction = System.Data.ParameterDirection.Output;
                        sqlCommand.Parameters.Add(outParameter);
                        sw.Start();
                        result = sqlCommand.ExecuteNonQuery();
                    }
                    catch (Exception ex)
                    {
                        outException = ex;
                        if (sw.IsRunning)
                        {
                            sw.Stop();
                        }
                    }
                    finally
                    {
                        conn.Close();
                        sqlCommand.Dispose();
                    }
                    outInfo.e = outException;
                    outInfo.time = sw.Elapsed;
                    outInfo.finished = true;
                    outInfo.TotalValue = result;
                    lock (RTOALoadEngine.queryOutQueue)
                    {
                        RTOALoadEngine.queryOutQueue.Enqueue(outInfo);
                        Monitor.Pulse(RTOALoadEngine.queryOutQueue);
                    }
                }
            }
            catch
            {
                throw;
            }
        }

    }
}