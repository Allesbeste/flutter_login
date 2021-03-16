import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:transformer_page_view/transformer_page_view.dart';
import '../constants.dart';
import 'animated_button.dart';
import 'animated_text.dart';
import 'custom_page_transformer.dart';
import 'expandable_container.dart';
import 'fade_in.dart';
import 'animated_text_form_field.dart';
import '../providers/auth.dart';
import '../providers/login_messages.dart';
import '../models/login_data.dart';
import '../dart_helper.dart';
import '../matrix.dart';
import '../paddings.dart';
import '../widget_helper.dart';

class AuthCard extends StatefulWidget {
  AuthCard({
    Key key,
    this.padding = const EdgeInsets.all(0),
    this.loadingController,
    this.usernameValidator,
    this.emailValidator,
    this.passwordValidator,
    this.firstNameValidator,
    this.lastNameValidator,
    this.mobileValidator,
    this.onSubmit,
    this.onSubmitCompleted,
    this.onRequestOTPResend,
  }) : super(key: key);

  final EdgeInsets padding;
  final AnimationController loadingController;
  final FormFieldValidator<String> usernameValidator;
  final FormFieldValidator<String> emailValidator;
  final FormFieldValidator<String> passwordValidator;
  final FormFieldValidator<String> firstNameValidator;
  final FormFieldValidator<String> lastNameValidator;
  final FormFieldValidator<String> mobileValidator;
  final Function onSubmit;
  final Function onSubmitCompleted;
  final ResendOTPCallback onRequestOTPResend;

  @override
  AuthCardState createState() => AuthCardState();
}

class AuthCardState extends State<AuthCard> with TickerProviderStateMixin {
  GlobalKey _cardKey = GlobalKey();

  var _isLoadingFirstTime = true;
  var _pageIndex = 0;
  var _fromPageIndex = 0;
  static const cardSizeScaleEnd = .2;

  TransformerPageController _pageController;
  AnimationController _formLoadingController;
  AnimationController _routeTransitionController;
  Animation<double> _flipAnimation;
  Animation<double> _cardSizeAnimation;
  Animation<double> _cardSize2AnimationX;
  Animation<double> _cardSize2AnimationY;
  Animation<double> _cardRotationAnimation;
  Animation<double> _cardOverlayHeightFactorAnimation;
  Animation<double> _cardOverlaySizeAndOpacityAnimation;

