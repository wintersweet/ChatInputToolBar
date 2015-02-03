//
//  LTZInputTool.m
//  ChatInputToolBar
//
//  Created by Peter Lee on 15/2/3.
//  Copyright (c) 2015年 Peter Lee. All rights reserved.
//

#import "LTZInputTool.h"
#import "LTZInputToolBarConstraints.h"

#define DEFAULT_MAGIN_WIDTH 4.0f
#define DEFAULT_MAGIN_HEIGHT DEFAULT_MAGIN_WIDTH

#define DEFAULT_BUTTON_HEIGHT (self.frame.size.height - 2*DEFAULT_MAGIN_HEIGHT)
#define DEFAULT_BUTTON_WITDH DEFAULT_BUTTON_HEIGHT

#define DEFAULT_TEXT_VIEW_WIDTH (self.frame.size.width - 5*DEFAULT_MAGIN_WIDTH - 3*DEFAULT_BUTTON_WITDH)
#define DEFAULT_TEXT_VIEW_HEIGHT (self.frame.size.height - 2*DEFAULT_MAGIN_HEIGHT)

#define DEFAULT_TALK_BUTTON_WIDTH 80.0f
#define DEFAULT_TALK_BUTTON_HEIGHT DEFAULT_TALK_BUTTON_WIDTH

static void * LTZInputTextViewHidenKeyValueObservingContext = &LTZInputTextViewHidenKeyValueObservingContext;

@interface LTZInputTool ()
{
    UIView *_inView;
}
@end

@implementation LTZInputTool
@synthesize inView = _inView;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - LTZInputTool class public methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGFloat)LTZInputToolDefaultHeight
{
    return LTZInputToolDefaultHeight;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - LTZInputTool object public methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame inView:nil delegate:nil];
}

