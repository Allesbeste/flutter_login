class Regex {
  // https://stackoverflow.com/a/32686261/9449426
  static final email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  // https://ihateregex.io/expr/phone/
  static final mobile = RegExp(r'^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$');
  // static final mobile = RegExp(r'^[\+]?27[1-9]{9}$');
}
