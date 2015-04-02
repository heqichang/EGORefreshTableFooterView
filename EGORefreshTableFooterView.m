//
//  EGORefreshTableHeaderView.m
//  Demo
//
//  Created by Devin Doty on 10/14/09October14.
//  Copyright 2009 enormego. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "EGORefreshTableFooterView.h"


#define TEXT_COLOR	 [UIColor colorWithRed:87.0/255.0 green:108.0/255.0 blue:137.0/255.0 alpha:1.0]
#define FLIP_ANIMATION_DURATION 0.18f


@interface EGORefreshTableFooterView (Private)
- (void)setState:(EGOFooterPullRefreshState)aState;
@end

@implementation EGORefreshTableFooterView

@synthesize delegate=_delegate;


- (id)initWithFrame:(CGRect)frame arrowImageName:(NSString *)arrow textColor:(UIColor *)textColor  {
    if((self = [super initWithFrame:frame])) {
		
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.backgroundColor = [UIColor colorWithRed:226.0/255.0 green:231.0/255.0 blue:237.0/255.0 alpha:1.0];

		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 18.0f, self.frame.size.width, 20.0f)];
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		label.font = [UIFont boldSystemFontOfSize:13.0f];
		label.textColor = textColor;
		label.shadowColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
		label.shadowOffset = CGSizeMake(0.0f, 1.0f);
		label.backgroundColor = [UIColor clearColor];
		label.textAlignment = NSTextAlignmentCenter;
		[self addSubview:label];
		_statusLabel=label;
		[label release];
		
		CALayer *layer = [CALayer layer];
		layer.frame = CGRectMake(frame.size.width - 85.0f, 15.0f, 20.0f, 40.0f);
		layer.contentsGravity = kCAGravityResizeAspect;
		layer.contents = (id)[UIImage imageNamed:arrow].CGImage;
		
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
		if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
			layer.contentsScale = [[UIScreen mainScreen] scale];
		}
#endif
		
		[[self layer] addSublayer:layer];
		_arrowImage=layer;
		
		UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		view.frame = CGRectMake(frame.size.width - 85.0f, 15.0f, 20.0f, 20.0f);
		[self addSubview:view];
		_activityView = view;
		[view release];
		
		
		[self setState:EGOOFooterPullRefreshNormal];
        
    }
	
    return self;
	
}

- (id)initWithFrame:(CGRect)frame  {
    return [self initWithFrame:frame arrowImageName:@"blueArrowReversal" textColor:TEXT_COLOR];
}

#pragma mark -
#pragma mark Setters


- (void)setState:(EGOFooterPullRefreshState)aState{
	
	switch (aState) {
		case EGOOFooterPullRefreshPulling:
            _statusLabel.text = @"松开即可加载";
			[CATransaction begin];
			[CATransaction setAnimationDuration:FLIP_ANIMATION_DURATION];
			_arrowImage.transform = CATransform3DMakeRotation((M_PI / 180.0) * 180.0f, 0.0f, 0.0f, 1.0f);
			[CATransaction commit];
			break;
		case EGOOFooterPullRefreshNormal:
			if (_state == EGOOFooterPullRefreshPulling) {
                
				[CATransaction begin];
				[CATransaction setAnimationDuration:FLIP_ANIMATION_DURATION];
				_arrowImage.transform = CATransform3DIdentity;
				[CATransaction commit];
			}
			
			//_statusLabel.text = NSLocalizedString(@"Pull down to refresh...", @"Pull down to refresh status");
            _statusLabel.text = @"上拉加载更多...";
            
			[_activityView stopAnimating];
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions]; 
			_arrowImage.hidden = NO;
			_arrowImage.transform = CATransform3DIdentity;
			[CATransaction commit];
			
			break;
		case EGOOFooterPullRefreshLoading:
            _statusLabel.text = @"正在加载...";
			[_activityView startAnimating];
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions]; 
			_arrowImage.hidden = YES;
			[CATransaction commit];
			
			break;
		default:
			break;
	}
	
	_state = aState;
}


#pragma mark -
#pragma mark ScrollView Methods

- (void)egoRefreshScrollViewDidScroll:(UIScrollView *)scrollView {	
	
	if (_state == EGOOFooterPullRefreshLoading) {
        
        CGFloat offset = MAX(scrollView.contentOffset.y + scrollView.frame.size.height - scrollView.contentSize.height , 0);
		offset = MIN(offset, 60);
		scrollView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, offset, 0.0f);
	} else if (scrollView.isDragging) {
		
        CGFloat scrollHight = MIN(scrollView.frame.size.height, scrollView.contentSize.height);
        
		BOOL _loading = NO;
		if ([_delegate respondsToSelector:@selector(egoRefreshTableFooterDataSourceIsLoading:)]) {
			_loading = [_delegate egoRefreshTableFooterDataSourceIsLoading:self];
		}
		
		if (_state == EGOOFooterPullRefreshPulling &&
            scrollHight + scrollView.contentOffset.y < scrollView.contentSize.height + 65.0f &&
            scrollHight + scrollView.contentOffset.y > scrollView.contentSize.height && !_loading) {
			[self setState:EGOOFooterPullRefreshNormal];
		} else if (_state == EGOOFooterPullRefreshNormal &&
                   scrollHight + scrollView.contentOffset.y > scrollView.contentSize.height + 65.0f && !_loading) {
			[self setState:EGOOFooterPullRefreshPulling];
		}
		
		if (scrollView.contentInset.top != 0) {
			scrollView.contentInset = UIEdgeInsetsZero;
		}
	}
}

- (void)egoRefreshScrollViewDidEndDragging:(UIScrollView *)scrollView {
	
	BOOL _loading = NO;
	if ([_delegate respondsToSelector:@selector(egoRefreshTableFooterDataSourceIsLoading:)]) {
		_loading = [_delegate egoRefreshTableFooterDataSourceIsLoading:self];
	}
	
    CGFloat scrollHight = MIN(scrollView.frame.size.height, scrollView.contentSize.height);
    
	if (scrollHight + scrollView.contentOffset.y >= scrollView.contentSize.height + 65.0f && !_loading) {
		
		if ([_delegate respondsToSelector:@selector(egoRefreshTableFooterDidTriggerRefresh:)]) {
            [_delegate egoRefreshTableFooterDidTriggerRefresh:self];
		}
        
		[self setState:EGOOFooterPullRefreshLoading];
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.2];
		scrollView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 60.0f, 0.0f);
		[UIView commitAnimations];
	}
}

- (void)egoRefreshScrollViewDataSourceDidFinishedLoading:(UIScrollView *)scrollView {	
	
    
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:.3];
	[scrollView setContentInset:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
	[UIView commitAnimations];
	
    [self setState:EGOOFooterPullRefreshNormal];

}


#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	
	_delegate=nil;
	_activityView = nil;
	_statusLabel = nil;
    [super dealloc];
}


@end
