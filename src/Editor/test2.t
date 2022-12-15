import AWS/Types/DynamoDB;

function <int> main <> {
    var m: map <string> to <AWS$DynamoDB$AttributeValue>;
    m = { "connectionId": { "S": "something" }, "sub": {"S": "bob"}};

    var m1: map <string> to <string>;
    m1["1"] = "1";
    m1("test") \\ {};
    
    $stdout <:: <bool>(m1("test") \\ {})<:: '\n';

    return 0;
}