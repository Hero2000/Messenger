//
// Copyright (c) 2016 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DialogflowView.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface DialogflowView()
{
	ApiAI *apiAI;
}
@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation DialogflowView

@synthesize rcmessages;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self
																						   action:@selector(actionDone)];
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.buttonInputAttach.userInteractionEnabled = NO;
	self.buttonInputAudio.userInteractionEnabled = NO;
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([FUser wallpaper] != nil)
		self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[FUser wallpaper]]];
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	apiAI = [ApiAI sharedApiAI];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	rcmessages = [[NSMutableArray alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self loadEarlierShow:NO];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self updateTitleDetails];
	//---------------------------------------------------------------------------------------------------------------------------------------------
}

#pragma mark - Message methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (RCMessage *)rcmessage:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return rcmessages[indexPath.section];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)addMessage:(NSString *)text incoming:(BOOL)incoming
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	RCMessage *rcmessage = [[RCMessage alloc] initWithText:text incoming:incoming];
	[rcmessages addObject:rcmessage];
	[self refreshTableView1];
}

#pragma mark - Avatar methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)avatarInitials:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	RCMessage *rcmessage = rcmessages[indexPath.section];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (rcmessage.outgoing)
	{
		return [FUser initials];
	}
	else return @"AI";
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UIImage *)avatarImage:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return nil;
}

#pragma mark - Header, Footer methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)textSectionHeader:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)textBubbleHeader:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)textBubbleFooter:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)textSectionFooter:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return nil;
}

#pragma mark - Menu controller methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSArray *)menuItems:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	RCMenuItem *menuItemCopy = [[RCMenuItem alloc] initWithTitle:@"Copy" action:@selector(actionMenuCopy:)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	menuItemCopy.indexPath = indexPath;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return @[menuItemCopy];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (action == @selector(actionMenuCopy:))	return YES;
	return NO;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)canBecomeFirstResponder
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return YES;
}

#pragma mark - Typing indicator methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)typingIndicatorShow:(BOOL)show animated:(BOOL)animated delay:(CGFloat)delay
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
	dispatch_after(time, dispatch_get_main_queue(), ^{ [self typingIndicatorShow:show animated:animated]; });
}

#pragma mark - Title details methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)updateTitleDetails
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self.labelTitle1.text = @"AI interface";
	self.labelTitle2.text = @"online now";
}

#pragma mark - Refresh methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)refreshTableView1
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self refreshTableView2];
	[self scrollToBottom:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)refreshTableView2
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self.tableView reloadData];
}

#pragma mark - Dialogflow methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)sendDialogflowRequest:(NSString *)text
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self typingIndicatorShow:YES animated:YES delay:0.5];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	AITextRequest *aiRequest = [apiAI textRequest];
	aiRequest.query = @[text];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[aiRequest setCompletionBlockSuccess:^(AIRequest *request, id response)
	{
		[self typingIndicatorShow:NO animated:YES delay:1.0];
		[self displayDialogflowResponse:response delay:1.1];
	}
	failure:^(AIRequest *request, NSError *error)
	{
		[ProgressHUD showError:@"Dialogflow request error."];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[apiAI enqueue:aiRequest];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)displayDialogflowResponse:(NSDictionary *)dictionary delay:(CGFloat)delay
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
	dispatch_after(time, dispatch_get_main_queue(), ^{ [self displayDialogflowResponse:dictionary]; });
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)displayDialogflowResponse:(NSDictionary *)dictionary
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSDictionary *result = dictionary[@"result"];
	NSDictionary *fulfillment = result[@"fulfillment"];
	NSString *text = fulfillment[@"speech"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self addMessage:text incoming:YES];
	[Audio playMessageIncoming];
}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionDone
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionSendMessage:(NSString *)text
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[Audio playMessageOutgoing];
	[self addMessage:text incoming:NO];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self sendDialogflowRequest:text];
}

#pragma mark - User actions (menu)

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionMenuCopy:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSIndexPath *indexPath = [RCMenuItem indexPath:sender];
	RCMessage *rcmessage = [self rcmessage:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[[UIPasteboard generalPasteboard] setString:rcmessage.text];
}

#pragma mark - Table view data source

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [rcmessages count];
}

@end
