using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace TkMeta
{
	public class Generate
	{

		public Generate (string source, string targetDir)
		{
			CsFile SegmentFile = new CsFile (targetDir + "Seg.cs");
			CsFile DocFile = new CsFile (targetDir + "Doc.cs");

			if (source.EndsWith (".meta.xsd")) {
				GenCs (new TkXsd (source).SequenceDefs (), SegmentFile);
				GenCs (new TkXsd (source).DocDefs (), DocFile);
			} else {
				GenCs (new TkMetaFld (source + "MetaFld").SequenceDefs (), SegmentFile);
				GenCs (new TkMetaSeg (source + "MetaSeg").DocDefs (), DocFile);
			}
		}

		private void GenCs (IEnumerable<TypeDescription> source, CsFile target)
		{
			target.emit (0, "using System;");
			target.emit (0, "using System.Collections.Generic;");
			target.emit (0, "using TkMeta.TkBaseTypes;");
			target.emit (0, "");
			target.emit (0, "namespace TkMeta");
			target.emit (0, "{");
			target.emit (0, "");

			GenClasses (source, target);

			target.emit (0, "");
			target.emit (0, "}");
			target.flush ();
		}

		private void GenClasses (IEnumerable<TypeDescription> source, CsFile target)
		{ 
			foreach (TypeDescription typeDef in source) 
				GenClass (typeDef, target);        
		}

		private void GenClass (TypeDescription t, CsFile target)
		{
			Console.WriteLine ("create class " + t.Name);
            
			target.emit (1, "public class " + t.Name + " {");

			foreach (MemberDescription m in t.Members) 
				GenMember (m, target);

			target.emit (1, "}");
			target.emit (1, "");
		}

		private string OfCardinality (MemberDescription m)
		{
			if (m.MaxOccurs > 1) 
				return "List<" + m.Type.Name + "> ";
			
			return m.Type.Name + " ";            
		}

		private string Head2Upper (string s)
		{
			//perhaps better to break coding convention and stick with provider and not to use this function
			return s.Substring (0, 1).ToUpper () + s.Substring (1);
		}

		private string ResolveKeywords (string w)
		{
			if (w == "class") 
				return "@class";

			return w;
		}

		private void GenMember (MemberDescription m, CsFile target)
		{
			target.emit (2, "public " + OfCardinality (m) + ResolveKeywords (m.Name) + " { get; set; }");
		}

	}


}
