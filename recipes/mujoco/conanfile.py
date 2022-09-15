from conans import ConanFile, tools
from conan.tools.cmake import CMakeToolchain, CMake, CMakeDeps
from conan.tools.files import collect_libs, copy, rmdir
import os


class MujocoConan(ConanFile):
    name = "mujoco"
    version = "2.2.2"
    url = "https://github.com/JaySinco/dev-setup"
    homepage = "https://github.com/deepmind/mujoco"
    description = "Multi-Joint dynamics with Contact. A general purpose physics simulator"
    license = "Apache-2.0"

    settings = "os", "arch", "compiler", "build_type"
    options = {
        "shared": [True, False],
        "fPIC": [True, False],
    }
    default_options = {
        "shared": True,
        "fPIC": True,
    }

    def config_options(self):
        if self.settings.os == "Windows":
            del self.options.fPIC

    def configure(self):
        if self.options.shared:
            del self.options.fPIC

    def requirements(self):
        self.requires("libccd/2.1@jaysinco/stable")
        self.requires("qhull/8.0.2@jaysinco/stable")
        self.requires("lodepng/v2022.07.18@jaysinco/stable")
        self.requires("tinyobjloader/v2020.02.28@jaysinco/stable")
        self.requires("tinyxml2/9.0.0@jaysinco/stable")

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
        self._patch_sources()

    def generate(self):
        tc = CMakeToolchain(self)
        tc.variables["MUJOCO_BUILD_EXAMPLES"] = False
        tc.variables["MUJOCO_BUILD_SIMULATE"] = False
        tc.variables["MUJOCO_BUILD_TESTS"] = False
        tc.variables["MUJOCO_TEST_PYTHON_UTIL"] = False
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
        self.cpp_info.set_property("cmake_file_name", "mujoco")
        self.cpp_info.set_property("cmake_target_name", "mujoco::mujoco")
        self.cpp_info.set_property("pkg_config_name", "mujoco")
        self.cpp_info.libs = collect_libs(self, folder="lib")

    def _patch_sources(self):
        patches = [
            "0001-fix-cmake-findorfetch-dependencies.patch"
        ]
        dirname = os.path.dirname(os.path.abspath(__file__))
        for pat in patches:
            tools.patch(self.source_folder, os.path.join(dirname, "patches", pat))
