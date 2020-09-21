/*
* Copyright SecureKey Technologies Inc. All Rights Reserved.
* SPDX-License-Identifier: Apache-2.0
*/

#import "ViewController.h"

@interface MyHandler: NSObject<ApiHandler>{

}
@end

@implementation MyHandler
    
NSString *lastTopic, *lastMessage;

- (NSString*) getLastNotification {
    return [NSString stringWithFormat:@"%@\n%@", lastTopic, lastMessage];
}

- (BOOL) handle: (NSString *)topic message:(NSData *)message
          error:(NSError * _Nullable __autoreleasing *)error {
    
    lastTopic = topic;
    lastMessage = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
    
    NSLog(@"received topic: %@", lastTopic);
    NSLog(@"received message: %@", lastMessage);
    
    return true;
}

@end

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIScrollView *mainScrollView;

@property IBOutlet UISwitch *agentTypeSwitch;
@property IBOutlet UITextField *agentURLTextField;
@property IBOutlet UITextField *websocketURLTextField;
@property IBOutlet UIButton *getCredentialsButton;
@property IBOutlet UITextView *getCredentialsResponseTextView;
@property IBOutlet UITextView *ariesNotificationsTextView;
@property IBOutlet UITextField *didExRecInvReqTextField;

@property NSString *urlToUse;
@property NSString *wsURLToUse;
@property NSString *didExRecInvReq;
@property BOOL useLocalAgent;
@property ApiAriesController* ariesAgent;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.mainScrollView setContentSize:(CGSizeMake(self.view.frame.size.width, self.view.frame.size.height))];
    _didExRecInvReq = @"{\n\t\t\"serviceEndpoint\":\"http://alice.agent.example.com:8081\",\n\t\t\"recipientKeys\":[\"FDmegH8upiNquathbHZiGBZKwcudNfNWPeGQFBt8eNNi\"],\n\t\t\"@id\":\"a35c0ac6-4fc3-46af-a071-c1036d036057\",\n\t\t\"label\":\"agent\",\n\t\t\"@type\":\"https://didcomm.org/didexchange/1.0/invitation\"}";

    [self addAgentLabel];
    [self addAgentSiwtch];
    [self addAgentURLTextField];
    [self addWebsocketURLTextField];
    [self addCreateAgentButton];
    [self addGetCredentialsButton];
    [self addResponseLabel];
    [self addGetCredentialsResponse];
    [self addNotifLabel];
    [self addDIDExchangeReceiveInvitationRequestTextField];
    [self addNotificationsTextView];
}

- (void) addAgentLabel {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 250, 160)];
    [label setText:@"Use Local Agent: "];
    [self.view addSubview:label];
}

- (void) addAgentSiwtch {
    _agentTypeSwitch = [[UISwitch alloc] init];
    [self.view addSubview:_agentTypeSwitch];
    _agentTypeSwitch.center = CGPointMake(180, 90);
    [_agentTypeSwitch addTarget:self action:@selector(switched:)
    forControlEvents:UIControlEventValueChanged];
}

- (IBAction) switched: (id)sender {
    _ariesAgent = nil;
    _useLocalAgent = _agentTypeSwitch.on ? true : false;
    _agentURLTextField.hidden = _useLocalAgent;
    _websocketURLTextField.hidden = _useLocalAgent;
    [_getCredentialsButton setBackgroundColor:UIColor.grayColor];
    [_getCredentialsButton setEnabled:false];
    [_getCredentialsResponseTextView setText:@""];
}