  @override
  void initState() {
    super.initState();

    _pageController = TransformerPageController();

    widget.loadingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isLoadingFirstTime = false;
        _formLoadingController.forward();
      }
    });

    _flipAnimation = Tween<double>(begin: pi / 2, end: 0).animate(
      CurvedAnimation(
        parent: widget.loadingController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );

    _formLoadingController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1150),
      reverseDuration: Duration(milliseconds: 300),
    );

    _routeTransitionController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1100),
    );

    _cardSizeAnimation = Tween<double>(begin: 1.0, end: cardSizeScaleEnd)
        .animate(CurvedAnimation(
      parent: _routeTransitionController,
      curve: Interval(0, .27272727 /* ~300ms */, curve: Curves.easeInOutCirc),
    ));
    // replace 0 with minPositive to pass the test
    // https://github.com/flutter/flutter/issues/42527#issuecomment-575131275
    _cardOverlayHeightFactorAnimation =
        Tween<double>(begin: double.minPositive, end: 1.0).animate(CurvedAnimation(
      parent: _routeTransitionController,
      curve: Interval(.27272727, .5 /* ~250ms */, curve: Curves.linear),
    ));
    _cardOverlaySizeAndOpacityAnimation =
        Tween<double>(begin: 1.0, end: 0).animate(CurvedAnimation(
      parent: _routeTransitionController,
      curve: Interval(.5, .72727272 /* ~250ms */, curve: Curves.linear),
    ));
    _cardSize2AnimationX =
        Tween<double>(begin: 1, end: 1).animate(_routeTransitionController);
    _cardSize2AnimationY =
        Tween<double>(begin: 1, end: 1).animate(_routeTransitionController);
    _cardRotationAnimation =
        Tween<double>(begin: 0, end: pi / 2).animate(CurvedAnimation(
      parent: _routeTransitionController,
      curve: Interval(.72727272, 1 /* ~300ms */, curve: Curves.easeInOutCubic),
    ));
  }

  @override
  void dispose() {
    super.dispose();

    _formLoadingController.dispose();
    _pageController.dispose();
    _routeTransitionController.dispose();
  }

  void _switchRecovery(bool recovery) {
    final auth = Provider.of<Auth>(context, listen: false);

    auth.isRecover = recovery;
    if (recovery) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.ease,
      );
      _pageIndex = 1;
    } else {
      _pageController.previousPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.ease,
      );
      _pageIndex = 0;
    }
  }

  void _switchSignupConfirm(bool confirm, bool resendOTP) {
    final auth = Provider.of<Auth>(context, listen: false);

    auth.isSignupConfirm = confirm;
    if (confirm) {
      if (resendOTP) {
        widget.onRequestOTPResend(auth.username);
      }
      _fromPageIndex = _pageIndex;
      _pageController.animateToPage(
        2,
        duration: Duration(milliseconds: 500),
        curve: Curves.ease,
      );
      _pageIndex = 2;
    } else {
      _fromPageIndex = _pageIndex;
      _pageController.animateToPage(
        0,
        duration: Duration(milliseconds: 500),
        curve: Curves.ease,
      );
      _pageIndex = 0;
    }
  }

  Future<void> runLoadingAnimation() {
    if (widget.loadingController.isDismissed) {
      return widget.loadingController.forward().then((_) {
        if (!_isLoadingFirstTime) {
          _formLoadingController.forward();
        }
      });
    } else if (widget.loadingController.isCompleted) {
      return _formLoadingController
          .reverse()
          .then((_) => widget.loadingController.reverse());
    }
    return Future(null);
  }

  Future<void> _forwardChangeRouteAnimation() {
    final isLogin = Provider.of<Auth>(context, listen: false).isLogin;
    final deviceSize = MediaQuery.of(context).size;
    final cardSize = getWidgetSize(_cardKey);
    // add .25 to make sure the scaling will cover the whole screen
    final widthRatio =
        deviceSize.width / cardSize.height + (isLogin ? .25 : .65);
    final heightRatio = deviceSize.height / cardSize.width + .25;

    _cardSize2AnimationX =
        Tween<double>(begin: 1.0, end: heightRatio / cardSizeScaleEnd)
            .animate(CurvedAnimation(
      parent: _routeTransitionController,
      curve: Interval(.72727272, 1, curve: Curves.easeInOutCubic),
    ));
    _cardSize2AnimationY =
        Tween<double>(begin: 1.0, end: widthRatio / cardSizeScaleEnd)
            .animate(CurvedAnimation(
      parent: _routeTransitionController,
      curve: Interval(.72727272, 1, curve: Curves.easeInOutCubic),
    ));

    widget?.onSubmit();

    return _formLoadingController
        .reverse()
        .then((_) => _routeTransitionController.forward());
  }

  void _reverseChangeRouteAnimation() {
    _routeTransitionController
        .reverse()
        .then((_) => _formLoadingController.forward());
  }

  void runChangeRouteAnimation() {
    if (_routeTransitionController.isCompleted) {
      _reverseChangeRouteAnimation();
    } else if (_routeTransitionController.isDismissed) {
      _forwardChangeRouteAnimation();
    }
  }

  void runChangePageAnimation() {
    final auth = Provider.of<Auth>(context, listen: false);
    _switchRecovery(!auth.isRecover);
  }

  Widget _buildLoadingAnimator({Widget child, ThemeData theme}) {
    Widget card;
    Widget overlay;

    // loading at startup
    card = AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) => Transform(
        transform: Matrix.perspective()..rotateX(_flipAnimation.value),
        alignment: Alignment.center,
        child: child,
      ),
      child: child,
    );

    // change-route transition
    overlay = Padding(
      padding: theme.cardTheme.margin,
      child: AnimatedBuilder(
        animation: _cardOverlayHeightFactorAnimation,
        builder: (context, child) => ClipPath.shape(
          shape: theme.cardTheme.shape,
          child: FractionallySizedBox(
            heightFactor: _cardOverlayHeightFactorAnimation.value,
            alignment: Alignment.topCenter,
            child: child,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: theme.accentColor),
        ),
      ),
    );

    overlay = ScaleTransition(
      scale: _cardOverlaySizeAndOpacityAnimation,
      child: FadeTransition(
        opacity: _cardOverlaySizeAndOpacityAnimation,
        child: overlay,
      ),
    );

    return Stack(
      children: <Widget>[
        card,
        Positioned.fill(child: overlay),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceSize = MediaQuery.of(context).size;
    Widget current = Container(
      height: deviceSize.height,
      width: deviceSize.width,
      padding: widget.padding,
      child: TransformerPageView(
        physics: NeverScrollableScrollPhysics(),
        pageController: _pageController,
        itemCount: 3,

        /// Need to keep track of page index because soft keyboard will
        /// make page view rebuilt
        index: _pageIndex,
        transformer: CustomPageTransformer(),
        itemBuilder: (BuildContext context, int index) {
          Widget child;
          switch (index) {
            case 1: {
              if (_pageIndex == 1 || _fromPageIndex == 1) {
                child = _RecoverCard(
                    emailValidator: widget.emailValidator,
                    onSwitchLogin: () => _switchRecovery(false),
                  );
              }
            }
            break;

            case 2: {
              if (_pageIndex == 2 || _fromPageIndex == 2) {
                child = _ConfirmCard(
                  onSwitchSignup: () => _switchSignupConfirm(false, false),
                  onSignupSuccess: () {
                    final auth = Provider.of<Auth>(context, listen: false);
                    auth.mode = AuthMode.Login;
                    _switchSignupConfirm(false, false);
                  },
                  onRequestOTPResend: widget.onRequestOTPResend,
                );
              }
            }
            break;

            default: {
              if (_pageIndex == 0 || _fromPageIndex == 0) {
                child = _buildLoadingAnimator(
                    theme: theme,
                    child: _LoginCard(
                      key: _cardKey,
                      loadingController: _isLoadingFirstTime
                          ? _formLoadingController
                          : (_formLoadingController..value = 1.0),
                      usernameValidator: widget.usernameValidator,
                      emailValidator: widget.emailValidator,
                      passwordValidator: widget.passwordValidator,
                      firstNameValidator: widget.firstNameValidator,
                      lastNameValidator: widget.lastNameValidator,
                      mobileValidator: widget.mobileValidator,
                      onSwitchRecoveryPassword: () => _switchRecovery(true),
                      onConfirmSignup: (confirm, resend) => _switchSignupConfirm(confirm, resend),
                      onSubmitCompleted: () {
                        _forwardChangeRouteAnimation().then((_) {
                          widget?.onSubmitCompleted();
                        });
                      },
                    ),
                  );
              }
            }
            break;
          }
          // final child = (index == 0)
          //     ? _buildLoadingAnimator(
          //         theme: theme,
          //         child: _LoginCard(
          //           key: _cardKey,
          //           loadingController: _isLoadingFirstTime
          //               ? _formLoadingController
          //               : (_formLoadingController..value = 1.0),
          //           emailValidator: widget.emailValidator,
          //           passwordValidator: widget.passwordValidator,
          //           mobileValidator: widget.mobileValidator,
          //           onSwitchRecoveryPassword: () => _switchRecovery(true),
          //           onSubmitCompleted: () {
          //             _forwardChangeRouteAnimation().then((_) {
          //               widget?.onSubmitCompleted();
          //             });
          //           },
          //         ),
          //       )
          //     : _RecoverCard(
          //         emailValidator: widget.emailValidator,
          //         onSwitchLogin: () => _switchRecovery(false),
          //       );

          return Align(
            alignment: Alignment.topCenter,
            child: child,
          );
        },
      ),
    );

    return AnimatedBuilder(
      animation: _cardSize2AnimationX,
      builder: (context, snapshot) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateZ(_cardRotationAnimation.value)
            ..scale(_cardSizeAnimation.value, _cardSizeAnimation.value)
            ..scale(_cardSize2AnimationX.value, _cardSize2AnimationY.value),
          child: current,
        );
      },
    );
  }
}

