require 'minitest/spec'

module Minitest
  module SkipDSL
    def xit desc = "anonymous", &block
      block ||= proc { skip "(no tests defined)" }

      @specs ||= 0
      @specs += 1

      name = "skip_%04d_%s" % [ @specs, desc ]

      undef_klasses = self.children.reject { |c| c.public_method_defined? name }

      define_method name, &block

      undef_klasses.each do |undef_klass|
        undef_klass.send :undef_method, name
      end

      name
    end

    def nuke_test_methods! # :nodoc:
      self.public_instance_methods.grep(/^test_|skip_/).each do |name|
        self.send :undef_method, name
      end
    end
  end

  Spec.extend(SkipDSL)
end

module Kernel
  def xdescribe(desc, *additional_desc, &block)
    stack = Minitest::Spec.describe_stack
    name  = [stack.last, desc, *additional_desc].compact.join("::")
    sclas = stack.last || if Class === self && kind_of?(Minitest::Spec::DSL) then
                            self
                          else
                            Minitest::Spec.spec_type desc, *additional_desc
                          end

    cls = sclas.create name, desc

    stack.push cls
    cls.singleton_class.send(:define_method, :it, cls.method(:xit))
    cls.class_eval(&block)
    stack.pop
    cls
  end

  private :xdescribe
end
