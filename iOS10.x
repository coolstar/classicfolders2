#import "Headers.h"

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
-(BOOL)pushFolderIcon:(SBFolderIcon *)folderIcon animated:(BOOL)animated completion:(id)completion {
	if (!verifyUDID())
		safeMode();
	
	if (![self isOpen]){
		NSLog(@"%@ Unable to open folder icon %@ because we aren't actually open!",self,folderIcon);
		return NO;
	}

	if (![self expandedChildViewController]){
		if ((folderIcon != nil) && ([self _iconAppearsOnCurrentPage:folderIcon])){
			SBIconController *controller = [%c(SBIconController) sharedInstance];
			SBIconViewMap *map = [controller homescreenIconViewMap];;
			if ([map mappedIconViewForIcon:folderIcon] == nil){
				NSLog(@"%@ No folder icon view for %@",self,folderIcon);
				return NO;
			}

			[self pushExpandedTreeNode:folderIcon animated:NO withCompletion:nil];

			SBFolderController *expandedChildViewController = [self expandedChildViewController];
			if ([expandedChildViewController _contentViewClass] == %c(CSClassicFolderView)){
				CSClassicFolderView *folderView = (CSClassicFolderView *)[expandedChildViewController contentView];
				[folderView openFolder:animated completion:completion];
				[folderView setFolderController:self];
			}
			return YES;
		} else {
			NSLog(@"%@ Folder icon %@ cannot be opened because it does not exist on the current page.",self,folderIcon);
			return NO;
		}
	}
	return YES;
}

- (BOOL)popFolderAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completion {
	if (!verifyUDID())
		safeMode();

	SBFolderController *innerController = [self innerFolderController];
	if (innerController != nil){
		if ([innerController innerFolderController] != nil){
			return [[innerController innerFolderController] popFolderAnimated:animated completion:completion];
		} else {
			CSClassicFolderView *folderView = (CSClassicFolderView *)[innerController contentView];
			if ([folderView respondsToSelector:@selector(closeFolder:completion:)]){
				[folderView closeFolder:animated completion:^(BOOL finished){
					[self popExpandedTreeNodeAnimated:NO withCompletion:completion];
				}];
				return YES;
			} else {
				[self popExpandedTreeNodeAnimated:animated withCompletion:completion];
				return YES;
			}
		}
	} else {
		return NO;
	}
}

- (void)popExpandedTreeNodeAnimated:(BOOL)animated withCompletion:(void(^)(BOOL finished))completion {
	SBFolderController *innerController = [self innerFolderController];
	[innerController retain];
	%orig();
	if (innerController != nil){
		if (innerController != [self innerFolderController]){
			CSClassicFolderView *folderView = (CSClassicFolderView *)[innerController contentView];
			if ([folderView respondsToSelector:@selector(closeFolder:completion:)])
				[folderView closeFolder:NO completion:nil];
		}
		[innerController release];
	}
}

-(Class)_contentViewClass {
	return %c(CSClassicFolderView);
}
%end
%end

%ctor {
	if (kCFCoreFoundationVersionNumber >= 1348 && kCFCoreFoundationVersionNumber < 1443){
		if ([[CSClassicFolderSettingsManager sharedInstance] enabled]){
			%init(FolderHooks);
		}
	}
}
