module VirtualBox
  class Platform
    class << self
      def mac?
        platform.include?("darwin")
      end

      def windows?
        platform.include?("mswin") || platform.include?("mingw") || platform.include?("cygwin")
      end

      def linux?
        platform.include?("linux")
      end

      def solaris?
        platform.include?("solaris")
      end

      def platform
        Config::CONFIG['target_os']
      end
    end
  end
end
