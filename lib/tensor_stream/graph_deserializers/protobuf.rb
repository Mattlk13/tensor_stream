require "yaml"

module TensorStream
  # A .pb graph deserializer
  class Protobuf
    def initialize
    end

    def load_from_string(buffer)
      evaluate_lines(buffer.split("\n").map(&:strip))
    end

    ##
    # parsers a protobuf file and spits out
    # a ruby hash
    def load(pbfile)
      f = File.new(pbfile, "r")
      lines = []
      while !f.eof? && (str = f.readline.strip)
        lines << str
      end
      evaluate_lines(lines)
    end

    def parse_value(value_node)
      return unless value_node["tensor"]

      evaluate_tensor_node(value_node["tensor"])
    end

    def evaluate_tensor_node(node)
      if !node["shape"].empty? && node["tensor_content"]
        content = node["tensor_content"]
        unpacked = eval(%("#{content}"))

        if node["dtype"] == "DT_FLOAT"
          TensorShape.reshape(unpacked.unpack("f*"), node["shape"])
        elsif node["dtype"] == "DT_INT32"
          TensorShape.reshape(unpacked.unpack("l*"), node["shape"])
        elsif node["dtype"] == "DT_STRING"
          node["string_val"]
        else
          raise "unknown dtype #{node["dtype"]}"
        end
      else

        val = if node["dtype"] == "DT_FLOAT"
          node["float_val"] ? node["float_val"].to_f : []
        elsif node["dtype"] == "DT_INT32"
          node["int_val"] ? node["int_val"].to_i : []
        elsif node["dtype"] == "DT_STRING"
          node["string_val"]
        else
          raise "unknown dtype #{node["dtype"]}"
        end

        if node["shape"] == [1]
          [val]
        else
          val
        end
      end
    end

    def map_type_to_ts(attr_value)
      case attr_value
      when "DT_FLOAT"
        :float32
      when "DT_INT32"
        :int32
      when "DT_INT64"
        :int64
      when "DT_STRING"
        :string
      when "DT_BOOL"
        :boolean
      else
        raise "unknown type #{attr_value}"
      end
    end

    def options_evaluator(node)
      return {} if node["attributes"].nil?

      node["attributes"].map { |attribute|
        attr_type, attr_value = attribute["value"].flat_map { |k, v| [k, v] }

        if attr_type == "tensor"
          attr_value = evaluate_tensor_node(attr_value)
        elsif attr_type == "type"
          attr_value = map_type_to_ts(attr_value)
        elsif attr_type == "b"
          attr_value = attr_value == "true"
        end

        [attribute["key"], attr_value]
      }.to_h
    end

    protected

    def evaluate_lines(lines = [])
      block = []
      node = {}
      node_attr = {}
      state = :top

      lines.each do |str|
        case state
        when :top
          node["type"] = parse_node_name(str)
          state = :node_context
          next
        when :node_context
          if str == "attr {"
            state = :attr_context
            node_attr = {}
            node["attributes"] ||= []
            node["attributes"] << node_attr
            next
          elsif str == "}"
            state = :top
            block << node
            node = {}
            next
          else
            key, value = str.split(":", 2)
            if key == "input"
              node["input"] ||= []
              node["input"] << process_value(value.strip)
            else
              node[key] = process_value(value.strip)
            end
          end
        when :attr_context
          if str == "value {"
            state = :value_context
            node_attr["value"] = {}
            next
          elsif str == "}"
            state = :node_context
            next
          else
            key, value = str.split(":", 2)
            node_attr[key] = process_value(value.strip)
          end
        when :value_context
          if str == "list {"
            state = :list_context
            node_attr["value"] = []
            next
          elsif str == "shape {"
            state = :shape_context
            node_attr["value"]["shape"] = []
            next
          elsif str == "tensor {"
            state = :tensor_context
            node_attr["value"]["tensor"] = {}
            next
          elsif str == "}"
            state = :attr_context
            next
          else
            key, value = str.split(":", 2)
            if key == "dtype"
              node_attr["value"]["dtype"] = value.strip
            elsif key == "type"
              node_attr["value"]["type"] = value.strip
            else
              node_attr["value"][key] = process_value(value.strip)
            end
          end
        when :list_context
          if str == "}"
            state = :value_context
            next
          else
            key, value = str.split(":", 2)
            node_attr["value"] << {key => value}
          end
        when :tensor_context
          if str == "tensor_shape {"
            state = :tensor_shape_context
            node_attr["value"]["tensor"]["shape"] = []
            next
          elsif str == "}"
            state = :value_context
            next
          else
            key, value = str.split(":", 2)
            if node_attr["value"]["tensor"][key] && !node_attr["value"]["tensor"][key].is_a?(Array)
              node_attr["value"]["tensor"][key] = [node_attr["value"]["tensor"][key]]
              node_attr["value"]["tensor"][key] << process_value(value.strip)
            elsif node_attr["value"]["tensor"][key]
              node_attr["value"]["tensor"][key] << process_value(value.strip)
            else
              node_attr["value"]["tensor"][key] = process_value(value.strip)
            end
          end
        when :tensor_shape_context
          if str == "dim {"
            state = :tensor_shape_dim_context
            next
          elsif str == "}"
            state = :tensor_context
            next
          end
        when :shape_context
          if str == "}"
            state = :value_context
            next
          elsif str == "dim {"
            state = :shape_dim_context
            next
          end
        when :shape_dim_context
          if str == "}"
            state = :shape_context
            next
          else
            _key, value = str.split(":", 2)
            node_attr["value"]["shape"] << value.strip.to_i
          end
        when :tensor_shape_dim_context
          if str == "}"
            state = :tensor_shape_context
            next
          else
            _key, value = str.split(":", 2)
            node_attr["value"]["tensor"]["shape"] << value.strip.to_i
          end
        end
      end

      block
    end

    def parse_node_name(str)
      str.split(" ")[0]
    end

    def process_value(value)
      if value.start_with?('"')
        unescape(value.gsub!(/\A"|"\Z/, ""))
      else
        unescape(value)
      end
    end

    UNESCAPES = {
      "a" => "\x07", "b" => "\x08", "t" => "\x09",
      "n" => "\x0a", "v" => "\x0b", "f" => "\x0c",
      "r" => "\x0d", "e" => "\x1b", "\\\\" => "\x5c",
      "\"" => "\x22", "'" => "\x27",
    }.freeze

    def unescape(str)
      # Escape all the things
      str.gsub(/\\(?:([#{UNESCAPES.keys.join}])|u([\da-fA-F]{4}))|\\0?x([\da-fA-F]{2})/) do
        if $1
          $1 == '\\' ? '\\' : UNESCAPES[$1]
        elsif $2 # escape \u0000 unicode
          [$2.to_s.hex].pack("U*")
        elsif $3 # escape \0xff or \xff
          [$3].pack("H2")
        end
      end
    end
  end
end
