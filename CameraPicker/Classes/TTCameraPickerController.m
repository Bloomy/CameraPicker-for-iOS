//
//  TTCameraPickerController
//  TTCameraPicker
//
//  Created by Orlando Aleman Ortiz on 15/04/13.
//
//

#import "TTCameraPickerController.h"
#import "UIBarButtonItem+Custom.h"
#import <UIImage+ResizeMagick.h>


@interface TTCameraPickerController () {
    NSDictionary *lastPhotoMediaInfo_;
    BOOL isTouchDown_;
}

- (void)setup;

- (IBAction)takePhoto:(id)sender;
- (IBAction)cancelCamera:(id)sender;
- (IBAction)chooseFromGallery:(id)sender;
- (IBAction)switchCamera:(id)sender;
- (IBAction)switchFlash:(id)sender;

@property (nonatomic) UIImagePickerController *imagePickerController;
@property (nonatomic) UIImageView *focusView;

@property (weak, nonatomic) IBOutlet UIButton *switchFlashBtn;
@property (weak, nonatomic) IBOutlet UIButton *switchCameraBtn;
@property (weak, nonatomic) IBOutlet UIToolbar *bottomBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *chooseFromGalleryBtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *takeBtn;
@end


@implementation TTCameraPickerController


- (id)init
{
    if (self = [super initWithNibName:@"TTCameraPickerView" bundle:nil]) {
        [self setup];
        [self view];
    }
    return self;
}


- (void)setup
{
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    self.imagePickerController.showsCameraControls = NO;
    self.imagePickerController.delegate = self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];


    self.view.frame = [[UIScreen mainScreen] bounds];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;

    CGRect viewFrame = self.imagePickerController.view.frame;
    self.imagePickerController.view.frame = viewFrame;
    [self.imagePickerController.cameraOverlayView addSubview:self.view];

    [self.takeBtn customViewButtonWithImage:@"camera-take"];

    [self refreshFlashModeButton];
  

    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    recognizer.minimumPressDuration = 0;
    recognizer.cancelsTouchesInView = NO;
    recognizer.numberOfTapsRequired = 0;
    recognizer.numberOfTouchesRequired = 1;
    recognizer.delegate = self;
    [self.view addGestureRecognizer:recognizer];
  
  
    UIImage *image = [UIImage imageNamed:@"focus-crosshair"];
    self.focusView = [[UIImageView alloc] initWithImage:image];
    self.focusView.alpha = 0;
    [self.view addSubview:self.focusView];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.chooseFromGalleryBtn.enabled = [self.delegate respondsToSelector:@selector(cameraPickerControllerWantsGallery:)];
}


- (void)refreshFlashModeButton
{
    BOOL flashAvailable = [UIImagePickerController isFlashAvailableForCameraDevice:self.imagePickerController.cameraDevice];
    self.switchFlashBtn.hidden = !flashAvailable;
    
    
    if (flashAvailable) {
        UIImagePickerControllerCameraFlashMode flashMode = self.imagePickerController.cameraFlashMode;
        
        UIImage *image = nil;
        switch (flashMode) {
            case UIImagePickerControllerCameraFlashModeOn:
                image = [UIImage imageNamed:@"camera-flash"];
                break;
            case UIImagePickerControllerCameraFlashModeAuto:
                image = [UIImage imageNamed:@"camera-flashauto"];
                break;
            case UIImagePickerControllerCameraFlashModeOff:
                image = [UIImage imageNamed:@"camera-flashoff"];
                break;
        }
        [self.switchFlashBtn setImage:image forState:UIControlStateNormal];
    }
}



#pragma mark - Actions

- (void)chooseFromGallery:(id)sender
{
    [self.delegate cameraPickerControllerWantsGallery:self];
}


