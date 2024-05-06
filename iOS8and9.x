#import "Headers.h"

/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.
*/

#define isModern [[CSClassicFolderSettingsManager sharedInstance] modern]

%group FolderHooks
%hook SBFolderIconListView

+ (NSUInteger)iconColumnsForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (UIInterfaceOrientationIsLandscape(interfaceOrientation)){
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
			return 5;
		else {
			if ([[UIScreen mainScreen] bounds].size.width > 320){
				return 6;
			} else if ([[UIScreen mainScreen] bounds].size.height > 480){
				return 5;
			} else {
				return 4;
			}
		}
	}
	return 4;
}

+ (NSUInteger)maxVisibleIconRowsInterfaceOrientation:(UIInterfaceOrientation)arg1 {
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
		return %orig;
	else {
		if ([[UIScreen mainScreen] bounds].size.width > 320){
				return 5;
		} else if ([[UIScreen mainScreen] bounds].size.height > 480){
				return 4;
		} else {
				return 3;
		}
	}
}

- (CGFloat)sideIconInset {
	if (isModern)
		return 17.0f;

	if ([[UIScreen mainScreen] bounds].size.width > 320 && [[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad)
		return 27.0f;
	else
		return 17.0f;
}

- (CGFloat)bottomIconInset {
	return 5.0f;
}
%end

%hook SBFolderController
-(BOOL)pushFolder:(SBFolder *)folder animated:(BOOL)animated completion:(id)completion {
	if (!verifyUDID())
		safeMode();

	if ([folder isKindOfClass:%c(SBNewsstandFolder)]){
		return %orig;
	}
	if (![self isOpen]){
		NSLog(@"%@ Unable to open folder %@ because we aren't actually open.",self,folder);
		return NO;
	}
	SBFolderController *innerController = [self innerFolderController];
	if (!innerController){
		SBFolderIcon *icon = [folder icon];
		if ((icon != nil) && ([self _iconAppearsOnCurrentPage:icon])){
			SBIconController *controller = [%c(SBIconController) sharedInstance];
			SBIconViewMap *map = nil;
			if ([controller respondsToSelector:@selector(homescreenIconViewMap)])
				map = [controller homescreenIconViewMap];
			else
				map = [%c(SBIconViewMap) homescreenMap];
			if ([map mappedIconViewForIcon:icon] == nil){
				NSLog(@"%@ No folder icon view for %@",self,icon);
				return NO;
			}
			Class controllerClass = nil;
			if ([[self delegate] respondsToSelector:@selector(controllerClassForFolder:)])
				controllerClass = [[self delegate] controllerClassForFolder:folder];
			else
				controllerClass = [folder controllerClass];
			SBIconViewMap *viewMap = nil;
			if ([self respondsToSelector:@selector(viewMap)])
				viewMap = [self viewMap];
			else if ([self respondsToSelector:@selector(_viewMap)])
				viewMap = [self _viewMap];
			innerController = [controllerClass alloc];
			if ([innerController respondsToSelector:@selector(initWithFolder:orientation:viewMap:)])
				innerController = [innerController initWithFolder:folder orientation:[self orientation] viewMap:viewMap];
			else
				innerController = [innerController initWithFolder:folder orientation:[self orientation]];
			[self setInnerFolderController:innerController];

			if ([innerController _contentViewClass] == %c(CSClassicFolderView)){
				[self _setInnerFolderOpen:YES animated:NO completion:nil];
				CSClassicFolderView *folderView = (CSClassicFolderView *)[innerController contentView];
				[folderView openFolder:animated completion:completion];
				[folderView setFolderController:self];
			} else {
				[self _setInnerFolderOpen:YES animated:animated completion:nil];
			}
			return YES;
		} else {
			NSLog(@"%@ Folder icon %@ cannot be opened because it does not exist on the current page.",self,icon);
			return NO;
		}
	}
	[innerController pushFolder:folder animated:YES completion:completion];
	return YES;
}

- (BOOL)popFolderAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completion {
	if (!verifyUDID())
		safeMode();

	SBFolderController *innerController = [self innerFolderController];
	if (innerController != nil){
		if ([innerController innerFolderController] != nil){
			return [innerController popFolderAnimated:animated completion:completion];
		} else {
			CSClassicFolderView *folderView = (CSClassicFolderView *)[innerController contentView];
			if ([folderView respondsToSelector:@selector(closeFolder:completion:)]){
				[folderView closeFolder:animated completion:^(BOOL finished){
					[self _setInnerFolderOpen:NO animated:NO completion:completion];
					[self setInnerFolderController:nil];
				}];
			} else {
				if ([[self folder] isKindOfClass:%c(SBNewsstandFolder)]){
					return %orig;
				}
				[self _setInnerFolderOpen:NO animated:animated completion:completion];
				[self setInnerFolderController:nil];
			}
			return YES;
		}
	} else {
		return NO;
	}
}

+ (CGFloat)wallpaperScaleForDepth:(unsigned)depth {
	return 1.0f;
}

-(Class)_contentViewClass {
	return %c(CSClassicFolderView);
}
%end

%hook SBRootFolderView
- (void)setHidden:(BOOL)hidden {
	[self setUserInteractionEnabled:!hidden];
	%orig(NO);
}
%end
%end

%ctor {
	if (kCFCoreFoundationVersionNumber < 1348){
		if ([[CSClassicFolderSettingsManager sharedInstance] enabled]){
			%init(FolderHooks);
		}
	}
}
