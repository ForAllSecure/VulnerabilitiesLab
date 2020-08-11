#include <stdio.h>
#include <stdlib.h>
#include <sstream>
#include <string>
#include <iostream>

#include "src/libfuzzer/libfuzzer_macro.h" // defines DEFINE_PROTO_FUZZER
#include "json_writer.h" // Defines JSON_value_to_string
#include "json.pb.h"  // Defines JSON_value

DEFINE_PROTO_FUZZER(const JSON_value& val) {

    std::string str = JSON_value_to_string(val);

    std::cout << str << std::endl;

}