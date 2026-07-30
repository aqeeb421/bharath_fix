import 'package:flutter/material.dart';

class QuoteItemDraft {
  String title;
  double price;
  bool isSparePart;

  QuoteItemDraft({required this.title, required this.price, this.isSparePart = true});
}

class QuotationBuilderScreen extends StatefulWidget {
  final String jobId;
  final Function(List<QuoteItemDraft>) onSubmitQuote;

  const QuotationBuilderScreen({
    Key? key,
    required this.jobId,
    required this.onSubmitQuote,
  }) : super(key: key);

  @override
  State<QuotationBuilderScreen> createState() => _QuotationBuilderScreenState();
}

class _QuotationBuilderScreenState extends State<QuotationBuilderScreen> {
  final List<QuoteItemDraft> _items = [
    QuoteItemDraft(title: 'Standard Inspection & Labor Charge', price: 299, isSparePart: false),
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _isSparePart = true;

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.price);

  void _addItem() {
    final title = _titleController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0;

    if (title.isNotEmpty && price > 0) {
      setState(() {
        _items.add(QuoteItemDraft(title: title, price: price, isSparePart: _isSparePart));
        _titleController.clear();
        _priceController.clear();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Itemized Quotation'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add Item Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add Part / Labor Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Item Name (e.g. Capacitor 36 MFD)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Price (₹)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Spare Part'),
                              selected: _isSparePart,
                              onSelected: (selected) => setState(() => _isSparePart = true),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Labor Fee'),
                              selected: !_isSparePart,
                              onSelected: (selected) => setState(() => _isSparePart = false),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Items List
            Expanded(
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.isSparePart ? Colors.blue.shade50 : Colors.orange.shade50,
                        child: Icon(
                          item.isSparePart ? Icons.extension_rounded : Icons.build_rounded,
                          color: item.isSparePart ? Colors.blue : Colors.orange,
                          size: 20,
                        ),
                      ),
                      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(item.isSparePart ? 'Spare Part' : 'Labor Charge', style: const TextStyle(fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _removeItem(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom Summary & Submit
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Quote Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        '₹${_totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_items.isNotEmpty) {
                          widget.onSubmitQuote(_items);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Send Quote for Customer Approval', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
