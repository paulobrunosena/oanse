import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesUtils {
  static Future<void> salvarDados(
      {required String nome, required String cpf}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("logado", true);
    prefs.setString("nome", nome);
    prefs.setString("cpf", cpf);
  }

  static Future<bool> removerDados() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("logado");
    prefs.remove("nome");
    prefs.remove("cpf");
    return true;
  }

  static read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static save(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  static remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }
}
