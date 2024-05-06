#import "Headers.h"

%group BlurRemoval
%hook SBFolderContainerView
- (void)layoutSubviews {
	[[self backgroundView] setAlpha:0];

	%orig;
}
%end

%hook SBFolderIconZoomAnimator
- (instancetype)initWithOuterController:(SBFolderController *)outerController innerController:(SBFolderController *)innerController folderIcon:(SBFolderIcon *)folderIcon {
	return nil;
}
%end
%end

%group BlurRemoval10to12
//iOS 10 - 12
%hook SBIconController
- (void)_animateFolderIcon:(SBFolderIcon *)folderIcon open:(BOOL)open animated:(BOOL)animated withCompletion:(id)completion {
	%orig;
	SBIconViewMap *homescreenMap = [self homescreenIconViewMap];

	SBFolderIconView *folderIconView = (SBFolderIconView *)[homescreenMap mappedIconViewForIcon:folderIcon];
	[folderIconView setIconImageAlpha:1];
}
%end
%end

%group BlurRemoval13
//iOS 13
%hook SBFolderController
-(void)viewWillTransitionToSize:(CGSize)arg2 forOperation:(NSInteger)operation withTransitionCoordinator:(id)coordinator {
	%orig;
	SBIconView *iconView = [self folderIconView];
	if ([iconView respondsToSelector:@selector(setAllIconElementsButLabelToHidden:)])
		[iconView setAllIconElementsButLabelToHidden:NO];
	else
		[iconView setAllIconElementsButLabelHidden:NO];
}
%end
%end

%ctor {
	if ([[CSClassicFolderSettingsManager sharedInstance] enabled]){
		if (kCFCoreFoundationVersionNumber >= 1348){
			%init(BlurRemoval);
			if (kCFCoreFoundationVersionNumber < 1600){
				%init(BlurRemoval10to12);
			} else {
				%init(BlurRemoval13);
			}
		}
	}
}