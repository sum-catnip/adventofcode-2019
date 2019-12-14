using System;
using System.IO;
using System.Linq;
using System.Numerics;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using System.Diagnostics;

using static System.Linq.Enumerable;

namespace day3 {

    class Instruction {
        public string Direction {get;}
        public int    Number    {get;}

        private static Regex parseRegex = new Regex(
            @"(?<inst>\w)(?<num>\d+)", RegexOptions.Compiled
        );

        public Instruction(string inst) {
            Direction = parseRegex.Match(inst).Groups["inst"].Value;
            Number = int.Parse(
                parseRegex.Match(inst).Groups["num"].Value);
        }
    }

    class Space {
        private Dictionary<Vector2, int> used = new Dictionary<Vector2, int>();
        public IList<Vector2> Intersections = new List<Vector2>();

        public void use(Vector2 pos, int cableID) {
            if(! used.TryAdd(pos, cableID))
                if(used[pos] != cableID) Intersections.Add(pos);
        }
    }

    class Program {
        public static IEnumerable<Action> rep(int count, Action action) {
            foreach (var _ in Range(0, count)) yield return action;
        }

        static void map_cable(
            Space space, int cableID,
            IEnumerable<Instruction> instructions) {

            var pos = new Vector2(0, 0);
            foreach(Instruction inst in instructions) {
                foreach(var action in inst.Direction switch {
                    "R" => rep(inst.Number, () => space.use(new Vector2(++pos.X, pos.Y), cableID)),
                    "L" => rep(inst.Number, () => space.use(new Vector2(--pos.X, pos.Y), cableID)),
                    "U" => rep(inst.Number, () => space.use(new Vector2(pos.X, ++pos.Y), cableID)),
                    "D" => rep(inst.Number, () => space.use(new Vector2(pos.X, --pos.Y), cableID))
                }) action();
            }
        }

        static void Main(string[] args) {
            // i could stream this but that would be so much more work
            var instructions = File.ReadLines(args[0]);
            var space = new Space();
            var perf = Stopwatch.StartNew();
            foreach(var cable in Range(0, 2))
                map_cable(space, cable, instructions
                    .ElementAt(cable)
                    .Split(',')
                    .Select(i => new Instruction(i)));

            perf.Stop();

            Console.WriteLine(
                "closest intersection: " +
                space.Intersections
                    .OrderBy(v => Math.Abs(v.X) + Math.Abs(v.Y))
                    .First());

            Console.WriteLine($"calculated in {perf.Elapsed}");
        }
    }
}
