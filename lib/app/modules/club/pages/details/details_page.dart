import 'package:asuka/asuka.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../shared/constants.dart';
import '../../../../shared/model/club/club_model.dart';
import '../../../../shared/widgets/card_menu.dart';
import 'details_controller.dart';

class DetailsPage extends StatefulWidget {
  final ClubModel club;
  const DetailsPage({super.key, required this.club});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final controller = Modular.get<DetailsController>();
  late TextTheme textTheme = Theme.of(context).textTheme;
  @override
  Widget build(BuildContext context) {
    textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.club.name),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: informationClub,
            icon: const Icon(Icons.info),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(5.0),
        children: [
          menu,
        ],
      ),
      backgroundColor: Colors.grey[100],

      /*Observer(
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
      ),*/
    );
  }

  /*Widget get informacoesClub => Card(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              titleCard,
              const SizedBox(
                height: 10,
              ),
              _tiles(label: "Diretor(a)", text: "Diana Margarido"),
              const Divider(),
              _tiles(label: "Líder 01", text: "Bianca Margarido"),
              const Divider(),
              _tiles(label: "Líder 02", text: "Célia Belém"),
              const Divider(),
              _tiles(label: "Líder 03", text: "Lene Vermelho"),
              const Divider(),
              _tiles(label: "Líder 04", text: "Suzana Martins"),
            ],
          ),
        ),
      );*/

  informationClub() {
    Asuka.showModalBottomSheet(builder: (BuildContext context) {
      return SafeArea(
          child: ListView(
        padding: const EdgeInsets.all(10.0),
        shrinkWrap: true,
        children: [
          titleCard,
          const SizedBox(
            height: 10,
          ),
          _tiles(label: "Diretor(a)", text: "Diana Margarido"),
          const Divider(),
          _tiles(label: "Líder 01", text: "Bianca Margarido"),
          const Divider(),
          _tiles(label: "Líder 02", text: "Célia Belém"),
          const Divider(),
          _tiles(label: "Líder 03", text: "Lene Vermelho"),
          const Divider(),
          _tiles(label: "Líder 04", text: "Suzana Martins"),
        ],
      ));
    });
  }

  Widget get titleCard => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text('Informações do Clube', style: textTheme.headlineSmall),
        ),
      );

  Widget _tiles({required String label, required String text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }

  Widget get menu => Container(
      width: MediaQuery.of(context).size.width,
      alignment: Alignment.center,
      child: Wrap(
        direction: Axis.horizontal,
        children: const <Widget>[
          CardMenuWidget(
            icone: FontAwesomeIcons.calendarWeek,
            label: "PONTUAÇÃO SEMANAL",
            route: "$routeClub/",
          ),
          CardMenuWidget(
            icone: FontAwesomeIcons.book,
            label: "PONTUAÇÃO INDIVIDUAL",
            route: "$routeUser/",
          ),
          CardMenuWidget(
            icone: FontAwesomeIcons.userGroup,
            label: "OANSISTAS",
            route: "$routeUser/",
          ),
          CardMenuWidget(
            icone: FontAwesomeIcons.userNinja,
            label: "LÍDERES",
            route: "$routeUser/",
          ),
        ],
      ));
}
