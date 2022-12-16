function <int> main <> {
    var l: shared list<string> = ["1", "2", "3"];
    var nsl: list<string>;

    for var i in l do {
        nsl ~> i;
    }

    $stdout <:j: <list<string>>(l) <:: '\n';
    $stdout <:j: <list<string>>(nsl) <:: '\n';

    return 0;
}