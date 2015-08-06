using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace TkMeta
{
    public class TypeDescription
    {
        public string Name { get; set; }
        public int SequenceNumber { get; set; }
        public int MaxLength { get; set; }
        public bool IsReferenced { get; set; }
        public IEnumerable<MemberDescription> Members { get; set; }

        public TypeDescription(string name, int sequence_number, int maxLength, IEnumerable<MemberDescription> members)
        {
            this.Name = name;
            this.SequenceNumber = sequence_number;
            this.MaxLength = maxLength;
            this.Members = members;
        }
    }
}