- (void)addAgentURLTextField {
    UILabel *prefixLabel = [[UILabel alloc]initWithFrame:CGRectZero];
    prefixLabel.text =@"  Agent URL";
    [prefixLabel setFont:[UIFont boldSystemFontOfSize:14]];
    [prefixLabel sizeToFit];

    _agentURLTextField = [[UITextField  alloc] initWithFrame:
    CGRectMake(50, 150, 280, 30)];

    _agentURLTextField.borderStyle = UITextBorderStyleRoundedRect;
    _agentURLTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [_agentURLTextField setFont:[UIFont boldSystemFontOfSize:12]];
    _agentURLTextField.placeholder = @"http://your.agent.url";
    _agentURLTextField.leftView = prefixLabel;
    _agentURLTextField.leftViewMode = UITextFieldViewModeAlways;
    _agentURLTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;

    [self.view addSubview:_agentURLTextField];
    _agentURLTextField.delegate = self;

    [_agentURLTextField addTarget:self action:@selector(textChanged:) forControlEvents:UIControlEventEditingChanged];
}

- (void) textChanged: (UITextField*)textField {
    _urlToUse = textField.text;
}

- (void)addWebsocketURLTextField {
    UILabel *prefixLabel = [[UILabel alloc]initWithFrame:CGRectZero];
    prefixLabel.text =@"Websocket URL";
    [prefixLabel setFont:[UIFont boldSystemFontOfSize:14]];
    [prefixLabel sizeToFit];

    _websocketURLTextField = [[UITextField  alloc] initWithFrame:
    CGRectMake(50, 185, 280, 30)];

    _websocketURLTextField.borderStyle = UITextBorderStyleRoundedRect;
    _websocketURLTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [_websocketURLTextField setFont:[UIFont boldSystemFontOfSize:12]];
    _websocketURLTextField.placeholder = @"ws://websocket.url/ws";
    _websocketURLTextField.leftView = prefixLabel;
    _websocketURLTextField.leftViewMode = UITextFieldViewModeAlways;
    _websocketURLTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;

    [self.view addSubview:_websocketURLTextField];
    _websocketURLTextField.delegate = self;

    [_websocketURLTextField addTarget:self action:@selector(textChangedWS:) forControlEvents:UIControlEventEditingChanged];
}

- (void) textChangedWS: (UITextField*)textField {
    _wsURLToUse = textField.text;
}

- (void) addCreateAgentButton {
    UIButton *button = [[UIButton alloc] init];
    [button setFrame:CGRectMake(90, 225, 200, 40)];
    [button setTintColor:UIColor.whiteColor];
    [button setBackgroundColor:UIColor.blueColor];
    
    [button setTitle:@"Create Agent" forState:UIControlStateNormal];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(setAgent:) forControlEvents:UIControlEventTouchUpInside];
}

- (void) setAgent: (UIButton*)button {
    ConfigOptions *opts = ConfigNew();
    [opts setAgentURL:_urlToUse];
    [opts setUseLocalAgent:_useLocalAgent];
    [opts setWebsocketURL:_wsURLToUse];
    
    NSError *error = nil;
    
    _ariesAgent = (ApiAriesController*) AriesagentNew(opts, &error);
    if(error) {
        NSLog(@"error creating an aries agent: %@", error);
    } else {
        [_getCredentialsButton setBackgroundColor:UIColor.purpleColor];
        [_getCredentialsButton setEnabled:true];
    }
    
    // register handler
    MyHandler *handler = [[MyHandler alloc] init];
    NSString *regID = [_ariesAgent registerHandler:handler topics:@"didexchange_states"];
    NSLog(@"handler registration id: %@", regID);
    
    ApiDIDExchangeController *didex = (ApiDIDExchangeController*) [_ariesAgent getDIDExchangeController:&error];
    if(error) {
        NSLog(@"error creating a did exchange controller instance: %@", error);
    }

    NSString *credResp = @"";
    NSData *data = [_didExRecInvReq dataUsingEncoding:NSUTF8StringEncoding];
    
    ModelsRequestEnvelope *req = ModelsNewRequestEnvelope(data);
    ModelsResponseEnvelope *resp = [didex receiveInvitation:req];
    if(resp.error) {
        NSLog(@"error receiving invitation: %@", resp.error.message);
    }
    else {
        credResp = [[NSString alloc] initWithData:resp.payload encoding:NSUTF8StringEncoding];
        NSLog(@"receive invitation response: %@", credResp);
    }

    [_ariesNotificationsTextView setText:credResp];
}

