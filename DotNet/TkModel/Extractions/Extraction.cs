
namespace Datamanagement.Normalization
{
  public static class Extraction
  {

    [Mhs(""PS", DC.N, T = 57174)]

    public static int? GetFadFmb_instrType(TKFAD fad)
    {
      ArgumentCheck.Assigned(fad, "fad");
      return fad.GFAD.GVAI.FMB.iType;
    }
...

    [Mhs("PS", DC.N, T = 56050)]
    
    public static string GetInstrumentCategory(TKFAD fad)
    {
      ArgumentCheck.Assigned(fad, "fad");
      return fad.GFAD.GVAI.FMGs == null ? null :
        fad.GFAD.GVAI.FMGs
         .Select(x => x.iGrpID)
         .FirstOrDefault();
    }

    [Mhs("PS", DC.N, T = 57174)]

    private static TResult PickByLanguage<TMultiLanguageItem, TResult>(IEnumerable<TMultiLanguageItem> Items,
                                                                      Func<TMultiLanguageItem, TResult> resultSelector,
                                                                      Func<TMultiLanguageItem, string> langIdSelector,
                                                                      Func<TResult> getDefaultResult)
    {
      return Items == null ? getDefaultResult() :
        Items.Select(x => new WithImplicitPriority<TResult, string>
                                          {
                                            Value = resultSelector(x),
                                            PriorityIndicator = langIdSelector(x)
                                          }).TopPriority("tk_Priority_lang");
    }

    [Mhs("PS", DC.N, T = 56050)]
    
    public static NameElements GetNames(TKFAD fad)
    {
      ArgumentCheck.Assigned(fad, "fad");

      Func<TKFAD_GVAI_VAI_VAK, NameElements> createNameElements = vak => new NameElements
                                                        {
                                                          Prefix = vak.iName1,
                                                          Suffix = vak.iName2
                                                        };

      return PickByLanguage(fad.GFAD.GVAI.VAKs, createNameElements, x => x.iName2, () => new NameElements());
    }

    [Mhs("2012-05-10 17:17", "PS", DC.N, T = 57174)]

    public static string GetProduct(TKFAD fad)
    {
      ArgumentCheck.Assigned(fad, "fad");
      return PickByLanguage(fad.GFAD.GVAI.VAPs, x => x.prod, x => x.K982.lang, () => null);
    }

	...

  }
}