class _LoginCard extends StatefulWidget {
  _LoginCard({
    Key key,
    this.loadingController,
    @required this.usernameValidator,
    @required this.emailValidator,
    @required this.passwordValidator,
    @required this.firstNameValidator,
    @required this.lastNameValidator,
    @required this.mobileValidator,
    @required this.onSwitchRecoveryPassword,
    @required this.onConfirmSignup,
    this.onSwitchAuth,
    this.onSubmitCompleted,
  }) : super(key: key);

  final AnimationController loadingController;
  final FormFieldValidator<String> usernameValidator;
  final FormFieldValidator<String> emailValidator;
  final FormFieldValidator<String> passwordValidator;
  final FormFieldValidator<String> firstNameValidator;
  final FormFieldValidator<String> lastNameValidator;
  final FormFieldValidator<String> mobileValidator;
  final Function onSwitchRecoveryPassword;
  final Function onSwitchAuth;
  final Function onSubmitCompleted;
  final Function onConfirmSignup;

  @override
  _LoginCardState createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey();

  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _firstnameFocusNode = FocusNode();
  final _lastnameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _mobileFocusNode = FocusNode();
  final _confirmationFocusNode = FocusNode();

  TextEditingController _nameController;
  TextEditingController _passController;
  TextEditingController _confirmPassController;
  TextEditingController _firstnameController;
  TextEditingController _lastnameController;
  TextEditingController _emailController;
  TextEditingController _mobileController;
  TextEditingController _confirmationController;

  var _isLoading = false;
  var _isSubmitting = false;
  var _showShadow = true;