- (IBAction)switchCamera:(id)sender
{
    UIImagePickerControllerCameraDevice currentDevice = self.imagePickerController.cameraDevice;
    UIImagePickerControllerCameraDevice nextDevice = currentDevice == UIImagePickerControllerCameraDeviceRear ? UIImagePickerControllerCameraDeviceFront : UIImagePickerControllerCameraDeviceRear;
    
    if ([UIImagePickerController isCameraDeviceAvailable:nextDevice]) {
        // Animated switching between rear and front camera
        [UIView transitionWithView:self.imagePickerController.view
                          duration:1.0
                           options:UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionTransitionFlipFromLeft
                        animations:^{
                            self.imagePickerController.cameraDevice = nextDevice;
                            [self refreshFlashModeButton];
                        } completion:NULL];
    }
}


- (IBAction)switchFlash:(id)sender
{
    UIImagePickerControllerCameraFlashMode nextFlashMode;
    switch (self.imagePickerController.cameraFlashMode) {
        case UIImagePickerControllerCameraFlashModeAuto:
            nextFlashMode = UIImagePickerControllerCameraFlashModeOn;
            break;
        case UIImagePickerControllerCameraFlashModeOff:
            nextFlashMode = UIImagePickerControllerCameraFlashModeAuto;
            break;
        case UIImagePickerControllerCameraFlashModeOn:
            nextFlashMode = UIImagePickerControllerCameraFlashModeOff;
            break;
    }
    self.imagePickerController.cameraFlashMode = nextFlashMode;
    [self refreshFlashModeButton];
}


- (void)cancelCamera:(id)sender
{
    [self.delegate cameraPickerControllerDidCancel:self];
}


- (IBAction)takePhoto:(id)sender
{
    [self.imagePickerController takePicture];
}


#pragma mark - UIImagePickerController

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    lastPhotoMediaInfo_ = info;
    
    TTCameraPreviewController *previewVC = [[TTCameraPreviewController alloc] init];
    previewVC.image = info[UIImagePickerControllerOriginalImage];
    previewVC.delegate = self;
    [self.imagePickerController pushViewController:previewVC animated:YES];
}


#pragma mark - CameraPreviewController

- (void)cameraPreviewControllerWantsRetake:(TTCameraPreviewController *)controller
{
    [self.imagePickerController popViewControllerAnimated:YES];
}


- (void)cameraPreviewControllerDidFinish:(TTCameraPreviewController *)picker
{
    [self.delegate cameraPickerController:self didFinishWithPhotoWithInfo:lastPhotoMediaInfo_];
    lastPhotoMediaInfo_ = nil;
}


#pragma mark - UIGestureRecognizer


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isEqual:self.view]) {
      return YES;
    }
    return NO;
}


- (void)handleTap:(UILongPressGestureRecognizer *)recognizer
{    
    CGPoint touchPoint = [recognizer locationInView:self.view];
    CGSize originalSize = self.focusView.frame.size;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        isTouchDown_ = YES;
        self.focusView.alpha = 0;
        self.focusView.frame = CGRectMake(touchPoint.x - 0.5*originalSize.width,
                                          touchPoint.y - 0.5*originalSize.height,
                                          originalSize.height,
                                          originalSize.height);
        self.focusView.transform = CGAffineTransformMakeScale(2.0, 2.0);
        
        [UIView animateWithDuration:0.5
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.focusView.alpha = 1;
                             self.focusView.transform = CGAffineTransformIdentity;
                         }
                         completion:^(BOOL finished) {
                             [self doBlinkAnimationWithDelay:0];
                         }];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        isTouchDown_ = NO;
    }
}


- (void)doBlinkAnimationWithDelay:(CGFloat)delay
{
    self.focusView.alpha = 1;     
    [UIView animateWithDuration:0.2
                          delay:delay
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [UIView setAnimationRepeatCount:2];
                         self.focusView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         if (isTouchDown_) {
                             [self doBlinkAnimationWithDelay:0.0];
                         }
                     }];
}


@end
