using System;
using System.Collections.Generic;
using TkMeta.TkBaseTypes;

namespace TkMeta_FromMetaFld
{

  public class G_CAD_GEI_MGG {
    public S_MGG HEADER { get; set; }
    public S_MGA MGA { get; set; }
    public List<S_GEK> GEK { get; set; }
    public S_CAA CAA { get; set; }
    public List<S_REF> REF { get; set; }
    public List<S_TXN> TXN { get; set; }
    public List<S_TQU> TQU { get; set; }
    public S_TKO TKO { get; set; }
  }
  
  public class G_CAD_GEI {
    public S_GEI HEADER { get; set; }
    public S_MGG MGG { get; set; }
  }
  
  public class CAD {
    public S_CAD HEADER { get; set; }
    public S_GEI GEI { get; set; }
  }
 
//	....

}
