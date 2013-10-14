Important File Types
--------------------
 - sourcecode.objj.h
 - sourcecode.c.objc
 - archive.ar
 - wrapper.cfbundle
 - text.plist.xml
 - text.plist.strings


"isa" Types
-----------

### PBXBuildfile:
 - fileRef: PBXFileReference
 - settings: May contain ATTRIBUTES = (list), which can contain "Public"

### PBXFileReference:
 - fileEncoding: always 4?
 - fileType: the file type (merged from lastKnownFileType and explicitFileType)
 - includeIndex: Seems to occur in libraries, frameworks, bundles etc and is always 0?
 - name: file name if path is nontrivial
 - path: Path to file
 - sourceTree: <group> for stuff in the project, otherwise env variable name. DEVELOPER_DIR is for dynamic libs/fws

### PBXContainerItemProxy:
 - containerPortal: Seems to always be the project itself
 - proxyType: always 1?
 - remoteGlobalIDString: pointed-to reference
 - remoteInfo: pointed-to type (isa)

### PBXFrameworksBuildPhase:
 - buildActionMask: not sure
 - files: list of PBXBuildFile
 - runOnlyForDeploymentPostprocessing: seems to be 0?

### PBXGroup:
 - children: list of PBXFileReference or PBXGroup
 - name: name if path is nontrivial or nonexistent
 - path: path of group or nonexistent if not a real path
 - sourceTree: <group> for stuff in the project

### PBXHeadersBuildPhase:
 - buildActionMask: not sure. Always 2147483647 (0x7fffffff)
 - files: list of PBXBuildFile
 - runOnlyForDeploymentPostprocessing: seems to be 0?

### PBXNativeTarget:
 - buildConfigurationList: XCConfigurationList
 - buildPhases: list of PBXzzzBuildPhase
 - buildRules: list of ?
 - dependencies: list of PBXTargetDependency
 - name: name
 - productName: actual name on disk
 - productReference: PBXFileReference
 - productType: com.apple.product-type.library.static or the like

### PBXProject:
 - attributes: dict of attributes
 - buildConfigurationList: XCConfigurationList
 - compatibilityVersion: "Xcode 3.2"
 - developmentRegion: English
 - hasScannedForEncodings: 0?
 - knownRegions: list of regions (e.g. en)
 - mainGroup: PBXGroup
 - productRefGroup: PBXGroup
 - projectDirPath: ""
 - projectRoot: ""
 - targets: list of PBXNativeTarget

### PBXResourcesBuildPhase:
 - buildActionMask: not sure. Always 2147483647 (0x7fffffff)
 - files: list of PBXBuildFile
 - runOnlyForDeploymentPostprocessing: seems to be 0?

### PBXShellScriptBuildPhase:
 - buildActionMask: not sure. Always 2147483647 (0x7fffffff)
 - files: empty list
 - inputPaths: empty list
 - outputPaths: empty list
 - runOnlyForDeploymentPostprocessing: 0
 - shellPath: /bin/sh
 - shellScript: script

### PBXSourcesBuildPhase:
 - buildActionMask: not sure. Always 2147483647 (0x7fffffff)
 - files: list of PBXBuildFile
 - runOnlyForDeploymentPostprocessing: seems to be 0?

### PBXTargetDependency:
 - target: PBXNativeTarget
 - targetProxy: PBXContainerItemProxy (always points to the same target, but via proxy?)

### PBXVariantGroup:
 - children: list of strings (for strings files, it is list of regions)
 - name: name if path is nontrivial or nonexistent
 - path: path of group or nonexistent
 - sourceTree: <group> for stuff in the project

### XCBuildConfiguration:
 - buildSettings: map of build setting key/values
 - name: name of config (Debug, Release, etc)

### XCConfigurationList:
 - buildConfigurations: list of XCBuildConfiguration
 - defaultConfigurationIsVisible: always 0?



Project Navigation Process
--------------------------

- get project object (rootObject from proj file)

#### Using project:
- from targets get PBXNativeTarget that matches current target name

#### Using PBXNativeTarget:
- (possibly grab config?)

### Get Public Headers:
- look in targets for PBXHeadersBuildPhase
Using PBXHeadersBuildPhase:
- from files get list of PBXBuildFile where settings contains attributes containing "Public"

### Get Libraries:
- look in targets for PBXFrameworksBuildPhase:
using PBXFrameworksBuildPhase:
- from files get list of PBXBuildFile where fileRef['fileType'] = archive.ar and fileRef['sourceTree'] not DEVELOPER_DIR

### Get Frameworks:
- look in targets for PBXFrameworksBuildPhase:
using PBXFrameworksBuildPhase:
- from files get list of PBXBuildFile where fileRef['fileType'] = wrapper.framework (or wrapper.cfbundle and path ends in ".framework") and fileRef['sourceTree'] not DEVELOPER_DIR

### Find Full Path of PBXFileReference:
- start in project mainGroup:
- maintain stack of subdir names
- descend into children until reference found
