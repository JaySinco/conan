import sys, os
from myconanfile import MyConanFile
from conans import ConanFile, tools
from conan.tools.files import rmdir, rm, collect_libs, copy
from conan.tools.microsoft import is_msvc
from conan.errors import ConanInvalidConfiguration


class NpcapConan(MyConanFile):
    name = "npcap"
    version = "1.13"
    homepage = "https://npcap.com/"
    description = "Windows port of the libpcap library"
    license = "LicenseRef-NPCAP"

    settings = "os", "arch", "compiler", "build_type"

    def package_id(self):
        del self.info.settings.compiler
        del self.info.settings.build_type

    def validate(self):
        if self.info.settings.os != "Windows":
            raise ConanInvalidConfiguration(f"{self.ref} requires Windows")

    def build(self):
        srcFile = self._src_abspath(f"npcap-sdk-{self.version}.zip")
        tools.unzip(srcFile, destination=self.source_folder, strip_root=False)

    def package(self):
        copy(self, "*.h", dst=os.path.join(self.package_folder, "include"),
            src=os.path.join(self.source_folder, "Include"))
        if self.settings.arch == "x86_64":
            copy(self, "*.lib", dst=os.path.join(self.package_folder, "lib"),
                src=os.path.join(self.source_folder, "Lib", "x64"))
        elif self.settings.arch == "armv8":
            copy(self, "*.lib", dst=os.path.join(self.package_folder, "lib"),
                src=os.path.join(self.source_folder, "Lib", "ARM64"))
        else:
            copy(self, "*.lib", dst=os.path.join(self.package_folder, "lib"),
                src=os.path.join(self.source_folder, "Lib"))

    def package_info(self):
        self.cpp_info.set_property("cmake_file_name", "npcap")
        self.cpp_info.set_property("cmake_target_name", "npcap::npcap")
        self.cpp_info.set_property("pkg_config_name", "npcap")
        self.cpp_info.libs = collect_libs(self, folder="lib")
