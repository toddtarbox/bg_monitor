import 'package:bg_monitor/secrets.dart';
import 'package:bg_monitor/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amazon_cognito_identity_dart/cognito.dart';

class UserService {
  bool _initialized = false;

  CognitoUserPool _userPool;
  CognitoUser _cognitoUser;
  CognitoUserSession _session;
  CognitoCredentials credentials;

  static final UserService _singleton = new UserService._internal();

  factory UserService() {
    return _singleton;
  }

  UserService._internal();

  /// Initiate user session from local storage if present
  Future<bool> init() async {
    if (!_initialized) {
      _initialized = true;

      final secrets =
          await SecretLoader(secretPath: 'assets/secrets.json').load();
      final prefs = await SharedPreferences.getInstance();
      final storage = new Storage(prefs);

      _userPool =
          new CognitoUserPool(secrets.awsUserPoolId, secrets.awsClientId);

      _userPool.storage = storage;

      credentials = new CognitoCredentials(secrets.identityPoolId, _userPool);

      _cognitoUser = await _userPool.getCurrentUser();
      if (_cognitoUser == null) {
        return false;
      }
      _session = await _cognitoUser.getSession();
    }
    return _session.isValid();
  }

  /// Get existing user with his/her attributes
  Future<User> getCurrentUser() async {
    await init();

    if (_cognitoUser == null) {
      return null;
    }
    final attributes = await _cognitoUser.getUserAttributes();
    if (attributes == null) {
      return null;
    }
    final user = new User.fromUserAttributes(attributes);
    user.hasAccess = _session != null;
    return user;
  }

  /// Retrieve user credentials -- for use with other AWS services
  Future<CognitoCredentials> getCredentials() async {
    await init();

    if (_cognitoUser == null || _session == null) {
      return null;
    }
    await credentials.getAwsCredentials(_session.getIdToken().getJwtToken());
    return credentials;
  }

  /// Login user
  Future<User> login(String email, String password) async {
    _cognitoUser =
        new CognitoUser(email, _userPool, storage: _userPool.storage);

    final authDetails = new AuthenticationDetails(
      username: email,
      password: password,
    );

    bool isConfirmed;
    try {
      _session = await _cognitoUser.authenticateUser(authDetails);
      isConfirmed = true;
    } on CognitoClientException catch (e) {
      if (e.code == 'UserNotConfirmedException') {
        isConfirmed = false;
      } else {
        throw e;
      }
    }

    if (!_session.isValid()) {
      return null;
    }

    final attributes = await _cognitoUser.getUserAttributes();
    final user = new User.fromUserAttributes(attributes);
    user.confirmed = isConfirmed;
    user.hasAccess = true;

    return user;
  }

  /// Confirm user's account with confirmation code sent to email
  Future<bool> confirmAccount(String email, String confirmationCode) async {
    _cognitoUser =
        new CognitoUser(email, _userPool, storage: _userPool.storage);

    return await _cognitoUser.confirmRegistration(confirmationCode);
  }

  /// Resend confirmation code to user's email
  Future<void> resendConfirmationCode(String email) async {
    _cognitoUser =
        new CognitoUser(email, _userPool, storage: _userPool.storage);
    await _cognitoUser.resendConfirmationCode();
  }

  /// Check if user's current session is valid
  Future<bool> checkAuthenticated() async {
    await init();

    if (_cognitoUser == null || _session == null) {
      return false;
    }
    return _session.isValid();
  }

  /// Sign up new user
  Future<User> signUp(String email, String password, String name) async {
    CognitoUserPoolData data;
    final userAttributes = [
      new AttributeArg(name: 'name', value: name),
    ];
    data =
        await _userPool.signUp(email, password, userAttributes: userAttributes);

    final user = new User();
    user.email = email;
    user.name = name;
    user.confirmed = data.userConfirmed;

    return user;
  }

  Future<void> signOut() async {
    if (credentials != null) {
      await credentials.resetAwsCredentials();
    }
    if (_cognitoUser != null) {
      return _cognitoUser.signOut();
    }
  }

  Future<void> forgotPassword(String email) async {
    _cognitoUser = new CognitoUser(email, _userPool, storage: _userPool.storage);
    await _cognitoUser.forgotPassword();
  }

  Future<bool> confirmPassword(String email, String verificationCode, String newPassword) async {
    _cognitoUser = new CognitoUser(email, _userPool, storage: _userPool.storage);
    return await _cognitoUser.confirmPassword(verificationCode, newPassword);
  }
}
