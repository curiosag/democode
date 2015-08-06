using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace TkMeta.TkBaseTypes
{
    public class TkDateTime
    {
        private long mRaw = long.MinValue;
        private DateTime mVal = Default;

        public long Raw
        {
            get { return mRaw; }            
            set                            
            {
                mRaw = value;
                DateTime.TryParse(Raw.ToString(), out mVal);
            }
        }

        public static DateTime Default { get { return DateTime.MinValue; } }

        public DateTime Val
        {
            get
            {
                return mVal;
            }
        }      

    }
}
