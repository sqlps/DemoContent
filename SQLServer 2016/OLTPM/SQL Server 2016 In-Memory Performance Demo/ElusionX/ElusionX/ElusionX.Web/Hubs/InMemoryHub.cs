using ElusionX.Web.Models;
using Microsoft.AspNet.SignalR;

namespace ElusionX.Web.Hubs
{
    public class InMemoryHub : Hub
    {
        private readonly InMemoryTicker messageTicker;
        public InMemoryHub() : this(InMemoryTicker.Instance) { }
        public InMemoryHub(InMemoryTicker messageTicker)
        {
            this.messageTicker = messageTicker;
        }

        public TechnicalMetrics GetTechnicalMetrics()
        {
            return messageTicker.GetTechnicalMetrics();
        }

        public LoadMetrics GetLoadMetrics()
        {
            return messageTicker.GetLoadMetrics();
        }

        public BusinessMetrics GetBusinessMetrics()
        {
            return messageTicker.GetBusinessMetrics();
        }
    }
}