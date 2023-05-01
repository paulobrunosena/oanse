import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../shared/model/leadership/leadership_model.dart';
import 'weekly_score_controller.dart';

class WeeklyScorePage extends StatefulWidget {
  final String title;
  final LeadershipModel leadership;
  const WeeklyScorePage(
      {super.key, required this.leadership, this.title = "Pontuação Semanal"});

  @override
  State<WeeklyScorePage> createState() => _WeeklyScorePageState();
}

class _WeeklyScorePageState extends State<WeeklyScorePage> {
  final controller = Modular.get<WeeklyScoreController>();
  late TextTheme textTheme = Theme.of(context).textTheme;
  late TextStyle? labelStyle;
  late TextStyle? textStyle;
  bool _switchUniforme = true;
  int _itemCount = 0;
  static const menuItems = <String>[
    'Não participou',
    '1º lugar',
    '2º lugar',
    '3º lugar',
    '4º lugar',
  ];

  String _btn1SelectedVal = 'Não participou';

  final List<DropdownMenuItem<String>> _dropDownMenuItems = menuItems
      .map(
        (String value) => DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        ),
      )
      .toList();

  @override
  void initState() {
    super.initState();
    controller.initWidgets(widget.leadership);
  }

  @override
  Widget build(BuildContext context) {
    textTheme = Theme.of(context).textTheme;
    labelStyle = textTheme.bodySmall?.copyWith(fontSize: 14);
    textStyle = textTheme.titleSmall?.copyWith(fontSize: 16);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.title),
            Text(
              widget.leadership.name,
              style: const TextStyle(fontSize: 16, color: Colors.white60),
            )
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: controller.save,
            icon: const Icon(Icons.save),
          )
        ],
      ),
      body: Column(
        children: [
          filter,
          scores,
        ],
      ),
      backgroundColor: Colors.grey[100],
    );
  }

  Widget get loading => Container(
        alignment: Alignment.center,
        width: 20,
        height: 20,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );

  Widget get filter => Padding(
        padding: const EdgeInsets.all(5.0),
        child: Card(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                meeting,
                const Divider(
                  indent: 10,
                  endIndent: 10,
                  height: 0,
                ),
                oansist,
                const Divider(
                  indent: 10,
                  endIndent: 10,
                  height: 0,
                ),
                Observer(builder: (_) {
                  return _tilesPontuacaoTotal(
                      label: "Pontuação total",
                      text: "${controller.totalScore} pontos");
                }),
              ],
            ),
          ),
        ),
      );

  Widget get meeting => Observer(builder: (_) {
        return ListTile(
          dense: true,
          title: Text(
            "Data da reunião",
            style: labelStyle,
          ),
          subtitle: Text(
            controller.selectMeeting != null
                ? controller.selectMeeting!.dataFormatada
                : "Selecione uma data",
            style: textStyle,
          ),
          trailing: controller.loadingWidgets
              ? loading
              : const Icon(
                  Icons.edit,
                  color: Colors.grey,
                ),
          onTap: controller.showMeetings,
        );
      });

  Widget get oansist => Observer(builder: (_) {
        return ListTile(
          dense: true,
          title: Text(
            "Oansista",
            style: labelStyle,
          ),
          subtitle: Text(
            controller.selectOansist != null
                ? controller.selectOansist!.name ?? ""
                : "Selecione um oansista",
            style: textStyle,
          ),
          trailing: controller.loadingWidgets
              ? loading
              : const Icon(
                  Icons.edit,
                  color: Colors.grey,
                ),
          onTap: controller.showOansists,
        );
      });

  Widget _tilesPontuacaoTotal({required String label, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.sports_score_rounded,
              color: Colors.grey,
            )),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(fontSize: 14),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              text,
              style: textTheme.titleSmall?.copyWith(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(
          width: 10,
        ),
      ],
    );
  }

  Widget get scores => Expanded(
          child: ListView(
        padding: const EdgeInsets.all(5.0),
        children: [
          Card(
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListTile(
                  title: const Text("Uniforme"),
                  subtitle: _switchUniforme
                      ? const Text("5.000 pontos")
                      : const Text("Não marcou ponto"),
                  trailing: Switch(
                    onChanged: (bool value) {
                      setState(() => _switchUniforme = value);
                    },
                    value: _switchUniforme,
                  ),
                ),
                const Divider(height: 0),
                ListTile(
                  title: const Text("Manual"),
                  subtitle: _switchUniforme
                      ? const Text("20.000 pontos")
                      : const Text("Não marcou ponto"),
                  trailing: Switch(
                    onChanged: (bool value) {
                      setState(() => _switchUniforme = value);
                    },
                    value: _switchUniforme,
                  ),
                ),
                const Divider(height: 0),
                ListTile(
                  title: const Text("Conduta + contagem até 5"),
                  subtitle: _switchUniforme
                      ? const Text("10.000 pontos")
                      : const Text("Não marcou ponto"),
                  trailing: Switch(
                    onChanged: (bool value) {
                      setState(() => _switchUniforme = value);
                    },
                    value: _switchUniforme,
                  ),
                ),
                const Divider(height: 0),
                ListTile(
                  title: const Text("Bíblia"),
                  subtitle: _switchUniforme
                      ? const Text("5.000 pontos")
                      : const Text("Não marcou ponto"),
                  trailing: Switch(
                    onChanged: (bool value) {
                      setState(() => _switchUniforme = value);
                    },
                    value: _switchUniforme,
                  ),
                ),
                const Divider(height: 0),
                ListTile(
                  title: const Text("Leitura bíblica"),
                  subtitle: _switchUniforme
                      ? const Text("20.000 pontos")
                      : const Text("Não marcou ponto"),
                  trailing: Switch(
                    onChanged: (bool value) {
                      setState(() => _switchUniforme = value);
                    },
                    value: _switchUniforme,
                  ),
                ),
                const Divider(height: 0),
                ListTile(
                  title: const Text("EBD"),
                  subtitle: _switchUniforme
                      ? const Text("5.000 pontos")
                      : const Text("Não marcou ponto"),
                  trailing: Switch(
                    onChanged: (bool value) {
                      setState(() => _switchUniforme = value);
                    },
                    value: _switchUniforme,
                  ),
                ),
                const Divider(height: 0),
                ListTile(
                  title: const Text("Visitante"),
                  subtitle: _itemCount != 0
                      ? const Text("10.000 pontos")
                      : const Text("Não marcou ponto"),
                  trailing: amount,
                ),
                const Divider(height: 0),
                ListTile(
                  title: const Text("Seção sem ajuda"),
                  subtitle: _itemCount != 0
                      ? const Text("20.000 pontos")
                      : const Text("Não marcou ponto"),
                  trailing: amount,
                ),
                const Divider(height: 0),
                ListTile(
                  title: const Text("Seção com ajuda"),
                  subtitle: _itemCount != 0
                      ? const Text("10.000 pontos")
                      : const Text("Não marcou ponto"),
                  trailing: amount,
                ),
                const Divider(height: 0),
                ListTile(
                  title: const Text("Atividade extra"),
                  subtitle: _itemCount != 0
                      ? const Text("15.000 pontos")
                      : const Text("Não marcou ponto"),
                  trailing: amount,
                ),
                const Divider(height: 0),
                ListTile(
                  title: const Text("Colocação no jogos"),
                  subtitle: _btn1SelectedVal != "Não participou"
                      ? const Text("15.000 pontos")
                      : const Text("Não marcou ponto"),
                  trailing: positionGames,
                ),
              ],
            ),
          ),
        ],
      ));

  Widget get amount => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _itemCount != 0
              ? IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => setState(() => _itemCount--),
                )
              : Container(),
          Text(_itemCount.toString()),
          IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => setState(() => _itemCount++))
        ],
      );

  Widget get positionGames => DropdownButton<String>(
        // Must be one of items.value.
        value: _btn1SelectedVal,
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() => _btn1SelectedVal = newValue);
          }
        },
        items: _dropDownMenuItems,
      );
}
