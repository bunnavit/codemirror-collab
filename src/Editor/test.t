// output test for type union ($type tuple)

type T = <string $type, int a, string b, bool c, list<int> d, map<string>to<int> e>;

function <int> main <>
{
  var t : T = ("", 19, "abc", true, [1, 2, 3], { { "abc", 1}, {"def", 2 } });

  t.$type = "a";
  $stdout <:j: t <:: '\n';

  t.$type = "b";
  $stdout <:j: t <:: '\n';

  t.$type = "c";
  $stdout <:j: t <:: '\n';

  t.$type = "d";
  $stdout <:j: t <:: '\n';

  t.$type = "e";
  $stdout <:j: t <:: '\n';

  return 0;
}
