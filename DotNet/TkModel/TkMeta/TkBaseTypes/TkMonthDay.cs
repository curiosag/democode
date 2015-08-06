using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace TkMeta.TkBaseTypes
{

    public class TkMonthDay
    {

        public uint Raw { get; set; }

        private TkMonthDayTuple mDefault = new TkMonthDayTuple(0, 0);

        public static TkMonthDayTuple Default
        {
            get
            {
                return Default;
            }
        }

        public TkMonthDayTuple Val
        {
            get
            {
                return Default;
            }
        }

        public UInt16 Month
        {
            get
            {
                return Default.Month;
            }
        }

        public UInt16 Day
        {
            get
            {
                return Default.Day;
            }
        }

    }
}
