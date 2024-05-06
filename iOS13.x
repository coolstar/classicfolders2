#import "Headers.h"

#define isModern [[CSClassicFolderSettingsManager sharedInstance] modern]

typedef struct SBIconCoordinate {
	long long row;
	long long col;
} SBIconCoordinate;

@interface SBFolderIconListView()
- (CGFloat)sideIconInset;
@end

@interface SBIconListGridLayoutConfiguration : NSObject
@property (assign,nonatomic) unsigned long long numberOfPortraitColumns;
@property (assign,nonatomic) unsigned long long numberOfPortraitRows;
@property (assign,nonatomic) unsigned long long numberOfLandscapeColumns;
@property (assign,nonatomic) unsigned long long numberOfLandscapeRows;
@property (assign,nonatomic) UIEdgeInsets portraitLayoutInsets;
@property (assign,nonatomic) UIEdgeInsets landscapeLayoutInsets;
@end

@interface SBIconListFlowLayout : NSObject
- (SBIconListGridLayoutConfiguration *)layoutConfiguration;
@end

%group FolderHooks
%subclass SBFolderIconListView : SBIconListView

- (SBIconListFlowLayout *)layout {
	SBIconListFlowLayout *layout = %orig;


	SBIconListGridLayoutConfiguration *configuration = [layout layoutConfiguration];
	configuration.numberOfPortraitColumns = 4;
	configuration.numberOfPortraitRows = 5;
	configuration.numberOfLandscapeColumns = 5;
	configuration.numberOfLandscapeRows = 4;

	configuration.portraitLayoutInsets = UIEdgeInsetsMake(0, [self sideIconInset], 5.0f, [self sideIconInset]);
	configuration.landscapeLayoutInsets = UIEdgeInsetsMake(0, [self sideIconInset], 5.0f, [self sideIconInset]);

	return layout;
}

%new;
- (CGFloat)sideIconInset {
	if (isModern)
		return 17.0f;

	if ([[UIScreen mainScreen] bounds].size.width > 320 && [[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad)
		return 27.0f;
	else
		return 17.0f;
}
%end

%hook SBFloatingDockViewController
- (void)_presentFolderForIcon:(SBFolderIcon *)folderIcon animated:(BOOL)animated completion:(id)completion {
	if (!verifyUDID())
		safeMode();

	if (folderIcon && [self _shouldOpenFolderIcon:folderIcon]){
			SBIconViewMap *map = [[self userIconListView] viewMap];
			if ([map mappedIconViewForIcon:folderIcon] == nil){
				NSLog(@"%@ No folder icon view for %@",self,folderIcon);
				return;
			}

			SBIconController *iconController = [self iconController];

			SBFolderController *folderController = [[%c(SBFolderController) alloc] initWithFolder:[folderIcon folder] orientation:[iconController orientation] viewMap:map];
			[folderController setFolderDelegate:self];
			[folderController setLegibilitySettings:[self legibilitySettings]];
			[folderController setEditing:[iconController isEditing]];

			SBFolderPresentingViewController *presentingController = [self folderPresentingViewController];
			[presentingController presentFolderController:folderController animated:NO completion:nil];

			if ([folderController _contentViewClass] == %c(CSClassicFolderView)){
				CSClassicFolderView *folderView = (CSClassicFolderView *)[folderController contentView];
				[folderView openFolder:animated completion:completion];
				[folderView setFolderController:folderController];
			}
			return;
	} else {
		NSLog(@"Folder icon %@ cannot be opened because it does not exist in the user icon list",folderIcon);
		return;
	}
}

- (void)dismissPresentedFolderAnimated:(BOOL)animated withTransitionContext:(id)context completion:(id)completion {
	if (!verifyUDID())
		safeMode();

	SBFolderPresentingViewController *presentingController = [self folderPresentingViewController];

	SBFolderController *folderController = [presentingController presentedFolderController];
	if (folderController){
		if ([folderController innerFolderController] != nil){
			[folderController popFolderAnimated:animated completion:completion];
			return;
		} else {
			CSClassicFolderView *folderView = (CSClassicFolderView *)[folderController contentView];
			if ([folderView respondsToSelector:@selector(closeFolder:completion:)]){
				[folderView closeFolder:animated completion:^(BOOL finished){
					[presentingController dismissPresentedFolderControllerAnimated:NO completion:completion];
				}];
			} else {
				[presentingController dismissPresentedFolderControllerAnimated:NO completion:completion];
			}
			return;
		}
	}
}
%end

%hook SBFolderController
-(BOOL)pushFolderIcon:(SBFolderIcon *)folderIcon location:(NSString *)location animated:(BOOL)animated completion:(id)completion {
	if (!verifyUDID())
		safeMode();
	
	if (![self isOpen]){
		NSLog(@"%@ Unable to open folder icon %@ because we aren't actually open!",self,folderIcon);
		return NO;
	}

	if ((folderIcon != nil) && ([self shouldOpenFolderIcon:folderIcon])){
		SBFolder *folder = [folderIcon folder];

		Class folderControllerClass = [self controllerClassForFolder:folder];
		Class configurationClass = [folderControllerClass configurationClass];

		SBFolderControllerConfiguration *configuration = (SBFolderControllerConfiguration *)[[configurationClass alloc] init];
		configuration.folder = folder;
		configuration.originatingIconLocation = location;

		[self configureInnerFolderControllerConfiguration:configuration];

		SBFolderController *innerController = [(SBFolderController *)[folderControllerClass alloc] initWithConfiguration:configuration];
		[self pushNestedViewController:innerController animated:NO withCompletion:^(BOOL finished){
			if ([folderControllerClass _contentViewClass] == %c(CSClassicFolderView)){
				CSClassicFolderView *folderView = (CSClassicFolderView *)[innerController contentView];
				[folderView setFolderController:innerController];
				[folderView setFolderIconView:[innerController folderIconView]];
				[folderView openFolder:animated completion:nil];
			}
		}];
		return YES;
	} else {
		NSLog(@"%@ Folder icon %@ cannot be opened because it does not exist on the current page.",self,folderIcon);
		return NO;
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
					[self popNestedViewControllerAnimated:NO withCompletion:completion];
				}];
				return YES;
			} else {
				[self popNestedViewControllerAnimated:animated withCompletion:completion];
				return YES;
			}
		}
	} else {
		return NO;
	}
}

- (void)popNestedViewControllerAnimated:(BOOL)animated withCompletion:(void(^)(BOOL finished))completion {
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
%end

%hook SBFloatyFolderController
+ (Class)_contentViewClass {
	return %c(CSClassicFolderView);
}
%end

//Fix crash
%hook UIImage
+ (UIImage *) sbf_imageFromContextWithSize:(CGSize)size scale:(CGFloat)scale type:(NSInteger)type pool:(id)pool drawing:(id)drawing encapsulation:(id)encapsulation {
	UIImage *image = nil;
	@try {
		image = %orig;
	} 
	@catch (NSException *exception){
		//NSLog(@"Caught iOS 13 crash: %@", exception);
	}
	return image;
}
%end
%end

%ctor {
	if (kCFCoreFoundationVersionNumber > 1600){
		if ([[CSClassicFolderSettingsManager sharedInstance] enabled]){
			%init(FolderHooks);
		}
	}
}