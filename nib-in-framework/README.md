Embedded Framework Containing a nib
===================================

In this example, we create, distribute, and use an embedded framework which contains a nib.

The framework project (fake framework) is contained in **CustomVC**, and the app that uses it is in **TestCustomVC**.

### How it was put together:

#### Making and building the embedded framework:

* Started a new fake universal framework project
* Deleted CustomVC.h and CustomVC.m
* Re-created CustomVC as a subclass of UIViewController, selecting **With XIB for user interface**
* Under **Build Phases**, moved **CustomVC.h** to the **Public** section of **Copy Headers**
* Under **Run Script**, changed **config_framework_type** in the **Configuration** section from **'framework'** to **'embeddedframework'**
* Selected **iOS Devcice** in the scheme selector
* Selected **Archive** from the **Product** menu


#### Making and building the app:

* Started a new view based application
* Deleted **ViewController**
* Dragged the embedded framework I built earlier into the project (selecting **Copy items into destination group's folder**)
* Added the following to AppDelegate:

.

	#import <CustomVC/CustomVC.h>
	
	@implementation AppDelegate
	
	- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
	{
	    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	    // Override point for customization after application launch.
	    self.viewController = [[CustomVC alloc] initWithNibName:@"CustomVC" bundle:nil];
	    self.window.rootViewController = self.viewController;
	    [self.window makeKeyAndVisible];
	    return YES;
	}

* Built and ran in the simulator, then on the device.
