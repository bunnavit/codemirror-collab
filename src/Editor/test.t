function <int> main <> {
    var cond = "something";
    var msg = cond ? "hello1" : "hello2";

    $stdout <:: cond ? "hello1" : "hello2" <:: '\n';

    var s : stream["input.txt", @utf8, @out];

    if(s){
        s <:: "test" <:: '\n';
    }
    
    return 0;
}