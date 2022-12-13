import Utility;

entry <int> main <> // new
{
   var $W0 : wire<int>[32];
   var $W1 : wire<int>[3];
   // once [-2]
   (out $W1) <:: <int>(5);
   // $count$FOT2XdYd [-1]
   node $count(trigger in $W1, trigger out $W0);
   // log [-5]
   node $log_d(trigger in $W0, @unused trigger out <int>);
   // once [-3]
   (out $W1) <:: <int>(0);
   // once [-4]
   (out $W1) <:: <int>(3);

  $stdout <:: "starting loop" <:: '\n';
   for (var i = 0; i < 5; i++){
    (out $W1) <:: <int>(1);
    }
   fork $numcores();
   return 0;
}

node $log_d
{
   var input : trigger in<int>;
   var ack : trigger out<int>;
   var comp, circ, capt : string;
   var key : int;
   export ctor <trigger in<int> input, trigger out<int> ack> : input(input), ack(ack) {}
   fire {
      var value = <:: input;
      $stderr <:: value <:: '\n';
      if (! @unused ack) ack <:: value;
      return 1;
   }
}

node Doc {
  
}