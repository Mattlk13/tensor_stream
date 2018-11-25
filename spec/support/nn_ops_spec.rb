RSpec.shared_examples "standard nn ops evaluator" do
  extend SupportedOp

  let(:ts) { TensorStream }

  before(:each) do
    TensorStream::Tensor.reset_counters
    TensorStream::Operation.reset_counters
    tf.reset_default_graph
    sess.clear_session_cache
  end

  supported_op ".conv2d" do
    context "rgb" do
      # 2 RGB images
      let(:image) do
        tf.constant([[[[0.14, 0.47, 0.20], [0.96, 0.10, 0.59], [0.65, 0.954, 0.023], [0.9461, 0.52, 0.701]],[[0.83, 0.101, 0.21], [0.91, 0.87, 0.96], [0.30, 0.01, 0.07], [0.95, 0.81, 0.36]],[[0.07, 0.95, 0.84], [0.23, 0.22, 0.68], [0.017, 0.16, 0.67], [0.78, 0.33, 0.51]],[[0.13, 0.77, 0.54], [0.65, 0.34, 0.19], [0.601, 0.41, 0.31], [0.26, 0.33, 0.07]]],[[[0.1, 0.47, 0.20], [0.5, 0.10, 0.59], [0.65, 0.954, 0.1], [0.9461, 0.2, 0.3]],[[0.2, 0.101, 0.21], [0.9, 0.87, 0.96], [0.30, 0.01, 0.07], [0.95, 0.81, 0.36]],[[0.3, 0.95, 0.84], [0.23, 0.22, 0.68], [0.017, 0.2, 0.67], [0.1, 0.33, 0.8]],[[0.13, 0.77, 0.54], [0.65, 0.34, 0.19], [0.601, 0.41, 0.9], [0.26, 0.33, 0.1]]]])
      end

      let(:sample_filter) do
        tf.constant([[[[0.97, 0.38, 0.62], [0.88, 0.16, 0.899], [0.87, 0.06, 0.06]], [[0.14, 0.47, 0.33], [0.83, 0.095, 0.04], [0.47, 0.16, 0.29]]],[[[0.79, 0.55, 0.24], [0.075, 0.84, 0.77], [0.40, 0.72, 0.55]], [[0.43, 0.05, 0.42], [0.16, 0.62, 0.31], [0.07, 0.94, 0.99]]]])
      end

      it "calculates for convultion on a 2d image" do
        conv = ts.nn.conv2d(image, sample_filter, [1, 1, 1, 1], 'SAME')
        expect(image.shape.shape).to eq([2, 4, 4, 3])
        expect(sample_filter.shape.shape).to eq([2, 2, 3, 3])
        expect(conv.shape.shape).to eq([2, 4, 4, 3])
        result = sess.run(conv)

        expect(tr(result, 2)).to eq(tr([
          [
            [
              [2.5631, 2.8753, 3.008], [3.7298, 2.8255, 2.5945], [3.2126, 2.1191, 2.923], [2.9404, 1.9469, 2.1458]
            ],
            [
              [3.0216, 3.2365, 3.2798], [3.1167, 2.2265, 2.8423], [2.0525, 2.05, 2.0801], [2.7925, 1.5856, 2.0606]
            ],
            [
              [2.8928, 1.9958, 2.7173], [2.4191, 1.6493, 1.7962], [2.162, 1.7334, 1.5243], [1.7489, 0.8504, 1.1659]
            ],
            [
              [1.736, 0.5732, 1.0884], [1.6651, 0.6838, 1.0247], [1.5567, 0.4773, 0.8791], [0.6035, 0.1558, 0.4621]
            ]
          ],
          [
            [
              [1.9579, 2.2969, 2.676], [3.3119, 2.6575, 2.3293], [2.8255, 2.0292, 2.7986], [2.31, 1.8716, 1.8341]
            ],
            [
              [2.5908, 3.1189, 2.9411], [3.1134, 2.2475, 2.8485], [1.7834, 2.3222, 2.1124], [2.3713, 1.4204, 2.0569]
            ],
            [
              [3.1159, 2.0832, 2.86], [2.4936, 2.2077, 2.3819], [2.4764, 1.9196, 1.7742], [1.3536, 0.631, 0.7782]
            ],
            [
              [1.736, 0.5732, 1.0884], [1.9424, 0.7782, 1.1958], [2.0841, 0.5175, 0.9232], [0.6296, 0.1576, 0.4639]
            ]
          ]
        ],2))
      end

      specify "gradients" do
        conv = ts.nn.conv2d(image, sample_filter, [1, 1, 1, 1], 'SAME')
        r = conv + 1.0
        f = ts.sin(r)
        g = ts.gradients(f, [image, sample_filter])
        result = sess.run(g)

        expect(tr(result[0], 2)).to eq(
          tr([[[[-1.568816  , -1.5039766 , -0.87727493],
            [-1.5256536 , -1.7708805 , -0.8208158 ],
            [-1.9434927 , -1.3150585 , -0.8961165 ],
            [-2.4406657 , -2.1909385 , -1.3167944 ]],

           [[-2.3367596 , -2.2017555 , -1.8628157 ],
            [-3.1695065 , -4.078808  , -3.5368373 ],
            [-4.2702627 , -4.702943  , -4.550505  ],
            [-4.534155  , -5.2563124 , -4.9313416 ]],

           [[-2.4608912 , -2.310964  , -1.560841  ],
            [-4.342957  , -4.551013  , -3.943637  ],
            [-4.8697486 , -5.3035965 , -5.2367163 ],
            [-4.421178  , -4.9375453 , -5.179074  ]],

           [[-2.5218909 , -2.7856035 , -2.2953    ],
            [-3.6560836 , -4.504217  , -4.7302465 ],
            [-3.6266844 , -4.2232084 , -4.6373353 ],
            [-1.8186971 , -2.2765572 , -3.079284  ]]],


          [[[-1.862654  , -1.796917  , -0.9662708 ],
            [-2.2038217 , -2.309808  , -1.3200754 ],
            [-2.4080024 , -1.9984912 , -1.388797  ],
            [-2.7502923 , -2.647991  , -1.72563   ]],

           [[-3.0450664 , -3.0750842 , -2.436968  ],
            [-3.8709986 , -4.7204967 , -4.482834  ],
            [-4.6719003 , -4.8817997 , -4.8569574 ],
            [-5.0242257 , -5.386572  , -5.2241716 ]],

           [[-2.5775683 , -2.405006  , -1.7401757 ],
            [-4.571049  , -4.6201143 , -4.2154384 ],
            [-4.918666  , -5.3476524 , -5.1783614 ],
            [-4.026435  , -4.269988  , -4.9582386 ]],

           [[-2.3725717 , -2.7142625 , -2.1868238 ],
            [-3.8160563 , -4.8028965 , -4.8271914 ],
            [-3.9573305 , -4.7156396 , -5.1080194 ],
            [-1.5534053 , -2.0360773 , -2.9270544 ]]]],2))

        expect(tr(result[1],2)).to eq(tr([[[[-10.859395 ,  -9.890453 , -11.0549755],
          [-10.63558  ,  -9.274404 ,  -9.921782 ],
          [-10.875986 ,  -9.578144 , -10.424688 ]],

         [[-10.358284 ,  -9.019288 ,  -9.614937 ],
          [ -7.127036 ,  -6.455966 ,  -7.320156 ],
          [ -9.0591755,  -8.021906 ,  -8.073763 ]]],


        [[[ -7.584304 ,  -8.881921 ,  -8.918311 ],
          [ -7.5069113,  -8.5464325,  -8.645248 ],
          [ -8.340102 ,  -9.969032 ,  -9.925108 ]],

         [[ -6.7498846,  -8.0087595,  -7.1545835],
          [ -5.7078614,  -6.4431744,  -5.6287665],
          [ -6.9071035,  -7.5253587,  -6.828193 ]]]],2))
      end

      context "padding option = 'VALID" do
        it "calculates for convultion on a 2d image" do
          conv = ts.nn.conv2d(image, sample_filter, [1, 1, 1, 1], 'VALID')
          expect(image.shape.shape).to eq([2, 4, 4, 3])
          expect(sample_filter.shape.shape).to eq([2, 2, 3, 3])
          expect(conv.shape.shape).to eq([2, 3, 3, 3])
          result = sess.run(conv)
          expect(tr(result, 2)).to eq([[[[2.56, 2.88, 3.01], [3.73, 2.83, 2.59], [3.21, 2.12, 2.92]],
            [[3.02, 3.24, 3.28], [3.12, 2.23, 2.84], [2.05, 2.05, 2.08]],
            [[2.89, 2.0, 2.72], [2.42, 1.65, 1.8], [2.16, 1.73, 1.52]]],
           [[[1.96, 2.3, 2.68], [3.31, 2.66, 2.33], [2.83, 2.03, 2.8]],
            [[2.59, 3.12, 2.94], [3.11, 2.25, 2.85], [1.78, 2.32, 2.11]],
            [[3.12, 2.08, 2.86], [2.49, 2.21, 2.38], [2.48, 1.92, 1.77]]]])
        end
      end
    end

    context "grayscale" do
      let(:image) do
        [
          [
            [[0.92], [0.58], [0.62], [0.98]],
            [[0.61], [0.56], [0.08], [0.99]],
            [[0.98], [0.18], [0.031], [0.74]],
            [[0.769], [0.79], [0.42], [0.057]]
          ],
          [
            [[0.63], [0.62], [0.10], [0.83]],
            [[0.808], [0.44], [0.67], [0.12]],
            [[0.21], [0.52], [0.19], [0.40]],
            [[0.04], [0.37], [0.51], [0.75]]
          ]
        ].t
      end

      let(:sample_filter) do
          [
            [[ [1.0] ], [ [0.5] ]],
            [[ [0.0] ], [ [0.2] ]],
          ].t
      end

      let(:sample_filter_2) do
        [
          [[ [1.0, 1.0] ], [ [0.5, 1.0] ]],
          [[ [0.0, 0.0] ], [ [0.2, 0.1] ]],
        ].t
      end

      specify do
        expect(image.shape.shape).to eq([2, 4, 4, 1])
        expect(sample_filter.shape.shape).to eq([2, 2, 1, 1])
        conv = ts.nn.conv2d(image, sample_filter, [1, 1, 1, 1], 'SAME')
        expect(conv.shape.shape).to eq([2, 4, 4, 1])
        result = sess.run(conv)

        expect(tr(result)).to eq([
          [
            [[1.322], [0.906], [1.308], [0.98]],
            [[0.926], [0.6062], [0.723], [0.99]],
            [[1.228], [0.2795], [0.4124], [0.74]],
            [[1.164], [1.0], [0.4485], [0.057]]
          ],
          [
            [[1.028], [0.804], [0.539], [0.83]],
            [[1.132], [0.813], [0.81], [0.12]],
            [[0.544], [0.717], [0.54], [0.4]],
            [[0.225], [0.625], [0.885], [0.75]]]
          ])

        conv = ts.nn.conv2d(image, sample_filter_2, [1, 1, 1, 1], 'SAME')
        result = sess.run(conv)
        expect(result.shape).to eq([2, 4, 4, 2])

        expect(tr(result)).to eq([
          [[[1.322, 1.556], [0.906, 1.208], [1.308, 1.699], [0.98, 0.98]],
          [[0.926, 1.188], [0.6062, 0.6431], [0.723, 1.144], [0.99, 0.99]],
          [[1.228, 1.239], [0.2795, 0.253], [0.4124, 0.7767], [0.74, 0.74]],
          [[1.164, 1.559], [1.0, 1.21], [0.4485, 0.477], [0.057, 0.057]]],
        [[[1.028, 1.294], [0.804, 0.787], [0.539, 0.942], [0.83, 0.83]],
          [[1.132, 1.3], [0.813, 1.129], [0.81, 0.83], [0.12, 0.12]],
          [[0.544, 0.767], [0.717, 0.761], [0.54, 0.665], [0.4, 0.4]],
          [[0.225, 0.41], [0.625, 0.88], [0.885, 1.26], [0.75, 0.75]]]])
      end

      specify "strides" do
        conv = ts.nn.conv2d(image, sample_filter_2, [1, 2, 2, 1], 'SAME')
        result = sess.run(conv)
        expect(tr(result)).to eq([
          [
            [[1.322, 1.556], [1.308, 1.699]], [[1.228, 1.239], [0.4124, 0.7767]]
          ],
          [
            [[1.028, 1.294], [0.539, 0.942]], [[0.544, 0.767], [0.54, 0.665]]
          ]
        ])

        conv = ts.nn.conv2d(image, sample_filter_2, [1, 1, 2, 1], 'SAME')
        result = sess.run(conv)
        expect(tr(result)).to eq([
          [
            [[1.322, 1.556], [1.308, 1.699]],
            [[0.926, 1.188], [0.723, 1.144]],
            [[1.228, 1.239], [0.4124, 0.7767]
          ],
          [
            [1.164, 1.559], [0.4485, 0.477]]],
            [[[1.028, 1.294], [0.539, 0.942]],
            [[1.132, 1.3], [0.81, 0.83]],
            [[0.544, 0.767], [0.54, 0.665]],
            [[0.225, 0.41], [0.885, 1.26]]
          ]
        ])
      end

      specify "gradient" do
        conv = ts.nn.conv2d(image, sample_filter, [1, 1, 1, 1], 'SAME')
        g = tf.gradients(conv, [image, sample_filter])
        result = sess.run(g)

        expect(tr(result[0])).to eq([
            [
              [[1.0],[1.5],[1.5],[1.5]],
              [[1.0 ],[1.7],[1.7],[1.7]],
              [[1.0 ],[1.7],[1.7],[1.7]],
              [[1.0 ],[1.7],[1.7],[1.7]]
            ],
            [
              [[1.0 ],[1.5],[1.5],[1.5]],
              [[1.0 ],[1.7],[1.7],[1.7]],
              [[1.0 ],[1.7],[1.7],[1.7]],
              [[1.0 ],[1.7],[1.7],[1.7]]
            ]
          ])

        expect(tr(result[1])).to eq([
          [
            [[16.515]],[[11.548]]
          ],
          [
            [[11.235]],[[ 7.818]]
          ]
        ])

        conv = ts.nn.conv2d(image, sample_filter_2, [1, 1, 1, 1], 'SAME')
        g = tf.gradients(conv, [image, sample_filter_2])
        result = sess.run(g)

        expect(tr(result)).to eq([
          [
            [
              [[2.0], [3.5], [3.5], [3.5]],
              [[2.0], [3.8], [3.8], [3.8]],
              [[2.0], [3.8], [3.8], [3.8]],
              [[2.0], [3.8], [3.8], [3.8]]
            ],
            [
              [[2.0], [3.5], [3.5], [3.5]],
              [[2.0], [3.8], [3.8], [3.8]],
              [[2.0], [3.8], [3.8], [3.8]],
              [[2.0], [3.8], [3.8], [3.8]]
            ]
          ],
          [
            [
              [[16.515, 16.515]],
              [[11.548, 11.548]]
            ],
            [
              [[11.235, 11.235]],
              [[7.818, 7.818]]
            ]
          ]
        ])

        conv = ts.nn.conv2d(image, sample_filter, [1, 2, 2, 1], 'SAME')
        g = tf.gradients(conv, [image, sample_filter])
        result = sess.run(g)

        expect(tr(result[0])).to eq(
          [
            [
              [[1.0], [0.5], [1.0], [0.5]],
              [[0.0], [0.2], [0.0], [0.2]],
              [[1.0], [0.5], [1.0], [0.5]],
              [[0.0], [0.2], [0.0], [0.2]]
            ],
            [
              [[1.0], [0.5], [1.0], [0.5]],
              [[0.0], [0.2], [0.0], [0.2]],
              [[1.0], [0.5], [1.0], [0.5]],
              [[0.0], [0.2], [0.0], [0.2]]
            ]
          ])

        expect(tr(result[1])).to eq(
          [
            [
              [[3.681]], [[4.85]]], [[[3.907]], [[4.077]]
            ]
          ]
        )
      end
    end

    context "grayscale 2" do
      let(:image) do
        tf.constant([[[[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0],[0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [84.0], [185.0], [159.0], [151.0], [60.0], [36.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [222.0], [254.0], [254.0], [254.0], [254.0], [241.0], [198.0], [198.0], [198.0], [198.0], [198.0], [198.0], [198.0], [198.0], [170.0], [52.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [67.0], [114.0], [72.0], [114.0], [163.0], [227.0], [254.0], [225.0], [254.0], [254.0], [254.0], [250.0], [229.0], [254.0], [254.0], [140.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [17.0], [66.0], [14.0], [67.0], [67.0], [67.0], [59.0], [21.0], [236.0], [254.0], [106.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [83.0], [253.0], [209.0], [18.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [22.0], [233.0], [255.0], [83.0], [0.0],[0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [129.0], [254.0], [238.0], [44.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [59.0], [249.0], [254.0], [62.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [133.0], [254.0], [187.0], [5.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [9.0], [205.0], [248.0], [58.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [126.0], [254.0], [182.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [75.0], [251.0], [240.0], [57.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [19.0], [221.0], [254.0], [166.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [3.0], [203.0], [254.0], [219.0], [35.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0],[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [38.0], [254.0], [254.0], [77.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [31.0], [224.0], [254.0], [115.0], [1.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [133.0], [254.0], [254.0], [52.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [61.0], [242.0], [254.0], [254.0], [52.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [121.0], [254.0], [254.0], [219.0], [40.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [121.0], [254.0], [207.0], [18.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]], [[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0],[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0]]]])
      end

      let(:filter) do
        tf.constant([[[[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]]], [[[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]]],[[[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]]],[[[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]]],[[[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]], [[1.0, 1.0, 1.0, 1.0]]]])
      end

      let(:filter_2) do
        tf.constant([[[[0.58, -1.45, 0.7, 0.41, -1.02, 0.17, -0.22, 1.65], [0.09, -0.01, 0.38, 1.04, 0.98, 0.48, 3.01, -0.45], [1.1, 1.1, -1.92, -0.06, 1.19, -1.94, 0.45, 0.56], [-0.32, 0.6, 0.09, -1.72, 0.84, -0.11, -1.18, -0.4]], [[-0.33, 0.85, -1.66, 1.28, -0.63, -0.1, -0.79, -0.65], [-0.4, -0.45, -0.63, -1.09, 0.23, 1.13, 0.08, -0.48], [0.19, 0.42, 1.74, 1.32, 1.1, 0.66, 0.96, 1.28], [0.13, 0.31, 0.05, -0.99, 0.0, -0.15, -0.43, -0.79]], [[-0.22, 0.16, -0.42, -1.42, 0.41, 0.06, 0.39, -0.46], [0.16, -1.51, -0.12, -0.9, 0.43, -0.63, 1.08, -0.65], [0.09, -1.28, 0.31, 0.88, 2.06, 1.13,-0.24, 0.03], [-0.29, 0.24, -2.05, -1.77, 1.11, -0.57, -0.25, -1.48]], [[0.15, -0.64, -1.85, 0.06, -0.19, -0.05, -0.21, 0.3], [-2.64, -1.08, -0.81, 0.5, -0.4, -1.06, 0.26, -0.33], [0.6, 0.21,0.0, 0.07, -1.28, -0.81, -0.15, 0.06], [-1.93, -1.46, -0.6, 1.59, 0.93, 0.13, 0.19, -0.15]], [[0.38, -0.66, 2.38, -0.19, -0.23, 0.3, -1.04, 0.7], [0.58, 0.1, 1.51, 0.79, -0.68, 1.41, -0.62, 0.3], [0.57, -1.57, -0.29, -0.58, 0.24, 0.17, -0.21, -1.86], [-0.1, 0.25, 1.51, 0.88, 1.18, 0.61, 1.39, -0.3]]], [[[-0.29, -0.99, 0.3, -1.5, 0.85, 1.12, -0.45, -0.54], [-1.22, 2.35, -0.27, -1.13, -0.39, 0.61, 1.25, -1.01], [2.36, 1.51, -1.22, 1.88, -0.7, -1.41, 0.27, 0.41], [-0.73, 0.87, -0.82, -0.0, 0.33, -0.64, 0.62, -1.37]], [[1.45, -1.19, 0.23, -0.06, -1.6, 0.55, 0.28, -0.1], [0.31, -0.64, -0.57, 0.48, -0.19, -0.09, 0.29, -0.02], [1.97, 0.54, -0.99, -0.09, 0.72, 0.24, -0.37, -0.54], [-0.51, 1.77, 0.14, 0.47, 1.38, -0.86, -0.38, -0.11]], [[0.47, 0.42, -0.33, 0.85, 1.3, 0.94, -1.58, 0.19], [0.32, 0.78, -1.99, 0.54, 1.49, 0.45, -2.54, -0.83], [-0.03, 0.24, -1.12, -0.71, 0.28, -2.47, 0.36, 0.61], [-0.42, -0.39, -0.31, 0.78, 1.14, -1.68, -0.9, -1.46]], [[-0.09, 0.05, 2.13, 0.61, 1.72, 0.97, 0.83, 1.16], [0.29, -0.7, -1.2, -0.76, -0.77, -0.4, -0.88, -0.24], [0.28, -0.89, 0.72, -0.76, 2.0, -0.13, -0.59, -1.01], [-0.1, -1.38, -0.9, 0.35, 0.44, -1.11, -0.82, -0.86]], [[0.83, -0.73, 0.02, 1.01, -1.02, -0.1, 0.13, 0.03], [-0.67, 0.51, 0.45, 0.4, -1.31, 0.37, -1.61, -0.67], [0.0, -0.18, -0.34, 1.19, 2.16, -1.84, 0.0, -1.08], [-1.36, 0.33, -0.4, 0.55, 1.17, 1.3, 0.68, 1.67]]], [[[-0.77, -0.71, -2.05, -0.03, 0.24, -0.64, -0.96, 1.01], [2.56, -0.15, 1.15, 0.09, 0.78, -0.34, 0.48, -0.91], [-0.95, 1.68, 0.37, -0.11, -0.92, 0.08, 0.3, -0.7], [0.51, -0.62, 0.13, -1.37, 0.36, -1.88, -0.71, 0.84]], [[-1.4, -0.36, 0.22, -0.23, 1.37, -1.81, 1.16, -0.69], [0.52, 0.04, 2.35, -0.13, -1.91, -1.12, -1.33, -0.41], [0.72, 1.03, -0.27, 0.24, 0.93, 1.46, 0.65, 0.79], [1.1, 0.43, -0.28, 0.53, 1.86, 0.14, -0.54, 0.25]], [[1.03, 1.32, 0.21, 0.43, -1.72, -0.03, -0.34, 0.06], [0.04, -1.36, -0.87, 0.14, 0.34, 0.4, -0.65, -0.82], [1.01, -1.03, -1.32, -0.33, -1.42, -0.78, 0.01, -1.14], [0.81, -0.59, -0.08, 2.35, -0.1, 1.02, 0.05, 0.61]], [[1.28, 0.96, -0.4, -0.21, 2.19, -0.08, -0.93, -0.54], [0.78, 1.75, -1.22, 0.05, 0.18, -1.29, -0.7, -0.53], [-0.26, 0.76, -0.2, -0.4, -1.29, -0.73, 1.15, 0.55], [-0.9, 1.69, 1.21, -0.7, -2.37, -0.89, 0.73, -1.29]], [[0.64, 0.19, -0.33, -2.18, 0.42, -0.56, 0.17, -0.3], [0.65, -0.82, -0.1, -1.15, -1.5, -0.23, 0.64, 0.75], [0.85, -0.18, -2.4, 0.16, 1.14, -0.03, 1.07, -0.94], [-0.11, -1.07, 0.33, -1.64, 0.73, -0.63, 0.2, -1.03]]], [[[-0.1, -2.24, -1.41, 0.83, -0.16, -1.41, -1.17, 2.3], [0.84, -1.43, -2.92, -1.92, -1.34, -0.1, 0.47, -0.24], [0.14, -1.17, 0.55, -0.12, 0.18, -0.7, -0.64, 0.4], [2.98, -0.83, -0.98, -1.93, -2.01, -1.04, 0.77, 0.14]], [[-0.62, 0.21, 0.61, -1.17, -0.33, -1.24, -0.25, 0.94], [-0.24, 0.19, -0.07, -0.01, -1.01, -0.54, 0.75, 0.49], [-1.5, 0.26, 1.29, -0.22, -0.0, 0.39, -1.34, 1.36], [-0.74, -1.68, -1.04, 1.2, 0.98, -1.0, -0.62, -0.18]], [[2.0, 2.04, -1.35, -1.82, -0.21, -1.59, 0.03, 1.38], [-0.03, -0.26, -0.33, -0.92, -0.82, -0.79, 0.2, 0.83], [0.01, -0.47, 0.58, 1.66, 0.33, 1.15, 0.14, -0.61], [-0.08, 0.26, 1.99, 1.23, 0.43, 0.31, -1.28, 0.56]], [[-1.68, -1.43, -0.28, -0.23, -0.47, 0.98, 0.87, -2.12], [-1.0, 0.18, 0.38, 1.11, -1.2, -1.66, 1.37, 1.23], [0.83, 1.03, -1.06, -0.9, 1.29, -0.4, -1.04, 0.54], [-0.49, 0.69, -0.69, 0.01, -0.19, 0.67, 0.02, 0.14]], [[-0.88, -0.54, -1.51, 0.32, 0.85, 0.14, 1.27, -0.5], [0.29, 0.36, 2.3, -0.4, 1.35, -0.15, 0.16, 1.08], [-1.84, -0.69, -0.7, -0.04, -0.99, 0.04, 0.61, -0.32], [-0.36, -1.14, -1.12, 1.6, -1.04, -1.0, 0.48, -1.77]]], [[[-0.66, 0.33, -0.32, -1.28, 1.34, 1.6, -1.59, -1.24], [-0.55, 0.6, 0.53, -0.56, -0.55, -0.33, -1.65, -0.05], [-2.05, 1.37, -1.15, 0.7, 0.74, -0.92, -0.88, 0.42], [-0.16, 0.1, 0.12, 1.01, 0.51, 0.89, -0.04, 0.77]], [[-0.47, -0.56, 1.51, -0.4, -0.17, 0.02, 0.63, -0.49], [0.06, 1.35, 1.48, 0.34, -0.37, 0.48, -0.23, -0.46], [0.74, 0.56, -0.48, 0.37, 1.14, -0.0, -2.35, 0.76], [-0.89, -0.19, 0.75, 0.84, -1.03, -0.72, -0.22, 0.03]], [[0.39, 0.69, -0.57, -1.33, -2.1, 1.05, 0.21, -0.32], [1.35, 0.84, 0.71, 0.21, 0.3, -0.6, -0.47, -1.08], [-0.92, 1.55, -1.4, 1.24, -0.43, 0.07, 0.56, 0.66], [-0.98, 1.51, -0.13, -0.58, 0.91, -0.14, 0.57, -0.17]], [[-0.32, 1.19, -1.75, 0.5, 0.23, 1.98, -0.49, -2.09], [0.45, -3.3, -0.2, -0.51, -0.33, 1.39, 0.35, -0.37], [-0.44, -0.68, 0.59, 0.27, -1.16, 0.1, 0.45, -2.12], [0.11, 0.56, 0.95, -1.36, -0.7, -0.76, -0.28, 0.62]], [[1.04, -0.66, -1.01,-0.3, 1.31, -2.36, -1.09, -1.52], [-0.44, 1.13, -1.52, -0.11, 0.24, -1.0, 0.29, -0.39], [-2.27, 0.12, -0.2, 1.48, 0.68, -0.32, -2.22, -0.33], [0.38, -1.11, 0.03, -0.28, 0.84, 0.59, 0.57, -0.38]]]])
      end

      let(:b1) do
        tf.constant([0.10000000149011612, 0.10000000149011612, 0.10000000149011612, 0.10000000149011612])
      end

      let(:b2) do
        tf.constant([1.4732561834197797, 0.09282322887646464, 1.2571291315858455, -0.16020681915040377, -0.735139313455455, -0.789421065872052, -0.01703308768731945, -0.554601484278356])
      end

      let(:expected_filter_2_grad) do
        [[[[104878.0, 64155.0, 548.0, 25029.0, 111460.0, 1255.0, 25045.0, 7251.0], [104878.0, 64155.0, 548.0, 25029.0, 111460.0, 1255.0, 25045.0, 7251.0], [104878.0, 64155.0, 548.0, 25029.0, 111460.0, 1255.0, 25045.0, 7251.0], [104878.0, 64155.0, 548.0, 25029.0, 111460.0, 1255.0, 25045.0, 7251.0]], [[99212.0, 49162.0, 850.0, 33861.0, 110805.0, 1763.0, 14795.0, 2655.0], [99212.0, 49162.0, 850.0, 33861.0, 110805.0, 1763.0, 14795.0, 2655.0], [99212.0, 49162.0, 850.0, 33861.0, 110805.0, 1763.0, 14795.0, 2655.0], [99212.0, 49162.0, 850.0, 33861.0, 110805.0, 1763.0, 14795.0, 2655.0]], [[90919.0, 34079.0, 1255.0, 46790.0, 111460.0, 2335.0, 9210.0, 586.0], [90919.0, 34079.0, 1255.0, 46790.0, 111460.0, 2335.0, 9210.0, 586.0], [90919.0, 34079.0, 1255.0, 46790.0, 111460.0, 2335.0, 9210.0, 586.0], [90919.0, 34079.0, 1255.0, 46790.0, 111460.0, 2335.0, 9210.0, 586.0]], [[78354.0, 19531.0, 2439.0, 60519.0, 110805.0, 3726.0, 9257.0, 0.0], [78354.0, 19531.0, 2439.0, 60519.0, 110805.0, 3726.0, 9257.0, 0.0], [78354.0, 19531.0, 2439.0, 60519.0, 110805.0, 3726.0, 9257.0, 0.0], [78354.0, 19531.0, 2439.0, 60519.0, 110805.0, 3726.0, 9257.0, 0.0]], [[65399.0, 9346.0, 4447.0, 72770.0, 111460.0, 5892.0, 14745.0, 0.0], [65399.0, 9346.0, 4447.0, 72770.0, 111460.0, 5892.0, 14745.0, 0.0], [65399.0, 9346.0, 4447.0, 72770.0, 111460.0, 5892.0, 14745.0, 0.0], [65399.0, 9346.0, 4447.0, 72770.0, 111460.0, 5892.0, 14745.0, 0.0]]], [[[107076.0, 68432.0, 0.0, 19950.0, 111319.0, 17.0, 15560.0, 7888.0], [107076.0, 68432.0, 0.0, 19950.0, 111319.0, 17.0, 15560.0, 7888.0], [107076.0, 68432.0, 0.0, 19950.0, 111319.0, 17.0, 15560.0, 7888.0], [107076.0, 68432.0, 0.0, 19950.0, 111319.0, 17.0, 15560.0, 7888.0]], [[100161.0, 52821.0, 0.0, 30418.0, 111266.0, 83.0, 6803.0, 3397.0], [100161.0, 52821.0, 0.0, 30418.0, 111266.0, 83.0, 6803.0, 3397.0], [100161.0, 52821.0, 0.0, 30418.0, 111266.0, 83.0, 6803.0, 3397.0], [100161.0, 52821.0, 0.0, 30418.0, 111266.0, 83.0, 6803.0, 3397.0]], [[90303.0, 37768.0, 17.0, 44375.0, 112309.0, 114.0, 3519.0, 1087.0], [90303.0, 37768.0, 17.0, 44375.0, 112309.0, 114.0, 3519.0, 1087.0], [90303.0, 37768.0, 17.0, 44375.0, 112309.0, 114.0, 3519.0, 1087.0], [90303.0, 37768.0, 17.0, 44375.0, 112309.0, 114.0, 3519.0, 1087.0]], [[76998.0, 23896.0, 675.0, 58087.0, 112256.0, 839.0, 6171.0, 222.0], [76998.0, 23896.0, 675.0, 58087.0, 112256.0, 839.0, 6171.0, 222.0], [76998.0, 23896.0, 675.0, 58087.0, 112256.0, 839.0, 6171.0, 222.0], [76998.0, 23896.0, 675.0, 58087.0, 112256.0, 839.0, 6171.0, 222.0]], [[64249.0, 14733.0, 1824.0, 68979.0, 113299.0, 2055.0, 13862.0, 52.0], [64249.0, 14733.0, 1824.0, 68979.0, 113299.0, 2055.0, 13862.0, 52.0], [64249.0, 14733.0, 1824.0, 68979.0, 113299.0, 2055.0, 13862.0, 52.0], [64249.0, 14733.0, 1824.0, 68979.0, 113299.0, 2055.0, 13862.0, 52.0]]], [[[99579.0, 70993.0, 0.0, 14897.0, 105798.0, 0.0, 9962.0, 9261.0], [99579.0, 70993.0, 0.0, 14897.0, 105798.0, 0.0, 9962.0, 9261.0], [99579.0, 70993.0, 0.0, 14897.0, 105798.0, 0.0, 9962.0, 9261.0], [99579.0, 70993.0, 0.0, 14897.0, 105798.0, 0.0, 9962.0, 9261.0]], [[91304.0, 56013.0, 0.0, 26089.0, 106410.0, 0.0, 3795.0, 4566.0], [91304.0, 56013.0, 0.0, 26089.0, 106410.0, 0.0, 3795.0, 4566.0], [91304.0, 56013.0, 0.0, 26089.0, 106410.0, 0.0, 3795.0, 4566.0], [91304.0, 56013.0, 0.0, 26089.0, 106410.0, 0.0, 3795.0, 4566.0]], [[80897.0, 41976.0, 0.0, 39897.0, 108294.0, 0.0, 3409.0, 1840.0], [80897.0, 41976.0, 0.0, 39897.0, 108294.0, 0.0, 3409.0, 1840.0], [80897.0, 41976.0, 0.0, 39897.0, 108294.0, 0.0, 3409.0, 1840.0], [80897.0, 41976.0, 0.0, 39897.0, 108294.0, 0.0, 3409.0, 1840.0]], [[68195.0, 29617.0, 309.0, 52070.0, 109069.0, 309.0, 8803.0, 616.0], [68195.0, 29617.0, 309.0, 52070.0, 109069.0, 309.0, 8803.0, 616.0], [68195.0, 29617.0, 309.0, 52070.0, 109069.0, 309.0, 8803.0, 616.0], [68195.0, 29617.0, 309.0, 52070.0, 109069.0, 309.0, 8803.0, 616.0]], [[56863.0, 21765.0, 931.0, 61292.0, 111104.0, 931.0, 18063.0, 192.0], [56863.0, 21765.0, 931.0, 61292.0, 111104.0, 931.0, 18063.0, 192.0], [56863.0, 21765.0, 931.0, 61292.0, 111104.0, 931.0, 18063.0, 192.0], [56863.0, 21765.0, 931.0, 61292.0, 111104.0, 931.0, 18063.0, 192.0]]], [[[85579.0, 72072.0, 0.0, 11594.0, 95411.0, 52.0, 4995.0, 11133.0], [85579.0, 72072.0, 0.0, 11594.0, 95411.0, 52.0, 4995.0, 11133.0], [85579.0, 72072.0, 0.0, 11594.0, 95411.0, 52.0, 4995.0, 11133.0], [85579.0, 72072.0, 0.0, 11594.0, 95411.0, 52.0, 4995.0, 11133.0]], [[76047.0, 58491.0, 0.0, 22312.0, 96231.0, 0.0, 2520.0, 6020.0], [76047.0, 58491.0, 0.0, 22312.0, 96231.0, 0.0, 2520.0, 6020.0], [76047.0, 58491.0, 0.0, 22312.0, 96231.0, 0.0, 2520.0, 6020.0], [76047.0, 58491.0, 0.0, 22312.0, 96231.0, 0.0, 2520.0, 6020.0]], [[65408.0, 46278.0, 0.0, 34315.0, 98237.0, 0.0, 5516.0, 2874.0], [65408.0, 46278.0, 0.0, 34315.0, 98237.0, 0.0, 5516.0, 2874.0], [65408.0, 46278.0, 0.0, 34315.0, 98237.0, 0.0, 5516.0, 2874.0], [65408.0, 46278.0, 0.0, 34315.0, 98237.0, 0.0, 5516.0, 2874.0]], [[53722.0, 36287.0, 0.0, 44202.0, 99679.0, 0.0, 13154.0, 1198.0], [53722.0, 36287.0, 0.0, 44202.0, 99679.0, 0.0, 13154.0, 1198.0], [53722.0, 36287.0, 0.0, 44202.0, 99679.0, 0.0, 13154.0, 1198.0], [53722.0, 36287.0, 0.0, 44202.0, 99679.0, 0.0, 13154.0, 1198.0]], [[44073.0, 29686.0, 0.0, 51223.0, 102429.0, 9.0, 22923.0, 350.0], [44073.0, 29686.0, 0.0, 51223.0, 102429.0, 9.0, 22923.0, 350.0], [44073.0, 29686.0, 0.0, 51223.0, 102429.0, 9.0, 22923.0, 350.0], [44073.0, 29686.0, 0.0, 51223.0, 102429.0, 9.0, 22923.0, 350.0]]], [[[71962.0, 75432.0, 838.0, 15693.0, 87568.0, 1914.0, 2925.0, 12915.0], [71962.0, 75432.0, 838.0, 15693.0, 87568.0, 1914.0, 2925.0, 12915.0], [71962.0, 75432.0, 838.0, 15693.0, 87568.0, 1914.0, 2925.0, 12915.0], [71962.0, 75432.0, 838.0, 15693.0, 87568.0, 1914.0, 2925.0, 12915.0]], [[62045.0, 63202.0, 502.0, 25441.0, 87943.0, 1569.0, 3112.0, 7491.0], [62045.0, 63202.0, 502.0, 25441.0, 87943.0, 1569.0, 3112.0, 7491.0], [62045.0, 63202.0, 502.0, 25441.0, 87943.0, 1569.0, 3112.0, 7491.0], [62045.0, 63202.0, 502.0, 25441.0, 87943.0, 1569.0, 3112.0, 7491.0]], [[51996.0, 52969.0, 283.0, 35028.0, 89927.0, 1453.0, 8076.0, 4002.0], [51996.0, 52969.0, 283.0, 35028.0, 89927.0, 1453.0, 8076.0, 4002.0], [51996.0, 52969.0, 283.0, 35028.0, 89927.0, 1453.0, 8076.0, 4002.0], [51996.0, 52969.0, 283.0, 35028.0, 89927.0, 1453.0, 8076.0, 4002.0]], [[41769.0, 44749.0, 96.0, 41981.0, 91333.0, 1141.0, 16014.0, 1819.0], [41769.0, 44749.0, 96.0, 41981.0, 91333.0, 1141.0, 16014.0, 1819.0], [41769.0, 44749.0, 96.0, 41981.0, 91333.0, 1141.0, 16014.0, 1819.0], [41769.0, 44749.0, 96.0, 41981.0, 91333.0, 1141.0, 16014.0, 1819.0]], [[34446.0, 38809.0, 36.0, 46912.0, 94682.0, 1009.0, 24845.0, 508.0], [34446.0, 38809.0, 36.0, 46912.0, 94682.0, 1009.0, 24845.0, 508.0], [34446.0, 38809.0, 36.0, 46912.0, 94682.0, 1009.0, 24845.0, 508.0], [34446.0, 38809.0, 36.0, 46912.0, 94682.0, 1009.0, 24845.0, 508.0]]]]
      end

      specify "standard relu conv test" do
        expect(image.shape.shape).to eq([1, 28, 28, 1])
        expect(filter.shape.shape).to eq([5, 5, 1, 4])

        conv = tf.nn.conv2d(image, filter, [1, 1, 1, 1], 'SAME')
        expected_output = JSON.parse(File.read(File.join('spec', 'fixtures', 'data.json')))
        result = sess.run(conv)

        expect(tr(sess.run(conv), 2)).to eq(tr(expected_output, 2))

        g = tf.gradients(tf.nn.relu(conv + b1), [image, filter])

        expected_grad_output = JSON.parse(File.read(File.join('spec', 'fixtures', 'expected_grad.json')))
        expected_grad_2_output = JSON.parse(File.read(File.join('spec', 'fixtures', 'expected_grad_2.json')))
        result = sess.run(g)

        expect(tr(result[0], 2)).to eq(tr(expected_grad_output, 2))
        expect(tr(result[1], 2)).to eq(tr(expected_grad_2_output, 2))
      end

      specify "standard relu conv test stride 2" do
        expect(filter_2.shape.shape).to eq([5, 5, 4, 8])
        input = JSON.parse(File.read(File.join('spec', 'fixtures', 'data_stride_2_input.json')))
        expect(input.shape).to eq([1, 28, 28, 4])
        conv = tf.nn.conv2d(input, filter_2, [1, 2, 2, 1], 'SAME')
        result = sess.run(conv)

        expected_output = JSON.parse(File.read(File.join('spec', 'fixtures', 'data_stride_2.json')))
        expect(result.shape).to eq([1, 14, 14, 8])
        expect(tr(result, 2)).to eq(tr(expected_output, 2))
      end

      specify "standard relu conv test stride 2 (gradient)" do
        input = tf.constant(JSON.parse(File.read(File.join('spec', 'fixtures', 'data_stride_2_input.json'))))
        conv = tf.nn.conv2d(input, filter_2, [1, 2, 2, 1], 'SAME')
        expect(conv.shape.shape).to eq([1, 14, 14, 8])
        g = tf.gradients(tf.nn.relu(conv + b2), [input, filter_2])
        expected_grad_output = JSON.parse(File.read(File.join('spec', 'fixtures', 'data_stride_2_grad.json')))
        result = sess.run(g)

        expect(tr(result[0], 2)).to eq(tr(expected_grad_output, 2))
        expect(tr(result[1], 2)).to eq(tr(expected_filter_2_grad, 2))
      end
    end
  end
end
