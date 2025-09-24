import 'package:flutter/material.dart';

class GestionDePedidos extends StatefulWidget {
  const GestionDePedidos({super.key});

  @override
  State<GestionDePedidos> createState() => _GestionDePedidosState();
}

class _GestionDePedidosState extends State<GestionDePedidos> {
  // Lista dinámica de pedidos
  List<Map<String, dynamic>> pedidos = [
    {
      "id": "P01",
      "cliente": "Maria Gonza",
      "total": "L. 500",
      "estado": "Pendiente",
    },
    {
      "id": "P02",
      "cliente": "Carlos Ruiz",
      "total": "L. 300",
      "estado": "Confirmado",
    },
    {
      "id": "P03",
      "cliente": "Ana López",
      "total": "L. 800",
      "estado": "Entregado",
    },
  ];

  String filtroEstado = "Todos";
  String filtroFecha = "Hoy";
  String filtroCliente = "Todos";

  @override
  Widget build(BuildContext context) {
    // Filtramos pedidos según estado
    List<Map<String, dynamic>> pedidosFiltrados = pedidos.where((pedido) {
      if (filtroEstado != "Todos" && pedido["estado"] != filtroEstado) {
        return false;
      }
      return true;
    }).toList();

    // Contadores
    int pendientes = pedidos.where((p) => p["estado"] == "Pendiente").length;
    int confirmados = pedidos.where((p) => p["estado"] == "Confirmado").length;
    int entregados = pedidos.where((p) => p["estado"] == "Entregado").length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Pedidos"),
        backgroundColor: Colors.teal[700],
      ),
      body: Column(
        children: [
          // FILTROS
          Container(
            color: Colors.teal[700],
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildDropdown(
                  "Estado",
                  filtroEstado,
                  ["Todos", "Pendiente", "Confirmado", "Entregado"],
                  (value) => setState(() => filtroEstado = value!),
                ),
                _buildDropdown(
                  "Fecha",
                  filtroFecha,
                  ["Hoy", "Ayer", "Última semana"],
                  (value) => setState(() => filtroFecha = value!),
                ),
                _buildDropdown(
                  "Cliente",
                  filtroCliente,
                  ["Todos", "Maria Gonza", "Carlos Ruiz", "Ana López"],
                  (value) => setState(() => filtroCliente = value!),
                ),
              ],
            ),
          ),

          // TARJETAS DE RESUMEN
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _buildCard(
                  pendientes.toString(),
                  "Pendientes",
                  Icons.sync,
                  Colors.orange,
                ),
                _buildCard(
                  confirmados.toString(),
                  "Confirmados",
                  Icons.check,
                  Colors.green,
                ),
                _buildCard(
                  entregados.toString(),
                  "Entregados",
                  Icons.check_box,
                  Colors.blue,
                ),
              ],
            ),
          ),

          // ENCABEZADOS TABLA
          Container(
            color: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: const [
                Expanded(
                  child: Text(
                    "Id Pedido",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Cliente",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Total",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Estado",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Acción",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // LISTA DE PEDIDOS
          Expanded(
            child: ListView.builder(
              itemCount: pedidosFiltrados.length,
              itemBuilder: (context, index) {
                final pedido = pedidosFiltrados[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(pedido["id"])),
                      Expanded(child: Text(pedido["cliente"])),
                      Expanded(child: Text(pedido["total"])),
                      Expanded(child: Text(pedido["estado"])),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            _editarPedido(pedido);
                          },
                          child: const Text("Editar"),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Barra inferior de navegación
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Catálogo"),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Pedidos",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }

  // WIDGET DROPDOWN
  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        underline: const SizedBox(),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text("$label: $e")))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  // WIDGET CARD DE RESUMEN
  Widget _buildCard(String number, String label, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                number,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  // FUNCIÓN PARA EDITAR PEDIDO
  void _editarPedido(Map<String, dynamic> pedido) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Editar ${pedido['id']}"),
          content: Text("Aquí podrías implementar un formulario de edición."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }
}
