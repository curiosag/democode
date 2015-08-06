using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Diagnostics;

namespace TkMeta
{

    class CsFile
    {
        private StreamWriter writer = null;

        public CsFile(string path) {
            writer = new StreamWriter(path);
        }

        private string ind(int ind, string val) {
            var ret = val;
            foreach (int i in Enumerable.Range(1, ind))
                ret = "  " + ret;
            
            return ret;
        }

        public void emit(int indent, string val) {
            Debug.Assert(writer != null, "he!");
            writer.WriteLine(ind(indent, val));
        }

        public void flush() { 
            writer.Close();            
        }
    }
}
