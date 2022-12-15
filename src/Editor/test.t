
entry <int> main <> // new
{

   var $W0: wire<string>[1];
   var $T: wire<string>[1];
   var $W1: wire<string>[32];

   node testNode(in $W0, trigger in $T, trigger out $W1);
   node log(trigger in $W1);

   for (var i = 0; i < 10; i++){
      (out $W0) <:: <string>(i);
   } 

   (out $T) <:: <string>("T");
   
   fork $numcores();
   return 0;
}

node testNode
{
   var input : in<string>;
   var inputT: trigger in<string>;
   var output : trigger out<string>;
   #meta menu "Utility/Operation"
   export ctor <in<string> input, trigger in<string> inputT, trigger out<string> output>: input(input), inputT(inputT), output(output) {}
   fire {
      if(input) {
         output <:: <:: input; 
         return 1;
      } else {
         return $Yield;
      }
   }
}

node log {
   var input: trigger in<string>;
   export ctor <trigger in<string> input> : input(input){}
   fire{
      $stderr <:: (<:: input) <:: '\n';
      return 1;
   } 
}
