require "spec_helper"
require "benchmark"
require "matrix"

RSpec.describe "Hello world sample" do
  it "prints hello world" do
    # Simple hello world using TensorStream

    # Create a Constant op
    hello = TensorStream.constant("Hello, TensorStream!")

    # Start the TensorStream session
    sess = TensorStream.session(:ruby_evaluator)

    expect(sess.run(hello)).to eq("Hello, TensorStream!")
    puts(sess.run(hello))
  end
end
