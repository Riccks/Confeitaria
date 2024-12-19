import 'package:confeitaria/main.dart';
import 'package:confeitaria/telas/login.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Conta extends StatefulWidget {
  const Conta({super.key});

  @override
  State<Conta> createState() => _ContaState();
}

class _ContaState extends State<Conta> {
  String? firtName;
  String? lastName;
  String? email;
  String? cep;
  String? telefone;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserMetadata();
  }

  Future<void> _loadUserMetadata() async {
    final user = supabase.auth.currentUser;

    if (user != null) {
      final userId = user.id;

      final profileResponse = await supabase
          .from('profiles')
          .select('first_name, last_name')
          .eq('user_id', userId)
          .single();

      final homeResponse = await supabase
          .from('home')
          .select('cep_home')
          .eq('user_id', userId)
          .single();

      final telephoneResponse = await supabase
          .from('telephone')
          .select('ddd_telephone, number_telephone')
          .eq('user_id', userId)
          .single();

      setState(() {
        firtName = profileResponse['first_name'];
        lastName = profileResponse['last_name'];
        email = user.email;
        cep = homeResponse['cep_home'];
        final ddd = telephoneResponse['ddd_telephone'] ?? '';
        final numero = telephoneResponse['number_telephone'] ?? '';
        telefone = '($ddd) $numero';
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    try {
      await supabase.functions.invoke('delete_user');
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TelaLogin()),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao deletar a conta: $error')),
      );
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text(
              'Tem certeza que deseja excluir sua conta? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteAccount();
    }
  }

  Future<void> _editarCampo(String campo, String? valorAtual) async {
    final TextEditingController _controller =
        TextEditingController(text: valorAtual);
    print(_controller.text.trim());
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar $campo'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: 'Digite seu $campo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final novoValor = _controller.text.trim();
                if (novoValor.isNotEmpty) {
                  final user = supabase.auth.currentUser;
                  String campoBD = '';
                  if (campo == 'Nome') campoBD = 'first_name';
                  if (campo == 'Sobrenome') campoBD = 'last_name';

                  await supabase.from('profiles').update({
                    campoBD: novoValor,
                  }).eq('user_id', user!.id);
                  setState(() {
                    if (campo == 'Nome') firtName = novoValor;
                    if (campo == 'Sobrenome') lastName = novoValor;
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editarCEP() async {
    final TextEditingController _controller = TextEditingController(text: cep);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar CEP'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Digite seu CEP'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final novoCEP = _controller.text.trim();
                if (novoCEP.isNotEmpty) {
                  try {
                    final endereco = await buscarEndereco(novoCEP);
                    await supabase.from('home').update({
                      'cep_home': novoCEP,
                    }).eq('user_id', supabase.auth.currentUser!.id);

                    final homeResponse = await supabase
                        .from('home')
                        .select('id_home')
                        .eq('user_id', supabase.auth.currentUser!.id)
                        .single();

                    final homeId = homeResponse['id_home'];

                    await supabase.from('address').update({
                      'street_address': endereco['street_address'],
                      'neighborhood_address': endereco['neighborhood_address'],
                      'city_address': endereco['city_address'],
                      'state_address': endereco['state_address'],
                      'country_address': endereco['country_address'],
                    }).eq('id_home_fk', homeId);

                    setState(() {
                      cep = novoCEP;
                    });
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Erro ao atualizar o CEP: $error')),
                    );
                  }
                }
                Navigator.of(context).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editarTelefone() async {
    final TextEditingController _controller =
        TextEditingController(text: telefone);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Telefone'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Digite seu Telefone'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final novoTelefone = _controller.text.trim();
                if (novoTelefone.isNotEmpty) {
                  try {
                    String ddd = '';
                    String numero = '';
                    if (novoTelefone.startsWith('(')) {
                      ddd = novoTelefone.substring(1, 3);
                      numero = novoTelefone.substring(5).replaceAll('-', '');
                    }

                    await supabase.from('telephone').update({
                      'ddd_telephone': ddd,
                      'number_telephone': numero,
                    }).eq('user_id', supabase.auth.currentUser!.id);

                    setState(() {
                      telefone = novoTelefone;
                    });
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Erro ao atualizar o Telefone: $error')),
                    );
                  }
                }
                Navigator.of(context).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, String>> buscarEndereco(String cep) async {
    final url = Uri.parse('https://viacep.com.br/ws/$cep/json/');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data.containsKey('erro') && data['erro'] == true) {
        throw Exception('CEP não encontrado.');
      }

      return {
        'street_address': data['logradouro'] ?? '',
        'neighborhood_address': data['bairro'] ?? '',
        'city_address': data['localidade'] ?? '',
        'state_address': data['uf'] ?? '',
        'country_address': 'Brasil',
      };
    } else {
      throw Exception('Erro ao buscar endereço: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                title: const Text('Nome'),
                subtitle: Text(firtName ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editarCampo('Nome', firtName),
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Sobrenome'),
                subtitle: Text(lastName ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editarCampo('Sobrenome', lastName),
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('CEP'),
                subtitle: Text(cep ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editarCEP,
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Telefone'),
                subtitle: Text(telefone ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editarTelefone,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _confirmDeleteAccount,
              child: const Text('Excluir Conta'),
            ),
          ],
        ),
      ),
    );
  }
}
