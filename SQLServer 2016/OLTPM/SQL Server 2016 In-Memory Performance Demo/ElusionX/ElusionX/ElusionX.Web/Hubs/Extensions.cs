using System.Globalization;

namespace ElusionX.Web.Hubs
{
    public static class Exentions
    {
        public static string ToMillion(this decimal num)
        {
            //Console.WriteLine(value.ToString("#,##0,,,B", CultureInfo.InvariantCulture));
            // Displays 1B
            //return string.Format("{0:C}", num);
            return num.ToString("#,##0,,M", CultureInfo.InvariantCulture);
        }

        public static string ToBillion(this decimal num)
        {
            // Displays 1B
            return string.Format(num.ToString("#,##0,,,B", CultureInfo.InvariantCulture));
        }

        public static string ToThousand(this decimal num)
        {
            return num.ToString("#,##0,K", CultureInfo.InvariantCulture);
        }

        public static string ToCurrency(this decimal num)
        {
            return string.Format("{0:C0}", decimal.Round(num, 0));
        }
    }
}