#include <stdio.h>
#include <sstream>
#include <string>
#include <iostream>
#include <stdlib.h>

#include "json_writer.h"  // Defines JSON_value_to_string
#include "jq_writer.h"  // defines JQ_program_to_str
#include "jq.pb.h"  // defines JQ_pair and others
#include "src/libfuzzer/libfuzzer_macro.h"  // defines DEFINE_PROTO_FUZZER
#include "skip_assert.h"  // defines get_jmp_buf()

using namespace std;

// jq is a C project
extern "C" {
#include "jq.h"
#include "jv.h"
}

void fuzz_jq_pair(const char *program_str, const char *input_str);


DEFINE_PROTO_FUZZER(const JQ_pair& input_pair) {

    string program_str = JQ_program_to_string(input_pair.program());
    string json_str = JSON_value_to_string(input_pair.input());

    // build null-terminated mutable c-style strings
    char json_char_str[json_str.size() + 1];
    char program_char_str[program_str.size() + 1];

    memcpy(json_char_str, json_str.c_str(), json_str.size());
    memcpy(program_char_str, program_str.c_str(), program_str.size());

    program_char_str[program_str.size()] = 0;
    json_char_str[json_str.size()] = 0;

    fuzz_jq_pair(program_char_str, json_char_str);
}


void fuzz_jq_pair(const char *program_str, const char *input_str) {
    cout << "program_str: " << program_str << endl;
    cout << "input_str: " << input_str << endl;

    // parse program
    jq_state *jq = jq_init();

    // setup jmp_buf to return to on asserts
    jmp_buf *env = get_jmp_buf();
    if (setjmp(*env)) {
        //cout << "hit assert on input, skipping" << endl;
        return;
    }

    // try to compile program
    int compiled = jq_compile(jq, program_str);
    if (!compiled) {
        jq_teardown(&jq);
        //cout << "compilation failed" << endl;
        return;
    }

    //cout << "disasm: " << endl;
    //jq_dump_disassembly(jq, 2);

    // parse input
    jv input = jv_parse(input_str);
    if (!jv_is_valid(input)) {
        jv_free(input);
        jq_teardown(&jq);
        //cout << "input is invalid" << endl;
        return;
    }

    // run on input
    jq_start(jq, input, 1);

    // fetch results until invalid
    //cout << "results:" << endl;
    int i = 0;
    while (1) {
        jv res = jq_next(jq);

        if (!jv_is_valid(res)) {
            jv_free(res);
            break;
        }

        //cout << "output " << i << ":" << endl; i++;
        jv_dump(res, 0);
    }

    jq_teardown(&jq);
}