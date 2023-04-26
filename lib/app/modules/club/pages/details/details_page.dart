import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../shared/model/club/club_model.dart';
import 'details_controller.dart';

class DetailsPage extends StatefulWidget {
  final ClubModel club;
  const DetailsPage({super.key, required this.club});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final controller = Modular.get<DetailsController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.club.name),
      ),
      body: Observer(
        builder: (_) {
          if (controller.meetings.isEmpty) {
            return const Center(
              child: Text("Não existem reuniões cadastradas"),
            );
          }

          return ListView.separated(
              separatorBuilder: (context, index) => const Divider(),
              itemCount: controller.meetings.length,
              itemBuilder: (context, int index) {
                return ListTile(
                  title: Text(controller.meetings[index].dataFormatada),
                );
              });
        },
      ),
    );
  }
}
