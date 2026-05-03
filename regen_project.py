#!/usr/bin/env python3
"""
regen_project.py — Regenerates MacCleaner.xcodeproj/project.pbxproj
Run: python3 ~/Documents/MacCleaner/regen_project.py
"""

import hashlib, os, re, sys

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
PBXPROJ     = os.path.join(PROJECT_DIR, "MacCleaner.xcodeproj", "project.pbxproj")

SWIFT_FILES = [
    "AppState.swift",
    "SystemService.swift",
    "Models.swift",
    "ScanServices.swift",
    "SharedComponents.swift",
    "MacCleanerApp.swift",
    "ContentView.swift",
    "CleanerViewModel.swift",
    "MenuBarView.swift",
    "DashboardView.swift",
    "SmartScanView.swift",
    "SystemJunkView.swift",
    "LargeFilesView.swift",
    "AppUninstallerView.swift",
    "PrivacyView.swift",
    "MemoryView.swift",
    "MaintenanceView.swift",
]

def uid(seed: str) -> str:
    return hashlib.sha1(seed.encode()).hexdigest()[:24].upper()

def gen() -> str:
    proj_uid   = uid("project")
    target_uid = uid("target")
    group_uid  = uid("group_sources")
    asset_uid  = uid("assets")
    plist_uid  = uid("infoplist")
    sources_phase_uid = uid("build_phase_sources")
    resources_phase_uid = uid("build_phase_resources")
    asset_build_uid = uid("asset_build")
    plist_build_uid = uid("plist_build")
    config_list_proj   = uid("config_list_project")
    config_list_target = uid("config_list_target")
    debug_proj_uid     = uid("debug_project_config")
    release_proj_uid   = uid("release_project_config")
    debug_target_uid   = uid("debug_target_config")
    release_target_uid = uid("release_target_config")

    # Per-file UIDs
    file_refs  = {f: uid(f"fileref_{f}") for f in SWIFT_FILES}
    build_refs = {f: uid(f"buildref_{f}") for f in SWIFT_FILES}
    asset_fileref = uid("fileref_Assets.xcassets")
    plist_fileref = uid("fileref_Info.plist")

    lines = ['// !$*UTF8*$!', '{']
    lines += ['\tarchiveVersion = 1;', '\tclasses = {', '\t};',
              '\tobjectVersion = 56;', '\tobjects = {', '']

    # --- PBXBuildFile ---
    lines.append('/* Begin PBXBuildFile section */')
    for f in SWIFT_FILES:
        lines.append(f'\t\t{build_refs[f]} /* {f} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {f} */; }};')
    lines.append(f'\t\t{asset_build_uid} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {asset_fileref} /* Assets.xcassets */; }};')
    lines.append('/* End PBXBuildFile section */')
    lines.append('')

    # --- PBXFileReference ---
    lines.append('/* Begin PBXFileReference section */')
    for f in SWIFT_FILES:
        lines.append(f'\t\t{file_refs[f]} /* {f} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {f}; sourceTree = "<group>"; }};')
    lines.append(f'\t\t{asset_fileref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};')
    lines.append(f'\t\t{plist_fileref} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};')
    lines.append(f'\t\t{target_uid}P /* MacCleaner.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = MacCleaner.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    lines.append('/* End PBXFileReference section */')
    lines.append('')

    # --- PBXGroup ---
    lines.append('/* Begin PBXGroup section */')
    lines.append(f'\t\t{uid("main_group")} /* = */ = {{')
    lines.append('\t\t\tisa = PBXGroup;')
    lines.append('\t\t\tchildren = (')
    lines.append(f'\t\t\t\t{group_uid} /* MacCleaner */,')
    lines.append(f'\t\t\t\t{uid("products_group")} /* Products */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\tsourceTree = "<group>";')
    lines.append('\t\t};')
    lines.append(f'\t\t{uid("products_group")} /* Products */ = {{')
    lines.append('\t\t\tisa = PBXGroup;')
    lines.append('\t\t\tchildren = (')
    lines.append(f'\t\t\t\t{target_uid}P /* MacCleaner.app */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\tname = Products;')
    lines.append('\t\t\tsourceTree = "<group>";')
    lines.append('\t\t};')
    lines.append(f'\t\t{group_uid} /* MacCleaner */ = {{')
    lines.append('\t\t\tisa = PBXGroup;')
    lines.append('\t\t\tchildren = (')
    for f in SWIFT_FILES:
        lines.append(f'\t\t\t\t{file_refs[f]} /* {f} */,')
    lines.append(f'\t\t\t\t{asset_fileref} /* Assets.xcassets */,')
    lines.append(f'\t\t\t\t{plist_fileref} /* Info.plist */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\tpath = MacCleaner;')
    lines.append('\t\t\tsourceTree = "<group>";')
    lines.append('\t\t};')
    lines.append('/* End PBXGroup section */')
    lines.append('')

    # --- PBXNativeTarget ---
    lines.append('/* Begin PBXNativeTarget section */')
    lines.append(f'\t\t{target_uid} /* MacCleaner */ = {{')
    lines.append('\t\t\tisa = PBXNativeTarget;')
    lines.append(f'\t\t\tbuildConfigurationList = {config_list_target} /* Build configuration list for PBXNativeTarget "MacCleaner" */;')
    lines.append('\t\t\tbuildPhases = (')
    lines.append(f'\t\t\t\t{sources_phase_uid} /* Sources */,')
    lines.append(f'\t\t\t\t{resources_phase_uid} /* Resources */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\tbuildRules = (')
    lines.append('\t\t\t);')
    lines.append('\t\t\tdependencies = (')
    lines.append('\t\t\t);')
    lines.append('\t\t\tname = MacCleaner;')
    lines.append('\t\t\tpackageProductDependencies = (')
    lines.append('\t\t\t);')
    lines.append('\t\t\tproductName = MacCleaner;')
    lines.append(f'\t\t\tproductReference = {target_uid}P /* MacCleaner.app */;')
    lines.append('\t\t\tproductType = "com.apple.product-type.application";')
    lines.append('\t\t};')
    lines.append('/* End PBXNativeTarget section */')
    lines.append('')

    # --- PBXProject ---
    lines.append('/* Begin PBXProject section */')
    lines.append(f'\t\t{proj_uid} /* Project object */ = {{')
    lines.append('\t\t\tisa = PBXProject;')
    lines.append('\t\t\tattributes = {')
    lines.append('\t\t\t\tBuildIndependentTargetsInParallel = 1;')
    lines.append('\t\t\t\tLastSwiftUpdateCheck = 1500;')
    lines.append('\t\t\t\tLastUpgradeCheck = 1500;')
    lines.append('\t\t\t\tTargetAttributes = {')
    lines.append(f'\t\t\t\t\t{target_uid} = {{')
    lines.append('\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;')
    lines.append('\t\t\t\t\t};')
    lines.append('\t\t\t\t};')
    lines.append('\t\t\t};')
    lines.append(f'\t\t\tbuildConfigurationList = {config_list_proj} /* Build configuration list for PBXProject "MacCleaner" */;')
    lines.append('\t\t\tcompatibilityVersion = "Xcode 14.0";')
    lines.append('\t\t\tdevelopmentRegion = en;')
    lines.append('\t\t\thasScannedForEncodings = 0;')
    lines.append('\t\t\tknownRegions = (')
    lines.append('\t\t\t\ten,')
    lines.append('\t\t\t\tBase,')
    lines.append('\t\t\t);')
    lines.append(f'\t\t\tmainGroup = {uid("main_group")};')
    lines.append(f'\t\t\tproductRefGroup = {uid("products_group")} /* Products */;')
    lines.append('\t\t\tprojectDirPath = "";')
    lines.append('\t\t\tprojectRoot = "";')
    lines.append('\t\t\ttargets = (')
    lines.append(f'\t\t\t\t{target_uid} /* MacCleaner */,')
    lines.append('\t\t\t);')
    lines.append('\t\t};')
    lines.append('/* End PBXProject section */')
    lines.append('')

    # --- PBXResourcesBuildPhase ---
    lines.append('/* Begin PBXResourcesBuildPhase section */')
    lines.append(f'\t\t{resources_phase_uid} /* Resources */ = {{')
    lines.append('\t\t\tisa = PBXResourcesBuildPhase;')
    lines.append('\t\t\tbuildActionMask = 2147483647;')
    lines.append('\t\t\tfiles = (')
    lines.append(f'\t\t\t\t{asset_build_uid} /* Assets.xcassets in Resources */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
    lines.append('\t\t};')
    lines.append('/* End PBXResourcesBuildPhase section */')
    lines.append('')

    # --- PBXSourcesBuildPhase ---
    lines.append('/* Begin PBXSourcesBuildPhase section */')
    lines.append(f'\t\t{sources_phase_uid} /* Sources */ = {{')
    lines.append('\t\t\tisa = PBXSourcesBuildPhase;')
    lines.append('\t\t\tbuildActionMask = 2147483647;')
    lines.append('\t\t\tfiles = (')
    for f in SWIFT_FILES:
        lines.append(f'\t\t\t\t{build_refs[f]} /* {f} in Sources */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
    lines.append('\t\t};')
    lines.append('/* End PBXSourcesBuildPhase section */')
    lines.append('')

    # --- XCBuildConfiguration ---
    def build_settings(name: str, target: bool) -> list:
        s = []
        s.append(f'\t\t\tbuildSettings = {{')
        if target:
            s.append('\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;')
            s.append('\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;')
            s.append('\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;')
            s.append('\t\t\t\tINFOPLIST_FILE = MacCleaner/Info.plist;')
            s.append('\t\t\t\tLD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/../Frameworks";')
            s.append('\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 13.0;')
            s.append('\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "com.maccleaner.app";')
            s.append('\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
            s.append('\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;')
            s.append('\t\t\t\tSWIFT_VERSION = 5.0;')
            if name == 'Debug':
                s.append('\t\t\t\tCODE_SIGN_IDENTITY = "-";')
                s.append('\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;')
                s.append('\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";')
            else:
                s.append('\t\t\t\tCODE_SIGN_IDENTITY = "-";')
                s.append('\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";')
                s.append('\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";')
        else:
            s.append('\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;')
            s.append('\t\t\t\tCLANG_ANALYZER_NONNULL = YES;')
            s.append('\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";')
            s.append('\t\t\t\tCOPY_PHASE_STRIP = NO;')
            s.append('\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 13.0;')
            s.append('\t\t\t\tSWIFT_VERSION = 5.0;')
            if name == 'Debug':
                s.append('\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;')
                s.append('\t\t\t\tENABLE_TESTABILITY = YES;')
                s.append('\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;')
                s.append('\t\t\t\tONLY_ACTIVE_ARCH = YES;')
                s.append('\t\t\t\tOPTIMIZATION_LEVEL = 0;')
            else:
                s.append('\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";')
                s.append('\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;')
                s.append('\t\t\t\tOPTIMIZATION_LEVEL = s;')
                s.append('\t\t\t\tSTRIPPED_INSTALLED_PRODUCT = YES;')
        s.append('\t\t\t};')
        s.append(f'\t\t\tname = {name};')
        return s

    lines.append('/* Begin XCBuildConfiguration section */')
    for uid_val, name, is_target in [
        (debug_proj_uid, 'Debug', False), (release_proj_uid, 'Release', False),
        (debug_target_uid, 'Debug', True), (release_target_uid, 'Release', True),
    ]:
        lines.append(f'\t\t{uid_val} /* {name} */ = {{')
        lines.append('\t\t\tisa = XCBuildConfiguration;')
        lines += build_settings(name, is_target)
        lines.append('\t\t};')
    lines.append('/* End XCBuildConfiguration section */')
    lines.append('')

    # --- XCConfigurationList ---
    lines.append('/* Begin XCConfigurationList section */')
    lines.append(f'\t\t{config_list_proj} /* Build configuration list for PBXProject "MacCleaner" */ = {{')
    lines.append('\t\t\tisa = XCConfigurationList;')
    lines.append('\t\t\tbuildConfigurations = (')
    lines.append(f'\t\t\t\t{debug_proj_uid} /* Debug */,')
    lines.append(f'\t\t\t\t{release_proj_uid} /* Release */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\tdefaultConfigurationIsVisible = 0;')
    lines.append('\t\t\tdefaultConfigurationName = Release;')
    lines.append('\t\t};')
    lines.append(f'\t\t{config_list_target} /* Build configuration list for PBXNativeTarget "MacCleaner" */ = {{')
    lines.append('\t\t\tisa = XCConfigurationList;')
    lines.append('\t\t\tbuildConfigurations = (')
    lines.append(f'\t\t\t\t{debug_target_uid} /* Debug */,')
    lines.append(f'\t\t\t\t{release_target_uid} /* Release */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\tdefaultConfigurationIsVisible = 0;')
    lines.append('\t\t\tdefaultConfigurationName = Release;')
    lines.append('\t\t};')
    lines.append('/* End XCConfigurationList section */')
    lines.append('')

    lines += ['\t};', f'\trootObject = {proj_uid} /* Project object */;', '}']
    return '\n'.join(lines) + '\n'

content = gen()
with open(PBXPROJ, 'w') as f:
    f.write(content)
print(f"✅ project.pbxproj regenerated with {len(SWIFT_FILES)} Swift files.")
print("   Open Xcode, then Product → Clean Build Folder (⇧⌘K), then Build (⌘B).")
