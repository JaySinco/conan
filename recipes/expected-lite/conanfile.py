from conans import ConanFile, tools
from conan.tools.files import copy
import os


class ExpectedLiteConan(ConanFile):
    name = "expected-lite"
    version = "0.5.0"
    url = "https://github.com/JaySinco/dev-setup"
    homepage = "https://github.com/martinmoene/expected-lite"
    description = "Expected objects in C++11 and later in a single-file header-only library"
    license = "BSL-1.0"

    settings = "os", "arch", "compiler", "build_type"

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

    def build(self):
        pass

    def package_id(self):
        self.info.clear()

    def package(self):
        copy(self, "LICENSE.txt", dst=os.path.join(
            self.package_folder, "licenses"), src=self.source_folder)
        copy(self, "*.hpp", dst=os.path.join(self.package_folder, "include"),
             src=os.path.join(self.source_folder, "include"))

    def package_info(self):
        self.cpp_info.set_property("cmake_file_name", "expected-lite")
        self.cpp_info.set_property(
            "cmake_target_name", "nonstd::expected-lite")
        self.cpp_info.set_property("pkg_config_name", "expected-lite")
