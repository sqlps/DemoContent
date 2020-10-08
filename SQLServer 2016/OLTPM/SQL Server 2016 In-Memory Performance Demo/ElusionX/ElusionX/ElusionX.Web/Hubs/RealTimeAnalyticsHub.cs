using Microsoft.AspNet.SignalR;

namespace ElusionX.Web.Hubs
{
    public class RealTimeAnalyticsHub : Hub
    {
        private readonly RealTimeAnalyticsTicker realTimeAnalyticsTicker;

        public RealTimeAnalyticsHub() : this(RealTimeAnalyticsTicker.Instance) { }

        public RealTimeAnalyticsHub(RealTimeAnalyticsTicker messageTicker)
        {
            this.realTimeAnalyticsTicker = messageTicker;
        }
    }

   
}


