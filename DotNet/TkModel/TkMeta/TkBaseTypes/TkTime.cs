using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace TkMeta.TkBaseTypes
{
    public class TkTime
    {
        public UInt16 Raw { get; set; }
        public DateTime Default { get; private set; }
        public DateTime Val { get; private set; }
    }
}
