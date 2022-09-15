import sys, os
from myconanfile import MyConanFile
from conans import ConanFile, tools
from conan.tools.files import collect_libs, copy, rmdir
from conan.tools.microsoft import msvc_runtime_flag, is_msvc
from conan.tools.build import build_jobs
from conan.errors import ConanException


class BoostConan(MyConanFile):
    name = "boost"
    version = "1.79.0"
    homepage = "https://www.boost.org"
    description = "Boost provides free peer-reviewed portable C++ source libraries"
    license = "BSL-1.0"

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
        with tools.vcvars(self) if is_msvc(self) else tools.no_op():
            bootstrap_cmd = "{} {}".format(
                self._bootstrap_exe, self._bootstrap_flags)
            self.run(command=bootstrap_cmd, cwd=self.source_folder)

    def package_id(self):
        del self.info.settings.build_type

    def package(self):
        with tools.vcvars(self) if is_msvc(self) else tools.no_op():
            install_cmd = "{} {} install --prefix={}".format(
                self._b2_exe, self._build_flags, self.package_folder)
            self.run(command=install_cmd, cwd=self.source_folder)

        copy(self, "LICENSE_1_0.txt", dst=os.path.join(
            self.package_folder, "licenses"), src=self.source_folder)

    def package_info(self):
        self.cpp_info.set_property("cmake_find_mode", "none")

    @property
    def _b2_exe(self):
        return "b2.exe" if tools.os_info.is_windows else "./b2"

    @property
    def _bootstrap_exe(self):
        return "bootstrap.bat" if tools.os_info.is_windows else "./bootstrap.sh"

    @property
    def _toolset(self):
        if is_msvc(self):
            return "msvc"
        if self.settings.compiler in ["clang", "gcc"]:
            return str(self.settings.compiler)
        return None

    @property
    def _b2_architecture(self):
        if str(self.settings.arch).startswith("x86"):
            return "x86"
        return None

    @property
    def _bootstrap_flags(self):
        return "--without-libraries=python --with-toolset={}".format(self._toolset)

    @property
    def _b2_address_model(self):
        if str(self.settings.arch) in ("x86_64"):
            return "64"
        return "32"

    @property
    def _gnu_cxx11_abi(self):
        try:
            if str(self.settings.compiler.libcxx) == "libstdc++":
                return "0"
            if str(self.settings.compiler.libcxx) == "libstdc++11":
                return "1"
        except ConanException:
            pass
        return None

    @property
    def _b2_stdlib(self):
        return { "libstdc++11": "libstdc++" }.get(
            str(self.settings.compiler.libcxx),
            str(self.settings.compiler.libcxx)
        )

    @property
    def _b2_cxxflags(self):
        cxx_flags = []
        if self.options.get_safe("fPIC"):
            cxx_flags.append("-fPIC")
        if self.settings.compiler in ("clang", "apple-clang"):
            cxx_flags.append(f"-stdlib={self._b2_stdlib}")
        return " ".join(cxx_flags)

    @property
    def _b2_linkflags(self):
        link_flags = []
        if self.settings.compiler in ("clang", "apple-clang"):
            link_flags.append(f"-stdlib={self._b2_stdlib}")
        return " ".join(link_flags)

    @property
    def _build_flags(self):
        flags = []
        if self.settings.build_type == "Debug":
            flags.append("variant=debug")
        else:
            flags.append("variant=release")
        if is_msvc(self):
            flags.append(
                "runtime-link={}".format('static' if 'MT' in msvc_runtime_flag(self) else 'shared'))
        if self._gnu_cxx11_abi:
            flags.append(f"define=_GLIBCXX_USE_CXX11_ABI={self._gnu_cxx11_abi}")
        flags.append(f"link={'shared' if self.options.shared else 'static'}")
        flags.append(f"architecture={self._b2_architecture}")
        flags.append(f"address-model={self._b2_address_model}")
        flags.append(f"toolset={self._toolset}")
        flags.append("threading=multi")
        flags.append(f'cxxflags="{self._b2_cxxflags}"')
        flags.append(f'linkflags="{self._b2_linkflags}"')
        flags.append(f"-j{build_jobs(self)}")
        flags.append("--abbreviate-paths")
        flags.append("--layout=system")
        flags.append("--debug-configuration")
        flags.append(f"--build-dir={self.build_folder}")
        flags.append("-q")
        return " ".join(flags)
