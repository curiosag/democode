using System;
using System.Collections.Generic;
using System.Linq;
using System.Diagnostics;

namespace TkMeta
{
    static class TkRawDataSlicer
    {
        public static IEnumerable<TkMetaRec> Slice(this IEnumerable<TkMetaRec> parts, Func<TkMetaRec, bool> predicate)
        {
            Debug.Assert(parts != null, "param is null: parts");
            IEnumerable<TkMetaRec> rest = parts;            

            while (rest.Count() > 0)
            {
                TkMetaRec slice = rest.First();
                Debug.Assert(predicate(slice), "invalid sequence to slice");
                slice.WithSub(rest.Skip(1).TakeWhile(predicate).ToArray());
                rest = rest.Skip(1).SkipWhile(predicate);
                yield return slice;
            }
        }

        public static IEnumerable<TkMetaRec> Slice_(this IEnumerable<TkMetaRec> parts, Func<TkMetaRec, bool> predicate)
        {
            Debug.Assert(parts != null, "param is null: parts");

            IEnumerator<TkMetaRec> cursor = parts.GetEnumerator();
            cursor.Reset();

            TkMetaRec slice = null;
            List<TkMetaRec> sub = null;

            bool eof = cursor.MoveNext();
            while (!eof)
            {
                slice = cursor.Current;
                Debug.Assert(predicate(slice), "invalid sequence to slice");
                sub = new List<TkMetaRec>();
                while (!eof && predicate(cursor.Current))
                {
                    sub.Add(cursor.Current);
                    eof = cursor.MoveNext();
                }
                yield return slice.WithSub(sub.ToArray());
            }
        }
    }
}
