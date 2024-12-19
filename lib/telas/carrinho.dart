import 'package:flutter/material.dart';
import 'package:confeitaria/main.dart';

class CarrinhoManager {
  static final List<Map<String, dynamic>> itens = [];

  static void adicionarItem(Map<String, dynamic> produto, int quantidade) {
    itens.add({'produto': produto, 'quantidade': quantidade});
  }

  static double get total {
    double total = 0.0;
    for (var item in itens) {
      total +=
          (item['produto']['price_product'] ?? 0.0) * (item['quantidade'] ?? 1);
    }
    return total;
  }
}

class Carrinho extends StatefulWidget {
  const Carrinho({super.key});

  @override
  State<Carrinho> createState() => _CarrinhoState();
}

class _CarrinhoState extends State<Carrinho> {
  double total = 0.0;

  void removerItem(int index) {
    setState(() {
      CarrinhoManager.itens.removeAt(index);
    });
  }

  void finalizarCompra() async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Você precisa estar logado para finalizar a compra.')),
      );
      return;
    }

    final response = await supabase
        .from('orders')
        .insert({
          'user_id': userId,
          'date_order': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    final idOrders = response['id_order'];

    for (var item in CarrinhoManager.itens) {
      await supabase.from('orders_has_product').insert({
        'id_order': idOrders,
        'id_product': item['produto']['id_product'],
        'qty_product': item['quantidade'],
      });
    }

    setState(() {
      CarrinhoManager.itens.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compra finalizada com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CarrinhoManager.itens.isEmpty
            ? const Center(
                child: Text('O carrinho está vazio'),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: CarrinhoManager.itens.length,
                      itemBuilder: (context, index) {
                        final item = CarrinhoManager.itens[index];
                        return Card(
                          child: ListTile(
                            leading:
                                Image.network(item['produto']['image_product']),
                            title: Text(item['produto']['name_product']),
                            subtitle: Text(
                                'Preço: R\$ ${item['produto']['price_product']} x ${item['quantidade']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                removerItem(index);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Text(
                      'Total: R\$ ${CarrinhoManager.total.toStringAsFixed(2)}'),
                  ElevatedButton(
                    onPressed: finalizarCompra,
                    child: const Text('Finalizar Compra'),
                  ),
                ],
              ),
      ),
    );
  }
}
