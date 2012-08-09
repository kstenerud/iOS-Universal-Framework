Basic Universal Framework Example
=================================

This is a basic example of creating, distributing, and using a universal framework.

The framework project (fake framework) is contained in **MyCustomFW**, and the app that uses it is in **MyApp**.

### How it was put together:

#### Making and building the framework:

* Started a new fake universal framework project
* Deleted MyCustomFW.h and MyCustomFW.m
* Created a new class "SomeClass"
* Under **Build Phases**, moved **SomeClass.h** to the **Public** section of **Copy Headers**
* Selected **iOS Devcice** in the scheme selector
* Selected **Archive** from the **Product** menu


#### Making and building the app:

* Started a new view based application
* Dragged the framework I built earlier into the project (selecting **Copy items into destination group's folder**)
* Added the following to AppDelegate:

.

    #import <MyCustomFW/SomeClass.h>
    
    @implementation AppDelegate
    
    - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
    {
        SomeClass* instance = [SomeClass new];
        NSLog(@"Instance = %@", instance);
        ...

* Built and ran in the simulator, then on the device, watching the console output.
