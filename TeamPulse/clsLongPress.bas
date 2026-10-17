B4A=true
B4i=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=12.80
@EndOfDesignText@
' iOS long-press that raises the same Page_LongClick the Android view already uses.
Sub Class_Globals
	Private callback As Object
	Private eventName As String
	Private host As Panel
End Sub

Public Sub Initialize(pnl As Panel, cb As Object, ev As String)
	callback = cb
	eventName = ev
	host = pnl
#if B4i
	Dim no As NativeObject = Me
	no.RunMethod("installOnView:", Array(pnl))
#End If
End Sub

Public Sub HostPanel As Panel
	Return host
End Sub

' Raised from the inline gesture recognizer. The compiler does not see that call.
#IgnoreWarnings: 12
#if B4i
Private Sub LongPress
	modUI.NoteLongPress(Me)
	modUI.RaiseLongClick(callback, eventName)
End Sub
#End If

#if OBJC
- (void)installOnView:(UIView*)view {
	UILongPressGestureRecognizer *gr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLong:)];
	gr.minimumPressDuration = 0.45;
	gr.cancelsTouchesInView = NO;
	[view addGestureRecognizer:gr];
}
- (void)handleLong:(UILongPressGestureRecognizer*)gr {
	UIScrollView *scroll = nil;
	UIView *parent = gr.view.superview;
	while (parent != nil) {
		if ([parent isKindOfClass:[UIScrollView class]]) {
			scroll = (UIScrollView*)parent;
			break;
		}
		parent = parent.superview;
	}
	if (gr.state == UIGestureRecognizerStateBegan) {
		if (scroll != nil) scroll.scrollEnabled = NO;
		[B4IObjectWrapper raiseEvent:self :@"_longpress" :nil];
	} else if (gr.state == UIGestureRecognizerStateEnded || gr.state == UIGestureRecognizerStateCancelled || gr.state == UIGestureRecognizerStateFailed) {
		if (scroll != nil) scroll.scrollEnabled = YES;
	}
}
#End If
