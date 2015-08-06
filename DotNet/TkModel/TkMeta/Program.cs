using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Diagnostics;

namespace TkMeta
{
	class Program
	{
		static void Main (string[] args)
		{
			new Generate (@"/home/sp/Downloads/TelekursMetadata/",
						  @"/home/sp/Downloads/TelekursMetadata/FromFldSeg/");
		}
	}
}
