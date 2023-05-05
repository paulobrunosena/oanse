import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../shared/constants.dart';
import '../../shared/model/leadership/leadership_model.dart';
import '../../shared/widgets/custom_icon_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import 'login_controller.dart';

class LoginPage extends StatefulWidget {
  final String title;
  const LoginPage({Key? key, this.title = "Login"}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final controller = Modular.get<LoginController>();
  final _key = GlobalKey<ScaffoldMessengerState>();
  final LeadershipModel _data =
      LeadershipModel(id: 0, name: "", userName: "", password: "");
  late Image logo;
  late DecorationImage decorationImage;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() {
    logo = Image.asset(
      "images/awana.png",
      width: 200,
      //height: 100,
      fit: BoxFit.contain,
    );

    decorationImage = const DecorationImage(
      image: AssetImage('images/login_bg.jpg'),
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        backgroundImage,
        Scaffold(
            backgroundColor: Colors.transparent,
            key: _key,
            body: GestureDetector(
              onTap: () => hideKeyboard(context),
              child: CustomScrollView(
                slivers: [
                  SliverList(
                      delegate: SliverChildListDelegate([
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const SizedBox(
                          height: 80,
                        ),
                        logoOanse,
                        const SizedBox(
                          height: 80,
                        ),
                        camposLogin,
                      ],
                    )
                  ]))
                ],
              ),
            )),
      ],
    );
  }

  Widget get backgroundImage => ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.black, Colors.black12],
          begin: Alignment.bottomCenter,
          end: Alignment.center,
        ).createShader(bounds),
        blendMode: BlendMode.darken,
        child: Container(
          decoration: BoxDecoration(
            image: decorationImage,
          ),
        ),
      );

  Widget get logoOanse => Container(
        padding: const EdgeInsets.only(left: 50, right: 50),
        height: 150,
        child: logo,
      );

  Widget get camposLogin => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Form(
          key: controller.formController.key,
          child: Column(
            children: <Widget>[
              userName,
              const SizedBox(
                height: 20,
              ),
              senha,
              const SizedBox(
                height: 20,
              ),
              botaoAcessar,
              const SizedBox(
                height: 20,
              ),
              botaoCadastrese,
            ],
          ),
        ),
      );
  Widget get userName => CustomTextField(
        hint: 'Username',
        prefix: const Icon(Icons.email),
        textInputType: TextInputType.emailAddress,
        onSaved: (value) => _data.userName = value ?? "",
        onChanged: controller.setUserName,
        textInputAction: TextInputAction.next,
      );

  Widget get senha => Observer(
        builder: (_) {
          return CustomTextField(
            hint: 'Senha',
            prefix: const Icon(Icons.lock),
            obscure: !controller.senhaVisible,
            onSaved: (value) => _data.password = value ?? "",
            onChanged: controller.setSenha,
            suffix: CustomIconButton(
              radius: 32,
              iconData: controller.senhaVisible
                  ? Icons.visibility_off
                  : Icons.visibility,
              onTap: controller.toggleSenhaVisibility,
            ),
            textInputAction: TextInputAction.go,
            onFieldSubmitted: (value) async {
              await controller.login();
            },
          );
        },
      );

  Widget get botaoAcessar => Row(
        children: <Widget>[
          Expanded(
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50.0),
                  ),
                ),
                onPressed: () async {
                  hideKeyboard(context);
                  await controller.login();
                },
                child: const Text(
                  'ACESSAR',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          )
        ],
      );

  Widget get botaoCadastrese => TextButton(
      onPressed: () {
        Modular.to.pushNamed('$routeUser/add');
      },
      child: const Text("CADASTRE-SE", style: TextStyle(color: Colors.white)));

  void hideKeyboard(BuildContext context) {
    var currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }
}
