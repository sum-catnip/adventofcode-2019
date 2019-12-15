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
        private Dictionary<Vector2, Step> used = new Dictionary<Vector2, Step>();
        public IList<Step> Intersections = new List<Step>();

        public void use(Step step) {
            if(! used.TryAdd(step.Pos, step)) {
                if(used[step.Pos].Cable != step.Cable) Intersections.Add(
                    step.add_count(used[step.Pos].Count));
                used[step.Pos] = step;
            }
        }
    }

    class Step {
        public int Count {get;}
        public int Cable {get;}
        public Vector2 Pos {get;}
        public Step(int cable, int count, float x, float y) {
            Cable = cable;
            Count = count;
            Pos   = new Vector2(x, y);
        }

        public Step add_count(int count) =>
            new Step(Cable, Count + count, Pos.X, Pos.Y);
    }

    class Program {
        public static IEnumerable<Action> rep(int count, Action action) {
            foreach (var _ in Range(0, count)) yield return action;
        }

        static void map_cable(
            Space space, int cableID,
            IEnumerable<Instruction> instructions) {
            int steps = 0;
            var pos = new Vector2(0, 0);
            foreach(Instruction inst in instructions) {
                foreach(var action in inst.Direction switch {
                    "R" => rep(inst.Number, () =>
                        space.use(new Step(cableID, ++steps, ++pos.X, pos.Y))),
                    "L" => rep(inst.Number, () =>
                        space.use(new Step(cableID, ++steps, --pos.X, pos.Y))),
                    "U" => rep(inst.Number, () =>
                        space.use(new Step(cableID, ++steps, pos.X, ++pos.Y))),
                    "D" => rep(inst.Number, () =>
                        space.use(new Step(cableID, ++steps, pos.X, --pos.Y)))
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
                "closest intersection by distance: " +
                space.Intersections
                    .OrderBy(i => Math.Abs(i.Pos.X) + Math.Abs(i.Pos.Y))
                    .First().Pos);

            Console.WriteLine(
                "closest intersection by steps: " +
                space.Intersections.OrderBy(s => s.Count).First().Count);

            Console.WriteLine($"calculated in {perf.Elapsed}");
        }
    }
}
