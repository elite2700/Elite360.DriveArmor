#!/usr/bin/env python3
"""
Regenerate DriveArmor.xcodeproj/project.pbxproj with all current Swift files.
Preserves CocoaPods integration references.
"""
import hashlib
import os
import glob

def make_uuid(seed: str) -> str:
    return hashlib.md5(seed.encode()).hexdigest()[:24].upper()

def quote_if_needed(path: str) -> str:
    """Quote paths containing special chars like + or spaces."""
    if any(c in path for c in ('+', ' ', '-', '(', ')')):
        return f'"{path}"'
    return path

# Gather all source files
os.chdir("/workspaces/Elite360.DriveArmor")

swift_files = sorted(glob.glob("DriveArmor/**/*.swift", recursive=True))
test_files = sorted(glob.glob("DriveArmorTests/**/*.swift", recursive=True))
resource_files = ["DriveArmor/Resources/GoogleService-Info.plist", "DriveArmor/Resources/Assets.xcassets"]

# Known CocoaPods framework references (from pod install)
pods_main_fw = "Pods_DriveArmor.framework"
pods_test_fw = "Pods_DriveArmorTests.framework"

# Fixed UUIDs for project structure
PROJECT_UUID = make_uuid("project_root")
MAIN_TARGET_UUID = make_uuid("target_DriveArmor")
TEST_TARGET_UUID = make_uuid("target_DriveArmorTests")
UITEST_TARGET_UUID = make_uuid("target_DriveArmorUITests")

MAIN_GROUP_UUID = make_uuid("group_main")
SOURCES_PHASE_UUID = make_uuid("sources_phase_main")
RESOURCES_PHASE_UUID = make_uuid("resources_phase_main")
FRAMEWORKS_PHASE_UUID = make_uuid("frameworks_phase_main")
TEST_SOURCES_PHASE_UUID = make_uuid("sources_phase_tests")
TEST_FW_PHASE_UUID = make_uuid("frameworks_phase_tests")

PRODUCTS_GROUP_UUID = make_uuid("group_products")
APP_PRODUCT_UUID = make_uuid("product_app")
TEST_PRODUCT_UUID = make_uuid("product_tests")

# Config UUIDs
CONFIG_LIST_PROJECT = make_uuid("configlist_project")
CONFIG_LIST_MAIN = make_uuid("configlist_main")
CONFIG_LIST_TEST = make_uuid("configlist_test")
CONFIG_DEBUG_PROJ = make_uuid("config_debug_proj")
CONFIG_RELEASE_PROJ = make_uuid("config_release_proj")
CONFIG_DEBUG_MAIN = make_uuid("config_debug_main")
CONFIG_RELEASE_MAIN = make_uuid("config_release_main")
CONFIG_DEBUG_TEST = make_uuid("config_debug_test")
CONFIG_RELEASE_TEST = make_uuid("config_release_test")

# Pods references
PODS_MAIN_FW_UUID = make_uuid("fw_pods_main")
PODS_TEST_FW_UUID = make_uuid("fw_pods_test")
PODS_MAIN_BUILD_UUID = make_uuid("build_fw_pods_main")
PODS_TEST_BUILD_UUID = make_uuid("build_fw_pods_test")

# Generate UUIDs for each file
file_refs = {}  # path -> fileRef UUID
build_files = {}  # path -> buildFile UUID

for f in swift_files + test_files + resource_files:
    file_refs[f] = make_uuid(f"fileref_{f}")
    build_files[f] = make_uuid(f"buildfile_{f}")

# Group structure
def get_group_path(filepath):
    return os.path.dirname(filepath)

groups = {}  # group_path -> list of (child_uuid, is_group, name)
all_group_paths = set()
for f in swift_files + resource_files:
    gp = get_group_path(f)
    while gp:
        all_group_paths.add(gp)
        gp = os.path.dirname(gp)

for f in test_files:
    gp = get_group_path(f)
    while gp:
        all_group_paths.add(gp)
        gp = os.path.dirname(gp)

group_uuids = {}
for gp in sorted(all_group_paths):
    group_uuids[gp] = make_uuid(f"group_{gp}")

# Build PBXBuildFile section
lines = []
lines.append("// !$*UTF8*$!")
lines.append("{")
lines.append("\tarchiveVersion = 1;")
lines.append("\tclasses = {")
lines.append("\t};")
lines.append("\tobjectVersion = 56;")
lines.append("\tobjects = {")
lines.append("")

# PBXBuildFile
lines.append("/* Begin PBXBuildFile section */")
for f in sorted(swift_files):
    name = os.path.basename(f)
    lines.append(f"\t\t{build_files[f]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {name} */; }};")

