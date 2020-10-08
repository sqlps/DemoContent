using ElusionX.Web.DataModel;
using ElusionX.Web.Models;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Configuration;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using System.Web;

namespace ElusionX.Web.Providers
{
    public class RTOALoadEngine
    {
        private string connectionString;
        public readonly string query;
        public int Users;
        public static int Iterations;
        public static int NumberOfOrders;
        public static string QueryType;
        public static List<Thread> taskPool;
        public static Queue<QueryOutput> queryOutQueue = new Queue<QueryOutput>();

        public RTOALoadEngine(
                    int users,
                    int iterations,
                    int numberOfOrders,
                    string queryType)
        {
            connectionString = ConfigurationManager.ConnectionStrings["oadbconnection_oltp"].ToString();
            SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder(connectionString);
            builder.MinPoolSize = users * iterations;
            builder.MaxPoolSize = users * iterations;
            this.connectionString = builder.ConnectionString;
            Users = users;
            QueryType = queryType;
            NumberOfOrders = numberOfOrders;
            Iterations = iterations;
            taskPool = new List<Thread>();
        }

        public void StartLoad()
        {
            KillThreads();
            taskPool.Clear();
            queryOutQueue.Clear();
            SqlConnection sqlConnection;
            sqlConnection = new SqlConnection(this.connectionString);
            try
            {
                SqlConnection.ClearPool(sqlConnection);
                sqlConnection.Open();
                sqlConnection.Dispose();
                for (int j = 0; j < Users; j++)
                {
                    for (int i = 0; i < Iterations; i++)
                    {
                        sqlConnection = new SqlConnection(this.connectionString);
                        SqlCommand sqlCommand = new SqlCommand();
                        sqlCommand.Connection = sqlConnection;
                        sqlCommand.CommandTimeout = 120;
                        sqlCommand.CommandType = System.Data.CommandType.StoredProcedure;
                        sqlCommand.CommandText = "dbo.GenerateOrders";
                        RTOAThread threadInput = new RTOAThread(NumberOfOrders, sqlCommand, QueryType);
                        Thread thread = new Thread(new ThreadStart(threadInput.startLoadThread));
                        thread.Priority = ThreadPriority.BelowNormal;
                        taskPool.Add(thread);
                    }
                }
                int sleepCounter = 0;
                foreach (var task in taskPool)
                {
                    task.Start();
                    ++sleepCounter;
                    if (sleepCounter == 200)
                    {
                        Thread.Sleep(3000);
                        sleepCounter = 0;
                    }
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
            finally
            {
                //sqlConnection.Dispose();
            }
        }

        private void KillThreads()
        {
            foreach (var thread in taskPool)
            {
                thread.Abort();
            }
            foreach (Thread theThread in taskPool)
            {
                theThread.Join();
            }
        }
    }
}





