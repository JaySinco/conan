from conans import ConanFile, tools
from conan.tools.files import collect_libs, copy, rmdir
from conan.tools.microsoft import msvc_runtime_flag, is_msvc
from conan.tools.build import build_jobs
import os


class BoostConan(ConanFile):
    name = "boost"
    version = "1.79.0"
    url = "https://github.com/JaySinco/dev-setup"
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

    def layout(self):
        build_folder = "out"
        build_type = str(self.settings.build_type)
        self.folders.source = "src"
        self.folders.build = os.path.join(build_folder, build_type)

    def source(self):
        srcFile = os.path.join(
            tools.get_env("JAYSINCO_SOURCE_REPO"), "%s-%s.tar.gz" % (self.name, self.version))
        tools.unzip(srcFile, destination=self.source_folder, strip_root=True)
        bootstrap_cmd = "{} {}".format(
            self._bootstrap_exe, self._bootstrap_flags)
        self.run(command=bootstrap_cmd, cwd=self.source_folder)

    def package_id(self):
        del self.info.settings.build_type

    def package(self):
        install_cmd = "{} {} install --prefix={}".format(
            self._b2_exe, self._build_flags, self.package_folder)
        self.run(command=install_cmd, cwd=self.source_folder)

        copy(self, "LICENSE_1_0.txt", dst=os.path.join(
            self.package_folder, "licenses"), src=self.source_folder)

    def package_info(self):
        self.cpp_info.set_property("cmake_find_mode", "none")

    @property
    def _b2_exe(self):
        return "b2.exe" if tools.os_info.is_windows else "b2"

    @property
    def _bootstrap_exe(self):
        return "bootstrap.bat" if tools.os_info.is_windows else "bootstrap.sh"

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
    def _b2_cxxflags(self):
        cxx_flags = []
        if self.options.get_safe("fPIC"):
            cxx_flags.append("-fPIC")
        return " ".join(cxx_flags)

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
        flags.append(f"link={'shared' if self.options.shared else 'static'}")
        flags.append(f"architecture={self._b2_architecture}")
        flags.append(f"address-model={self._b2_address_model}")
        flags.append(f"toolset={self._toolset}")
        flags.append("threading=multi")
        flags.append(f'cxxflags="{self._b2_cxxflags}"')
        flags.append(f"-j{build_jobs(self)}")
        flags.append("--abbreviate-paths")
        flags.append("--layout=system")
        flags.append("--debug-configuration")
        flags.append(f"--build-dir={self.build_folder}")
        flags.append("-q")
        return " ".join(flags)
