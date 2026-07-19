abstract class CustomRegex {
  static const nameRegex = r'^[a-zA-Z\s]+$';
  static RegExp passwordRegex = RegExp(r'^(?=.*?[a-z])(?=.*?[0-9]).{8,}$');
}
