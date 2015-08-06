

namespace DataManagement.Normalization
{
  public class WithImplicitPriority<TValue, TPriorityIndicator>     
  {
    private TPriorityIndicator mPriorityIndicator;

    [Mhs("PS", DC.N, T = 55658)]

    public TValue Value { get; set; }

    [Mhs("PS", DC.N, T = 55658)]

    public TPriorityIndicator PriorityIndicator
    {
      get { return mPriorityIndicator; }
      set
      {
        ArgumentCheck.Assigned(value, "Priority indicator must not be null");
        mPriorityIndicator = value;
      }
    }

  }
}
