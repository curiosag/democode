using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml.Linq;
using System.Xml;
using System.Xml.XPath;
using System.Diagnostics;

namespace TkMeta
{

    public class TkXsd : TkMetaSource
    {

        private string url_nsxsd = "http://www.w3.org/2001/XMLSchema";
        private XNamespace nsXsd = "http://www.w3.org/2001/XMLSchema";

        public TkXsd(string path)
            : base(path){
        }

        private XElement root()
        {
            return XElement.Load(Path);
        }

        private IEnumerable<XElement> baseElements(XNamespace xsd)
        {
            return from e in root().Elements()
                   where e.Element(xsd + "attributeGroup") != null
                   select e;
        }

        private XElement Shrink(XNode node)
        {
            XElement element = node as XElement;

            if (element == null)
            {
                return element;
            }

            if (element.FirstNode != null)
            {
                if ((element.FirstNode as XElement).Name.LocalName == "complexType")
                {
                    return new XElement(element.Name,
                                element.Attributes(),
                                ((element.FirstNode as XElement).FirstNode as XElement).Nodes().Select(n => Shrink(n)));
                }
            }

            return new XElement(element.Name,
                                element.Attributes(),
                                element.Nodes().Select(n => Shrink(n)));

        }

        public string SeqNameFromSource(string seqId)
        {
            return seqId.Replace("SegType", "S").Replace("_1", "");
        }

        private List<MemberDescription> AddSomeMembers(IEnumerable<MemberDescription> members)
        {
            List<MemberDescription> result = new List<MemberDescription>();

            result.Add(new MemberDescription("segQual", 1, 1, new TypeDescription("string", 0, 1, null)));
            result.AddRange(members);
            return result;
        }

        public IEnumerable<TypeDescription> SequenceDefs()
        {
            Dictionary<string, string> type_map = new Dictionary<string, string>();

            type_map.Add("xsd:date", "TkDate");
            type_map.Add("xsd:time", "TkTime");
            type_map.Add("xsd:dateTime", "TkDateTime");
            type_map.Add("xsd:gMonthDay", "TkMonthDay");
            type_map.Add("xsd:integer", "int");
            type_map.Add("xsd:decimal", "double");
            type_map.Add("xsd:string", "string");

            var types = from e in
                            (from e in baseElements(nsXsd)
                             where e.Element(nsXsd + "attributeGroup").FirstAttribute.Value.StartsWith("AttrGrpField")
                             select e)
                        let item = e.Element(nsXsd + "sequence").Element(nsXsd + "element")
                        where item.Attribute("name").Value == "v"
                        select new
                        {
                            name = e.FirstAttribute.Value,
                            type = type_map[item.Attribute("type").Value]
                        };



            return from e in
                       (from e in baseElements(nsXsd)
                        where e.Element(nsXsd + "attributeGroup").FirstAttribute.Value.StartsWith("AttrGrpSegment")
                        select e)
                   let fields = e.Element(nsXsd + "sequence").Elements()
                   let fieldlist = from f in fields
                                   join t in types on f.Attribute("type").Value equals t.name
                                   select new MemberDescription(f.Attribute("name").Value, 1, 1, new TypeDescription(t.type, 0, 0, null))                   
                   select new TypeDescription(SeqNameFromSource(e.Attribute("name").Value), 0, 0, AddSomeMembers(fieldlist));
        }

        public IEnumerable<XElement> XmlDocs()
        {

            XmlNamespaceManager nsMgr = new XmlNamespaceManager(new NameTable());
            nsMgr.AddNamespace("xsd", url_nsxsd);

            var docs = from e in
                           (from e in baseElements(nsXsd)
                            where e.Element(nsXsd + "attributeGroup").FirstAttribute.Value.StartsWith("AttrGrpDoc")
                            select e)
                       select e.XPathSelectElements("./xsd:sequence/xsd:element", nsMgr);

            return from d in docs
                   select Shrink(d.First());

        }

        private int Cardinality(XAttribute numericAttribute)
        {
            if (numericAttribute == null)
            {
                return 1;
            }

            if (numericAttribute.Value == "unbounded")
            {
                return int.MaxValue;
            }
            return int.Parse(numericAttribute.Value);

        }

        private int MaxOccurs(XElement e)
        {
            Debug.Assert(e != null);
            return Cardinality(e.Attribute("maxOccurs"));
        }

        private int MinOccurs(XElement e)
        {
            Debug.Assert(e != null);
            return Cardinality(e.Attribute("minOccurs"));
        }

        private bool IsGroup(XElement e)
        {
            Debug.Assert(e != null);
            return e.Attribute("name").Value.StartsWith("G-");
        }

        private bool IsSequence(string name)
        {
            return name.StartsWith("SegType_");
        }

        private string ToIdentifier(string groupName)
        {
            Debug.Assert(groupName != null);
            return groupName.Replace('.', '_').Replace('-', '_');
        }

        private string GetTypeName(XElement e)
        {
            Debug.Assert(e != null);
            if (IsGroup(e))
            {
                var name = ToIdentifier(e.Attribute("name").Value);
                if (name.Split('_').Length > 2)
                {
                    return name;
                }
                else
                {
                    return name.Split('_').Last();
                }
            }
            Debug.Assert(e.Attribute("type") != null);

            if (IsSequence(e.Attribute("type").Value)){
                return SeqNameFromSource(e.Attribute("type").Value);
            }                

            return e.Attribute("type").Value;
        }

        private string GetMemberName(XElement e)
        {
            Debug.Assert(e != null);
            if (IsGroup(e))
            {
                return ToIdentifier(e.Attribute("name").Value).Split('_').Last();
            }

            return e.Attribute("name").Value;
        }

        private IEnumerable<TypeDescription> ExtractGroups(XElement e, Dictionary<string, TypeDescription> seqDefs)
        {
            Debug.Assert(e != null);
            Debug.Assert(seqDefs != null);

            List<TypeDescription> result = new List<TypeDescription>();

            if (IsGroup(e))
            {
                List<MemberDescription> members = new List<MemberDescription>();

                foreach (XElement c in e.Elements())
                {
                    result.AddRange(ExtractGroups(c, seqDefs));

                    if (MinOccurs(c) == 1 && MaxOccurs(c) == 1 && !IsGroup(c))
                    {
                        members.Add(new MemberDescription("HEADER",
                                                   MinOccurs(c),
                                                   MaxOccurs(c),
                                                   new TypeDescription(GetTypeName(c), 0, 0, null)));
                    }
                    else
                    {
                     members.Add(new MemberDescription(GetMemberName(c),
                                                   MinOccurs(c),
                                                   MaxOccurs(c),
                                                   new TypeDescription(GetTypeName(c), 0, 0, null)));
                    }

                }
                result.Add(new TypeDescription(GetTypeName(e), 0, 0, members));

            }
            return result;
        }

        public IEnumerable<TypeDescription> DocDefs()
        {
            Dictionary<string, TypeDescription> seqDefs = SequenceDefs().ToDictionary(s => s.Name, s => s);
            List<TypeDescription> docdefs = new List<TypeDescription>();

            foreach (XElement d in XmlDocs())
            {
                docdefs.AddRange(ExtractGroups(d, seqDefs));
            }
            return docdefs;
        }
    }

}