for f in sorted(test_files):
    name = os.path.basename(f)
    lines.append(f"\t\t{build_files[f]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {name} */; }};")

for f in resource_files:
    name = os.path.basename(f)
    lines.append(f"\t\t{build_files[f]} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {name} */; }};")

# Pods frameworks
lines.append(f"\t\t{PODS_MAIN_BUILD_UUID} /* {pods_main_fw} in Frameworks */ = {{isa = PBXBuildFile; fileRef = {PODS_MAIN_FW_UUID} /* {pods_main_fw} */; }};")
lines.append(f"\t\t{PODS_TEST_BUILD_UUID} /* {pods_test_fw} in Frameworks */ = {{isa = PBXBuildFile; fileRef = {PODS_TEST_FW_UUID} /* {pods_test_fw} */; }};")
lines.append("/* End PBXBuildFile section */")
lines.append("")

# PBXFileReference
lines.append("/* Begin PBXFileReference section */")
lines.append(f"\t\t{APP_PRODUCT_UUID} /* DriveArmor.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = DriveArmor.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
lines.append(f"\t\t{TEST_PRODUCT_UUID} /* DriveArmorTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = DriveArmorTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};")

for f in sorted(swift_files + test_files):
    name = os.path.basename(f)
    qname = quote_if_needed(name)
    qpath = quote_if_needed(f)
    lines.append(f"\t\t{file_refs[f]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {qname}; sourceTree = \"<group>\"; }};")

for f in resource_files:
    name = os.path.basename(f)
    if f.endswith(".xcassets"):
        ftype = "folder.assetcatalog"
    else:
        ftype = "text.plist.xml"
    lines.append(f"\t\t{file_refs[f]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {name}; sourceTree = \"<group>\"; }};")

lines.append(f"\t\t{PODS_MAIN_FW_UUID} /* {pods_main_fw} */ = {{isa = PBXFileReference; explicitFileType = wrapper.framework; includeInIndex = 0; path = {pods_main_fw}; sourceTree = BUILT_PRODUCTS_DIR; }};")
lines.append(f"\t\t{PODS_TEST_FW_UUID} /* {pods_test_fw} */ = {{isa = PBXFileReference; explicitFileType = wrapper.framework; includeInIndex = 0; path = {pods_test_fw}; sourceTree = BUILT_PRODUCTS_DIR; }};")
lines.append("/* End PBXFileReference section */")
lines.append("")

# PBXFrameworksBuildPhase
lines.append("/* Begin PBXFrameworksBuildPhase section */")
lines.append(f"\t\t{FRAMEWORKS_PHASE_UUID} /* Frameworks */ = {{")
lines.append(f"\t\t\tisa = PBXFrameworksBuildPhase;")
lines.append(f"\t\t\tbuildActionMask = 2147483647;")
lines.append(f"\t\t\tfiles = (")
lines.append(f"\t\t\t\t{PODS_MAIN_BUILD_UUID} /* {pods_main_fw} in Frameworks */,")
lines.append(f"\t\t\t);")
lines.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append(f"\t\t}};")
lines.append(f"\t\t{TEST_FW_PHASE_UUID} /* Frameworks */ = {{")
lines.append(f"\t\t\tisa = PBXFrameworksBuildPhase;")
lines.append(f"\t\t\tbuildActionMask = 2147483647;")
lines.append(f"\t\t\tfiles = (")
lines.append(f"\t\t\t\t{PODS_TEST_BUILD_UUID} /* {pods_test_fw} in Frameworks */,")
lines.append(f"\t\t\t);")
lines.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append(f"\t\t}};")
lines.append("/* End PBXFrameworksBuildPhase section */")
lines.append("")

# PBXGroup - build group hierarchy
# Collect children for each group
group_children = {}  # group_path -> [(uuid, name, is_group)]
for gp in sorted(all_group_paths):
    group_children[gp] = []

# Add files to their parent groups
for f in sorted(swift_files + resource_files):
    parent = get_group_path(f)
    name = os.path.basename(f)
    group_children.setdefault(parent, []).append((file_refs[f], name, False))

for f in sorted(test_files):
    parent = get_group_path(f)
    name = os.path.basename(f)
    group_children.setdefault(parent, []).append((file_refs[f], name, False))

# Add subgroups to their parent groups
for gp in sorted(all_group_paths):
    parent = os.path.dirname(gp)
    if parent and parent in all_group_paths:
        name = os.path.basename(gp)
        group_children.setdefault(parent, []).append((group_uuids[gp], name, True))

lines.append("/* Begin PBXGroup section */")

# Root group
ROOT_GROUP_UUID = make_uuid("group_root")
lines.append(f"\t\t{ROOT_GROUP_UUID} = {{")
lines.append(f"\t\t\tisa = PBXGroup;")
lines.append(f"\t\t\tchildren = (")
# Top-level children: DriveArmor group, DriveArmorTests group, Products group
if "DriveArmor" in group_uuids:
    lines.append(f"\t\t\t\t{group_uuids['DriveArmor']} /* DriveArmor */,")
if "DriveArmorTests" in group_uuids:
    lines.append(f"\t\t\t\t{group_uuids['DriveArmorTests']} /* DriveArmorTests */,")
lines.append(f"\t\t\t\t{PRODUCTS_GROUP_UUID} /* Products */,")
lines.append(f"\t\t\t);")
lines.append(f"\t\t\tsourceTree = \"<group>\";")
lines.append(f"\t\t}};")

# Products group
lines.append(f"\t\t{PRODUCTS_GROUP_UUID} /* Products */ = {{")
lines.append(f"\t\t\tisa = PBXGroup;")
lines.append(f"\t\t\tchildren = (")
lines.append(f"\t\t\t\t{APP_PRODUCT_UUID} /* DriveArmor.app */,")
lines.append(f"\t\t\t\t{TEST_PRODUCT_UUID} /* DriveArmorTests.xctest */,")
lines.append(f"\t\t\t);")
lines.append(f"\t\t\tname = Products;")
lines.append(f"\t\t\tsourceTree = \"<group>\";")
lines.append(f"\t\t}};")

# All other groups
for gp in sorted(all_group_paths):
    if gp in ("DriveArmor", "DriveArmorTests"):
        # Top-level source groups
        pass
    uuid = group_uuids[gp]
    name = os.path.basename(gp)
    children = sorted(group_children.get(gp, []), key=lambda x: (not x[2], x[1]))  # groups first, then files
    
    lines.append(f"\t\t{uuid} /* {name} */ = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    for child_uuid, child_name, is_group in children:
        lines.append(f"\t\t\t\t{child_uuid} /* {child_name} */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tpath = {quote_if_needed(name)};")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")

lines.append("/* End PBXGroup section */")
lines.append("")

# PBXNativeTarget
lines.append("/* Begin PBXNativeTarget section */")
lines.append(f"\t\t{MAIN_TARGET_UUID} /* DriveArmor */ = {{")
lines.append(f"\t\t\tisa = PBXNativeTarget;")
lines.append(f"\t\t\tbuildConfigurationList = {CONFIG_LIST_MAIN};")
lines.append(f"\t\t\tbuildPhases = (")
lines.append(f"\t\t\t\t{SOURCES_PHASE_UUID} /* Sources */,")
lines.append(f"\t\t\t\t{FRAMEWORKS_PHASE_UUID} /* Frameworks */,")
lines.append(f"\t\t\t\t{RESOURCES_PHASE_UUID} /* Resources */,")
lines.append(f"\t\t\t);")
lines.append(f"\t\t\tbuildRules = (")
lines.append(f"\t\t\t);")
lines.append(f"\t\t\tdependencies = (")
lines.append(f"\t\t\t);")
lines.append(f"\t\t\tname = DriveArmor;")
lines.append(f"\t\t\tproductName = DriveArmor;")
lines.append(f"\t\t\tproductReference = {APP_PRODUCT_UUID} /* DriveArmor.app */;")
lines.append(f"\t\t\tproductType = \"com.apple.product-type.application\";")
lines.append(f"\t\t}};")

lines.append(f"\t\t{TEST_TARGET_UUID} /* DriveArmorTests */ = {{")
lines.append(f"\t\t\tisa = PBXNativeTarget;")
lines.append(f"\t\t\tbuildConfigurationList = {CONFIG_LIST_TEST};")
lines.append(f"\t\t\tbuildPhases = (")
lines.append(f"\t\t\t\t{TEST_SOURCES_PHASE_UUID} /* Sources */,")
lines.append(f"\t\t\t\t{TEST_FW_PHASE_UUID} /* Frameworks */,")
lines.append(f"\t\t\t);")
lines.append(f"\t\t\tbuildRules = (")
lines.append(f"\t\t\t);")
lines.append(f"\t\t\tdependencies = (")
lines.append(f"\t\t\t);")
lines.append(f"\t\t\tname = DriveArmorTests;")
lines.append(f"\t\t\tproductName = DriveArmorTests;")
lines.append(f"\t\t\tproductReference = {TEST_PRODUCT_UUID} /* DriveArmorTests.xctest */;")
lines.append(f"\t\t\tproductType = \"com.apple.product-type.bundle.unit-test\";")
lines.append(f"\t\t}};")
lines.append("/* End PBXNativeTarget section */")
lines.append("")

# PBXProject
lines.append("/* Begin PBXProject section */")
lines.append(f"\t\t{PROJECT_UUID} /* Project object */ = {{")
lines.append(f"\t\t\tisa = PBXProject;")
lines.append(f"\t\t\tattributes = {{")
lines.append(f"\t\t\t\tBuildIndependentTargetsInParallel = 1;")
lines.append(f"\t\t\t\tLastSwiftUpdateCheck = 1500;")
lines.append(f"\t\t\t\tLastUpgradeCheck = 1500;")
lines.append(f"\t\t\t}};")
lines.append(f"\t\t\tbuildConfigurationList = {CONFIG_LIST_PROJECT};")
lines.append(f"\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
lines.append(f"\t\t\tdevelopmentRegion = en;")
lines.append(f"\t\t\thasScannedForEncodings = 0;")
lines.append(f"\t\t\tknownRegions = (")
lines.append(f"\t\t\t\ten,")
lines.append(f"\t\t\t\tBase,")
lines.append(f"\t\t\t);")
lines.append(f"\t\t\tmainGroup = {ROOT_GROUP_UUID};")
lines.append(f"\t\t\tproductRefGroup = {PRODUCTS_GROUP_UUID} /* Products */;")
lines.append(f"\t\t\tprojectDirPath = \"\";")
lines.append(f"\t\t\tprojectRoot = \"\";")
lines.append(f"\t\t\ttargets = (")
lines.append(f"\t\t\t\t{MAIN_TARGET_UUID} /* DriveArmor */,")
lines.append(f"\t\t\t\t{TEST_TARGET_UUID} /* DriveArmorTests */,")
lines.append(f"\t\t\t);")
lines.append(f"\t\t}};")
lines.append("/* End PBXProject section */")
lines.append("")

# PBXResourcesBuildPhase
lines.append("/* Begin PBXResourcesBuildPhase section */")
lines.append(f"\t\t{RESOURCES_PHASE_UUID} /* Resources */ = {{")
lines.append(f"\t\t\tisa = PBXResourcesBuildPhase;")
lines.append(f"\t\t\tbuildActionMask = 2147483647;")
lines.append(f"\t\t\tfiles = (")
for f in resource_files:
    name = os.path.basename(f)
    lines.append(f"\t\t\t\t{build_files[f]} /* {name} in Resources */,")
lines.append(f"\t\t\t);")
lines.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append(f"\t\t}};")
lines.append("/* End PBXResourcesBuildPhase section */")
lines.append("")

# PBXSourcesBuildPhase
lines.append("/* Begin PBXSourcesBuildPhase section */")
lines.append(f"\t\t{SOURCES_PHASE_UUID} /* Sources */ = {{")
lines.append(f"\t\t\tisa = PBXSourcesBuildPhase;")
lines.append(f"\t\t\tbuildActionMask = 2147483647;")
lines.append(f"\t\t\tfiles = (")
for f in sorted(swift_files):
    name = os.path.basename(f)
    lines.append(f"\t\t\t\t{build_files[f]} /* {name} in Sources */,")
lines.append(f"\t\t\t);")
lines.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append(f"\t\t}};")

lines.append(f"\t\t{TEST_SOURCES_PHASE_UUID} /* Sources */ = {{")
lines.append(f"\t\t\tisa = PBXSourcesBuildPhase;")
lines.append(f"\t\t\tbuildActionMask = 2147483647;")
lines.append(f"\t\t\tfiles = (")
for f in sorted(test_files):
    name = os.path.basename(f)
    lines.append(f"\t\t\t\t{build_files[f]} /* {name} in Sources */,")
lines.append(f"\t\t\t);")
lines.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append(f"\t\t}};")
lines.append("/* End PBXSourcesBuildPhase section */")
lines.append("")

# XCBuildConfiguration
common_debug = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ENABLE_MODULES": "YES",
    "SWIFT_OPTIMIZATION_LEVEL": '"-Onone"',
    "DEBUG_INFORMATION_FORMAT": '"dwarf-with-dsym"',
    "GCC_OPTIMIZATION_LEVEL": "0",
    "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
    "ONLY_ACTIVE_ARCH": "YES",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": '"$(inherited) DEBUG"',
}
common_release = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ENABLE_MODULES": "YES",
    "SWIFT_OPTIMIZATION_LEVEL": '"-Owholemodule"',
    "DEBUG_INFORMATION_FORMAT": '"dwarf-with-dsym"',
    "SWIFT_COMPILATION_MODE": "wholemodule",
}

target_settings = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "CODE_SIGN_ENTITLEMENTS": '"DriveArmor/DriveArmor.entitlements"',
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "INFOPLIST_FILE": '"DriveArmor/Resources/Info.plist"',
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "LD_RUNPATH_SEARCH_PATHS": '"$(inherited) @executable_path/Frameworks"',
    "MARKETING_VERSION": "1.0.0",
    "PRODUCT_BUNDLE_IDENTIFIER": '"com.elite360.DriveArmor"',
    "PRODUCT_NAME": '"$(TARGET_NAME)"',
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": '"1,2"',
    "GENERATE_INFOPLIST_FILE": "NO",
}

