#!/usr/bin/env python3
"""
Generates Kamus.xcodeproj for iOS App, Action Extension, and WidgetKit extension.
"""

import os
import hashlib
import gzip
import shutil

def gen_id(name: str) -> str:
    # PBX 24-char hex ID
    h = hashlib.md5(name.encode("utf-8")).hexdigest()[:24].upper()
    return h

def main():
    proj_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    xcode_dir = os.path.join(proj_dir, "Kamus.xcodeproj")
    os.makedirs(xcode_dir, exist_ok=True)
    pbx_path = os.path.join(xcode_dir, "project.pbxproj")

    # Bundle the uncompressed database expected by DictionaryStore.
    with gzip.open(os.path.join(proj_dir, "Resources/seeds.sqlite.gz"), "rb") as source:
        with open(os.path.join(proj_dir, "Resources/seeds.sqlite"), "wb") as target:
            shutil.copyfileobj(source, target)

    # Define File References
    # Shared sources
    shared_files = [
        ("Sources/Kamus/TDKAPIClient.swift", "TDKAPIClient.swift", "sourcecode.swift"),
        ("Sources/Kamus/DictionaryStore.swift", "DictionaryStore.swift", "sourcecode.swift"),
        ("Sources/Kamus/TurkishSpeechSpeaker.swift", "TurkishSpeechSpeaker.swift", "sourcecode.swift"),
        ("Resources/seeds.sqlite", "seeds.sqlite", "file"),
    ]

    shared_files += [
        ("Resources/Brand.xcassets", "Brand.xcassets", "folder.assetcatalog"),
    ]

    # App sources
    app_files = [
        ("iOS/Kamus/KamusMobileApp.swift", "KamusMobileApp.swift", "sourcecode.swift"),
        ("iOS/Kamus/MobileSearchViewModel.swift", "MobileSearchViewModel.swift", "sourcecode.swift"),
        ("iOS/Kamus/HomeSearchView.swift", "HomeSearchView.swift", "sourcecode.swift"),
        ("iOS/Kamus/WordDetailView.swift", "WordDetailView.swift", "sourcecode.swift"),
        ("iOS/Kamus/WordOfTheDayView.swift", "WordOfTheDayView.swift", "sourcecode.swift"),
        ("iOS/Kamus/FavoritesAndHistoryView.swift", "FavoritesAndHistoryView.swift", "sourcecode.swift"),
        ("iOS/Kamus/Assets.xcassets", "Assets.xcassets", "folder.assetcatalog"),
        ("iOS/Kamus/Info.plist", "Info.plist", "text.plist.xml"),
        ("iOS/Kamus/Kamus.entitlements", "Kamus.entitlements", "text.plist.entitlements"),
    ]

    # Action Extension sources
    action_files = [
        ("iOS/KamusActionExtension/ActionViewController.swift", "ActionViewController.swift", "sourcecode.swift"),
        ("iOS/KamusActionExtension/ActionLookupView.swift", "ActionLookupView.swift", "sourcecode.swift"),
        ("iOS/KamusActionExtension/Assets.xcassets", "Assets.xcassets", "folder.assetcatalog"),
        ("iOS/KamusActionExtension/ActionIcon.png", "ActionIcon.png", "image.png"),
        ("iOS/KamusActionExtension/ActionIcon@2x.png", "ActionIcon@2x.png", "image.png"),
        ("iOS/KamusActionExtension/ActionIcon@3x.png", "ActionIcon@3x.png", "image.png"),
        ("iOS/KamusActionExtension/Info.plist", "Info.plist", "text.plist.xml"),
        ("iOS/KamusActionExtension/KamusActionExtension.entitlements", "KamusActionExtension.entitlements", "text.plist.entitlements"),
    ]

    # Widget sources
    widget_files = [
        ("iOS/KamusWidgets/KamusWidgets.swift", "KamusWidgets.swift", "sourcecode.swift"),
        ("iOS/KamusWidgets/WordOfTheDayWidget.swift", "WordOfTheDayWidget.swift", "sourcecode.swift"),
        ("iOS/KamusWidgets/QuickSearchWidget.swift", "QuickSearchWidget.swift", "sourcecode.swift"),
        ("iOS/KamusWidgets/Info.plist", "Info.plist", "text.plist.xml"),
        ("iOS/KamusWidgets/KamusWidgets.entitlements", "KamusWidgets.entitlements", "text.plist.entitlements"),
    ]

    # Product references
    app_prod_id = gen_id("prod_Kamus_app")
    action_prod_id = gen_id("prod_KamusAction_appex")
    widget_prod_id = gen_id("prod_KamusWidgets_appex")

    # Target IDs
    app_target_id = gen_id("target_Kamus_app")
    action_target_id = gen_id("target_KamusAction_appex")
    widget_target_id = gen_id("target_KamusWidgets_appex")

    # Project ID
    proj_obj_id = gen_id("project_Kamus")
    main_group_id = gen_id("group_main")
    products_group_id = gen_id("group_products")
    shared_group_id = gen_id("group_shared")
    app_group_id = gen_id("group_app")
    action_group_id = gen_id("group_action")
    widget_group_id = gen_id("group_widget")

    # Build Configuration IDs
    proj_cfg_list = gen_id("proj_cfg_list")
    proj_dbg_cfg = gen_id("proj_dbg_cfg")
    proj_rel_cfg = gen_id("proj_rel_cfg")

    app_cfg_list = gen_id("app_cfg_list")
    app_dbg_cfg = gen_id("app_dbg_cfg")
    app_rel_cfg = gen_id("app_rel_cfg")

    action_cfg_list = gen_id("action_cfg_list")
    action_dbg_cfg = gen_id("action_dbg_cfg")
    action_rel_cfg = gen_id("action_rel_cfg")

    widget_cfg_list = gen_id("widget_cfg_list")
    widget_dbg_cfg = gen_id("widget_dbg_cfg")
    widget_rel_cfg = gen_id("widget_rel_cfg")

    # Phase IDs
    app_sources_phase = gen_id("app_sources_phase")
    app_frameworks_phase = gen_id("app_frameworks_phase")
    app_resources_phase = gen_id("app_resources_phase")
    app_embed_phase = gen_id("app_embed_phase")

    action_sources_phase = gen_id("action_sources_phase")
    action_frameworks_phase = gen_id("action_frameworks_phase")
    action_resources_phase = gen_id("action_resources_phase")

    widget_sources_phase = gen_id("widget_sources_phase")
    widget_frameworks_phase = gen_id("widget_frameworks_phase")
    widget_resources_phase = gen_id("widget_resources_phase")

    # Dependencies & Containers
    action_dep_id = gen_id("action_target_dep")
    action_proxy_id = gen_id("action_container_item_proxy")
    widget_dep_id = gen_id("widget_target_dep")
    widget_proxy_id = gen_id("widget_container_item_proxy")

    action_embed_build_file = gen_id("action_embed_build_file")
    widget_embed_build_file = gen_id("widget_embed_build_file")

    # Collect PBX sections
    pbx_file_refs = []
    pbx_build_files = []

    def add_file(rel_path, name, filetype):
        fid = gen_id("file_" + rel_path)
        pbx_file_refs.append(f'\t\t{fid} /* {name} */ = {{isa = PBXFileReference; explicitFileType = "{filetype}"; path = "{rel_path}"; sourceTree = "<group>"; }};')
        return fid

    def add_build_file(fid, name):
        bf_id = gen_id("bf_" + fid)
        pbx_build_files.append(f'\t\t{bf_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {name} */; }};')
        return bf_id

    def add_res_file(fid, name):
        bf_id = gen_id("res_" + fid)
        pbx_build_files.append(f'\t\t{bf_id} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {name} */; }};')
        return bf_id

    # Register shared
    shared_fids = {}
    for path, name, ftype in shared_files:
        shared_fids[path] = add_file(path, name, ftype)

    # Register app
    app_fids = {}
    for path, name, ftype in app_files:
        app_fids[path] = add_file(path, name, ftype)

    # Register action
    action_fids = {}
    for path, name, ftype in action_files:
        action_fids[path] = add_file(path, name, ftype)

    # Register widget
    widget_fids = {}
    for path, name, ftype in widget_files:
        widget_fids[path] = add_file(path, name, ftype)

    # Build files for App
    app_bf_sources = [
        add_build_file(shared_fids["Sources/Kamus/TDKAPIClient.swift"], "TDKAPIClient.swift"),
        add_build_file(shared_fids["Sources/Kamus/DictionaryStore.swift"], "DictionaryStore.swift"),
        add_build_file(shared_fids["Sources/Kamus/TurkishSpeechSpeaker.swift"], "TurkishSpeechSpeaker.swift"),
        add_build_file(app_fids["iOS/Kamus/KamusMobileApp.swift"], "KamusMobileApp.swift"),
        add_build_file(app_fids["iOS/Kamus/MobileSearchViewModel.swift"], "MobileSearchViewModel.swift"),
        add_build_file(app_fids["iOS/Kamus/HomeSearchView.swift"], "HomeSearchView.swift"),
        add_build_file(app_fids["iOS/Kamus/WordDetailView.swift"], "WordDetailView.swift"),
        add_build_file(app_fids["iOS/Kamus/WordOfTheDayView.swift"], "WordOfTheDayView.swift"),
        add_build_file(app_fids["iOS/Kamus/FavoritesAndHistoryView.swift"], "FavoritesAndHistoryView.swift"),
    ]

    app_bf_resources = [
        add_res_file(app_fids["iOS/Kamus/Assets.xcassets"], "Assets.xcassets"),
        add_res_file(shared_fids["Resources/seeds.sqlite"], "seeds.sqlite"),
    ]

    # Build files for Action
    action_bf_sources = [
        add_build_file(shared_fids["Sources/Kamus/TDKAPIClient.swift"], "TDKAPIClient.swift"),
        add_build_file(shared_fids["Sources/Kamus/DictionaryStore.swift"], "DictionaryStore.swift"),
        add_build_file(shared_fids["Sources/Kamus/TurkishSpeechSpeaker.swift"], "TurkishSpeechSpeaker.swift"),
        add_build_file(action_fids["iOS/KamusActionExtension/ActionViewController.swift"], "ActionViewController.swift"),
        add_build_file(action_fids["iOS/KamusActionExtension/ActionLookupView.swift"], "ActionLookupView.swift"),
    ]

    action_bf_resources = [
        add_res_file(action_fids["iOS/KamusActionExtension/Assets.xcassets"], "Assets.xcassets"),
        add_res_file(action_fids["iOS/KamusActionExtension/ActionIcon.png"], "ActionIcon.png"),
        add_res_file(action_fids["iOS/KamusActionExtension/ActionIcon@2x.png"], "ActionIcon@2x.png"),
        add_res_file(action_fids["iOS/KamusActionExtension/ActionIcon@3x.png"], "ActionIcon@3x.png"),
    ]

    # Build files for Widget
    widget_bf_sources = [
        add_build_file(shared_fids["Sources/Kamus/TDKAPIClient.swift"], "TDKAPIClient.swift"),
        add_build_file(shared_fids["Sources/Kamus/DictionaryStore.swift"], "DictionaryStore.swift"),
        add_build_file(widget_fids["iOS/KamusWidgets/KamusWidgets.swift"], "KamusWidgets.swift"),
        add_build_file(widget_fids["iOS/KamusWidgets/WordOfTheDayWidget.swift"], "WordOfTheDayWidget.swift"),
        add_build_file(widget_fids["iOS/KamusWidgets/QuickSearchWidget.swift"], "QuickSearchWidget.swift"),
    ]

    widget_bf_resources = []
    for resources in (app_bf_resources, action_bf_resources, widget_bf_resources):
        for name in ("Brand.xcassets",):
            # Each target needs its own PBXBuildFile, even for shared images.
            fid = shared_fids["Resources/" + name]
            # Stable identifiers make project regeneration deterministic.
            target = "app" if resources is app_bf_resources else "action" if resources is action_bf_resources else "widget"
            bf_id = gen_id("brand_" + target + "_" + name)
            pbx_build_files.append(f'\t\t{bf_id} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {name} */; }};')
            resources.append(bf_id)

    # Embed App Extensions in App
    pbx_build_files.append(f'\t\t{action_embed_build_file} /* KamusActionExtension.appex in Embed App Extensions */ = {{isa = PBXBuildFile; fileRef = {action_prod_id} /* KamusActionExtension.appex */; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};')
    pbx_build_files.append(f'\t\t{widget_embed_build_file} /* KamusWidgets.appex in Embed App Extensions */ = {{isa = PBXBuildFile; fileRef = {widget_prod_id} /* KamusWidgets.appex */; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};')

    # Product file references
    pbx_file_refs.append(f'\t\t{app_prod_id} /* Kamus.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Kamus.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    pbx_file_refs.append(f'\t\t{action_prod_id} /* KamusActionExtension.appex */ = {{isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = KamusActionExtension.appex; sourceTree = BUILT_PRODUCTS_DIR; }};')
    pbx_file_refs.append(f'\t\t{widget_prod_id} /* KamusWidgets.appex */ = {{isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = KamusWidgets.appex; sourceTree = BUILT_PRODUCTS_DIR; }};')

    content = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 55;
	objects = {{

/* Begin PBXBuildFile section */
{chr(10).join(pbx_build_files)}
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
		{action_proxy_id} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {proj_obj_id} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {action_target_id};
			remoteInfo = KamusActionExtension;
		}};
		{widget_proxy_id} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {proj_obj_id} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {widget_target_id};
			remoteInfo = KamusWidgets;
		}};
