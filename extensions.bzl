load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _node_module_from_http_archive(name, url, integrity): 
    http_archive(
        name = name,
        url = url,
        integrity = integrity,
        build_file_content = """
filegroup(
    name = "{name}",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)
    """.format(name = name)
    )

def _repo_for_package(package_name, package):
    if "resolved" not in package:
      return
    
    labelized_package_name = package_name.replace("/", "_").replace("-", "_").replace('.', '_')
    resolved = package["resolved"]
    integrity = package["integrity"]
    
    _node_module_from_http_archive(labelized_package_name, resolved, integrity)
        
def _my_extension(module_ctx):
    for module in module_ctx.modules:
        for from_file in module.tags.from_file:
            lockfile = json.decode(module_ctx.read(from_file.package_lock))
            packages = lockfile["packages"]
            for package_name in packages:
                _repo_for_package(package_name, packages[package_name])
    pass

_from_file_tag = tag_class(
    attrs = {
        "package_lock": attr.label(
            mandatory = True,
            allow_single_file = True,
        )
    }
)

my_extension = module_extension(
    implementation = _my_extension,
    tag_classes = {
        "from_file": _from_file_tag
    }
)