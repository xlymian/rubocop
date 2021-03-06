# frozen_string_literal: true

describe RuboCop::Cop::Layout::ExtraSpacing, :config do
  subject(:cop) { described_class.new(config) }

  shared_examples 'common behavior' do
    it 'registers an offense for alignment with token not preceded by space' do
      # The = and the ( are on the same column, but this is not for alignment,
      # it's just a mistake.
      inspect_source(<<-RUBY.strip_indent)
        website("example.org")
        name   = "Jill"
      RUBY
      expect(cop.offenses.size).to eq(1)
    end

    it 'accepts aligned values of an implicit hash literal' do
      source = <<-RUBY.strip_indent
        register(street1:    '1 Market',
                 street2:    '#200',
                 :city =>    'Some Town',
                 state:      'CA',
                 postal_code:'99999-1111')
      RUBY
      inspect_source(source)
      expect(cop.offenses).to be_empty
    end

    it 'accepts space between key and value in a hash with hash rockets' do
      source = <<-RUBY.strip_indent
        ospf_h = {
          'ospfTest'    => {
            'foo'      => {
              area: '0.0.0.0', cost: 10, hello: 30, pass: true },
            'longname' => {
              area: '1.1.1.38', pass: false },
            'vlan101'  => {
              area: '2.2.2.101', cost: 5, hello: 20, pass: true }
          },
          'TestOspfInt' => {
            'x'               => {
              area: '0.0.0.19' },
            'vlan290'         => {
              area: '2.2.2.29', cost: 200, hello: 30, pass: true },
            'port-channel100' => {
              area: '3.2.2.29', cost: 25, hello: 50, pass: false }
          }
        }
      RUBY
      inspect_source(source)
      expect(cop.offenses).to be_empty
    end

    context 'when spaces are present in a single-line hash literal' do
      it 'registers an offense for hashes with symbol keys' do
        inspect_source('hash = {a:   1,  b:    2}')
        expect(cop.offenses.size).to eq(3)
      end

      it 'registers an offense for hashes with hash rockets' do
        source = <<-RUBY.strip_indent
          let(:single_line_hash) {
            {"a"   => "1", "b" => "2"}
          }
        RUBY

        inspect_source(source)
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.first.line).to eq(2)
      end
    end

    it 'can handle extra space before a float' do
      source = <<-RUBY.strip_indent
        {:a => "a",
         :b => [nil,  2.5]}
      RUBY
      inspect_source(source)
      expect(cop.offenses.size).to eq(1)
    end

    it 'can handle unary plus in an argument list' do
      source = <<-RUBY.strip_indent
        assert_difference(MyModel.count, +2,
                          3,  +3, # Extra spacing only here.
                          4,+4)
      RUBY
      inspect_source(source)
      expect(cop.offenses.map { |o| o.location.line }).to eq([2])
    end

    it 'gives the correct line' do
      inspect_source(<<-RUBY.strip_indent)
        class A   < String
        end
      RUBY
      expect(cop.offenses.first.location.line).to eq(1)
    end

    it 'registers an offense for double extra spacing on variable assignment' do
      inspect_source('m    = "hello"')
      expect(cop.offenses.size).to eq(1)
    end

    it 'ignores whitespace at the beginning of the line' do
      expect_no_offenses('  m = "hello"')
    end

    it 'ignores whitespace inside a string' do
      expect_no_offenses('m = "hello   this"')
    end

    it 'ignores trailing whitespace' do
      inspect_source(['      class Benchmarker < Performer     ',
                      '      end'])
      expect(cop.offenses).to be_empty
    end

    it 'registers an offense on class inheritance' do
      inspect_source(<<-RUBY.strip_indent)
        class A   < String
        end
      RUBY
      expect(cop.offenses.size).to eq(1)
    end

    it 'auto-corrects a line indented with mixed whitespace' do
      new_source = autocorrect_source(<<-RUBY.strip_indent)
        website("example.org")
        name    = "Jill"
      RUBY
      expect(new_source).to eq(<<-RUBY.strip_indent)
        website("example.org")
        name = "Jill"
      RUBY
    end

    it 'auto-corrects the class inheritance' do
      new_source = autocorrect_source(<<-RUBY.strip_indent)
        class A   < String
        end
      RUBY
      expect(new_source).to eq(<<-RUBY.strip_indent)
        class A < String
        end
      RUBY
    end
  end

  sources = {
    'lining up assignments' => <<-RUBY.strip_indent,
      website = "example.org"
      name    = "Jill"
    RUBY

    'lining up assignments with empty lines and comments in between' =>
    <<-RUBY.strip_indent,
      a   += 1

      # Comment
      aa   = 2
      bb   = 3

      a  ||= 1
    RUBY

    'aligning with the same character' => <<-RUBY.strip_margin('|'),
      |      y, m = (year * 12 + (mon - 1) + n).divmod(12)
      |      m,   = (m + 1)                    .divmod(1)
    RUBY

    'lining up different kinds of assignments' => <<-RUBY.strip_indent,
      type_name ||= value.class.name if value
      type_name   = type_name.to_s   if type_name

      type_name  = value.class.name if     value
      type_name += type_name.to_s   unless type_name

      a  += 1
      aa -= 2
    RUBY

    'aligning comments on non-adjacent lines' => <<-RUBY.strip_indent,
      include_examples 'aligned',   'var = until',  'test'

      include_examples 'unaligned', "var = if",     'test'
    RUBY

    'aligning = on lines where there are trailing comments' =>
    <<-RUBY.strip_indent,
      a_long_var_name = 100 # this is 100
      short_name1     = 2

      clear

      short_name2     = 2
      a_long_var_name = 100 # this is 100

      clear

      short_name3     = 2   # this is 2
      a_long_var_name = 100 # this is 100
    RUBY

    'aligning tokens with empty line between' => <<-RUBY.strip_indent,
      unless nochdir
        Dir.chdir "/"    # Release old working directory.
      end

      File.umask 0000    # Ensure sensible umask.
    RUBY

    'aligning long assignment expressions that include line breaks' =>
    <<-RUBY.strip_indent
      size_attribute_name    = FactoryGirl.create(:attribute,
                                                  name:   'Size',
                                                  values: %w{small large})
      carrier_attribute_name = FactoryGirl.create(:attribute,
                                                  name:   'Carrier',
                                                  values: %w{verizon})
    RUBY
  }.freeze

  context 'when AllowForAlignment is true' do
    let(:cop_config) do
      { 'AllowForAlignment' => true, 'ForceEqualSignAlignment' => false }
    end

    include_examples 'common behavior'

    context 'with extra spacing for alignment purposes' do
      sources.each do |reason, src|
        context "such as #{reason}" do
          it 'allows it' do
            inspect_source(src)
            expect(cop.offenses).to be_empty
          end
        end
      end
    end
  end

  context 'when AllowForAlignment is false' do
    let(:cop_config) do
      { 'AllowForAlignment' => false, 'ForceEqualSignAlignment' => false }
    end

    include_examples 'common behavior'

    context 'with extra spacing for alignment purposes' do
      sources.each do |reason, src|
        context "such as #{reason}" do
          it 'registers offense(s)' do
            inspect_source(src)
            expect(cop.offenses).not_to be_empty
          end
        end
      end
    end
  end

  context 'when ForceEqualSignAlignment is true' do
    let(:cop_config) do
      { 'AllowForAlignment' => true, 'ForceEqualSignAlignment' => true }
    end

    it 'registers an offense if consecutive assignments are not aligned' do
      inspect_source(<<-RUBY.strip_indent)
        a = 1
        bb = 2
        ccc = 3
      RUBY
      expect(cop.offenses.size).to eq(3)
      expect(cop.messages).to eq(
        ['`=` is not aligned with the following assignment.',
         '`=` is not aligned with the preceding assignment.',
         '`=` is not aligned with the preceding assignment.']
      )
    end

    it 'does not register an offense if assignments are separated by blanks' do
      expect_no_offenses(<<-RUBY.strip_indent)
        a = 1

        bb = 2

        ccc = 3
      RUBY
    end

    it 'does not register an offense if assignments are aligned' do
      expect_no_offenses(<<-RUBY.strip_indent)
        a   = 1
        bb  = 2
        ccc = 3
      RUBY
    end

    it 'aligns the first assignment with the following assignment' do
      expect_no_offenses(<<-RUBY.strip_indent)
        # comment
        a   = 1
        bb  = 2
      RUBY
    end

    it 'autocorrects consecutive assignments which are not aligned' do
      new_source = autocorrect_source(<<-RUBY.strip_indent)
        a = 1
        bb = 2
        ccc = 3

        abcde        = 1
        a                 = 2
        abc = 3
      RUBY
      expect(new_source).to eq(<<-RUBY.strip_indent)
        a   = 1
        bb  = 2
        ccc = 3

        abcde = 1
        a     = 2
        abc   = 3
      RUBY
    end

    it 'autocorrects consecutive operator assignments which are not aligned' do
      new_source = autocorrect_source(<<-RUBY.strip_indent)
        a += 1
        bb = 2
        ccc <<= 3

        abcde        = 1
        a                 *= 2
        abc ||= 3
      RUBY
      expect(new_source).to eq(<<-RUBY.strip_indent)
        a    += 1
        bb    = 2
        ccc <<= 3

        abcde = 1
        a    *= 2
        abc ||= 3
      RUBY
    end

    it 'autocorrects consecutive aref assignments which are not aligned' do
      new_source = autocorrect_source(<<-RUBY.strip_indent)
        a[1] = 1
        bb[2,3] = 2
        ccc[:key] = 3

        abcde[0]        = 1
        a                 = 2
        abc += 3
      RUBY
      expect(new_source).to eq(<<-RUBY.strip_indent)
        a[1]      = 1
        bb[2,3]   = 2
        ccc[:key] = 3

        abcde[0] = 1
        a        = 2
        abc     += 3
      RUBY
    end

    it 'autocorrects consecutive attribute assignments which are not aligned' do
      new_source = autocorrect_source(<<-RUBY.strip_indent)
        a.attr = 1
        bb &&= 2
        ccc.s = 3

        abcde.blah        = 1
        a.attribute_name              = 2
        abc[1] = 3
      RUBY
      expect(new_source).to eq(<<-RUBY.strip_indent)
        a.attr = 1
        bb   &&= 2
        ccc.s  = 3

        abcde.blah       = 1
        a.attribute_name = 2
        abc[1]           = 3
      RUBY
    end

    it 'does not register an offense when optarg equals is not aligned with ' \
       'assignment equals sign' do
      inspect_source(<<-RUBY.strip_indent)
        def method(arg = 1)
          var = arg
        end
      RUBY
      expect(cop.offenses).to be_empty
    end
  end
end
