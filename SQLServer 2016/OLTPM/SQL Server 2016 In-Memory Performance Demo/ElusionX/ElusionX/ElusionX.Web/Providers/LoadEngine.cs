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
using System.Web;

namespace ElusionX.Web.Providers
{
    public class LoadEngine
    {
        public static Queue<QueryOutput> queryOutQueue = new Queue<QueryOutput>();
        private readonly string connectionString;
        public readonly string query;
        public static int Users;
        public static List<Thread> usersThreadPool = new List<Thread>();
        public static List<SqlCommand> commandPool = new List<SqlCommand>();
        private readonly int commandTimeout;
        private readonly bool collectIOStats;
        private readonly bool collectTimeStats;
        private readonly bool forceDataRetrieval;
        public static DateTime loadEngineStartTime;
        public static DateTime loadEngineEndTime;
        public static int OrderCount;
        public static int QueryFlag;

        public LoadEngine(
                    int users,
                    int orderCount,
                    int queryFlag,
                    int commandTimeout,
                    string query,
                    bool collectIOStats,
                    bool collectTimeStats,
                    bool forceDataRetrieval)
        {
            connectionString = ConfigurationManager.ConnectionStrings["proddbconnection"].ToString();
            //Set the min pool size so that the pool does not have to get allocated in real-time
            SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder(connectionString);
            builder.MinPoolSize = users;
            builder.MaxPoolSize = users;
            this.connectionString = builder.ConnectionString;
            Users = users;
            this.query = query;
            QueryFlag = queryFlag;
            OrderCount = orderCount;
            this.commandTimeout = commandTimeout;
            this.collectIOStats = collectIOStats;
            this.collectTimeStats = collectTimeStats;
            this.forceDataRetrieval = forceDataRetrieval;
        }

        public void StartLoad()
        {
            CancelThreads();
            usersThreadPool.Clear();
            queryOutQueue.Clear();
            //Initialize the connection pool            
            SqlConnection sqlConnection = new SqlConnection(this.connectionString);
            SqlConnection.ClearPool(sqlConnection);
            sqlConnection.Open();
            //just to ensure all connections are disposed before creating a new one
            sqlConnection.Dispose();
            ApplicationConfiguration appConfig = null;
            using (var appConfigContext = new ElusionX_ProdDBEntities())
            {
                appConfig = appConfigContext.ApplicationConfiguration.FirstOrDefault();
            }
            //make sure the run cancelled flag is not set
            QueryInput.RunCancelled = false;
            var perc = new SQLProvider().GenerateRandomNumber();
            var percValue = ((double)perc / 100) * Users;
            Debug.WriteLine("Number users for low timeout: " + percValue);
            int minThreads = 0;
            //Spin up the load threads
            for (int i = 0; i < Users; i++)
            {
                sqlConnection = new SqlConnection(this.connectionString);
                SqlCommand statisticsCommand = null;
                SqlCommand sqlCommand = new SqlCommand();
                if (minThreads < percValue)
                {
                    sqlCommand.CommandTimeout = appConfig.MinCommandTimeOut;
                    ++minThreads;
                }
                else
                {
                    sqlCommand.CommandTimeout = appConfig.MaxCommandTimeOut;
                }
                sqlCommand.Connection = sqlConnection;
                sqlCommand.CommandText = this.query;

                string setStatistics =
                    ((collectIOStats) ? (@"SET STATISTICS IO ON;") : ("")) +
                    ((collectTimeStats) ? (@"SET STATISTICS TIME ON;") : (""));

                if (setStatistics.Length > 0)
                {
                    statisticsCommand = new SqlCommand();
                    statisticsCommand.CommandTimeout = this.commandTimeout;
                    statisticsCommand.Connection = sqlConnection;
                    statisticsCommand.CommandText = setStatistics;
                }

                QueryInput input = new QueryInput(statisticsCommand, sqlCommand, OrderCount);
                Thread theThread = new Thread(new ThreadStart(input.startLoadThread));
                theThread.Priority = ThreadPriority.BelowNormal;
                usersThreadPool.Add(theThread);
                commandPool.Add(sqlCommand);
            }

            loadEngineStartTime = DateTime.UtcNow;

            //Start the load threads
            for (int i = 0; i < Users; i++)
            {
                if (usersThreadPool.Count == Users)
                {
                    usersThreadPool[i].Start();
                }
            }

        }

        public void CancelThreads()
        {
            QueryInput.RunCancelled = true;
            //First, kill connections as fast as possible
            SqlConnection.ClearAllPools();
            //for each 20 threads, create a new thread dedicated
            //to killing them
            int threadNum = usersThreadPool.Count;
            List<Thread> killerThreads = new List<Thread>();
            while (threadNum > 0)
            {
                int i = (threadNum <= 20) ? 0 : (threadNum - 20);
                Thread[] killThreads = new Thread[((threadNum - i) < 1) ? threadNum : (threadNum - i)];
                SqlCommand[] killCommands = new SqlCommand[((threadNum - i) < 1) ? threadNum : (threadNum - i)];
                usersThreadPool.CopyTo(i, killThreads, 0, killThreads.Length);
                commandPool.CopyTo(i, killCommands, 0, killCommands.Length);
                for (int j = (threadNum - 1); j >= i; j--)
                {
                    usersThreadPool.RemoveAt(j);
                    commandPool.RemoveAt(j);
                }
                ThreadKiller kill = new ThreadKiller(killThreads, killCommands);
                Thread killer = new Thread(new ThreadStart(kill.KillEm));
                killer.Start();
                Thread.Sleep(0);
                killerThreads.Add(killer);
                threadNum = i;
            }
            //wait for the kill threads to return
            //before exiting...
            foreach (Thread theThread in killerThreads)
            {
                theThread.Join();
            }
        }

    }
}





