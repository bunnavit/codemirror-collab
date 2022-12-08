type T = <int a, string b>;

function <int> main <>
{
  var binout : stream[@bin];
  binout <:: "{ \"a\": 17, \"b\": \"yes\" }";
  var binvec = <vector<uint8>>(binout);
  var binin : stream[binvec];
  var x = <T> <:j: binin;
  $stdout <:j: x;
  return 0;
}