/* End PBXContainerItemProxy section */

/* Begin PBXCopyFilesBuildPhase section */
		{app_embed_phase} /* Embed App Extensions */ = {{
			isa = PBXCopyFilesBuildPhase;
			buildActionMask = 2147483647;
			dstPath = "";
			dstSubfolderSpec = 13;
			files = (
				{action_embed_build_file} /* KamusActionExtension.appex in Embed App Extensions */,
				{widget_embed_build_file} /* KamusWidgets.appex in Embed App Extensions */,
			);
			name = "Embed App Extensions";
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXCopyFilesBuildPhase section */

/* Begin PBXFileReference section */
{chr(10).join(pbx_file_refs)}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{app_frameworks_phase} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{action_frameworks_phase} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{widget_frameworks_phase} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{main_group_id} = {{
			isa = PBXGroup;
			children = (
				{shared_group_id} /* Shared */,
				{app_group_id} /* Kamus (iOS App) */,
				{action_group_id} /* KamusActionExtension */,
				{widget_group_id} /* KamusWidgets */,
				{products_group_id} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{shared_group_id} /* Shared */ = {{
			isa = PBXGroup;
			children = (
				{shared_fids["Sources/Kamus/TDKAPIClient.swift"]} /* TDKAPIClient.swift */,
				{shared_fids["Sources/Kamus/DictionaryStore.swift"]} /* DictionaryStore.swift */,
				{shared_fids["Sources/Kamus/TurkishSpeechSpeaker.swift"]} /* TurkishSpeechSpeaker.swift */,
				{shared_fids["Resources/seeds.sqlite"]} /* seeds.sqlite */,
				{shared_fids["Resources/Brand.xcassets"]} /* Brand.xcassets */,
			);
			name = Shared;
			sourceTree = "<group>";
		}};
		{app_group_id} /* Kamus (iOS App) */ = {{
			isa = PBXGroup;
			children = (
				{app_fids["iOS/Kamus/KamusMobileApp.swift"]} /* KamusMobileApp.swift */,
				{app_fids["iOS/Kamus/MobileSearchViewModel.swift"]} /* MobileSearchViewModel.swift */,
				{app_fids["iOS/Kamus/HomeSearchView.swift"]} /* HomeSearchView.swift */,
				{app_fids["iOS/Kamus/WordDetailView.swift"]} /* WordDetailView.swift */,
				{app_fids["iOS/Kamus/WordOfTheDayView.swift"]} /* WordOfTheDayView.swift */,
				{app_fids["iOS/Kamus/FavoritesAndHistoryView.swift"]} /* FavoritesAndHistoryView.swift */,
				{app_fids["iOS/Kamus/Assets.xcassets"]} /* Assets.xcassets */,
				{app_fids["iOS/Kamus/Info.plist"]} /* Info.plist */,
				{app_fids["iOS/Kamus/Kamus.entitlements"]} /* Kamus.entitlements */,
			);
			name = "Kamus";
			sourceTree = "<group>";
		}};
		{action_group_id} /* KamusActionExtension */ = {{
			isa = PBXGroup;
			children = (
				{action_fids["iOS/KamusActionExtension/ActionViewController.swift"]} /* ActionViewController.swift */,
				{action_fids["iOS/KamusActionExtension/ActionLookupView.swift"]} /* ActionLookupView.swift */,
				{action_fids["iOS/KamusActionExtension/Info.plist"]} /* Info.plist */,
				{action_fids["iOS/KamusActionExtension/KamusActionExtension.entitlements"]} /* KamusActionExtension.entitlements */,
			);
			name = "KamusActionExtension";
			sourceTree = "<group>";
		}};
		{widget_group_id} /* KamusWidgets */ = {{
			isa = PBXGroup;
			children = (
				{widget_fids["iOS/KamusWidgets/KamusWidgets.swift"]} /* KamusWidgets.swift */,
				{widget_fids["iOS/KamusWidgets/WordOfTheDayWidget.swift"]} /* WordOfTheDayWidget.swift */,
				{widget_fids["iOS/KamusWidgets/QuickSearchWidget.swift"]} /* QuickSearchWidget.swift */,
				{widget_fids["iOS/KamusWidgets/Info.plist"]} /* Info.plist */,
				{widget_fids["iOS/KamusWidgets/KamusWidgets.entitlements"]} /* KamusWidgets.entitlements */,
			);
			name = "KamusWidgets";
			sourceTree = "<group>";
		}};
		{products_group_id} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{app_prod_id} /* Kamus.app */,
				{action_prod_id} /* KamusActionExtension.appex */,
				{widget_prod_id} /* KamusWidgets.appex */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{app_target_id} /* Kamus */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {app_cfg_list} /* Build configuration list for PBXNativeTarget "Kamus" */;
			buildPhases = (
				{app_sources_phase} /* Sources */,
				{app_frameworks_phase} /* Frameworks */,
				{app_resources_phase} /* Resources */,
				{app_embed_phase} /* Embed App Extensions */,
			);
			buildRules = (
			);
			dependencies = (
				{action_dep_id} /* PBXTargetDependency */,
				{widget_dep_id} /* PBXTargetDependency */,
			);
			name = Kamus;
			productName = Kamus;
			productReference = {app_prod_id} /* Kamus.app */;
			productType = "com.apple.product-type.application";
		}};
		{action_target_id} /* KamusActionExtension */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {action_cfg_list} /* Build configuration list for PBXNativeTarget "KamusActionExtension" */;
			buildPhases = (
				{action_sources_phase} /* Sources */,
				{action_frameworks_phase} /* Frameworks */,
				{action_resources_phase} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = KamusActionExtension;
			productName = KamusActionExtension;
			productReference = {action_prod_id} /* KamusActionExtension.appex */;
			productType = "com.apple.product-type.app-extension";
		}};
		{widget_target_id} /* KamusWidgets */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {widget_cfg_list} /* Build configuration list for PBXNativeTarget "KamusWidgets" */;
			buildPhases = (
				{widget_sources_phase} /* Sources */,
				{widget_frameworks_phase} /* Frameworks */,
				{widget_resources_phase} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = KamusWidgets;
			productName = KamusWidgets;
			productReference = {widget_prod_id} /* KamusWidgets.appex */;
			productType = "com.apple.product-type.app-extension";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{proj_obj_id} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastUpgradeCheck = 1600;
				TargetAttributes = {{
					{app_target_id} = {{
						CreatedOnToolsVersion = 16.0;
					}};
					{action_target_id} = {{
						CreatedOnToolsVersion = 16.0;
					}};
					{widget_target_id} = {{
						CreatedOnToolsVersion = 16.0;
					}};
				}};
			}};
			buildConfigurationList = {proj_cfg_list} /* Build configuration list for PBXProject "Kamus" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = tr;
			hasScannedForEncodings = 0;
			knownRegions = (
				tr,
				Base,
			);
			mainGroup = {main_group_id};
			productRefGroup = {products_group_id} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{app_target_id} /* Kamus */,
				{action_target_id} /* KamusActionExtension */,
				{widget_target_id} /* KamusWidgets */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{app_resources_phase} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{chr(10).join([f"{chr(9)}{chr(9)}{chr(9)}{fid}," for fid in app_bf_resources])}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{action_resources_phase} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{chr(10).join([f"{chr(9)}{chr(9)}{chr(9)}{fid}," for fid in action_bf_resources])}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{widget_resources_phase} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{chr(10).join([f"{chr(9)}{chr(9)}{chr(9)}{fid}," for fid in widget_bf_resources])}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{app_sources_phase} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{chr(10).join([f"{chr(9)}{chr(9)}{chr(9)}{fid}," for fid in app_bf_sources])}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{action_sources_phase} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{chr(10).join([f"{chr(9)}{chr(9)}{chr(9)}{fid}," for fid in action_bf_sources])}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{widget_sources_phase} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{chr(10).join([f"{chr(9)}{chr(9)}{chr(9)}{fid}," for fid in widget_bf_sources])}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		{action_dep_id} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {action_target_id} /* KamusActionExtension */;
			targetProxy = {action_proxy_id} /* PBXContainerItemProxy */;
		}};
		{widget_dep_id} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {widget_target_id} /* KamusWidgets */;
			targetProxy = {widget_proxy_id} /* PBXContainerItemProxy */;
		}};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
		{proj_dbg_cfg} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 5.0;
			}};
			name = Debug;
		}};
		{proj_rel_cfg} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_NO_COMMON_BLOCKS = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				SWIFT_VERSION = 5.0;
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
		{app_dbg_cfg} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CODE_SIGN_IDENTITY = "Apple Development";
				CURRENT_PROJECT_VERSION = 2;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = "iOS/Kamus/Info.plist";
				CODE_SIGN_ENTITLEMENTS = "iOS/Kamus/Kamus.entitlements";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0.1;
				PRODUCT_BUNDLE_IDENTIFIER = cloud.bakedapps.kamus;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		{app_rel_cfg} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CODE_SIGN_IDENTITY = "Apple Development";
				CURRENT_PROJECT_VERSION = 2;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = "iOS/Kamus/Info.plist";
				CODE_SIGN_ENTITLEMENTS = "iOS/Kamus/Kamus.entitlements";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0.1;
				PRODUCT_BUNDLE_IDENTIFIER = cloud.bakedapps.kamus;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
		{action_dbg_cfg} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_STYLE = Automatic;
				CODE_SIGN_IDENTITY = "Apple Development";
				CURRENT_PROJECT_VERSION = 2;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = "iOS/KamusActionExtension/Info.plist";
				CODE_SIGN_ENTITLEMENTS = "iOS/KamusActionExtension/KamusActionExtension.entitlements";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@executable_path/../../Frameworks",
				);
				MARKETING_VERSION = 1.0.1;
				PRODUCT_BUNDLE_IDENTIFIER = cloud.bakedapps.kamus.action;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SKIP_INSTALL = YES;
				SWIFT_EMIT_LOC_STRINGS = YES;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		{action_rel_cfg} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_STYLE = Automatic;
				CODE_SIGN_IDENTITY = "Apple Development";
				CURRENT_PROJECT_VERSION = 2;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = "iOS/KamusActionExtension/Info.plist";
				CODE_SIGN_ENTITLEMENTS = "iOS/KamusActionExtension/KamusActionExtension.entitlements";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@executable_path/../../Frameworks",
				);
				MARKETING_VERSION = 1.0.1;
				PRODUCT_BUNDLE_IDENTIFIER = cloud.bakedapps.kamus.action;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SKIP_INSTALL = YES;
				SWIFT_EMIT_LOC_STRINGS = YES;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
		{widget_dbg_cfg} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_STYLE = Automatic;
				CODE_SIGN_IDENTITY = "Apple Development";
				CURRENT_PROJECT_VERSION = 2;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = "iOS/KamusWidgets/Info.plist";
				CODE_SIGN_ENTITLEMENTS = "iOS/KamusWidgets/KamusWidgets.entitlements";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@executable_path/../../Frameworks",
				);
				MARKETING_VERSION = 1.0.1;
				PRODUCT_BUNDLE_IDENTIFIER = cloud.bakedapps.kamus.widgets;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SKIP_INSTALL = YES;
				SWIFT_EMIT_LOC_STRINGS = YES;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		{widget_rel_cfg} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_STYLE = Automatic;
				CODE_SIGN_IDENTITY = "Apple Development";
				CURRENT_PROJECT_VERSION = 2;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = "iOS/KamusWidgets/Info.plist";
				CODE_SIGN_ENTITLEMENTS = "iOS/KamusWidgets/KamusWidgets.entitlements";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@executable_path/../../Frameworks",
				);
				MARKETING_VERSION = 1.0.1;
				PRODUCT_BUNDLE_IDENTIFIER = cloud.bakedapps.kamus.widgets;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SKIP_INSTALL = YES;
				SWIFT_EMIT_LOC_STRINGS = YES;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{proj_cfg_list} /* Build configuration list for PBXProject "Kamus" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{proj_dbg_cfg} /* Debug */,
				{proj_rel_cfg} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{app_cfg_list} /* Build configuration list for PBXNativeTarget "Kamus" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{app_dbg_cfg} /* Debug */,
				{app_rel_cfg} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{action_cfg_list} /* Build configuration list for PBXNativeTarget "KamusActionExtension" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{action_dbg_cfg} /* Debug */,
				{action_rel_cfg} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{widget_cfg_list} /* Build configuration list for PBXNativeTarget "KamusWidgets" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{widget_dbg_cfg} /* Debug */,
				{widget_rel_cfg} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */

	}};
	rootObject = {proj_obj_id} /* Project object */;
}}
"""

    with open(pbx_path, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"✅ Generated {pbx_path}")

if __name__ == "__main__":
    main()