test_settings = {
    "BUNDLE_LOADER": '"$(TEST_HOST)"',
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "LD_RUNPATH_SEARCH_PATHS": '"$(inherited) @executable_path/Frameworks @loader_path/Frameworks"',
    "PRODUCT_BUNDLE_IDENTIFIER": '"com.elite360.DriveArmorTests"',
    "PRODUCT_NAME": '"$(TARGET_NAME)"',
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": '"1,2"',
    "TEST_HOST": '"$(BUILT_PRODUCTS_DIR)/DriveArmor.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/DriveArmor"',
    "GENERATE_INFOPLIST_FILE": "YES",
}

def write_config(uuid, name, settings):
    lines.append(f"\t\t{uuid} /* {name} */ = {{")
    lines.append(f"\t\t\tisa = XCBuildConfiguration;")
    lines.append(f"\t\t\tname = {name};")
    lines.append(f"\t\t\tbuildSettings = {{")
    for k, v in sorted(settings.items()):
        lines.append(f"\t\t\t\t{k} = {v};")
    lines.append(f"\t\t\t}};")
    lines.append(f"\t\t}};")

lines.append("/* Begin XCBuildConfiguration section */")
# Project-level configs
proj_debug = {**common_debug, "SDKROOT": "iphoneos", "IPHONEOS_DEPLOYMENT_TARGET": "17.0"}
proj_release = {**common_release, "SDKROOT": "iphoneos", "IPHONEOS_DEPLOYMENT_TARGET": "17.0"}
write_config(CONFIG_DEBUG_PROJ, "Debug", proj_debug)
write_config(CONFIG_RELEASE_PROJ, "Release", proj_release)

