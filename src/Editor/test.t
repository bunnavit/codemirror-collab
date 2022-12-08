type JSONValue =
<
    string $type,
    double D,
    bool B,
    string S,
    list<JSONValue> L,
    map<string>to<JSONValue> M
>;


type JSONObject = map<string>to<JSONValue>;

type JSONList = list<JSONValue>;
type JSONValue2 = <string $type, int a, list<string $type, int c, string d> b>;
type JSONList2 = list<JSONValue2>;

type Request = 
  <
    string Type,
    int version,
    Updates updates
  >;

type Changes = list<string $type, int i, list<string $type, int i, string s> l>;

type Updates = 
  list<
    string clientID,
    Changes changes
  >;

function <int> main <>
{
    var a = “{"foo": ["bar", "baz"]}”;
    var b = “{"foo": ["hello", "world"]}”;
    var x = <JSONObject> <:j: <stream>(a);
    var y = <JSONObject> <:j: <stream>(b);
    $stderr <:k: @join(x, y) <:: '\n';

    var c = "[1, [\"test\", 3], 3]";
    var z = <JSONList2> <:j: <stream>(c);
    $stdout <:j: z[1].$type <:: '\n';

    for var item in z do {
      if(item.$type == "a"){
        $stdout <:: "is int" <:: '\n';
      }
      if(item.$type == "b"){
        var test = item.b;
        for var subTest in test do {
          $stdout <:: subTest.$type <:: '\n';
        }
      }
    }


    var testInput = "{\"Type\":\"pushUpdates\",\"version\":5,\"updates\":[{\"clientID\":\"19xqfh\",\"changes\":[61,[0,\"\",\"text18\",\"text19\",\"text20\"],114]}]}";
    
    var request = <Request> <:j: <stream>(testInput);
    $stdout <:J: request <:: '\n';
  
    return 0;
}
