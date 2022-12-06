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

class C : A
{
    ctor <int b> A(b){
        this->x = 10;
    }
    method <> something <> {}
}

function <int> main <>
{
  var b = B(2);
  assert b->x == 5;
  var something = <bool>(<sig<C>>(b));
  $stdout <:: something <:: '\n';
  return 0;
}
