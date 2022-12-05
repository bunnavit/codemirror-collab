class A {

    var anum: int;
    ctor <int a> anum(a){
        $stdout <:: "hello from ctor A" <:: '\n';
    }
    method <int> f <> {
        $stdout <:: "hello from A" <:: '\n';
        return anum;
    }

}

class B{
    var bnum: int;
    ctor <int a> bnum(a){
        $stdout <:: "hello from ctor B" <:: '\n';
    }
    method <int> f2 <> {
        $stdout <:: "hello from B" <:: '\n';
        return bnum;
    }
}

class C : A, B {
    var cnum : int;
    ctor <int a> cnum(a), A(1), B(2) {
        $stdout <:: "hello from ctor C" <:: '\n';
    }
    method <> call <> {
        $stdout <:: "hello from call" <:: '\n';
    }
}

function <int> main <> {
    var c = A(3);
    $stdout <:: c->f() <:: '\n';

    return 0;
}