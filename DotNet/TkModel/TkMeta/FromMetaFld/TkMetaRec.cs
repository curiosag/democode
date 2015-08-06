using System;
using System.Collections.Generic;

namespace TkMeta
{
    public class TkMetaRec
    {
        public string Qualifier { get; private set; }
        public string Name { get; private set; }
        public string TypeCode { get; private set; }
        public int MaxLength { get; private set; }
        public int Cardinality { get; private set; }
        public TkMetaRec[] Sub { get; private set; }

        public TkMetaRec(string qualifier, string name, string typeCode, int maxLength, int cardinality)
        {
            Qualifier = qualifier;
            Name = name;
            TypeCode = typeCode;
            MaxLength = maxLength;
            Cardinality = cardinality;
        }

        public TkMetaRec WithSub(TkMetaRec[] sub)
        {
            Sub = sub;
            return this;
        }
    }

}