- (instancetype)initWithFrame:(CGRect)frame inView:(UIView *)inView delegate:(id<LTZInputToolDelegate>)delegate
{
    self = [super initWithFrame:frame];
    if (self) {
        _inView = inView;
        self.delegate = delegate;
        [self _initData];
        [self _setupViews];
        [self beginListeningForKeyboard];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - LTZInputTool object private methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)_setupViews
{
    self.userInteractionEnabled = YES;
    /*
    self.image = [[UIImage imageNamed:@"chat_input_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(2.0f, 0.0f, 0.0f, 0.0f)
                                                                       resizingMode:UIImageResizingModeStretch];
     */
    self.backgroundColor = [UIColor redColor];
    _voiceButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(DEFAULT_MAGIN_WIDTH, DEFAULT_MAGIN_HEIGHT, DEFAULT_BUTTON_WITDH, DEFAULT_BUTTON_HEIGHT);
        button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [button setBackgroundImage:[UIImage imageNamed:@"chat_input_voice_button"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(voiceButtonCliked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        button;
    });
    
    _inputTextView = ({
        LTZGrowingTextView *textView = [[LTZGrowingTextView alloc] initWithFrame:CGRectMake(2*DEFAULT_MAGIN_WIDTH + DEFAULT_BUTTON_WITDH, DEFAULT_MAGIN_HEIGHT, DEFAULT_TEXT_VIEW_WIDTH, DEFAULT_TEXT_VIEW_HEIGHT)];
        textView.isScrollable = NO;
        textView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
        
        textView.minNumberOfLines = 1;
        textView.maxNumberOfLines = 4;
        // you can also set the maximum height in points with maxHeight
        // textView.maxHeight = 200.0f;
        textView.returnKeyType = UIReturnKeySend; //just as an example
        textView.font = [UIFont systemFontOfSize:16.0f];
        textView.delegate = self;
        textView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
        textView.backgroundColor = [UIColor whiteColor];
        textView.placeholder = @"send new message...";
        textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        // textView.text = @"test\n\ntest";
        // textView.animateHeightChange = NO; //turns off animation
        
        CGFloat cornerRadius = 6.0f;
        textView.backgroundColor = [UIColor whiteColor];
        textView.layer.borderWidth = 0.5f;
        textView.layer.borderColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
        textView.layer.cornerRadius = cornerRadius;
        
        textView;
    });
    
    _recordButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(2*DEFAULT_MAGIN_WIDTH + DEFAULT_BUTTON_WITDH, DEFAULT_MAGIN_HEIGHT, DEFAULT_TEXT_VIEW_WIDTH, DEFAULT_TEXT_VIEW_HEIGHT);
        button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [button setBackgroundImage:[[UIImage imageNamed:@"chat_record_bg"] stretchableImageWithLeftCapWidth:10 topCapHeight:10] forState:UIControlStateNormal];
        [button setBackgroundImage:[[UIImage imageNamed:@"chat_record_selected_bg"] stretchableImageWithLeftCapWidth:10 topCapHeight:10] forState:UIControlStateHighlighted];
        [button setTitle:@"按住\t对讲" forState:UIControlStateNormal];
        [button setTitle:@"松开\t完成" forState:UIControlStateHighlighted];
        [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [self addSubview:button];
        button;
    });
    
    _expressionButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(3*DEFAULT_MAGIN_WIDTH+DEFAULT_BUTTON_WITDH+DEFAULT_TEXT_VIEW_WIDTH, DEFAULT_MAGIN_HEIGHT, DEFAULT_BUTTON_WITDH, DEFAULT_BUTTON_HEIGHT);
        button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [button setBackgroundImage:[UIImage imageNamed:@"chat_input_emo_button"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(expressionButtonCliked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        button;
    });
    
    _moreButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(4*DEFAULT_MAGIN_WIDTH+2*DEFAULT_BUTTON_WITDH+DEFAULT_TEXT_VIEW_WIDTH, DEFAULT_MAGIN_HEIGHT, DEFAULT_BUTTON_WITDH, DEFAULT_BUTTON_HEIGHT);
        button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [button setBackgroundImage:[UIImage imageNamed:@"chat_input_action_button"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(moreButtonCliked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        button;
    });
    
    [_recordButton setHidden:YES];
    //[_inputTextView setHidden:YES];
    
    [self addSubview:_inputTextView];
    
    //NSStringFromSelector(@selector(isHidden))
    [_inputTextView addObserver:self
                    forKeyPath:NSStringFromSelector(@selector(hidden))
                       options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                       context:LTZInputTextViewHidenKeyValueObservingContext];
}

- (void)voiceButtonCliked:(id)sender
{
    if (!self.isRecordViewShowing) {
        
//        if (![self isFirstResponder]) {
//            [self hideMoreViewOrExpressionView];
//        }
        
        [self prepareToRecord];
        
    }else{
        
        [self prepareToInputText];
    }
}

- (void)moreButtonCliked:(id)sender
{
    
}

- (void)expressionButtonCliked:(id)sender
{
    
}

- (void)prepareToRecord
{
    self.isMoreViewShowing = NO;
    self.isExpressionViewShowing = NO;
    self.isRecordViewShowing = YES;
    
    if ([self.inputTextView isFirstResponder]) {
        [self.inputTextView resignFirstResponder];
    }
}

- (void)prepareToInputText
{
    self.isMoreViewShowing = NO;
    self.isExpressionViewShowing = NO;
    self.isRecordViewShowing = NO;
    
    if (![self.inputTextView isFirstResponder]) {
        [self.inputTextView becomeFirstResponder];
    }
}

- (void)prepareToInputExpression
{
    self.isMoreViewShowing = NO;
    self.isExpressionViewShowing = YES;
    self.isRecordViewShowing = NO;
    
    if ([self isFirstResponder]) {
        [self resignFirstResponder];
    }
    
    //[self showMoreViewOrExpressionView];
    
}

- (void)prepareToInputMoreInfo
{
    self.isMoreViewShowing = YES;
    self.isExpressionViewShowing = NO;
    self.isRecordViewShowing = NO;
    
    if ([self isFirstResponder]) {
        [self resignFirstResponder];
    }
    
    //[self showMoreViewOrExpressionView];
}

- (void)stopToInput
{
    if ([_inputTextView isFirstResponder]) {
        self.isMoreViewShowing = NO;
        self.isExpressionViewShowing = NO;
        self.isRecordViewShowing = NO;
        
    }else{
        
    }
}

- (void)_initData
{
    self.isKeyboardShowing = NO;
    self.isRecordViewShowing = NO;
    self.isExpressionViewShowing = NO;
    self.isMoreViewShowing = NO;
}

- (void)dealloc
{
    @try {
        [_inputTextView removeObserver:self
                            forKeyPath:NSStringFromSelector(@selector(frame))
                               context:LTZInputTextViewHidenKeyValueObservingContext];
    }@catch (NSException * __unused exception) {
    
    }
    _voiceButton = nil;
    _inputTextView = nil;
    _recordButton = nil;
    _expressionButton = nil;
    _moreButton = nil;
    [self endListeningForKeyboard];
}

- (void)beginListeningForKeyboard
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inputKeyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inputKeyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}
- (void)endListeningForKeyboard
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - 监听键盘的显示与隐藏
-(void)inputKeyboardWillShow:(NSNotification *)notification
{
    self.isKeyboardShowing = YES;
    [self keyboardWillShowHide:notification];
}
-(void)inputKeyboardWillHide:(NSNotification *)notification
{
    self.isKeyboardShowing = NO;
    [self keyboardWillShowHide:notification];
}

- (void)keyboardWillShowHide:(NSNotification *)notification
{
    
    if (!self.isMoreViewShowing && !self.isExpressionViewShowing) {
        
        CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        
        // The keyboard animation time duration
        NSTimeInterval animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        // The keyboard animation curve
        NSUInteger animationCurve = [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
        
        // begin animation action
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:animationDuration];
        [UIView setAnimationCurve:(UIViewAnimationCurve)animationCurve];
        
        {
            UIWindow *window = [[UIApplication sharedApplication] keyWindow];
            UIView *view = window.rootViewController.view;
            
            CGFloat keyboardY = [view convertRect:keyboardRect fromView:nil].origin.y;
            
            CGRect inputViewFrame = self.inView.frame;
            
            CGFloat inputViewFrameY = keyboardY - self.frame.size.height;
            
            // for ipad modal form presentations
            CGFloat messageViewFrameBottom = view.frame.size.height - self.frame.size.height;
            
            if(inputViewFrameY > messageViewFrameBottom) inputViewFrameY = messageViewFrameBottom;
            
            inputViewFrame.origin.y = inputViewFrameY;
            
            _inView.frame = inputViewFrame;
            
        }
        
        // end animation action
        [UIView commitAnimations];
    }/*
      else if ([notification.name isEqualToString:UIKeyboardWillHideNotification]) {
      [self hideMoreViewOrExpressionView];
      }else if ([notification.name isEqualToString:UIKeyboardWillShowNotification]){
      CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
      
      // The keyboard animation time duration
      NSTimeInterval animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
      
      // The keyboard animation curve
      NSUInteger animationCurve = [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
      
      // begin animation action
      [UIView beginAnimations:nil context:NULL];
      [UIView setAnimationDuration:animationDuration];
      [UIView setAnimationCurve:(UIViewAnimationCurve)animationCurve];
      
      {
      CGRect newFrame = self.frame;
      CGFloat newFrameY = self.originFrame.origin.y - keyboardRect.size.height;
      newFrame.origin.y = newFrameY;
      
      self.frame = newFrame;
      /*
      // for ipad modal form presentations
      CGFloat messageViewFrameBottom = self.contextView.frame.size.height - self.frame.size.height;
      
      if(inputViewFrameY > messageViewFrameBottom) inputViewFrameY = messageViewFrameBottom;
      
      self.frame = CGRectMake(inputViewFrame.origin.x,
      inputViewFrameY,
      inputViewFrame.size.width,
      inputViewFrame.size.height);
      if ([notification.name isEqualToString:UIKeyboardWillShowNotification]) {
      [self setScrollViewInsetsWithBottomValue:(self.contextView.frame.size.height - self.frame.origin.y - self.frame.size.height + _inputTextView.bounds.size.height-_recordButton.bounds.size.height)];
      }else if ([notification.name isEqualToString:UIKeyboardWillHideNotification] && self.isRecordViewShowing){
      [self setScrollViewInsetsWithBottomValue:(self.contextView.frame.size.height - self.frame.origin.y - self.frame.size.height)];
      }else if ([notification.name isEqualToString:UIKeyboardWillHideNotification] && !self.isRecordViewShowing) {
      [self setScrollViewInsetsWithBottomValue:(self.contextView.frame.size.height - self.frame.origin.y - self.frame.size.height + _inputTextView.bounds.size.height-_recordButton.bounds.size.height)];
      }
      
      }
      
      // end animation action
      [UIView commitAnimations];
      }*/
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - LTZInputTool properites
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setIsMoreViewShowing:(BOOL)isMoreViewShowing
{
    _isMoreViewShowing = isMoreViewShowing;
    [_moreButton setBackgroundImage:[UIImage imageNamed:(isMoreViewShowing ? @"chat_input_keyboard_button":@"chat_input_action_button")] forState:UIControlStateNormal];
    
}

- (void)setIsExpressionViewShowing:(BOOL)isExpressionViewShowing
{
    _isExpressionViewShowing = isExpressionViewShowing;
    [_expressionButton setBackgroundImage:[UIImage imageNamed:(isExpressionViewShowing ? @"chat_input_keyboard_button":@"chat_input_emo_button")] forState:UIControlStateNormal];
}

- (void)setIsRecordViewShowing:(BOOL)isRecordViewShowing
{
    _isRecordViewShowing = isRecordViewShowing;
    [_voiceButton setBackgroundImage:[UIImage imageNamed:(isRecordViewShowing ? @"chat_input_keyboard_button":@"chat_input_voice_button")] forState:UIControlStateNormal];
    
    [_inputTextView setHidden:isRecordViewShowing];
    [_recordButton setHidden:!isRecordViewShowing];
    
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - LTZGrowingTextViewDelegate methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)growingTextView:(LTZGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float changedHeight = (growingTextView.frame.size.height - height);
    
    //changed its height of frame
    CGRect newFrame = self.frame;
    newFrame.size.height -= changedHeight;
    //newFrame.origin.y += changedHeight;
    self.frame = newFrame;
    
    //changed its futher view frame
    CGRect inViewFrame = self.inView.frame;
    inViewFrame.size.height -= changedHeight;
    inViewFrame.origin.y += changedHeight;
    _inView.frame = inViewFrame;
}

- (BOOL)growingTextView:(LTZGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    
    if ([text isEqualToString:@"\n"])
    {
        NSString * content = growingTextView.text;
        if (content.length == 0 || [content isEqualToString:@""]){
            NSLog(@"请输入内容");
        }
        else {
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(ltzInputTool:didSentTextContent:)]) {
                [self.delegate ltzInputTool:self didSentTextContent:content];
            }
            
            growingTextView.text = @"";
        }
        return NO;
    }
    return YES;
}

#pragma mark - Key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == LTZInputTextViewHidenKeyValueObservingContext) {
        
        if (object == _inputTextView && [keyPath isEqualToString:NSStringFromSelector(@selector(hidden))]) {
            
            BOOL oldHidenState = [[change objectForKey:NSKeyValueChangeOldKey] boolValue];
            BOOL newHidenState = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
            
            if (newHidenState == oldHidenState) {
                return;
            }
            
            //  do not convert frame to contextView coordinates here
            //  KVO is triggered during panning (see below)
            //  panning occurs in contextView coordinates already
            [self adjustInViewFrameWithInputViewHiddenState:newHidenState];
        }
    }
}

- (void)adjustInViewFrameWithInputViewHiddenState:(BOOL)hidde
{
    CGFloat changedHeight = _inputTextView.frame.size.height - _recordButton.frame.size.height;
    
    if (changedHeight == 0) return;
    
    CGRect newFrame = self.frame;
    CGRect inViewFrame = self.inView.frame;
    if (hidde) {//inputView :show->hidden
        
        //changed its height of frame
        newFrame.size.height -= changedHeight;
        
        //changed its futher view frame
        inViewFrame.size.height -= changedHeight;
        inViewFrame.origin.y += changedHeight;
        
        
    }else{//inputView :hidden->show
    
        //changed its height of frame
        newFrame.size.height += changedHeight;
        
        //changed its futher view frame
        inViewFrame.size.height += changedHeight;
        inViewFrame.origin.y -= changedHeight;
    }
    
    self.frame = newFrame;
    _inView.frame = inViewFrame;
}

@end