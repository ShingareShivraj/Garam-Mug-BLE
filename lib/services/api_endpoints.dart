class ApiEndpoints {
  static const baseUrl = 'https://garamug.erpkey.in';
  static const loginMethod = 'login';
  static const currentUserMethod = 'frappe.auth.get_logged_user';

  static const _mugModule = 'garmug.garam_mug.mug_registration';
  static const listMugsMethod = '$_mugModule.get_my_registered_mugs';
  static const registerMugMethod = '$_mugModule.register_garam_mug';
  static const unregisterMugMethod = '$_mugModule.unregister_garam_mug';

  static Uri get signupUrl =>
      Uri.parse(baseUrl).resolve('/login#signup');

  static Uri get forgotPasswordUrl =>
      Uri.parse(baseUrl).resolve('/login#forgot');

  static Uri method(String name) =>
      Uri.parse(baseUrl).resolve('/api/method/$name');
}
