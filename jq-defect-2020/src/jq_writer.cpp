#include "jq_writer.h"

#define MAX_OPERAND_DEPTH 4  // Limit the depth of tree, small for demonstration

// serializes the JQ_program protobuf message to a string
class JQWriter {
    public:
        JQWriter(const JQ_program &jq_prog);
        std::string to_string();
    private:
        void write_JQ_program(const JQ_program &jq_prog);
        void write_JQ_filter(const JQ_filter &filt);
        void write_JQ_operand(const JQ_operand &operand);
        void write_JQ_binary_op(const JQ_binary_op &op);
        std::ostringstream _out;
        int depth;
};

JQWriter::JQWriter(const JQ_program &jq_prog) {
    _out.str("");
    depth = 0;
    write_JQ_program(jq_prog);
}

void JQWriter::write_JQ_program(const JQ_program &jq_prog) {
    // room to do more complex things here
    for (int i=0; i < jq_prog.filters_size(); i++) {
        JQ_filter filt = jq_prog.filters(i);
        write_JQ_filter(filt);

        if (i < jq_prog.filters_size() - 1) {
            _out << ",";
        }
    }
}

void JQWriter::write_JQ_filter(const JQ_filter &filt) {
    // room to do more complex things here
    write_JQ_operand(filt.operand());
}

void JQWriter::write_JQ_operand(const JQ_operand &operand) {
    depth++;

    if (depth > MAX_OPERAND_DEPTH) {
        _out << ".";  // terminate too-deep nestings with a reasonable default
    } else if (operand.has_identity()) {  // else handle JQ_operand oneof {}
        _out << ".";
    } else if (operand.has_length()) {
        _out << "length";
    } else if (operand.has_keys()) {
        _out << "keys";
    } else if (operand.has_val()) {
        // handle JQ_val one_of {}
        JQ_val val = operand.val();
        switch (val.val_case()) {
            case JQ_val::kLongValue : _out << val.long_value(); break;
            case JQ_val::kStringValue :
                // invalid values in filters can cause problems
                //_out << "\"" << val.string_value() << "\""; break;
                // using a static string for now
                _out << "\"" << "EXAMPLE" << "\""; break;
            default: _out << "0";  // default value
        }
    } else if (operand.has_binary_op()) {
        _out << "(";
        write_JQ_binary_op(operand.binary_op());
        _out << ")";
    } else {
        _out << "0";  // default value
    }

    depth--;
}

void JQWriter::write_JQ_binary_op(const JQ_binary_op &op) {
    // handle JQ_binary_op oneof {}
    _out << "(";
    JQ_binary_operator cur_operator = op.operator_();
    if (cur_operator.has_add()) {
        write_JQ_operand(op.left());
        _out << "+";
        write_JQ_operand(op.right());
    } else if (cur_operator.has_sub()) {
        write_JQ_operand(op.left());
        _out << "-";
        write_JQ_operand(op.right());
    } else if (cur_operator.has_mul()) {
        write_JQ_operand(op.left());
        _out << "*";
        write_JQ_operand(op.right());
    } else if (cur_operator.has_div()) {
        write_JQ_operand(op.left());
        _out << "/";
        write_JQ_operand(op.right());
    } else {
        // default value (use left-hand operand)
        write_JQ_operand(op.left());
    }
    _out << ")";
}

std::string JQWriter::to_string() {
    return _out.str();
}

std::string JQ_program_to_string(const JQ_program &jq_prog) {
    JQWriter w(jq_prog);
    return w.to_string();
}