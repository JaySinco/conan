from conans import ConanFile, tools
from conan.tools.cmake import CMakeToolchain, CMake
from conan.tools.files import collect_libs, copy, rmdir
from conan.tools.microsoft import is_msvc
import os


class QhullConan(ConanFile):
    name = "qhull"
    version = "8.0.2"
    url = "https://github.com/JaySinco/dev-setup"
    homepage = "http://www.qhull.org"
    description = "Qhull computes the convex hull, Delaunay triangulation, Voronoi diagram, halfspace intersection about a point, furthest-site Delaunay triangulation, and furthest-site Voronoi diagram"
    license = "Qhull"

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
        self._patch_sources()

    def generate(self):
        tc = CMakeToolchain(self)
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        copy(self, "COPYING.txt", dst=os.path.join(
            self.package_folder, "licenses"), src=self.source_folder)
        cmake = CMake(self)
        cmake.install()
        rmdir(self, os.path.join(self.package_folder, "doc"))
        rmdir(self, os.path.join(self.package_folder, "man"))
        rmdir(self, os.path.join(self.package_folder, "lib", "pkgconfig"))
        rmdir(self, os.path.join(self.package_folder, "share"))

    def package_info(self):
        self.cpp_info.set_property("cmake_find_mode", "none")

    def _patch_sources(self):
        patches = [
            "0001-fix-cmake-minimum-required-location.patch"
        ]
        dirname = os.path.dirname(os.path.abspath(__file__))
        for pat in patches:
            tools.patch(self.source_folder, os.path.join(dirname, "patches", pat))