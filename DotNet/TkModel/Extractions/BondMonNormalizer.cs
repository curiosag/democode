

namespace Datamanagement.Normalization
{
  public static class BondMonNormalizer 
  {
    private const int cInvalidSubordinationCode = -1;
    private static readonly List<int> mSubordinated = new List<int> { 1, 3, 7 };
    private static readonly List<int> mValidQModes = new List<int> { 3, 4 };
    private static readonly List<string> mValidCouponIndicators = new List<string> { "C", "V" };

    [Mhs("PS", DC.N, T = 57174)]

    public static void NormalizeBond(TTarget target, RawAsset raw)
    {
     NormalizationElements normalizationElements = new NormalizationElements(raw);

      target.SecSubType = GetBondSecSubType(raw);
      target.SecComplementType = GetSecComplementType(raw);
      target.SecCurrency = normalizationElements.SecCurrency(() => target.SecCurrency);

... many more

      target.FlatIndicator = GetFlatIndicator(raw.Hxds);
    }


    [Mhs("2012-05-02 19:27", "PS", DC.N, T = 57174)]

    private static SecSubType GetBondSecSubType(RawAsset raw)
    {
      var NameElements = Extraction.GetNames(raw.Fad);

      return new
      {
        tk_instrumentType = Extraction.GetFadFmb_instrType(raw.Fad),

... another 15

        tk_marketAffiliation = Extraction.GetInstrumentCategory(raw.Fad, "MAXU"),
        tk_productName = Extraction.GetProductName(audit, raw.Fad)
      }.Map<SecSubType>("tk_BondSecSubType");
    }

....
    
    [Mhs("PS", DC.N, T = 57174)]

    private static int? GetSecComplementType(IEnumerable<TKHXD> hxds)
    {
      return Extraction.GetHxdWais(hxds).Where(wai => wai.GHLR.HLR.flatReason != null).Select(Util.Id).Any();
    }

    [Mhs("2012-05-09 18:47", "PS", DC.N, T = 57174)]

    private static DateTime? GetSomePaymentDate(IEnumerable<TKXCD> xcds)
    {
      return (from xcd in xcds
              let xca = xcd.GXCD.GVAI.GMGG.XCA
              let dtFrom = xca.uncertainBegin
              let dtTo = xca.certainEnd
              where Extraction.IsCurrentInterval(dtFrom, dtTo)
              select xcd.GXCD.GVAI.GMGG.XAA.collissionDate_C).SingleOrDefault(Util.Id);
    }

    [Mhs("PS", DC.N, T = 57174)]

    private static DateTime? GetXyDate(RawAsset raw)
    {
      DateTime? prio1 = Extraction.ExtractMultipleFromCids(raw.Cids, cid => cid.dateFrom_A).Where(dt => dt < DateTime.Now).Min();
      Func<DateTime?> prio2 = () => raw.Xcds.Select(xcd => xcd.GXCD.GVAI.GMGG.XCA.entitledForBegin).Where(dt => dt < DateTime.Now).Max();
      Func<DateTime?> prio31 = () => raw.Fzd.GFZD.GVAI_A.FZY.intrFrom_B;
      Func<DateTime?> prio32 = () => raw.Emd.GEMD.GVAI.GMGG.EMA.K819.intrusionDate;
      Func<DateTime?> prio33 = () => raw.Emd.GEMD.GVAI.GMGG.EMA.intrusionDate2_C;

      return prio1 ?? prio2() ?? prio31() ?? prio32() ?? prio33();
    }

    
    [Mhs("PS", DC.N, T = 57174)]

    private static bool? GetHappyPriceIndicator(TKEMD emd)
    {
      return (from gei in emd.GEMD.GVAI.GMGG.GGEIs
              from wai in gei.GWAIs
              where wai.EMK.happyFlag == "H"
              select 1).Any();

    }

... really many more

  }


}
