class IcetouchAT36 < Formula
  desc "Implementation of Ice for iOS and OS X targeting Xcode development"
  homepage "https://zeroc.com"
  url "https://github.com/zeroc-ice/icetouch.git", :tag => "v3.6.4"

  bottle do
    root_url "https://zeroc.com/download/homebrew/bottles"
    cellar :any
    sha256 "95d778a69a7c585b658864c9e7b0091fdf78e4b396e94d1023c81d9ad5295890" => :sierra
  end

  depends_on "mcpp"

  def install
    # Unset ICE_HOME as it interferes with the build
    ENV.delete("ICE_HOME")
    ENV.delete("USE_BIN_DIST")
    ENV.delete("CPPFLAGS")
    ENV.O2

    args = %W[
      prefix=#{prefix}
      OPTIMIZE=yes
      MCPP_HOME=#{Formula["mcpp"].opt_prefix}
    ]

    system "make", "install", *args
  end

  test do
    (testpath/"Hello.ice").write <<~EOS
      module Test {
        interface Hello {
          void sayHello();
        };
      };
    EOS
    (testpath/"Test.cpp").write <<~EOS
      #include <Ice/Ice.h>
      #include <Hello.h>

      class HelloI : public Test::Hello {
      public:
        virtual void sayHello(const Ice::Current&) {}
      };

      int main(int argc, char* argv[]) {
        Ice::CommunicatorPtr communicator;
        communicator = Ice::initialize(argc, argv);
        Ice::ObjectAdapterPtr adapter =
            communicator->createObjectAdapterWithEndpoints("Hello", "default -h localhost");
        adapter->add(new HelloI, communicator->stringToIdentity("hello"));
        adapter->activate();
        communicator->destroy();
        return 0;
      }
    EOS
    system "#{lib}/IceTouch/Cpp/bin/slice2cpp", "hello.ice"
    system "xcrun", "--sdk", "macosx", "clang++", "-c", "-I#{lib}/IceTouch/Cpp/macosx.sdk/usr/include", "-I.", "Hello.cpp"
    system "xcrun", "--sdk", "macosx", "clang++", "-c", "-I#{lib}/IceTouch/Cpp/macosx.sdk/usr/include", "-I.", "Test.cpp"
    system "xcrun", "--sdk", "macosx", "clang++", "-L#{lib}/IceTouch/Cpp/macosx.sdk/usr/lib", "-o", "test", "Test.o", \
      "Hello.o", "-lIce", "-framework", "Security", "-framework", "Foundation", "-lbz2", "-liconv"
    system "./test", "--Ice.InitPlugins=0"
  end
end
