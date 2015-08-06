using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace TkMeta
{
    public class TkMetaSource
    {
        public string Path {get; private set;}

        public TkMetaSource(string path)
        {
            Path = path;
        }
    }
}
