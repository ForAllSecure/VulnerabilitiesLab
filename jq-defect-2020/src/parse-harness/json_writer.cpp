#include "json_writer.h"

// serializes the JSON_value protobuf message to a string
class JSONWriter {
    public:
        JSONWriter(const JSON_value &json_value);
        std::string to_string();

    private:
        void _write_JSON_value(const JSON_value &json_value);
        void _write_JSON_object(const JSON_object &obj);
        void _write_JSON_array(const JSON_array &arr);
        void _write_JSON_number(const JSON_number &num);
        void _write_string(const std::string s);

        std::ostringstream _out;

};

// constructor just builds out a string internally
JSONWriter::JSONWriter(const JSON_value &json_value) {
        _write_JSON_value(json_value);
}

void JSONWriter::_write_JSON_object(const JSON_object &obj) {
    _out << "{";

    for (int i = 0; i < obj.entries_size(); ++i) {
        JSON_key_value_pair pair = obj.entries(i);

        _write_string(pair.key());
        _out << ": ";
        _write_JSON_value(pair.value());
        
        if (i < obj.entries_size() - 1) {
            _out << ", ";
        }
    }

    _out << "}";
}

void JSONWriter::_write_JSON_array(const JSON_array &arr) {
    _out << "[";

    for (int i = 0; i < arr.items_size(); ++i) {
        JSON_array_item item = arr.items(i);

        _write_JSON_value(item.value());

        if (i < arr.items_size() - 1) {
            _out << ", ";
        }
    }

    _out << "]";
}

void JSONWriter::_write_JSON_number(const JSON_number &num) {
    switch (num.value_case()) {
        case JSON_number::kLong : _out << num.long_(); break;
        case JSON_number::kDouble : _out << num.double_(); break;
        case JSON_number::VALUE_NOT_SET :
            _out << 777; break;  // arbitrary visibly distinct default
    }
}

void JSONWriter::_write_string(const std::string s) {
    _out << "\"" << s << "\"";
}

void JSONWriter::_write_JSON_value(const JSON_value &json_value) {
    switch (json_value.value_case()) {
        case JSON_value::kObj :
            _write_JSON_object(json_value.obj());
            break;
        case JSON_value::kArr :
            _write_JSON_array(json_value.arr());
            break;
        case JSON_value::kNum :
            _write_JSON_number(json_value.num());
            break;
        case JSON_value::kTrue :
            _out << "true";
            break;
        case JSON_value::kFalse :
            _out << "false";
            break;
        case JSON_value::kNull :
            _out << "null";
            break;
        case JSON_value::kStr :
            _write_string(json_value.str());
            break;
        case JSON_value::VALUE_NOT_SET :
            _write_string("ABCDABCD"); // arbitrary visibly distinct default
            break;
    }
}

std::string JSONWriter::to_string() {
    return _out.str();
}

// the only exposed function
std::string JSON_value_to_string(const JSON_value &json_value) {
    JSONWriter w(json_value);
    return w.to_string();
}
