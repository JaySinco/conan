from conans import ConanFile, tools
from conan.tools.cmake import CMakeToolchain, CMake, CMakeDeps
from conan.tools.files import collect_libs, copy, rmdir
import os


class ZlibConan(ConanFile):
    name = "zlib"
    version = "1.2.12"
    url = "https://github.com/JaySinco/dev-setup"
    homepage = "https://zlib.net"
    description = "A Massively Spiffy Yet Delicately Unobtrusive Compression Library"
    license = "Zlib"

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

    def generate(self):
        tc = CMakeToolchain(self)
        tc.variables["SKIP_INSTALL_ALL"] = False
        tc.variables["SKIP_INSTALL_LIBRARIES"] = False
        tc.variables["SKIP_INSTALL_HEADERS"] = False
        tc.variables["SKIP_INSTALL_FILES"] = True
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        copy(self, "zlib.h", dst=os.path.join(self.package_folder, "include"), src=self.source_folder)
        copy(self, "zconf.h", dst=os.path.join(self.package_folder, "include"), src=self.build_folder)
        copy(self, "zlibstatic.lib", dst=os.path.join(self.package_folder, "lib"), src=self.build_folder)

    def package_info(self):
        self.cpp_info.set_property("cmake_file_name", "ZLIB")
        self.cpp_info.set_property("cmake_target_name", "ZLIB::ZLIB")
        self.cpp_info.set_property("pkg_config_name", "zlib")
        self.cpp_info.libs = collect_libs(self, folder="lib")
