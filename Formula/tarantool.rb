class Tarantool < Formula
  desc "In-memory database and Lua application server."
  homepage "https://tarantool.org/"
  url "http://download.tarantool.org/tarantool/1.6/src/tarantool-1.6.8.772.tar.gz"
  version "1.6.8-772"
  sha256 "e07913d3416fcf855071e7b82eed0c5bcdb81a6e587fa2d900a9755ed5bb220c"
  revision 2

  head "https://github.com/tarantool/tarantool.git", :branch => "1.7", :shallow => false

  bottle do
    sha256 "06452c73ff96c97c21bc874059a9fbe71a2a3b030325f618500a8e83700dd10d" => :sierra
    sha256 "bf47282a6990eaa65fcea8f05c75dcbde904c87c33cc9dc7a0ab54917e0e257b" => :el_capitan
    sha256 "580b317f6916c9b52c9dc05d351e5655837e27ba228420ccdb0a8f7780fdeaae" => :yosemite
  end

  depends_on "cmake" => :build
  depends_on "openssl"
  depends_on "readline"

  def install
    args = std_cmake_args

    # Fix "dyld: lazy symbol binding failed: Symbol not found: _clock_gettime"
    # Reported 19 Sep 2016 https://github.com/tarantool/tarantool/issues/1777
    if MacOS.version == "10.11" && MacOS::Xcode.installed? && MacOS::Xcode.version >= "8.0"
      args << "-DHAVE_CLOCK_GETTIME:INTERNAL=0"
      inreplace "src/trivia/util.h", "#ifndef HAVE_CLOCK_GETTIME",
                                     "#ifdef UNDEFINED_GIBBERISH"
    end

    args << "-DCMAKE_INSTALL_MANDIR=#{doc}"
    args << "-DCMAKE_INSTALL_SYSCONFDIR=#{etc}"
    args << "-DCMAKE_INSTALL_LOCALSTATEDIR=#{var}"
    args << "-DENABLE_DIST=ON"
    args << "-DOPENSSL_ROOT_DIR=#{Formula["openssl"].opt_prefix}"

    system "cmake", ".", *args
    system "make"
    system "make", "install"
  end

  def post_install
    local_user = ENV["USER"]
    inreplace etc/"default/tarantool", /(username\s*=).*/, "\\1 '#{local_user}'"

    (var/"lib/tarantool").mkpath
    (var/"log/tarantool").mkpath
    (var/"run/tarantool").mkpath
  end

  test do
    (testpath/"test.lua").write <<-EOS.undent
        box.cfg{}
        local s = box.schema.create_space("test")
        s:create_index("primary")
        local tup = {1, 2, 3, 4}
        s:insert(tup)
        local ret = s:get(tup[1])
        if (ret[3] ~= tup[3]) then
          os.exit(-1)
        end
        os.exit(0)
    EOS
    system bin/"tarantool", "#{testpath}/test.lua"
  end
end