# Main target configs
main_debug = {**target_settings}
main_release = {**target_settings}
write_config(CONFIG_DEBUG_MAIN, "Debug", main_debug)
write_config(CONFIG_RELEASE_MAIN, "Release", main_release)

# Test target configs
test_debug = {**test_settings}
test_release = {**test_settings}
write_config(CONFIG_DEBUG_TEST, "Debug", test_debug)
write_config(CONFIG_RELEASE_TEST, "Release", test_release)
lines.append("/* End XCBuildConfiguration section */")
lines.append("")

# XCConfigurationList
lines.append("/* Begin XCConfigurationList section */")
for cl_uuid, cl_name, debug_uuid, release_uuid in [
    (CONFIG_LIST_PROJECT, "Project", CONFIG_DEBUG_PROJ, CONFIG_RELEASE_PROJ),
    (CONFIG_LIST_MAIN, "DriveArmor", CONFIG_DEBUG_MAIN, CONFIG_RELEASE_MAIN),
    (CONFIG_LIST_TEST, "DriveArmorTests", CONFIG_DEBUG_TEST, CONFIG_RELEASE_TEST),
]:
    lines.append(f"\t\t{cl_uuid} /* Build configuration list for {cl_name} */ = {{")
    lines.append(f"\t\t\tisa = XCConfigurationList;")
    lines.append(f"\t\t\tbuildConfigurations = (")
    lines.append(f"\t\t\t\t{debug_uuid} /* Debug */,")
    lines.append(f"\t\t\t\t{release_uuid} /* Release */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tdefaultConfigurationIsVisible = 0;")
    lines.append(f"\t\t\tdefaultConfigurationName = Release;")
    lines.append(f"\t\t}};")
lines.append("/* End XCConfigurationList section */")
lines.append("")

lines.append("\t};")
lines.append(f"\trootObject = {PROJECT_UUID} /* Project object */;")
lines.append("}")
lines.append("")

# Write the file
output_path = "DriveArmor.xcodeproj/project.pbxproj"
with open(output_path, "w") as f:
    f.write("\n".join(lines))

print(f"Generated {output_path} with {len(swift_files)} source files, {len(test_files)} test files, {len(resource_files)} resources")
print(f"Total lines: {len(lines)}")
