import 'package:flutter/material.dart';

class LoginMessages with ChangeNotifier {
  LoginMessages({
    this.usernameHint: defaultUsernameHint,
    this.passwordHint: defaultPasswordHint,
    this.confirmPasswordHint: defaultConfirmPasswordHint,    
    this.forgotPasswordButton: defaultForgotPasswordButton,
    this.emailHint: defaultEmailHint,
    this.mobileHint: defaultMobileHint,
    this.confirmSignupHint: defaultSignupConfirmHint,
    this.loginButton: defaultLoginButton,
    this.signupButton: defaultSignupButton,
    this.confirmSignupButton: defaultConfirmSignupButton,
    this.confirmSignupIntro: defaultConfirmSignupIntro,
    this.confirmSignupDescription: defaultConfirmSignupDescription,
    this.confirmSignupRetryButton: defaultConfirmSignupRetryButton,
    this.signupSuccess: defaultSignupSuccess,
    this.recoverPasswordButton: defaultRecoverPasswordButton,
    this.recoverPasswordIntro: defaultRecoverPasswordIntro,
    this.recoverPasswordDescription: defaultRecoverPasswordDescription,
    this.goBackButton: defaultGoBackButton,
    this.confirmPasswordError: defaultConfirmPasswordError,
    this.recoverPasswordSuccess: defaultRecoverPasswordSuccess,
    this.successToastTitle: defaultSuccessToastTitle,
    this.errorToastTitle: defaultErrorToastTitle,
  });

  static const defaultUsernameHint = 'Username';
  static const defaultPasswordHint = 'Password';
  static const defaultConfirmPasswordHint = 'Confirm Password';
  static const defaultForgotPasswordButton = 'Forgot Password?';
  static const defaultEmailHint = 'Email';
  static const defaultMobileHint = 'Mobile';
  static const defaultSignupConfirmHint = 'OTP';
  static const defaultLoginButton = 'LOGIN';
  static const defaultSignupButton = 'SIGNUP';
  static const defaultConfirmSignupButton = 'VERIFY';
  static const defaultConfirmSignupIntro = 'Enter your verification code here';
  static const defaultConfirmSignupDescription =
      'You will receive a verification code via SMS within a minute or two on the contact number provided during signup.';
  static const defaultConfirmSignupRetryButton = 'RETRY';
  static const defaultSignupSuccess = 'You can now login.';
  static const defaultRecoverPasswordButton = 'RECOVER';
  static const defaultRecoverPasswordIntro = 'Reset your password here';
  static const defaultRecoverPasswordDescription =
      'We will send your plain-text password to this email account.';
  static const defaultGoBackButton = 'BACK';
  static const defaultConfirmPasswordError = 'Password do not match!';
  static const defaultRecoverPasswordSuccess = 'An email has been sent';
  static const defaultSuccessToastTitle = 'Success';
  static const defaultErrorToastTitle = 'Error';

  /// Hint text of the user name [TextField]
  final String usernameHint;

  /// Hint text of the password [TextField]
  final String passwordHint;

  /// Hint text of the confirm password [TextField]
  final String confirmPasswordHint;

  /// Hint text of the email [TextField]
  final String emailHint;

  /// Hint text of the mobile [TextField]
  final String mobileHint;

  /// Hint text of the signup confirmation [TextField]
  final String confirmSignupHint;

  /// Forgot password button's label
  final String forgotPasswordButton;

  /// Login button's label
  final String loginButton;

  /// Signup button's label
  final String signupButton;

  /// Signup confirmation code dialog button's label
  final String confirmSignupButton;

  /// Intro in signup confirmation form
  final String confirmSignupIntro;

  /// Description in signup confirmation form
  final String confirmSignupDescription;

  /// Signup confirmation retry button's label. Retry button is used to go back to to
  /// signup form from the signup confirmation form
  final String confirmSignupRetryButton;

  /// The success message to show after signing up
  final String signupSuccess;

  /// Recover password button's label
  final String recoverPasswordButton;

  /// Intro in password recovery form
  final String recoverPasswordIntro;

  /// Description in password recovery form
  final String recoverPasswordDescription;

  /// Go back button's label. Go back button is used to go back to to
  /// login/signup form from the recover password form
  final String goBackButton;

  /// The error message to show when the confirm password not match with the
  /// original password
  final String confirmPasswordError;

  /// The success message to show after submitting recover password
  final String recoverPasswordSuccess;

  /// The title of the error toast
  final String successToastTitle;

  /// The title of the error toast
  final String errorToastTitle;
}
