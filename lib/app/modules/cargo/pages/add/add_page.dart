import 'package:flutter/material.dart';

class AddPage extends StatefulWidget {
  final String title;
  const AddPage({Key? key, this.title = 'AddPage'}) : super(key: key);
  @override
  AddPageState createState() => AddPageState();
}

class AddPageState extends State<AddPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Form(
            child: Column(
          children: [
            TextFormField(
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                filled: true,
                icon: Icon(Icons.person),
                hintText: 'Informe o nome do cargo',
                labelText: 'Nome *',
              ),
              onSaved: (String? value) {
                //this._name = value;
                //print('name=$_name');
              },
              //validator: _validateName,
            ),
            const SizedBox(height: 24.0),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nome',
                suffixStyle: TextStyle(color: Colors.green),
              ),
            ),
            const SizedBox(height: 24.0),
            TextFormField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Breve descrição sobre o cargo',
                helperText:
                    'Pode ser uma descrição das possíveis responsabilidades do cargo.',
                labelText: 'Descrição',
              ),
              maxLines: 3,
            ),
          ],
        )),
      ),
    );
  }
}