  /// switch between login and signup
  AnimationController _loadingController;
  AnimationController _switchAuthController;
  AnimationController _postSwitchAuthController;
  // AnimationController _signupConfirmController;
  AnimationController _submitController;

  Interval _nameTextFieldLoadingAnimationInterval;
  Interval _passTextFieldLoadingAnimationInterval;
  Interval _textButtonLoadingAnimationInterval;
  Animation<double> _buttonScaleAnimation;

  bool get buttonEnabled => !_isLoading && !_isSubmitting;

  @override
  void initState() {
    super.initState();

    final auth = Provider.of<Auth>(context, listen: false);
    _nameController = TextEditingController(text: auth.username);
    _passController = TextEditingController(text: auth.password);
    _confirmPassController = TextEditingController(text: auth.confirmPassword);
    _firstnameController = TextEditingController(text: auth.firstName);
    _lastnameController = TextEditingController(text: auth.lastName);
    _emailController = TextEditingController(text: auth.email);
    _mobileController = TextEditingController(text: auth.mobile);

    _loadingController = widget.loadingController ??
        (AnimationController(
          vsync: this,
          duration: Duration(milliseconds: 1150),
          reverseDuration: Duration(milliseconds: 300),
        )..value = 1.0);

    _loadingController?.addStatusListener(handleLoadingAnimationStatus);

    _switchAuthController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _postSwitchAuthController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    // _signupConfirmController = AnimationController(
    //   vsync: this,
    //   duration: Duration(milliseconds: 800),
    // );
    _submitController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _nameTextFieldLoadingAnimationInterval = const Interval(0, .85);
    _passTextFieldLoadingAnimationInterval = const Interval(.15, 1.0);
    _textButtonLoadingAnimationInterval =
        const Interval(.6, 1.0, curve: Curves.easeOut);
    _buttonScaleAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Interval(.4, 1.0, curve: Curves.easeOutBack),
    ));
  }

  void handleLoadingAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      setState(() => _isLoading = true);
    }
    if (status == AnimationStatus.completed) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _loadingController?.removeStatusListener(handleLoadingAnimationStatus);
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _emailFocusNode.dispose();
    _mobileFocusNode.dispose();
    _confirmationFocusNode.dispose();

    _switchAuthController.dispose();
    _postSwitchAuthController.dispose();
    // _signupConfirmController.dispose();
    _submitController.dispose();

    super.dispose();
  }

  void _switchAuthMode() {
    final auth = Provider.of<Auth>(context, listen: false);
    final newAuthMode = auth.switchAuth();

    if (newAuthMode == AuthMode.Signup) {
      _switchAuthController.forward();
    } else {
      _switchAuthController.reverse();
    }
  }

  Future<bool> _submit() async {
    // a hack to force unfocus the soft keyboard. If not, after change-route
    // animation completes, it will trigger rebuilding this widget and show all
    // textfields and buttons again before going to new route
    FocusScope.of(context).requestFocus(FocusNode());

    if (!_formKey.currentState.validate()) {
      return false;
    }

    _formKey.currentState.save();
    _submitController.forward();
    setState(() => _isSubmitting = true);
    final auth = Provider.of<Auth>(context, listen: false);
    String error;

    if (auth.isLogin) {
      error = await auth.onLogin(LoginData(
        name: auth.username,
        password: auth.password,
      ));
    } else {
      error = await auth.onSignup(SignupData(
        name: auth.username,
        password: auth.password,
        firstName: auth.firstName,
        lastName: auth.lastName,
        email: auth.email,
        mobile: auth.mobile,
      ));
    }
    // } else {
    //   error = await auth.onSignupConfirm(SignupConfirmData(
    //     name: auth.username,
    //     confirmationString: auth.confirmationString,
    //   ));
    // }

    // workaround to run after _cardSizeAnimation in parent finished
    // need a cleaner way but currently it works so..
    // Future.delayed(const Duration(milliseconds: 270), () {
    //   setState(() => _showShadow = false);
    // });

    _submitController.reverse();

    if (!DartHelper.isNullOrEmpty(error)) {
      if (error == 'CONFIRM') {
        // auth.mode = AuthMode.SignupConfirm;
        widget.onConfirmSignup(true, false);
        return true;
      } else if (error == "RECONFIRM") {
        widget.onConfirmSignup(true, true);
        return true;
      }
      final messages = Provider.of<LoginMessages>(context, listen: false);
      showErrorToast(context, messages.errorToastTitle, error);
      Future.delayed(const Duration(milliseconds: 271), () {
        setState(() => _showShadow = true);
      });
      setState(() => _isSubmitting = false);
      return false;
    }

    widget?.onSubmitCompleted();

    return true;
  }

  Widget _buildNameField(double width, LoginMessages messages, Auth auth) {
    return AnimatedTextFormField(
      controller: _nameController,
      width: width,
      loadingController: _loadingController,
      interval: _nameTextFieldLoadingAnimationInterval,
      labelText: messages.usernameHint,
      prefixIcon: Icon(FontAwesomeIcons.solidUserCircle),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (value) {
        FocusScope.of(context).requestFocus(_passwordFocusNode);
      },
      validator: widget.usernameValidator,
      onSaved: (value) => auth.username = value,
    );
  }

  Widget _buildPasswordField(double width, LoginMessages messages, Auth auth) {
    return AnimatedPasswordTextFormField(
      animatedWidth: width,
      loadingController: _loadingController,
      interval: _passTextFieldLoadingAnimationInterval,
      labelText: messages.passwordHint,
      controller: _passController,
      textInputAction:
          auth.isLogin ? TextInputAction.done : TextInputAction.next,
      focusNode: _passwordFocusNode,
      onFieldSubmitted: (value) {
        if (auth.isLogin) {
          _submit();
        } else {
          // SignUp
          FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
        }
      },
      validator: widget.passwordValidator,
      onSaved: (value) => auth.password = value,
    );
  }

  Widget _buildConfirmPasswordField(double width, LoginMessages messages, Auth auth) {
    return AnimatedPasswordTextFormField(
      animatedWidth: width,
      enabled: auth.isSignup,
      loadingController: _loadingController,
      inertiaController: _postSwitchAuthController,
      inertiaDirection: TextFieldInertiaDirection.right,
      labelText: messages.confirmPasswordHint,
      controller: _confirmPassController,
      textInputAction: TextInputAction.next,
      focusNode: _confirmPasswordFocusNode,
      // onFieldSubmitted: (value) => _submit(),
      onFieldSubmitted: (value) {
        FocusScope.of(context).requestFocus(_firstnameFocusNode);
      },
      validator: auth.isSignup
          ? (value) {
              if (value != _passController.text) {
                return messages.confirmPasswordError;
              }
              return null;
            }
          : (value) => null,
      onSaved: (value) => auth.confirmPassword = value,
    );
  }

  Widget _buildFirstnameField(double width, LoginMessages messages, Auth auth) {
    return AnimatedTextFormField(
      controller: _firstnameController,
      width: width,
      enabled: auth.isSignup,
      loadingController: _loadingController,
      inertiaController: _postSwitchAuthController,
      inertiaDirection: TextFieldInertiaDirection.right,
      // interval: _nameTextFieldLoadingAnimationInterval,
      labelText: messages.firstnameHint,
      prefixIcon: Icon(FontAwesomeIcons.solidUserCircle),
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      focusNode: _firstnameFocusNode,
      onFieldSubmitted: (value) {
        FocusScope.of(context).requestFocus(_lastnameFocusNode);
      },
      validator: auth.isSignup
          ? widget.firstNameValidator
          : null,
      onSaved: (value) => auth.firstName = value,
    );
  }

  Widget _buildLastnameField(double width, LoginMessages messages, Auth auth) {
    return AnimatedTextFormField(
      controller: _lastnameController,
      width: width,
      enabled: auth.isSignup,
      loadingController: _loadingController,
      inertiaController: _postSwitchAuthController,
      inertiaDirection: TextFieldInertiaDirection.right,
      // interval: _nameTextFieldLoadingAnimationInterval,
      labelText: messages.lastnameHint,
      prefixIcon: Icon(FontAwesomeIcons.solidUserCircle),
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      focusNode: _lastnameFocusNode,
      onFieldSubmitted: (value) {
        FocusScope.of(context).requestFocus(_emailFocusNode);
      },
      validator: auth.isSignup
          ? widget.lastNameValidator
          : null,
      onSaved: (value) => auth.lastName = value,
    );
  }

  Widget _buildEmailField(double width, LoginMessages messages, Auth auth) {
    return AnimatedTextFormField(
      controller: _emailController,
      width: width,
      enabled: auth.isSignup,
      loadingController: _loadingController,
      inertiaController: _postSwitchAuthController,
      inertiaDirection: TextFieldInertiaDirection.right,
      // interval: _nameTextFieldLoadingAnimationInterval,
      labelText: messages.emailHint,
      prefixIcon: Icon(FontAwesomeIcons.at),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      focusNode: _emailFocusNode,
      onFieldSubmitted: (value) {
        FocusScope.of(context).requestFocus(_mobileFocusNode);
      },
      validator: auth.isSignup
          ? widget.emailValidator
          : null,
      onSaved: (value) => auth.email = value,
    );
  }

  Widget _buildMobileField(double width, LoginMessages messages, Auth auth) {
    return AnimatedTextFormField(
      controller: _mobileController,
      width: width,
      enabled: auth.isSignup,
      loadingController: _loadingController,
      inertiaController: _postSwitchAuthController,
      inertiaDirection: TextFieldInertiaDirection.right,
      // interval: _nameTextFieldLoadingAnimationInterval,
      labelText: messages.mobileHint,
      prefixIcon: Icon(FontAwesomeIcons.mobileAlt),
      prefixText: '+27',
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      focusNode: _mobileFocusNode,
      onFieldSubmitted: (value) => _submit(),
      validator: auth.isSignup
          ? widget.mobileValidator
          : null,
      onSaved: (value) => auth.mobile = value,
    );
  }

  Widget _buildSignupConfirmField(double width, LoginMessages messages, Auth auth) {
    return AnimatedTextFormField(
      controller: _mobileController,
      width: width,
      enabled: auth.isSignupConfirm,
      loadingController: _loadingController,
      inertiaController: _postSwitchAuthController,
      inertiaDirection: TextFieldInertiaDirection.right,
      // interval: _nameTextFieldLoadingAnimationInterval,
      labelText: messages.confirmSignupHint,
      prefixIcon: Icon(FontAwesomeIcons.mobileAlt),
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      focusNode: _confirmationFocusNode,
      onFieldSubmitted: (value) => _submit(),
      // validator: widget.mobileValidator,
      onSaved: (value) => auth.confirmationString = value,
    );
  }

  // Widget _buildForgotPassword(ThemeData theme, LoginMessages messages) {
  //   return FadeIn(
  //     controller: _loadingController,
  //     fadeDirection: FadeDirection.bottomToTop,
  //     offset: .5,
  //     curve: _textButtonLoadingAnimationInterval,
  //     child: FlatButton(
  //       child: Text(
  //         messages.forgotPasswordButton,
  //         style: theme.textTheme.body1,
  //         textAlign: TextAlign.left,
  //       ),
  //       onPressed: buttonEnabled ? () {
  //         // save state to populate email field on recovery card
  //         _formKey.currentState.save();
  //         widget.onSwitchRecoveryPassword();
  //       } : null,
  //     ),
  //   );
  // }

  Widget _buildSubmitButton(ThemeData theme, LoginMessages messages, Auth auth) {
    return ScaleTransition(
      scale: _buttonScaleAnimation,
      child: AnimatedButton(
        controller: _submitController,
        text: auth.isLogin ? messages.loginButton : messages.signupButton,
        onPressed: _submit,
      ),
    );
  }

  Widget _buildSwitchAuthButton(ThemeData theme, LoginMessages messages, Auth auth) {
    return FadeIn(
      controller: _loadingController,
      offset: .5,
      curve: _textButtonLoadingAnimationInterval,
      fadeDirection: FadeDirection.topToBottom,
      child: FlatButton(
        child: AnimatedText(
          text: auth.isSignup ? messages.loginButton : messages.signupButton,
          textRotation: AnimatedTextRotation.down,
        ),
        disabledTextColor: theme.primaryColor,
        onPressed: buttonEnabled ? _switchAuthMode : null,
        padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textColor: theme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: true);
    final isLogin = auth.isLogin;
    final messages = Provider.of<LoginMessages>(context, listen: false);
    final theme = Theme.of(context);
    final deviceSize = MediaQuery.of(context).size;
    final cardWidth = min(deviceSize.width * 0.75, 360.0);
    const cardPadding = 16.0;
    final textFieldWidth = cardWidth - cardPadding * 2;
    final authForm = Form(
      key: _formKey,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              left: cardPadding,
              right: cardPadding,
              top: cardPadding + 10,
            ),
            width: cardWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildNameField(textFieldWidth, messages, auth),
                SizedBox(height: 20),
                _buildPasswordField(textFieldWidth, messages, auth),
                SizedBox(height: 10),
              ],
            ),
          ),
          // ExpandableContainer(
          //   backgroundColor: theme.accentColor,
          //   controller: _signupConfirmController,
          //   initialState: (!auth.isSignupConfirm)
          //       ? ExpandableContainerState.shrunk
          //       : ExpandableContainerState.expanded,
          //   alignment: Alignment.topLeft,
          //   color: theme.cardTheme.color,
          //   width: cardWidth,
          //   padding: EdgeInsets.symmetric(
          //     horizontal: cardPadding,
          //     vertical: 10,
          //   ),
          //   onExpandCompleted: () => _postSwitchAuthController.forward(),
          //   child: Column(
          //     children: [
          //       _buildSignupConfirmField(textFieldWidth, messages, auth),
          //       SizedBox(height: 10),
          //     ],
          //   )
          // ),
          ExpandableContainer(
            backgroundColor: theme.accentColor,
            controller: _switchAuthController,
            initialState: isLogin
                ? ExpandableContainerState.shrunk
                : ExpandableContainerState.expanded,
            alignment: Alignment.topLeft,
            color: theme.cardTheme.color,
            width: cardWidth,
            padding: EdgeInsets.symmetric(
              horizontal: cardPadding,
              vertical: 10,
            ),
            onExpandCompleted: () => _postSwitchAuthController.forward(),
            child: Column(
              children: [
                _buildConfirmPasswordField(textFieldWidth, messages, auth),
                SizedBox(height: 20),
                _buildFirstnameField(textFieldWidth, messages, auth),
                SizedBox(height: 20),
                _buildLastnameField(textFieldWidth, messages, auth),
                SizedBox(height: 20),
                _buildEmailField(textFieldWidth, messages, auth),
                SizedBox(height: 20),
                _buildMobileField(textFieldWidth, messages, auth),
                SizedBox(height: 10),
              ],
            )
          ),
          Container(
            padding: Paddings.fromRBL(cardPadding),
            width: cardWidth,
            child: Column(
              children: <Widget>[
                // _buildForgotPassword(theme, messages),
                _buildSubmitButton(theme, messages, auth),
                _buildSwitchAuthButton(theme, messages, auth),
              ],
            ),
          ),
        ],
      ),
    );

    return FittedBox(
      child: Card(
        elevation: _showShadow ? theme.cardTheme.elevation : 0,
        child: authForm,
      ),
    );
  }
}

