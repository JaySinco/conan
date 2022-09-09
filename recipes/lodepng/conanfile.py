from conans import ConanFile, tools
from conan.tools.cmake import CMakeToolchain, CMake
from conan.tools.files import collect_libs, copy, rmdir
import os


class LodepngConan(ConanFile):
    name = "lodepng"
    version = "cci.20220718"
    url = "https://github.com/JaySinco/dev-setup"
    homepage = "https://github.com/lvandeve/lodepng"
    description = "PNG encoder and decoder in C and C++, without dependencies"
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
            tools.get_env("JAYSINCO_SOURCE_REPO"), "%s-%s.zip" % (self.name, self.version))
        tools.unzip(srcFile, destination=self.source_folder, strip_root=True)
        copy(self, "CMakeLists.txt", dst=self.source_folder,
             src=os.path.dirname(os.path.abspath(__file__)))

    def generate(self):
        tc = CMakeToolchain(self)
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        copy(self, "LICENSE", dst=os.path.join(
            self.package_folder, "licenses"), src=self.source_folder)
        cmake = CMake(self)
        cmake.install()

    def package_info(self):
        self.cpp_info.set_property("cmake_file_name", "lodepng")
        self.cpp_info.set_property("cmake_target_name", "lodepng")
        self.cpp_info.set_property("pkg_config_name", "lodepng")
        self.cpp_info.libs = collect_libs(self, folder="lib")