- (NSString*) getCredentials: (ApiAriesController*) agent
                   withError: (NSError*) error {

    ApiVerifiableController *ic = (ApiVerifiableController*) [agent getVerifiableController:&error];
    if(error) {
        NSLog(@"error creating an verifiable controller instance: %@", error);
    }

    NSString *credResp = @"";
    NSData *data = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    
    ModelsRequestEnvelope *req = ModelsNewRequestEnvelope(data);
    ModelsResponseEnvelope *resp = [ic getCredentials:req];
    if(resp.error) {
        NSLog(@"error getting credentials: %@", resp.error.message);
    }
    else {
        credResp = [[NSString alloc] initWithData:resp.payload encoding:NSUTF8StringEncoding];
        NSLog(@"get credentials response: %@", credResp);
    }
    
    return credResp;
}

- (void) setCredentialsResponse: (UIButton*)button {
    NSError *error = nil;
    NSString *credResp = [self getCredentials:_ariesAgent withError:error];
    
    [_getCredentialsResponseTextView setText:credResp];
}

- (void) addGetCredentialsButton {
    _getCredentialsButton = [[UIButton alloc] init];
    [_getCredentialsButton setFrame:CGRectMake(90, 270, 200, 40)];
    [_getCredentialsButton setBackgroundColor:UIColor.grayColor];
    
    [_getCredentialsButton setTitle:@"Get Credentials" forState:UIControlStateNormal];
    [self.view addSubview:_getCredentialsButton];
    
    [_getCredentialsButton setEnabled:false];
    [_getCredentialsButton addTarget:self action:@selector(setCredentialsResponse:) forControlEvents:UIControlEventTouchUpInside];
}

- (void) addResponseLabel {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(100, 280, 250, 160)];
    [label setText:@"Retrieved Credentials: "];
    [self.view addSubview:label];
}

- (void) addGetCredentialsResponse {
    _getCredentialsResponseTextView = [[UITextView alloc]
                                       initWithFrame:CGRectMake(5, 380,
                                                                CGRectGetWidth(self.view.bounds), 60)];
    _getCredentialsResponseTextView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    _getCredentialsResponseTextView.editable = NO;
    [self.view addSubview:_getCredentialsResponseTextView];
}

- (void) addNotifLabel {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(100, 390, 250, 160)];
    [label setText:@"Mobile Notification Test: "];
    [self.view addSubview:label];
}

- (void)addDIDExchangeReceiveInvitationRequestTextField {
    _didExRecInvReqTextField = [[UITextField  alloc] initWithFrame:
    CGRectMake(50, 510, 280, 30)];

    _didExRecInvReqTextField.borderStyle = UITextBorderStyleRoundedRect;
    _didExRecInvReqTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [_didExRecInvReqTextField setFont:[UIFont boldSystemFontOfSize:12]];
    _didExRecInvReqTextField.leftViewMode = UITextFieldViewModeAlways;
    _didExRecInvReqTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    [_didExRecInvReqTextField setText:_didExRecInvReq];

    [self.view addSubview:_didExRecInvReqTextField];
    _didExRecInvReqTextField.delegate = self;

    [_didExRecInvReqTextField addTarget:self action:@selector(textChangedReceiveInvitation:) forControlEvents:UIControlEventEditingChanged];
}

- (void) textChangedReceiveInvitation: (UITextField*)textField {
    _didExRecInvReq = textField.text;
}

- (void) addNotificationsTextView {
    _ariesNotificationsTextView = [[UITextView alloc]
                                       initWithFrame:CGRectMake(5, 550,
                                                                CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
    _ariesNotificationsTextView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    _ariesNotificationsTextView.editable = NO;
    [self.view addSubview:_ariesNotificationsTextView];
}

@end
