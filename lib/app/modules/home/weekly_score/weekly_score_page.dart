import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../shared/model/leadership/leadership_model.dart';
import '../../../shared/model/score/score_model.dart';
import '../../../shared/model/score_item/score_item_model.dart';

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
  int? positionGames;

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
                divider,
                oansist,
                divider,
                totalScore,
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

  Widget get totalScore => Observer(
        builder: (_) {
          return Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sports_score_rounded,
                  color: Colors.grey,
                ),
                const SizedBox(
                  width: 10,
                ),
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
                      "${controller.totalScore} pontos",
                      style: textTheme.titleSmall?.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

  Widget get scoreItems => Observer(builder: (_) {
        return controller.showScoreItems
            ? Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: controller.scoreItems.length,
                  itemBuilder: (_, index) {
                    ScoreItemModel scoreItem = controller.scoreItems[index];
                    ScoreModel score = controller.scores[index];

                    return Observer(builder: (_) {
                      if (scoreItem.isSport) {
                        return RadioListTile<int>(
                          title: Text(scoreItem.name!),
                          subtitle: score.quantity > 0
                              ? Text("${scoreItem.pointsFormatter} pontos")
                              : const Text("Não marcou ponto"),
                          groupValue: positionGames,
                          value: index,
                          onChanged: (value) {
                            if (positionGames == null) {
                              score.setQuantity(1);
                              controller.incrementTotalScore(scoreItem.points!);
                            } else {
                              var scoreItemBefore =
                                  controller.scoreItems[positionGames!];
                              var scoreStoreBefore =
                                  controller.scores[positionGames!];
                              scoreStoreBefore.setQuantity(0);
                              controller
                                  .decrementTotalScore(scoreItemBefore.points!);
                              score.setQuantity(1);
                              controller.incrementTotalScore(scoreItem.points!);
                            }
                            positionGames = value;
                          },
                          controlAffinity: ListTileControlAffinity.trailing,
                        );
                      } else {
                        return ListTile(
                          title: Text(scoreItem.name!),
                          subtitle: score.quantity > 0
                              ? Text("${scoreItem.pointsFormatter} pontos")
                              : const Text("Não marcou ponto"),
                          trailing: action(index),
                        );
                      }
                    });
                  },
                  separatorBuilder: (_, __) {
                    return const Divider(
                      height: 0,
                    );
                  },
                ),
              )
            : Container();
      });

  Widget action(int index) {
    ScoreItemModel scoreItem = controller.scoreItems[index];

    return (scoreItem.isSwitchScore) ? switchScore(index) : amount(index);
  }

  Widget switchScore(int index) {
    ScoreItemModel scoreItem = controller.scoreItems[index];
    ScoreModel score = controller.scores[index];
    return Switch(
      onChanged: (bool value) {
        score.setQuantity(value ? 1 : 0);
        if (value) {
          controller.incrementTotalScore(scoreItem.points!);
        } else {
          controller.decrementTotalScore(scoreItem.points!);
        }
      },
      value: score.quantity > 0,
    );
  }

  Widget amount(int index) {
    ScoreItemModel scoreItem = controller.scoreItems[index];
    ScoreModel scoreStore = controller.scores[index];
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

  Widget get loading => Container(
        alignment: Alignment.center,
        width: 20,
        height: 20,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
  Widget get divider => const Divider(
        indent: 10,
        endIndent: 10,
        height: 0,
      );
}
