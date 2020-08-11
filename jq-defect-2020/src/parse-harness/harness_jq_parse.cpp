#include <stdio.h>
#include <sstream>
#include <string>
#include <iostream>
#include <stdlib.h>

#include "json_writer.h" // Defines JSON_value_to_string
#include "json.pb.h"  // Defines JSON_value
#include "src/libfuzzer/libfuzzer_macro.h" // defines DEFINE_PROTO_FUZZER

// jq is a C project
extern "C" {
#include "jq.h"
#include "jv.h"
}

DEFINE_PROTO_FUZZER(const JSON_value& val) {

    std::string json_str = JSON_value_to_string(val);
    //std::cout << json_str << std::endl;

    char json_char_str[json_str.size() + 1];
    memcpy(json_char_str, json_str.c_str(), json_str.size());
    json_char_str[json_str.size()] = 0;

    jq_state *jq = jq_init();

    jv input = jv_parse(json_char_str);

    if (!jv_is_valid(input)) {
        //cout << "input is invalid" << endl;
    }
    jv_free(input);

    jq_teardown(&jq);
}