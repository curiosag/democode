

namespace DataManagement.Normalization
{
  public static class MappingExtensions
  {
    public class WithPriority<TValue> : WithImplicitPriority<TValue, string>, IComparable
    {
      
      [Mhs("PS", DC.N, T = 85655)]

      public int CompareTo(object obj)
      {
        WithImplicitPriority<TValue, string> comparator = obj as WithImplicitPriority<TValue, string>;
        Check.Assigned(comparator, "invalid Priority comparator");

        return String.CompareOrdinal(PriorityIndicator, comparator.PriorityIndicator);
      }
    }

    private static readonly ILogger sLogger = LoggerManager.Current.GetLogger(typeof(MappingExtensions));

    private const string cMapingIdPrefix = "tk_";

    [Mhs("PS", DC.N, T = 85655)]

    public static string IntToString(this int? me)
    {
      return me == null ? null : me.Value.ToString(CultureInfo.InvariantCulture.NumberFormat);
    }

    [Mhs("PS", DC.N, T = 85655)]

    public static string DecimalToString(this Decimal? me)
    {
      return me == null ? null : me.Value.ToString(CultureInfo.InvariantCulture);
    }

    [Mhs("PS", DC.N, T = 85655)]

    public static T Map<T>(this int? me)
      where T : LookupItem
    {
      return me == null ? null : me.ToString().Map<T>(GetMappingId<T>());
    }

    [Mhs("PS", DC.N, T = 85655)]
    
    public static TValue TopPriority<TValue, TPriorityIndicator>(this IEnumerable<WithImplicitPriority<TValue, TPriorityIndicator>> me, string PriorityId)     
    {
      ArgumentCheck.Assigned(me, "me");

      if (!me.Any())
        return default(WithPriority<TValue>);

      WithPriority<TValue> bestCandidate =
        me.Select(
          x =>
          new WithPriority<TValue>
            {
            Value = x.Value,
            PriorityIndicator = Mappings.Map(PriorityId, x.PriorityIndicator)
          })
          .Where(x => !String.IsNullOrEmpty(x.PriorityIndicator))
          .DefaultIfEmpty()
          .Min()
          .Value;

      if (bestCandidate == null)
      {
        Warn("No Priority could be calculated for PriorityId '{0}'. Consider to extend the related mapping or to introduce a default mapping", PriorityId); 
      }
      return bestCandidate;
    }

    [Mhs("PS", DC.N, T = 85655)]

    public static U IfAssigned<T, U>(this T t, Func<T, U> fn)
    {
      return t != null ? fn(t) : default(U);
    }

}