class _RecoverCard extends StatefulWidget {
  _RecoverCard({
    Key key,
    @required this.emailValidator,
    @required this.onSwitchLogin,
  }) : super(key: key);

  final FormFieldValidator<String> emailValidator;
  final Function onSwitchLogin;

  @override
  _RecoverCardState createState() => _RecoverCardState();
}

class _RecoverCardState extends State<_RecoverCard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formRecoverKey = GlobalKey();

  TextEditingController _nameController;

  var _isSubmitting = false;

  AnimationController _submitController;

  @override
  void initState() {
    super.initState();

    final auth = Provider.of<Auth>(context, listen: false);
    _nameController = new TextEditingController(text: auth.email);

    _submitController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _submitController.dispose();
  }

  Future<bool> _submit() async {
    if (!_formRecoverKey.currentState.validate()) {
      return false;
    }
    final auth = Provider.of<Auth>(context, listen: false);
    final messages = Provider.of<LoginMessages>(context, listen: false);

    _formRecoverKey.currentState.save();
    _submitController.forward();
    setState(() => _isSubmitting = true);
    final error = await auth.onRecoverPassword(auth.email);

    if (error != null) {
      showErrorToast(context, messages.errorToastTitle, error);
      setState(() => _isSubmitting = false);
      _submitController.reverse();
      return false;
    } else {
      showSuccessToast(context, messages.successToastTitle, messages.recoverPasswordSuccess);
      setState(() => _isSubmitting = false);
      _submitController.reverse();
      return true;
    }
  }

  Widget _buildRecoverNameField(double width, LoginMessages messages, Auth auth) {
    return AnimatedTextFormField(
      controller: _nameController,
      width: width,
      labelText: messages.usernameHint,
      prefixIcon: Icon(FontAwesomeIcons.solidUserCircle),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (value) => _submit(),
      validator: widget.emailValidator,
      onSaved: (value) => auth.email = value,
    );
  }

  Widget _buildRecoverButton(ThemeData theme, LoginMessages messages) {
    return AnimatedButton(
      controller: _submitController,
      text: messages.recoverPasswordButton,
      onPressed: !_isSubmitting ? _submit : null,
    );
  }

  Widget _buildBackButton(ThemeData theme, LoginMessages messages) {
    return FlatButton(
      child: Text(messages.goBackButton),
      onPressed: !_isSubmitting ? () {
        _formRecoverKey.currentState.save();
        widget.onSwitchLogin();
      } : null,
      padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textColor: theme.primaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<Auth>(context, listen: false);
    final messages = Provider.of<LoginMessages>(context, listen: false);
    final deviceSize = MediaQuery.of(context).size;
    final cardWidth = min(deviceSize.width * 0.75, 360.0);
    const cardPadding = 16.0;
    final textFieldWidth = cardWidth - cardPadding * 2;

    return FittedBox(
      // width: cardWidth,
      child: Card(
        child: Container(
          padding: const EdgeInsets.only(
            left: cardPadding,
            top: cardPadding + 10.0,
            right: cardPadding,
            bottom: cardPadding,
          ),
          width: cardWidth,
          alignment: Alignment.center,
          child: Form(
            key: _formRecoverKey,
            child: Column(
              children: [
                Text(
                  messages.recoverPasswordIntro,
                  key: kRecoverPasswordIntroKey,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.body1,
                ),
                SizedBox(height: 20),
                _buildRecoverNameField(textFieldWidth, messages, auth),
                SizedBox(height: 20),
                Text(
                  messages.recoverPasswordDescription,
                  key: kRecoverPasswordDescriptionKey,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.body1,
                ),
                SizedBox(height: 26),
                _buildRecoverButton(theme, messages),
                _buildBackButton(theme, messages),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmCard extends StatefulWidget {
  _ConfirmCard({
    Key key,
    @required this.onSwitchSignup,
    @required this.onSignupSuccess,
    this.onRequestOTPResend,
  }) : super(key: key);

  final Function onSwitchSignup;
  final Function onSignupSuccess;
  final ResendOTPCallback onRequestOTPResend;

  @override
  _ConfirmCardState createState() => _ConfirmCardState();
}

class _ConfirmCardState extends State<_ConfirmCard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formSignupKey = GlobalKey();

  // TextEditingController _confirmController;

  var _isSubmitting = false;

  AnimationController _submitController;

  @override
  void initState() {
    super.initState();

    // final auth = Provider.of<Auth>(context, listen: false);
    // _confirmController = new TextEditingController(text: auth.email);

    _submitController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _submitController.dispose();
  }

  Future<bool> _submit() async {
    // if (!_formSignupKey.currentState.validate()) {
    //   return false;
    // }
    final auth = Provider.of<Auth>(context, listen: false);
    final messages = Provider.of<LoginMessages>(context, listen: false);

    _formSignupKey.currentState.save();
    _submitController.forward();
    setState(() => _isSubmitting = true);
    final error = await auth.onSignupConfirm(SignupConfirmData(
      confirmationString: auth.confirmationString,
      name: auth.username,
    ));

    if (error != null) {
      showErrorToast(context, messages.errorToastTitle, error);
      setState(() => _isSubmitting = false);
      _submitController.reverse();
      return false;
    } else {
      showSuccessToast(context, messages.successToastTitle, messages.signupSuccess);
      setState(() => _isSubmitting = false);
      _submitController.reverse();
      widget?.onSignupSuccess();
      return true;
    }
  }

  Widget _buildConfirmCodeField(double width, LoginMessages messages, Auth auth) {
    return AnimatedTextFormField(
      // controller: _confirmController,
      width: width,
      labelText: messages.confirmSignupHint,
      prefixIcon: Icon(FontAwesomeIcons.mobileAlt),
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (value) => _submit(),
      // validator: widget.emailValidator,
      onSaved: (value) => auth.confirmationString = value,
    );
  }

  Widget _buildVerifyButton(ThemeData theme, LoginMessages messages) {
    return AnimatedButton(
      controller: _submitController,
      text: messages.confirmSignupButton,
      onPressed: !_isSubmitting ? _submit : null,
    );
  }

  Widget _buildBackButton(ThemeData theme, LoginMessages messages) {
    return FlatButton(
      child: Text(messages.confirmSignupBackButton),
      onPressed: !_isSubmitting ? () {
        // _formSignupKey.currentState.save();
        widget.onSwitchSignup();
      } : null,
      padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textColor: theme.primaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<Auth>(context, listen: false);
    final messages = Provider.of<LoginMessages>(context, listen: false);
    final deviceSize = MediaQuery.of(context).size;
    final cardWidth = min(deviceSize.width * 0.75, 360.0);
    const cardPadding = 16.0;
    final textFieldWidth = cardWidth - cardPadding * 2;

    return FittedBox(
      // width: cardWidth,
      child: Card(
        child: Container(
          padding: const EdgeInsets.only(
            left: cardPadding,
            top: cardPadding + 10.0,
            right: cardPadding,
            bottom: cardPadding,
          ),
          width: cardWidth,
          alignment: Alignment.center,
          child: Form(
            key: _formSignupKey,
            child: Column(
              children: [
                Text(
                  messages.confirmSignupIntro,
                  key: kConfirmSignupIntroKey,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.body1,
                ),
                SizedBox(height: 20),
                _buildConfirmCodeField(textFieldWidth, messages, auth),
                SizedBox(height: 20),
                Text(
                  messages.confirmSignupDescription,
                  key: kConfirmSignupDescriptionKey,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.body1,
                ),
                SizedBox(height: 26),
                _buildVerifyButton(theme, messages),
                _buildBackButton(theme, messages),
              ],
            ),
          ),
        ),
      ),
    );
  }
}