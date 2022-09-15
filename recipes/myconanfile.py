from conans import ConanFile, tools
from conan.tools.files import collect_libs, copy, rmdir
from typing import List
import os

class MyConanFile(ConanFile):
    url = "https://github.com/JaySinco/dev-setup"

    def export(self):
        self._export_myconanfile()

    def layout(self):
        build_folder = "out"
        build_type = str(self.settings.build_type)
        self.folders.source = "src"
        self.folders.build = os.path.join(build_folder, build_type)
        self.folders.generators = os.path.join(
            self.folders.build, "generators")

    def _src_abspath(self, filename: str):
        return os.path.join(tools.get_env("JAYSINCO_SOURCE_REPO"), filename)

    def _requires_with_ref(self, pkgname: str):
        return self.requires(f"{pkgname}@jaysinco/stable")

    def _file_dirname(self, file__: str):
        return os.path.dirname(os.path.abspath(file__))

    def _patch_sources(self, dirname: str, patches: List[str]):
        for pat in patches:
            tools.patch(self.source_folder, os.path.join(dirname, "patches", pat))

    def _export_myconanfile(self):
        copy(self, "myconanfile.py", dst=self.export_folder, src=self._file_dirname(__file__))

    def _normalize_path(self, path):
        if self.settings.os == "Windows":
            return path.replace("\\", "/")
        else:
            return path