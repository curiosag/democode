using System;
using System.Collections.Generic;
using TkMeta.TkBaseTypes;

namespace TkMeta
{


	public class XRD {
		public S_HEAD HEADER { get; set; }
		public G_XRD_VAI VAI { get; set; }
		public static List<XRD> Docs;
	}

	public class G_XUD_XUI {
		public S_XUI HEADER { get; set; }
		public S_XCU XCU { get; set; }
	}

	public class XUD {
		public S_HEAD HEADER { get; set; }
		public G_XUD_XUI XUI { get; set; }
		public static List<XUD> Docs;
	}

	public class G_FAD_VAI {
		public S_VAI HEADER { get; set; }
		public List<S_FMG> FMG { get; set; }
	}

	public class FAD {
		public S_HEAD HEADER { get; set; }
		public G_FAD_VAI VAI { get; set; }
		public static List<FAD> Docs;
	}
		
	public class G_FZD_VAI {
		public S_VAI HEADER { get; set; }
	}

	public class FZD {
		public S_HEAD HEADER { get; set; }
		public G_FZD_VAI VAI { get; set; }
		public static List<FZD> Docs;
	}

	public class G_XRD_VAI_MGG_XAB {
		public S_XAB_3 HEADER { get; set; }
	}
		
	public class G_XRD_VAI_MGG_XRK_XRL_XRM {
		public S_XRM HEADER { get; set; }
	}

	public class G_XRD_VAI_MGG_XRK_XRL {
		public S_XRL HEADER { get; set; }
		public List<G_XRD_VAI_MGG_XRK_XRL_XRM> XRM { get; set; }
	}

	public class G_XRD_VAI_MGG_XRK {
		public S_XRK HEADER { get; set; }
		public List<G_XRD_VAI_MGG_XRK_XRL> XRL { get; set; }
	}
		
	public class G_XRD_VAI_MGG {
		public List<S_VAK> VAK { get; set; }
		public G_XRD_VAI_MGG_XAB XAB { get; set; }
		public G_XRD_VAI_MGG_XRK XRK { get; set; }

	}

	public class G_XRD_VAI {
		public S_VAI HEADER { get; set; }
		public G_XRD_VAI_MGG MGG { get; set; }
	}

	public class G_FQD_VAI_MGG_FQI_VAI {
		public S_VAI HEADER { get; set; }
	}

	public class G_FQD_VAI_MGG_FQI {
		public S_FQI HEADER { get; set; }
		public List<G_FQD_VAI_MGG_FQI_VAI> VAI { get; set; }
	}

	public class G_FQD_VAI_MGG {
		public S_MGG_3 HEADER { get; set; }
		public G_FQD_VAI_MGG_FQI FQI { get; set; }
	}

	public class G_FQD_VAI {
		public S_VAI HEADER { get; set; }
		public G_FQD_VAI_MGG MGG { get; set; }
	}

	public class FQD {
		public S_HEAD HEADER { get; set; }
		public G_FQD_VAI VAI { get; set; }
		public static List<FQD> Docs;
	}
}
		