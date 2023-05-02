import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

import '../../../shared/model/leadership/leadership_model.dart';
import '../../../shared/model/score_item/score_item_model.dart';
import 'store/score_model_store.dart';
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
          scoreItems,
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
                pontuacaoTotal,
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

  Widget get pontuacaoTotal => Observer(
        builder: (_) {
          var formatter = NumberFormat('###,###,###');
          String totalScore = formatter.format(controller.totalScore);
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
                    "Pontuação total",
                    style: textTheme.bodySmall?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    "$totalScore pontos",
                    style: textTheme.titleSmall?.copyWith(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(
                width: 10,
              ),
            ],
          );
        },
      );

  Widget get scoreItems => Observer(builder: (_) {
        return Expanded(
            child: ListView.separated(
          shrinkWrap: true,
          itemCount: controller.scoreItems.length,
          itemBuilder: (_, index) {
            ScoreItemModel scoreItem = controller.scoreItems[index];
            ScoreModelStore scoreStore = controller.scoresStore[index];

            return Observer(builder: (_) {
              var formatter = NumberFormat('###,###,###');
              String points = formatter.format(scoreItem.points!);
              return ListTile(
                title: Text(scoreItem.name!),
                subtitle: scoreStore.quantity > 0
                    ? Text("$points pontos")
                    : const Text("Não marcou ponto"),
                trailing: action(index),
              );
            });
          },
          separatorBuilder: (_, __) {
            return const Divider();
          },
        ));
      });

  Widget action(int index) {
    ScoreItemModel scoreItem = controller.scoreItems[index];

    return (scoreItem.name!.contains("Visitante") ||
            scoreItem.name!.contains("Seção") ||
            scoreItem.name!.contains("Atividade"))
        ? amount(index)
        : switchScore(index);
  }

  Widget switchScore(int index) {
    ScoreItemModel scoreItem = controller.scoreItems[index];
    ScoreModelStore scoreStore = controller.scoresStore[index];
    return Switch(
      onChanged: (bool value) {
        scoreStore.setQuantity(value ? 1 : 0);
        if (value) {
          controller.incrementTotalScore(scoreItem.points!);
        } else {
          controller.decrementTotalScore(scoreItem.points!);
        }
      },
      value: scoreStore.quantity > 0,
    );
  }

  Widget amount(int index) {
    ScoreItemModel scoreItem = controller.scoreItems[index];
    ScoreModelStore scoreStore = controller.scoresStore[index];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        scoreStore.quantity != 0
            ? IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  scoreStore.setQuantity(scoreStore.quantity - 1);
                  controller.decrementTotalScore(scoreItem.points!);
                },
              )
            : Container(),
        Text(scoreStore.quantity.toString()),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            scoreStore.setQuantity(scoreStore.quantity + 1);
            controller.incrementTotalScore((scoreItem.points!));
          },
        )
      ],
    );
  }

  Widget get positionGames => DropdownButton<String>(
        value: _btn1SelectedVal,
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() => _btn1SelectedVal = newValue);
          }
        },
        items: _dropDownMenuItems,
      );
}
