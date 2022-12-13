entry <int> main <> 
{
   var $W0 : wire<list<int>>[1];
   var $W1 : wire<int>[32];
   var $W2 : wire<int>[32];
   var $W3 : wire<bool>[32];
   var $W4 : wire<list<int>>[32];
   var $$10_value = <string>( "the collected list" );
   // once [-2]
   (out $W0) <:: <shared list<int>>({ 1, 2, 3, 4, 5, 5, 4, 3, 2, 1 }
);
   // logJSON [-9]
   node $logJSON_Ld(trigger in $W4, @unused trigger out <shared list<int>>, "test", "test", -9, ":" + $$10_value);
   // expr [-4]
   node $expr_test_4(trigger in $W1, trigger out $W2, shared <int> <- <int _0> { return _0 * 2; });
   // collectlist [-11]
   node $collectlist_d_x3F_t(trigger in $W2, @unused trigger in <bool>, trigger in $W3, trigger out $W4);
   // foreachlist [-3]
   node $foreachlist_d(trigger in $W0, trigger out $W1, trigger out $W3);
   fork $numcores();
   return 0;
}
node $collectlist_d_x3F_t
{
    var i : trigger in <int>;
    var j : trigger in <bool>;
    var c : trigger in <bool>;
    var o : trigger out<list<int>>;
    var x : list<int>;
    export ctor <trigger in<int> i, trigger in<bool> j, trigger in<bool> c, trigger out<list<int>> o>: i(i), j(j), c(c), o(o) {}
    fire {
        var e = <:: i;
        if (@unused j || <:: j) x ~> e;
        if (<:: c) o <:: share x;
        return 1;
    }
}
node $expr_test_4
{
    var i0 : trigger in<int>;
   var output : trigger out<int>;
   var E : shared <int> <- <int>;
    export ctor <trigger in<int> i0, trigger out<int> output, shared <int> <- <int> E> : i0(i0), output(output), E(E) {}
    fire { output <:: E(<:: i0); return 1; }
 }
 node $foreachlist_d
{
    var i : trigger in <list<int>>;
    var o : trigger out<int>;
    var f : trigger out<bool>;
    var q : list<int>;
    export ctor <trigger in<list<int>> i, trigger out<int> o, trigger out<bool> f>: i(i), o(o), f(f) {}
    method <bool> $runable <> { return (q && (@unused f || f) && (@unused o || o)) || (!q && i); }
    method <int>  $quantum <> { return $runable(); }
    fire {
        if (!q && i)
        {
            var l = <:: i;
            @internal l; // do not send empty lists into this node
            for var x in l do @pushtail(q, x);
        }
        while (q && (@unused f || f) && (@unused o || o))
        {
            o <:: @pophead q;
            if (!@unused f) f <:: !q;
        }
        return 1;
    }
}
node $logJSON_Ld
{
   var input : trigger in<shared list<int>>;
   var ack : trigger out<shared list<int>>;
   var comp, circ, capt : string;
   var key : int;
   export ctor <trigger in<shared list<int>> input, trigger out<shared list<int>> ack, string comp, string circ, int key, string capt> : input(input), ack(ack), comp(comp), circ(circ), key(key), capt(capt) {}
   fire {
      var value = <:: input;
      $stderr <:: comp <:: ':' <:: circ <:: ':' <:: key <:: capt  <:: ": " <:K: value <:: '\n';
      if (! @unused ack) ack <:: value;
      return 1;
   }
}