from conans import ConanFile, tools
from conan.tools.files import collect_libs, copy
import os


class MujocoConan(ConanFile):
    name = "mujoco"
    version = "2.1.5"
    url = "https://github.com/JaySinco/dev-setup"
    homepage = "https://github.com/deepmind/mujoco"
    description = "Multi-Joint dynamics with Contact. A general purpose physics simulator"
    license = "Apache-2.0"

    settings = "os", "arch", "compiler", "build_type"

    def layout(self):
        build_folder = "out"
        build_type = str(self.settings.build_type)
        self.folders.source = "src"
        self.folders.build = os.path.join(build_folder, build_type)

    def build(self):
        srcFile = os.path.join(
            tools.get_env("JAYSINCO_SOURCE_REPO"), self._src_file)
        tools.unzip(srcFile, destination=self.source_folder, strip_root=True)

    def package_id(self):
        del self.info.settings.compiler
        del self.info.settings.build_type

    def package(self):
        copy(self, "*.*", dst=os.path.join(self.package_folder, "lib"),
             src=os.path.join(self.source_folder, "lib"))
        copy(self, "*.dll", dst=os.path.join(self.package_folder, "bin"),
             src=os.path.join(self.source_folder, "lib"))
        copy(self, "*.h", dst=os.path.join(self.package_folder, "include"),
             src=os.path.join(self.source_folder, "include"))

    def package_info(self):
        self.cpp_info.set_property("cmake_file_name", "mujoco")
        self.cpp_info.set_property("cmake_target_name", "mujoco::mujoco")
        self.cpp_info.set_property("pkg_config_name", "mujoco")
        self.cpp_info.libs = collect_libs(self, folder="lib")

    @property
    def _src_file(self):
        suffix = "tar.gz" if self.settings.os == "Linux" else "zip"
        return "{}-{}-{}-{}.{}".format(self.name, self.version,
                                       str(self.settings.os).lower(),
                                       self.settings.arch, suffix)
