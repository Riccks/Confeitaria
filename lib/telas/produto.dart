import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'carrinho.dart';

class Produto extends StatefulWidget {
  final int id;
  const Produto({super.key, required this.id});

  @override
  State<Produto> createState() => _ProdutoState();
}

class _ProdutoState extends State<Produto> {
  late Future<Map<String, dynamic>> _futureProduct;
  int quantidade = 1;

  @override
  void initState() {
    super.initState();
    _futureProduct = Supabase.instance.client
        .from('product')
        .select()
        .eq('id_product', widget.id)
        .single();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>>(
          future: _futureProduct,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data!['name_product']);
            } else {
              return const Text('Carregando...');
            }
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureProduct,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final productData = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.network(productData['image_product']),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      productData['desc_product'],
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        const Text('Quantidade:'),
                        const SizedBox(width: 8.0),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (quantidade > 1) {
                              setState(() {
                                quantidade--;
                              });
                            }
                          },
                        ),
                        Text('$quantidade'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              quantidade++;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () {
                        CarrinhoManager.adicionarItem(
                            snapshot.data!, quantidade);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Produto adicionado ao carrinho!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE0CFEC),
                          foregroundColor: const Color(0xFF65558F),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 95, vertical: 15)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_shopping_cart),
                          SizedBox(width: 8),
                          Text('Adicionar ao carrinho'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
