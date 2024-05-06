#import "Headers.h"

//iOS 8
%hook SBAppSwitcherHomePageCellView
- (void)layoutSubviews {
	%orig;
	[self setClipsToBounds:YES];
}
%end

//iOS 7
%hook SBAppSliderHomePageCellView
- (void)layoutSubviews {
	%orig;
	[self setClipsToBounds:YES];
}
%end