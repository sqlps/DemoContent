using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Threading;
using System.Web;

namespace ElusionX.Web.Providers
{
    public class ThreadKiller
    {
        private Thread[] theThreads;
        private SqlCommand[] theCommands;

        public ThreadKiller(
            Thread[] TheThreads,
            SqlCommand[] TheCommands)
        {
            this.theThreads = TheThreads;
            this.theCommands = TheCommands;
        }

        public void KillEm()
        {
            foreach (SqlCommand comm in theCommands)
            {
                comm.Cancel();
                comm.Connection.Dispose();
                comm.Connection = null;
                comm.Dispose();
                Thread.Sleep(0);
            }

            bool keepKilling = true;

            while (keepKilling)
            {
                keepKilling = false;

                foreach (Thread theThread in theThreads)
                {
                    if (theThread.IsAlive)
                    {
                        keepKilling = true;
                        theThread.Abort();
                        Thread.Sleep(0);
                    }
                }
            }
        }
    }
}