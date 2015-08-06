using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Diagnostics;

namespace TkMeta
{

    public class TkMetaFld : TkMetaSource
    {
        // segment definitions come in this form:
        //
        // /* Release 210 - 20100913 */     ... version header
        // S CAD        ... S => CADS is segment identifier 
        // C K801       ... C => K801 is field group name
        // K 0803 N 3   ... ohterwise it is a field where name=0803 type=N maxLength=3
        // K 0808 X 20 
        // C K802       ... segments consist of several field groups
        // K 2801 X 8  
        //    
        // field names become the form <group name>"_"<field name>, e.g. K801_0803


        private const string cSegmentMarker = "S";
        private const string cFieldGroupMarker = "C";
        private Dictionary<string, string> mTypeMap;

        public TkMetaFld(string path)
            : base(path)
        {
            mTypeMap = new Dictionary<string, string>();
            mTypeMap.Add("X", "string");
            mTypeMap.Add("N", "int");
            mTypeMap.Add("A", "???");
        }

        private TkMetaRec DecodeRaw(string[] raw){
            Debug.Assert(raw != null, "param is null");
            Debug.Assert((raw.Count() == 2 || raw.Count() == 4), "invalid metadata format");

            string qualifier = raw[0];
            string name = raw[1];
            string typeCode = "";
            int maxLength = 0;
            int cardinality = 0;

            if (raw.Count() == 4)
            {
                typeCode = raw[2];                
                Debug.Assert(int.TryParse(raw[3], out maxLength), "Int conversion failed for: " + raw[3]);     
            }

            return new TkMetaRec(qualifier, name, typeCode, maxLength, cardinality);
        }

        public IEnumerable<TkMetaRec> MetaSegStruct()
        {
            return from s in Source().Slice(x => x.Qualifier != cSegmentMarker)
                   select s.WithSub(s.Sub.Slice(x => x.Qualifier != cFieldGroupMarker).ToArray());
        }

        private IEnumerable<TkMetaRec> Source()
        {
            return from line in File.ReadAllLines(Path).Skip(1)
                   select DecodeRaw(line.Trim().Split(Const.symSeparator).ToArray());
        }

        private string ToType(string typeCode)
        {            
            try
            {
                return mTypeMap[typeCode];
            }
            catch {
                return "strange typeCode:" + typeCode;
            }
        }

        public IEnumerable<TypeDescription> SequenceDefs()
        {
            foreach (TkMetaRec segment in MetaSegStruct())
            {
                List<MemberDescription> members = new List<MemberDescription>();
                foreach (TkMetaRec group in segment.Sub)
                {
                    foreach (TkMetaRec basePart in group.Sub)
                    {
                        members.Add(new MemberDescription(group.Name + '_' + basePart.Name, 1, 1, new TypeDescription(ToType(basePart.TypeCode), 0, basePart.MaxLength, null)));
                    }
                }
                yield return new TypeDescription("S_" + segment.Name, 0, 0, members);
            }
        }

    }

}
