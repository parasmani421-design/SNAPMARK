import 'package:flutter/material.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  String _selectedCategory = 'All Fees';

  static const _categories = <({String name, IconData icon})>[
    (name: 'All Fees', icon: Icons.currency_rupee),
    (name: 'Academic', icon: Icons.school_outlined),
    (name: 'Hostel', icon: Icons.bed_outlined),
    (name: 'Transport', icon: Icons.directions_bus_outlined),
    (name: 'Miscellaneous', icon: Icons.more_horiz),
  ];

  static const _feeData =
      <String, ({int total, int paid, List<(String, int)> items})>{
        'Academic': (
          total: 120000,
          paid: 80000,
          items: [
            ('Tuition Fee', 90000),
            ('Examination Fee', 10000),
            ('Technology Fee', 8000),
            ('Other Academic Charges', 12000),
          ],
        ),
        'Hostel': (
          total: 0,
          paid: 0,
          items: [('Hostel Fee', 0), ('Hostel Miscellaneous', 0)],
        ),
        'Transport': (
          total: 0,
          paid: 0,
          items: [('Transport Fee', 0), ('Transport Miscellaneous', 0)],
        ),
        'Miscellaneous': (
          total: 8000,
          paid: 0,
          items: [('Academic Miscellaneous', 8000), ('Other Charges', 0)],
        ),
      };

  int get _total => _selectedCategory == 'All Fees'
      ? _feeData.values.fold(0, (sum, fees) => sum + fees.total)
      : _feeData[_selectedCategory]!.total;

  int get _paid => _selectedCategory == 'All Fees'
      ? _feeData.values.fold(0, (sum, fees) => sum + fees.paid)
      : _feeData[_selectedCategory]!.paid;

  int get _due => _total - _paid;

  List<(String, int)> get _items => _selectedCategory == 'All Fees'
      ? _feeData.values.expand((fees) => fees.items).toList()
      : _feeData[_selectedCategory]!.items;

  String _money(int amount) =>
      '₹${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: .62);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Fees',
          style: TextStyle(color: foreground, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fee Categories',
              style: TextStyle(
                color: foreground,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'Select a category to view its fee details',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 380 ? 2 : 3;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: columns == 2 ? 1.48 : 1.08,
                  children: _categories.map((category) {
                    final selected = _selectedCategory == category.name;
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () =>
                          setState(() => _selectedCategory = category.name),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected
                                ? Colors.blueAccent
                                : foreground.withValues(alpha: .08),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              category.icon,
                              color: Colors.blueAccent,
                              size: 30,
                            ),
                            const SizedBox(height: 9),
                            Text(
                              category.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: foreground,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 22),

            // TOTAL FEE CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff155EEF), Color(0xff4527A0)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_selectedCategory • Total Fees',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),

                  SizedBox(height: 8),

                  Text(
                    _money(_total),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Sample fee data • Academic Year 2026–27',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // PAID / DUE
            Row(
              children: [
                Expanded(
                  child: _amountCard(
                    context: context,
                    title: 'Paid',
                    amount: _money(_paid),
                    icon: Icons.check_circle,
                    iconColor: Colors.greenAccent,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _amountCard(
                    context: context,
                    title: 'Remaining',
                    amount: _money(_due),
                    icon: Icons.pending,
                    iconColor: Colors.orangeAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Text(
              _selectedCategory == 'All Fees'
                  ? 'Fee Breakdown'
                  : '$_selectedCategory Breakdown',
              style: TextStyle(
                color: foreground,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            const SizedBox(height: 15),
            ..._items.map(
              (item) => _feeItem(
                context,
                Icons.receipt_long,
                item.$1,
                _money(item.$2),
              ),
            ),

            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'These are sample amounts for the app preview. Your actual fee balance needs to come from your college account.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'Payment History',
              style: TextStyle(
                color: foreground,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _paymentHistory(
              context,
              '₹40,000',
              'Semester 1 Fee',
              '15 July 2026',
            ),

            _paymentHistory(
              context,
              '₹40,000',
              'Semester 1 Fee',
              '10 August 2026',
            ),

            const SizedBox(height: 25),

            // PAY BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Online fee payment will be connected soon.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.payment),
                label: const Text(
                  'Pay Remaining Fees',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // RECEIPT BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fee receipt will be available here.'),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text(
                  'View Fee Receipt',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  side: const BorderSide(color: Colors.blueAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _amountCard({
    required BuildContext context,
    required String title,
    required String amount,
    required IconData icon,
    required Color iconColor,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),

          const SizedBox(height: 12),

          Text(
            title,
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: .62),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            amount,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeItem(
    BuildContext context,
    IconData icon,
    String title,
    String amount,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),

          const SizedBox(width: 14),

          Expanded(
            child: Text(title, style: TextStyle(color: colors.onSurface)),
          ),

          Text(
            amount,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentHistory(
    BuildContext context,
    String amount,
    String title,
    String date,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xff172554),
            child: Icon(Icons.receipt, color: Colors.blueAccent),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  date,
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: .62),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Text(
            amount,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
