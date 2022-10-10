import sys
import os
from myconanfile import MyConanFile
from conans import ConanFile, tools, AutoToolsBuildEnvironment
from conan.tools.env import VirtualBuildEnv
from conan.tools.microsoft import msvc_runtime_flag, is_msvc
from conan.tools.cmake import CMakeToolchain, CMake
from conan.tools.files import collect_libs, copy, rmdir
from conan.tools.gnu import Autotools, AutotoolsToolchain, AutotoolsDeps, PkgConfigDeps
from contextlib import contextmanager
import functools


class LibiconvConan(MyConanFile):
    name = "libiconv"
    version = "1.17"
    homepage = "https://www.gnu.org/software/libiconv/"
    description = "Convert text to and from Unicode"
    license = "LGPL-2.1"

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

    def source(self):
        srcFile = self._src_abspath(f"{self.name}-{self.version}.tar.gz")
        tools.unzip(srcFile, destination=self.source_folder, strip_root=True)

    def build(self):
        with self._build_context():
            autotools = self._configure_autotools()
            autotools.make()

    # def package(self):
    #     copy(self, "LICENSE", dst=os.path.join(
    #         self.package_folder, "licenses"), src=self.source_folder)
    #     cmake = CMake(self)
    #     cmake.install()

    # def package_info(self):
    #     self.cpp_info.set_property("cmake_file_name", "lodepng")
    #     self.cpp_info.set_property("cmake_target_name", "lodepng")
    #     self.cpp_info.set_property("pkg_config_name", "lodepng")
    #     self.cpp_info.libs = collect_libs(self, folder="lib")

    @property
    def _is_clang_cl(self):
        return self.settings.compiler == "clang" and self.settings.os == "Windows"

    @property
    def _use_winbash(self):
        return tools.os_info.is_windows and (self.settings.compiler == "gcc" or tools.cross_building(self))

    @contextmanager
    def _build_context(self):
        env_vars = {}
        if is_msvc(self) or self._is_clang_cl:
            cc = "cl" if is_msvc(self) else os.environ.get("CC", "clang-cl")
            cxx = "cl" if is_msvc(self) else os.environ.get("CXX", "clang-cl")
            lib = "lib" if is_msvc(self) else os.environ.get("AR", "llvm-lib")
            build_aux_path = os.path.join(self.source_folder, "build-aux")
            lt_compile = tools.unix_path(os.path.join(build_aux_path, "compile"))
            lt_ar = tools.unix_path(os.path.join(build_aux_path, "ar-lib"))
            env_vars.update({
                "CC": "{} {} -nologo".format(lt_compile, cc),
                "CXX": "{} {} -nologo".format(lt_compile, cxx),
                "LD": "link",
                "STRIP": ":",
                "AR": "{} {}".format(lt_ar, lib),
                "RANLIB": ":",
                "NM": "dumpbin -symbols"
            })
            env_vars["win32_target"] = "_WIN32_WINNT_VISTA"
            env_vars["MSYS2_PATH_TYPE"] = "inherit"

        if not tools.cross_building(self) or is_msvc(self) or self._is_clang_cl:
            rc = None
            if self.settings.arch == "x86":
                rc = "windres --target=pe-i386"
            elif self.settings.arch == "x86_64":
                rc = "windres --target=pe-x86-64"
            if rc:
                env_vars["RC"] = rc
                env_vars["WINDRES"] = rc
        if self._use_winbash:
            env_vars["RANLIB"] = ":"

        with tools.vcvars(self.settings) if (is_msvc(self) or self._is_clang_cl) else tools.no_op():
            with tools.chdir(self.source_folder):
                with tools.environment_append(env_vars):
                    yield

    @functools.lru_cache(1)
    def _configure_autotools(self):
        host = None
        build = None
        if is_msvc(self) or self._is_clang_cl:
            build = False
            if self.settings.arch == "x86":
                host = "i686-w64-mingw32"
            elif self.settings.arch == "x86_64":
                host = "x86_64-w64-mingw32"

        autotools = AutoToolsBuildEnvironment(self, win_bash=tools.os_info.is_windows)

        configure_args = []
        if self.options.shared:
            configure_args.extend(["--disable-static", "--enable-shared"])
        else:
            configure_args.extend(["--enable-static", "--disable-shared"])

        if (self.settings.compiler == "Visual Studio" and tools.Version(self.settings.compiler.version) >= "12") or \
           self.settings.compiler == "msvc":
            autotools.flags.append("-FS")

        autotools.configure(args=configure_args, host=host, build=build)
        return autotools
