import sys, os
from myconanfile import MyConanFile
from conans import ConanFile, tools
from conan.tools.cmake import CMakeToolchain, CMake, CMakeDeps
from conan.tools.microsoft import msvc_runtime_flag, is_msvc
from conan.tools.files import collect_libs, copy, rmdir
from conans.errors import ConanInvalidConfiguration


class FollyConan(MyConanFile):
    name = "folly"
    version = "v2022.01.31.00"
    homepage = "https://github.com/facebook/folly"
    description = "An open-source C++ components library developed and used at Facebook"
    license = "Apache-2.0"

    settings = "os", "arch", "compiler", "build_type"
    options = {
        "shared": [True, False],
        "fPIC": [True, False],
    }
    default_options = {
        "shared": False,
        "fPIC": True,
    }

    def config_options(self):
        if self.settings.os == "Windows":
            del self.options.fPIC

    def configure(self):
        if self.options.shared:
            del self.options.fPIC

    def validate(self):
        if self.settings.os in ["Macos", "Windows"] and self.options.shared:
            raise ConanInvalidConfiguration(
                "Folly could not be built on {} as shared library".format(self.settings.os))

    def requirements(self):
        self.requires(self._ref_pkg("boost/1.79.0"))
        self.requires(self._ref_pkg("bzip2/1.0.8"))
        self.requires(self._ref_pkg("double-conversion/3.2.1"))
        self.requires(self._ref_pkg("gflags/2.2.2"))
        self.requires(self._ref_pkg("glog/0.6.0"))
        self.requires(self._ref_pkg("libevent/2.1.12"))
        self.requires(self._ref_pkg("openssl/1.1.1q"))
        self.requires(self._ref_pkg("lz4/1.9.4"))
        self.requires(self._ref_pkg("snappy/1.1.9"))
        self.requires(self._ref_pkg("zlib/1.2.12"))
        self.requires(self._ref_pkg("zstd/1.5.2"))
        self.requires(self._ref_pkg("fmt/8.1.1"))
        # self.requires("libsodium/1.0.18")
        # self.requires("xz_utils/5.2.5")
        # if not is_msvc(self):
        #     self.requires("libdwarf/20191104")
        # if self.settings.os == "Linux":
        #     self.requires("libiberty/9.1.0")
        #     self.requires("libunwind/1.5.0")

    def source(self):
        srcFile = self._src_abspath(f"{self.name}-{self.version}.tar.gz")
        tools.unzip(srcFile, destination=self.source_folder, strip_root=False)
        self._patch_sources(self._dirname(__file__), [
            "0001-fix-windows-minmax.patch",
            "0002-disable-gflags-namespace-check.patch",
        ])

    def generate(self):
        tc = CMakeToolchain(self)
        tc.cache_variables["CMAKE_POLICY_DEFAULT_CMP0077"] = "NEW"
        tc.variables["FOLLY_HAVE_UNALIGNED_ACCESS_EXITCODE"] = "0"
        tc.variables["FOLLY_HAVE_UNALIGNED_ACCESS_EXITCODE__TRYRUN_OUTPUT"] = ""
        tc.variables["FOLLY_HAVE_LINUX_VDSO_EXITCODE"] = "0"
        tc.variables["FOLLY_HAVE_LINUX_VDSO_EXITCODE__TRYRUN_OUTPUT"] = ""
        tc.variables["FOLLY_HAVE_WCHAR_SUPPORT_EXITCODE"] = "0"
        tc.variables["FOLLY_HAVE_WCHAR_SUPPORT_EXITCODE__TRYRUN_OUTPUT"] = ""
        tc.variables["HAVE_VSNPRINTF_ERRORS_EXITCODE"] = "0"
        tc.variables["HAVE_VSNPRINTF_ERRORS_EXITCODE__TRYRUN_OUTPUT"] = ""
        tc.variables["CMAKE_POSITION_INDEPENDENT_CODE"] = self.options.get_safe("fPIC", True)
        cxx_std_flag = tools.cppstd_flag(self.settings)
        cxx_std_value = cxx_std_flag.split('=')[1] if cxx_std_flag else "c++17"
        tc.variables["CXX_STD"] = cxx_std_value
        if is_msvc(self):
            tc.variables["MSVC_LANGUAGE_VERSION"] = cxx_std_value
            tc.variables["MSVC_ENABLE_ALL_WARNINGS"] = False
            tc.variables["MSVC_USE_STATIC_RUNTIME"] = "MT" in msvc_runtime_flag(self)
        tc.variables["CMAKE_PREFIX_PATH"] = self._cmake_path()
        tc.generate()
        cmake_deps = CMakeDeps(self)
        cmake_deps.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        copy(self, "LICENSE", dst=os.path.join(
            self.package_folder, "licenses"), src=self.source_folder)
        cmake = CMake(self)
        cmake.install()
        rmdir(self, os.path.join(self.package_folder, "lib", "pkgconfig"))
        rmdir(self, os.path.join(self.package_folder, "lib", "cmake"))

    def package_info(self):
        self.cpp_info.set_property("cmake_file_name", "folly")
        self.cpp_info.set_property("cmake_target_name", "Folly::folly")
        self.cpp_info.set_property("pkg_config_name", "libfolly")
        self.cpp_info.libs = collect_libs(self, folder="lib")
        self.cpp_info.requires = [
            "bzip2::bzip2",
            "double-conversion::double-conversion",
            "gflags::gflags",
            "glog::glog",
            "libevent::libevent",
            "lz4::lz4",
            "openssl::openssl",
            "snappy::snappy",
            "zlib::zlib",
            "zstd::zstd",
            "fmt::fmt",
            # "libsodium::libsodium",
            # "xz_utils::xz_utils"
        ]
        # if not is_msvc(self):
        #     self.cpp_info.requires.append("libdwarf::libdwarf")
        if self.settings.os == "Windows":
            self.cpp_info.system_libs.extend(["ws2_32", "iphlpapi", "crypt32"])
        elif self.settings.os == "Linux":
            # self.cpp_info.requires.extend(["libiberty::libiberty", "libunwind::libunwind"])
            # self.cpp_info.defines.extend(["FOLLY_HAVE_ELF", "FOLLY_HAVE_DWARF"])
            self.cpp_info.system_libs.extend(["pthread", "dl", "rt"])

    def _cmake_path(self):
        prefix_path = []
        cmake_dir = {
            "boost" : "lib/cmake",
        }
        for pkg in cmake_dir:
            prefix_path.append(self._normalize_path(
                os.path.join(self.deps_cpp_info[pkg].cpp_info.rootpath, cmake_dir[pkg])))

        return "%s;${CMAKE_PREFIX_PATH}" % (";".join(prefix_path))
