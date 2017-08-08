module Testm

    class Tesclass
        def initialize(d)
            Testm::d(d)

        end
    end

    def Testm.d(d)
        folder = d
        puts "lets see if we can print #{d}"
    end
end

Testm::Tesclass.new "kdkdkdkd"


Testm.somemethod