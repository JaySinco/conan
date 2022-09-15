from conans import ConanFile, tools
from conan.tools.cmake import CMakeToolchain, CMake
from conan.tools.files import collect_libs, copy, rmdir
import os


class Bzip2Conan(ConanFile):
    name = "bzip2"
    version = "1.0.8"
    url = "https://github.com/JaySinco/dev-setup"
    homepage = "http://www.bzip.org"
    description = "bzip2 is a free and open-source file compression program that uses the Burrows Wheeler algorithm."
    license = "bzip2"

    settings = "os", "arch", "compiler", "build_type"
    options = {
        "shared": [True, False],
        "fPIC": [True, False],
        "build_executable": [True, False],
    }
    default_options = {
        "shared": False,
        "fPIC": True,
        "build_executable": True,
    }

    def config_options(self):
        if self.settings.os == "Windows":
            del self.options.fPIC
        self.license = "bzip2-{}".format(self.version)

    def configure(self):
        if self.options.shared:
            del self.options.fPIC

    def layout(self):
        build_folder = "out"
        build_type = str(self.settings.build_type)
        self.folders.source = "src"
        self.folders.build = os.path.join(build_folder, build_type)
        self.folders.generators = os.path.join(
            self.folders.build, "generators")

    def source(self):
        srcFile = os.path.join(
            tools.get_env("JAYSINCO_SOURCE_REPO"), "%s-%s.tar.gz" % (self.name, self.version))
        tools.unzip(srcFile, destination=self.source_folder, strip_root=True)
        copy(self, "CMakeLists.txt", dst=self.source_folder,
             src=os.path.dirname(os.path.abspath(__file__)))

    def generate(self):
        tc = CMakeToolchain(self)
        tc.variables["BZ2_VERSION_STRING"] = self.version
        tc.variables["BZ2_VERSION_MAJOR"] = str(self.version).split(".")[0]
        tc.variables["BZ2_BUILD_EXE"] = self.options.build_executable
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package_id(self):
        del self.info.options.with_fmt_alias

    def package(self):
        copy(self, "LICENSE", dst=os.path.join(
            self.package_folder, "licenses"), src=self.source_folder)
        cmake = CMake(self)
        cmake.install()

    def package_info(self):
        self.cpp_info.set_property("cmake_file_name", "BZip2")
        self.cpp_info.set_property("cmake_target_name", "BZip2::BZip2")
        self.cpp_info.libs = collect_libs(self, folder="lib")
