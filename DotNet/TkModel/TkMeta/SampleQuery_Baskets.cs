using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace TkMeta
{
	class SampleQuery_Baskets
	{
		private string mapVal (string id, int val)
		{
			return val.ToString ();
		}

		private void q (string valor)
		{

			var q = from FQD fqd in FQD.Docs
			                 join xrd_flat in
			                     (from XRD _xrd in XRD.Docs
			                      from _xrl in _xrd.VAI.MGG.XRK.XRL
			                      from _xrm in _xrl.XRM
			                      select new { xrd = _xrd, xrl = _xrl, xrm = _xrm }) on fqd.VAI.HEADER.zmbNr equals xrd_flat.xrd.VAI.HEADER.zmbNr
			                 join FZD fzd in FZD.Docs on fqd.VAI.HEADER.zmbNr equals fzd.VAI.HEADER.zmbNr
			                 join fad_flat in
			                     (from FAD _fad in FAD.Docs
			                      from _fmg in _fad.VAI.FMG
			                      select new { fad = _fad, fmg = _fmg })
                        on fqd.VAI.HEADER.zmbNr equals fad_flat.fad.VAI.HEADER.zmbNr
			                 join XUD xud in XUD.Docs on xrd_flat.xrm.HEADER.funNo equals xud.XUI.HEADER.funNo
			                 where fqd.VAI.HEADER.zmbNr == valor
			                     && (fad_flat.fmg.fozSchemeType == "TOK" &&
			                     (new int[] { 4, 1, 14, 38 }.Any (x => x == xud.XUI.XCU.combLox) &&
			                     (xrd_flat.xrd.VAI.MGG.XAB.HEADER.annmntStatus == 7 ||
			                     xrd_flat.xrd.VAI.MGG.XAB.HEADER.annmntStatus == 2) &&
			                     fqd.VAI.MGG.FQI.VAI.Any (x => !string.IsNullOrEmpty (x.HEADER.zmbNr)) &&
			                     fqd.VAI.MGG.FQI.HEADER.cowNr == 11))
			                 let barrType = xrd_flat.xrm.HEADER.refDogType
			                 select new
                    {
                        valor = fqd.VAI.HEADER.zmbNr,
                        paymentStatus = xrd_flat.xrd.VAI.MGG.XAB.HEADER.annmntStatus,
                        instrumentCategorySchemeId = fad_flat.fmg.fozSchemeType,
                        barrierType = (new int[] { 3, 4 }.Any (x => x == barrType) ? "kick_in_barrier" :
                                       new int[] { 2, 5 }.Any (x => x == barrType) ? "kick_out_barrier" :
                                       barrType == 6 ? "stop_loss_barrier" :
                                       barrType != null ? "strike_price" :
                                       null
			                     ),
				barrierComp = mapVal ("TK_BARR_COMP", xrd_flat.xrm.HEADER.lasVegas)
 
			                     // usw...

                    };

		}
	}
}
