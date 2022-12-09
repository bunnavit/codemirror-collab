function <int> main <>
{
  var l : list<int> = [1, 2, 3, 4, 5];
  var v : vector<int>[|l|];

  var lIter = @fwd l;
  for (var i = 0; i < |l|; i++){
    v[i] = @elt lIter;
    lIter++;
  }

  v = <vector<int>>(3);

  for var i in v do {
    $stdout <:: i <:: '\n';
  }

  $stdout <:j: v <:: '\n';
  return 0;
}
