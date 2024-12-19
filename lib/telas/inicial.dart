import 'package:confeitaria/main.dart';
import 'package:confeitaria/telas/produto.dart';
import 'package:flutter/material.dart';

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  final TextEditingController _searchController = TextEditingController();
  late Future<dynamic> _futureProducts;

  @override
  void initState() {
    super.initState();
    _getProducts();
    _searchController.addListener(() {
      _getProducts();
    });
  }

  void _getProducts() {
    setState(() {
      final searchText = _searchController.text;
      if (searchText.isEmpty) {
        _futureProducts = supabase.from('product').select();
      } else {
        _futureProducts = supabase
            .from('product')
            .select()
            .ilike('name_product', '%$searchText%');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar produto',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _futureProducts,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final prod = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: prod.length,
                  itemBuilder: (BuildContext context, index) {
                    final prody = prod[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      height: 150.0,
                      child: Card(
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => Produto(
                                id: prody['id_product'],
                              ),
                            ));
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 100.0,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(prody['image_product']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        prody['name_product'],
                                        style: const TextStyle(
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        "R\$ ${prody['price_product']}",
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
