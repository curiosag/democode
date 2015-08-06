using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace TkMeta
{

    public class MemberDescription
    {
        public string Name {get; set;}
        public int MinOccurs { get; set; }
        public int MaxOccurs { get; set; }
        public TypeDescription Type { get; set; }

        public MemberDescription(string name, int minOccurs, int maxOccurs, TypeDescription type) 
        {
            this.Name = name;
            this.MinOccurs = minOccurs;
            this.MaxOccurs = maxOccurs;
            this.Type = type;
        }
    }


}
