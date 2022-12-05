class Base {
    ctor <> {} 
    method <> f <> {
        $stdout <:: "should never fire" <:: '\n';
    }
    method <> call <> {
        // do something here then call inherited class method (f)
        this->f();
    }
}

class A: Base {

    var anum: int;
    ctor <int a> anum(a){
        $stdout <:: "hello from ctor A" <:: '\n';
    }
    method <> f <> {
        $stdout <:: "hello from A" <:: '\n';
    }

}

class B: Base {
    var bnum: string;
    ctor <string a> bnum(a){
        $stdout <:: "hello from ctor B" <:: '\n';
    }
    method <> f <> {
        $stdout <:: "hello from B" <:: '\n';
    }
}


function <int> main <> {
    var a = A(3);
    a->call();

    var b = B("hello");
    b->call();
    
    return 0;
}