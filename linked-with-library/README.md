Linking A Static Library Into A Framework
=========================================

This project demonstrates how a fat static library may be statically linked into a framework. A fat library is a library containing multiple copies of the code, one for each architecture (typically armv6, armv7, and i386, though armv6 may be omitted if you're not interested in supporting older devices such as iPhone 3G or iPod Touch 2).

**Note:** Statically linking a library to your framework is usually a bad idea because you end up locking the user of your framework into the specific library version you linked against. Also, if you don't expose that library's headers, the user won't be able to use the lower level functions in that library. Worse, they may try to link against their own copy of the library, with linker errors resulting.

Now that you've been warned, let's get down to business.

### Subdirs:
- **SimpleLibrary**: Standalone project to build a static library.
- **LibsIncluded**: A framework which links against a previously compiled fat version of SimpleLibrary (armv7 and i386).
- **TestApp**: An app that checks to make sure everything worked (check the console log).
- **LinkedWithLibrary.xcworkspace**: Workspace containing LibsIncluded and TestApp.

### How I built it:

#### 1. Procure a universal static library to link against.

I just made a quick test library:

- Started a new **Static Library** framework project.
- Changed the **Run** section in the scheme to use **Release** build configuration.
- Compiled for device and for simulator.
- Combined the device and simulator library builds together using lipo:

    lipo -create -output libSimpleLibrary.a /path/to/iphonesimulator/build/libSimpleLibrary.a /path/to/iphoneos/build/libSimpleLibrary.a

#### 2. Start a new static framework project.

Note: I removed armv6 from the **Architectures** build setting to keep things simple.

#### 3. Add library to the framework project.
- Dragged my fat libSimpleLibrary.a binary and SimpleLibraryClass.h into the framework project.
- Ensured that SimpleLibraryClass.h and any other headers from my framework are in the **Copy Headers** build phase in the **Public** section.
- Ensured that libSimpleLibrary.a is included in the **Link Binary With Libraries** build phase.

#### 4. Add the resulting framework to my test app and run.

