module TensorStream
  # Class that defines a TensorStream variable
  class Constant < Tensor
    def initialize(data_type, rank, shape, options = {})
      setup_initial_state(options)
      @data_type = data_type
      @rank = rank
      @breakpoint = false
      @shape = TensorShape.new(shape, rank)
      @value = nil
      @options = options
      @is_const = true
      @internal = options[:internal]
      @name = [@graph.get_name_scope, options[:name] || build_name].compact.reject(&:empty?).join("/")
      @given_name = @name

      if options[:value]
        if options[:value].is_a?(Array)
          # check if single dimenstion array is passed
          options[:value] = _reshape(options[:value], shape.reverse.dup) if shape.size >= 2 && !options[:value].empty? && !options[:value][0].is_a?(Array)

          @value = options[:value].map { |v| v.is_a?(Tensor) ? Tensor.cast_dtype(v, @data_type) : v }
        elsif !shape.empty?
          @value = _reshape(Tensor.cast_dtype(options[:value], @data_type), shape.dup)
        else
          @value = Tensor.cast_dtype(options[:value], @data_type)
        end
        @shape = TensorShape.new(shape_eval(@value))
      end

      @op = Graph.get_default_graph.add_op!(:const, value: @value, data_type: @data_type, internal_name: @name, shape: @shape)
      @name = @op.name
    end

    def inspect
      "Constant(#{@value}, name: #{@name}, shape: #{@shape}, data_type: #{@data_type})"
    end

    protected

    def build_name
      "Const"
    end
  end
end
