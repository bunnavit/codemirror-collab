class A
{
  method x : int;
  ctor <int a> x(a) {}
}

class B : A
{
  // method x : int; // causes an override error
  ctor <int a> A(a) {
    this->x = 5;
  }
}

function <int> main <>
{
  var b = B(2);
  assert b->x == 5;
  return 0;
}
