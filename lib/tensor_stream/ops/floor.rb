TensorStream::OpMaker.define_operation :floor do |op|
  op.what_it_does "Returns element-wise largest integer not greater than x."

  op.parameter :input_a, "tensor X", validate: 'FLOATING_POINT_TYPES'

  op.option :name, "Optional name", :nil

  op.define_gradient do |grad, node, params|
    nil
  end

  op.define_shape do |tensor|
    tensor.inputs[0].shape.shape
  end
end