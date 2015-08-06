using System;
using System.Collections.Generic;
using System.Linq;
using System.IO;
using System.Text;
using System.Diagnostics;

namespace TkMeta
{
	public class TkMetaSeg : TkMetaSource
	{
		// Doc definitions come in the form
		//
		// CAD  0 1    --> 0 ... level, 0 => root
		// GEI  1 1    --> 1 ... multiplicity 1 (kein old/new, wäre 2)
		// MGG  2 1
		// MGA  3 2
		// GEK  3 6
		// ...

		public TkMetaSeg (string path)
			: base (path)
		{
		}

		private TkMetaRec DecodeRaw (string[] raw)
		{
			Debug.Assert (raw != null, "param is null");
			Debug.Assert ((raw.Count () >= 2 && raw.Count () <= 3), "invalid metadata format");

			string qualifier = raw [1];
			string name = raw [0];
			string typeCode = "";
			int maxLength = 0;
			int cardinality = 0;

			if (raw.Count () == 3) 
				Debug.Assert (int.TryParse (raw [2], out cardinality), "Int conversion failed for: " + raw [2]);

			return new TkMetaRec (qualifier, name, typeCode, maxLength, cardinality);
		}

		private IEnumerable<TkMetaRec> Source ()
		{
			return from line in File.ReadAllLines (Path).Skip (1)
			       select DecodeRaw (line.Trim ().Replace ("  ", " ").Split (Const.symSeparator).ToArray ());
		}

		private TkMetaRec[] AsArray (IEnumerable<TkMetaRec> recs)
		{
			if (recs == null) 
				return null;
			
			return recs.ToArray ();
		}

		private IEnumerable<TkMetaRec> DocStructure (int level, IEnumerable<TkMetaRec> raw)
		{
			if (raw.Count () == 0) 
				return null;

			return from elem in raw.Slice (x => x.Qualifier != level.ToString ())
			       select elem.WithSub (AsArray (DocStructure (level + 1, elem.Sub)));
		}

		public IEnumerable<TkMetaRec> DocStructure ()
		{
			return DocStructure (0, Source ());
		}

		private string GenTypeName (string elementName, int level, string path)
		{
			if (level == 0)
				return elementName;
			else
				return "G_" + path + elementName;
		}

		private IEnumerable<MemberDescription> GenMembers (TkMetaRec superTypeDef, int level)
		{
			Debug.Assert (superTypeDef.Sub != null);
			List<MemberDescription> members = new List<MemberDescription> ();
			if (level == 0)
				members.Add (new MemberDescription ("HEADER", 1, 1, new TypeDescription ("S_" + superTypeDef.Name, 0, 0, null)));

			foreach (TkMetaRec m in superTypeDef.Sub)
				members.Add (new MemberDescription (m.Name, 0, m.Cardinality, new TypeDescription ("S_" + m.Name, 0, 0, null)));

			return members;
		}

		private IEnumerable<TypeDescription> GenTypes (IEnumerable<TkMetaRec> typeDefs, int level, string path)
		{
			foreach (TkMetaRec typeDef in typeDefs)
				if (typeDef.Sub != null) {
					foreach (TypeDescription t in GenTypes (typeDef.Sub, level + 1, path + typeDef.Name + "_"))
						yield return t;

					yield return (new TypeDescription (GenTypeName (typeDef.Name, level, path), 0, 0, GenMembers (typeDef, 0)));
				}
		}

		public IEnumerable<TypeDescription> DocDefs ()
		{
			return GenTypes (DocStructure (), 0, "");
		}

	}
}
