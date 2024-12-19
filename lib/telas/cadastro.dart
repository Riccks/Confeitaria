import 'package:confeitaria/main.dart';
import 'package:confeitaria/telas/home.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  String _ddd = '';
  String _numeroTelefone = '';

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

  Future<void> _signUp() async {
    final firstname = _nameController.text.trim();
    final lastname = _lastnameController.text.trim();
    final cpf = _cpfController.text.trim();
    final cep = _cepController.text.trim();
    final houseNumber = _numberController.text.trim();

    try {
      final cpfExists = await supabase
          .from('profiles')
          .select('cpf')
          .eq('cpf', cpf)
          .maybeSingle();
      if (cpfExists != null) {
        showDialog(
          context: context,
          builder: (BuildContext) {
            return AlertDialog(
              title: const Text('Erro'),
              content: const Text("CPF já cadastrado."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                )
              ],
            );
          },
        );
        return;
      }

      final telefoneExists = await supabase
          .from('telephone')
          .select('number_telephone')
          .eq('number_telephone', _numeroTelefone)
          .maybeSingle();
      if (telefoneExists != null) {
        showDialog(
          context: context,
          builder: (BuildContext) {
            return AlertDialog(
              title: const Text('Erro'),
              content: const Text("Telefone já cadastrado."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                )
              ],
            );
          },
        );
        return;
      }

      final res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = res.user;
      final userId = user?.id;

      await supabase.from('profiles').upsert({
        'user_id': userId,
        'first_name': firstname,
        'last_name': lastname,
        'cpf': cpf,
      });

      final endereco = await buscarEndereco(cep);

      final homeResponse = await supabase
          .from('home')
          .insert({
            'user_id': userId,
            'cep_home': cep,
            'number_home': int.tryParse(houseNumber) ?? 0,
          })
          .select('id_home')
          .single();

      final homeId = homeResponse['id_home'];

      final addressResponse = await supabase
          .from('address')
          .insert({
            'id_home_fk': homeId,
            'street_address': endereco['street_address'],
            'neighborhood_address': endereco['neighborhood_address'],
            'city_address': endereco['city_address'],
            'state_address': endereco['state_address'],
            'country_address': endereco['country_address'],
          })
          .select('id_address')
          .single();

      if (addressResponse.isEmpty || addressResponse['id_address'] == null) {
        throw Exception("Erro ao salvar endereço: $addressResponse");
      }

      await supabase.from('telephone').insert({
        'user_id': userId,
        'ddd_telephone': _ddd,
        'number_telephone': _numeroTelefone,
      });
      showDialog(
        context: context,
        builder: (BuildContext) {
          return AlertDialog(
            title: const Text('Sucesso'),
            content: const Text("Cadastro realizado com sucesso."),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await supabase.auth.signInWithPassword(
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim(),
                  );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Homepage()),
                  );
                },
                child: const Text('OK'),
              )
            ],
          );
        },
      );

      // Limpar as variáveis após o cadastro
      _ddd = '';
      _numeroTelefone = '';

      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _lastnameController.clear();
      _cpfController.clear();
      _cepController.clear();
      _numberController.clear();

      if (!mounted) return;
    } on AuthApiException catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext) {
          return AlertDialog(
            title: const Text('Erro'),
            content: const Text(
                "Falha ao cadastrar. Verifique os dados e tente novamente."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              )
            ],
          );
        },
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext) {
          return AlertDialog(
            title: const Text('Erro'),
            content: const Text(
                'Ocorreu um erro inesperado. Tente novamente mais tarde.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              )
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(10),
            child: Text(
              "Cadastro",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFE0CFEC),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                prefixIcon: const Icon(Icons.person_outline),
                hintText: 'Nome',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _lastnameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFE0CFEC),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                prefixIcon: const Icon(Icons.person_outline),
                hintText: 'Sobrenome',
              ),
            ),
            const SizedBox(height: 10),
            IntlPhoneField(
              initialCountryCode: 'BR',
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFE0CFEC),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                hintText: '(XX) XXXXX-XXXX',
              ),
              onChanged: (phone) {
                String number = phone.number; // Número sem o código do país
                _ddd =
                    number.substring(0, 2); // Primeiros dois dígitos como DDD
                _numeroTelefone = number.substring(2); // Restante do número
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFE0CFEC),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                prefixIcon: const Icon(Icons.email_outlined),
                hintText: 'E-mail',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFE0CFEC),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                prefixIcon: const Icon(Icons.lock_outline),
                hintText: 'Senha',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _cpfController,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFE0CFEC),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                hintText: 'CPF',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: TextFormField(
                  controller: _cepController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFE0CFEC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20)),
                    hintText: 'CEP',
                  ),
                  textAlign: TextAlign.center,
                )),
                const SizedBox(width: 5),
                Expanded(
                    child: TextFormField(
                  controller: _numberController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFE0CFEC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20)),
                    hintText: 'Número',
                  ),
                  textAlign: TextAlign.center,
                ))
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _signUp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF65558F),
                foregroundColor: const Color(0xFFFFFFFF),
                padding:
                    const EdgeInsets.symmetric(horizontal: 120, vertical: 15),
              ),
              child: const Text('Cadastrar'),
            )
          ],
        ),
      ),
    );
  }
}
