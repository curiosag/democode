using System;
using System.Collections.Generic;
using TkMeta.TkBaseTypes;

namespace TkMeta
{

	public class S_MGG_3 {
		public string segQual { get; set; }
		public int funNo { get; set; }
	}

	public class S_VAK {
		public string segQual { get; set; }
		public string langSchemeID { get; set; }
		public string lang { get; set; }
	}

	public class S_HEAD {
		public string segQual { get; set; }
		public TkDate date { get; set; }
		public TkTime time { get; set; }
		public int docOnlGenNo { get; set; }
	}


	public class S_XUI {
		public string segQual { get; set; }
		public int funNo { get; set; }
	}

	public class S_XRM {
		public string segQual { get; set; }
		public int funNo { get; set; }
		public int refDogType { get; set; }
		public int lasVegas { get; set; }
	}


	public class S_XRL {
		public string segQual { get; set; }
		public int funNo { get; set; }
		public TkDate dateFrom { get; set; }
		public TkDate dateTo { get; set; }
	}
		
	public class S_XRK {
		public string segQual { get; set; }
	}

	public class S_MGG {
		public string segQual { get; set; }
		public int funNo { get; set; }
	}

	public class S_FQI {
		public string segQual { get; set; }
		public int cowNr { get; set; }
	}

	public class S_VAI {
		public string zmbNr { get; set; }
	}


	public class S_FMG {
		public string fozSchemeType { get; set; }
	}

	public class S_XCU {
		public int combLox { get; set; }
	}

	public class S_XAB_3 {
		public int annmntStatus { get; set; }
	}

}
