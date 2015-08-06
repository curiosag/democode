using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace TkMeta.TkBaseTypes
{
    public class TkDate
    {
        public UInt16 Raw { get; set; }

        public static DateTime Default {
            get
            {
                return DateTime.Parse("?");
            }
        }

        public DateTime Val {
            get{
                DateTime t = Default;
                if (DateTime.TryParse(Raw.ToString(), out t)) {
                    return t;
                }
                else 
                {
                    return Default;
                }
            }
        }
    }

}
