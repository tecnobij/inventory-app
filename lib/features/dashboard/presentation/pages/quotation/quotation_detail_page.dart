// lib/features/quotations/presentation/quotation_details_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/quotations_controller.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';

class QuotationDetailsPage extends StatelessWidget {
  final int quoteId;
  
  const QuotationDetailsPage({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuotationsController(
        db: context.read<AppDatabase>(),
        settings: context.read<SettingsProvider>(),
      ),
      child: _QuotationDetailsScaffold(quoteId: quoteId),
    );
  }
}

class _QuotationDetailsScaffold extends StatefulWidget {
  final int quoteId;
  
  const _QuotationDetailsScaffold({required this.quoteId});

  @override
  State<_QuotationDetailsScaffold> createState() => _QuotationDetailsScaffoldState();
}

class _QuotationDetailsScaffoldState extends State<_QuotationDetailsScaffold> {
  QuoteDetailVM? _quote;
  bool _loading = true;
  String? _error;
String tax="0";
  @override
  void initState() {
    super.initState();
    _loadQuoteDetails();
  }

  Future<void> _loadQuoteDetails() async {
    try {
      final ctrl = context.read<QuotationsController>();
      final quote = await ctrl.fetchQuoteDetails(widget.quoteId);
      setState(() {
        _quote = quote;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_quote?.docNo ?? 'Quotation Details'),
        backgroundColor: scheme.surface,
        actions: [
          if (_quote != null) ...[
            IconButton(
              tooltip: 'Share',
              onPressed: () => _shareQuotation(),
              icon: const Icon(Icons.share),
            ),
            PopupMenuButton<String>(
              onSelected: _onMenuSelected,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Quotation')),
                const PopupMenuItem(value: 'convert', child: Text('Convert to Sales Order')),
                const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                if (_quote!.status == QuoteStatus.open)
                  const PopupMenuItem(value: 'close', child: Text('Mark as Closed')),
              ],
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Error loading quotation', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadQuoteDetails(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_quote == null) {
      return const Center(child: Text('Quotation not found'));
    }

    final isMobile = MediaQuery.of(context).size.width < 700;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuotationHeader(quote: _quote!),
          const SizedBox(height: 24),
          _LineItemsSection(items: _quote!.items, quote: _quote!,),
          const SizedBox(height: 24),
          _TotalsSection(quote: _quote!),
          const SizedBox(height: 24),
          _ActionsSection(quote: _quote!, onAction: _onActionPressed),
        ],
      ),
    );
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'edit':
        _editQuotation();
        break;
      case 'convert':
        _convertToSalesOrder();
        break;
      case 'duplicate':
        _duplicateQuotation();
        break;
      case 'close':
        _closeQuotation();
        break;
    }
  }

  void _onActionPressed(String action) {
    _onMenuSelected(action);
  }

  void _shareQuotation() {
    _snack('Share functionality not implemented yet');
  }

  void _editQuotation() {
    _snack('Edit functionality not implemented yet');
  }

  void _convertToSalesOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to Sales Order'),
        content: const Text('This will create a new Sales Order based on this quotation. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performConversion();
            },
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }

  void _duplicateQuotation() {
    _snack('Duplicate functionality not implemented yet');
  }

  void _closeQuotation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Quotation'),
        content: const Text('Mark this quotation as closed? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performClose();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _performConversion() async {
    try {
      final ctrl = context.read<QuotationsController>();
      final soId = await ctrl.convertQuoteToSalesOrder(widget.quoteId);
      _snack('Converted to Sales Order #$soId');
    } catch (e) {
      _snack('Error converting: $e');
    }
  }

  Future<void> _performClose() async {
    try {
      final ctrl = context.read<QuotationsController>();
      await ctrl.updateQuoteStatus(widget.quoteId, QuoteStatus.rejected);
      await _loadQuoteDetails();
      _snack('Quotation closed');
    } catch (e) {
      _snack('Error closing quotation: $e');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _QuotationHeader extends StatelessWidget {
  final QuoteDetailVM quote;
  
  const _QuotationHeader({required this.quote});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 700;
    
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.docNo,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      quote.partyName,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (quote.partyAddress?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        quote.partyAddress!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusPill(status: quote.status),
            ],
          ),
          const SizedBox(height: 20),
          isMobile ? _headerFieldsMobile() : _headerFieldsDesktop(),
        ],
      ),
    );
  }

  Widget _headerFieldsMobile() {
    return Column(
      children: [
        _headerRow('Quote Date', _d(quote.quoteDate)),
        const SizedBox(height: 12),
        _headerRow('Valid Until', _d(quote.validTill)),
        const SizedBox(height: 12),
        _headerRow('Created', _formatDateTime(quote.createdAt)),
        const SizedBox(height: 12),
        _headerRow('Total Amount', '₹${_comma((quote.totalMinor/100) .toInt())}'),
      ],
    );
  }

  Widget _headerFieldsDesktop() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _headerRow('Quote Date', _d(quote.quoteDate)),
              const SizedBox(height: 12),
              _headerRow('Valid Until', _d(quote.validTill)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _headerRow('Created', _formatDateTime(quote.createdAt)),
              const SizedBox(height: 12),
              _headerRow('Total Amount', '₹${_comma((quote.totalMinor/100) .toInt())}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_d(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _LineItemsSection extends StatelessWidget {
  final List<QuoteItemVM> items;
final  QuoteDetailVM quote;
   _LineItemsSection({required this.items, required this.quote});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 700;
  
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Line Items',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          if (isMobile) 
            _itemsMobile(quote)
          else 
            _itemsDesktop(quote),
        ],
      ),
    );
  }

  Widget _itemsDesktop(   QuoteDetailVM quote) {
    var tax =(( quote.taxMinor/100).toInt()/ (quote.subtotalMinor/100).toInt())*100;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: const [
              Expanded(flex: 4, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.bold))),
             Expanded(flex: 2, child: Text('GST%', style: TextStyle(fontWeight: FontWeight.bold))),
            //  Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        for (int i = 0; i < items.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    items[i].productName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text('${items[i].qty}'),
                ),
                Expanded(
                  flex: 2,
                  child: Text('₹${_comma((items[i].unitPriceMinor/100).toInt())}'),
                ),
                Expanded(
                  flex: 2,
                  child: Expanded(
  flex: 2,
  child: Text('${tax.round()}%'),
),

                ),
              ],
            ),
          ),
          if (i < items.length - 1) const Divider(height: 1),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _itemsMobile( QuoteDetailVM quote) {
      var tax =(( quote.taxMinor/100).toInt()/ (quote.subtotalMinor/100).toInt())*100;

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  items[i].productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Qty: ${items[i].qty}'),
                    Text('₹${_comma((items[i].unitPriceMinor/100).toInt())} each'),
                      Text('GST  ${tax.round()}%'),
                  ],
                ),
                const SizedBox(height: 8),
              
                
              ],
            ),
          ),
          if (i < items.length - 1) const Divider(height: 1),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

}

class _TotalsSection extends StatelessWidget {
  final QuoteDetailVM quote;
  
  const _TotalsSection({required this.quote});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _totalRow('Subtotal', (quote.subtotalMinor/100).toInt()),
          const SizedBox(height: 8),
          _totalRow('GST',( quote.taxMinor/100).toInt()),
          const Divider(height: 24),
          _totalRow('Total',( quote.totalMinor/100).toInt(), isTotal: true),
        ],
      ),
    );
  }

  Widget _totalRow(String label, int amountMinor, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 18 : 16,
          ),
        ),
        Text(
          '₹${_comma(amountMinor)}',
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 18 : 16,
          ),
        ),
      ],
    );
  }
}

class _ActionsSection extends StatelessWidget {
  final QuoteDetailVM quote;
  final Function(String) onAction;
  
  const _ActionsSection({required this.quote, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (isMobile)
            _actionsMobile()
          else
            _actionsDesktop(),
        ],
      ),
    );
  }

  Widget _actionsMobile() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => onAction('convert'),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Convert to Sales Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onAction('edit'),
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onAction('duplicate'),
                icon: const Icon(Icons.copy),
                label: const Text('Duplicate'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionsDesktop() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => onAction('convert'),
          icon: const Icon(Icons.receipt_long),
          label: const Text('Convert to Sales Order'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => onAction('edit'),
          icon: const Icon(Icons.edit),
          label: const Text('Edit'),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => onAction('duplicate'),
          icon: const Icon(Icons.copy),
          label: const Text('Duplicate'),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final QuoteStatus status;

  @override
  Widget build(BuildContext context) {
    final dark = status == QuoteStatus.open;
    final bg = dark ? const Color(0xFF0B0B14) : const Color(0xFFF2F4F7);
    final fg = dark ? Colors.white : const Color(0xFF344054);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg, 
        borderRadius: BorderRadius.circular(999)
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          color: fg, 
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  String _label(QuoteStatus s) {
    switch (s) {
      case QuoteStatus.open: return 'Open';
      case QuoteStatus.accepted: return 'Accepted';
      case QuoteStatus.rejected: return 'Rejected';
      case QuoteStatus.expired: return 'Expired';
    }
  }
}

// Data models for quotation details
class QuoteDetailVM {
  final int id;
  final String docNo;
  final String partyName;
  final String? partyAddress;
  final DateTime quoteDate;
  final DateTime validTill;
  final DateTime createdAt;
  final QuoteStatus status;
  final int subtotalMinor;
  final int taxMinor;
  final int totalMinor;
  final List<QuoteItemVM> items;

  QuoteDetailVM({
    required this.id,
    required this.docNo,
    required this.partyName,
    this.partyAddress,
    required this.quoteDate,
    required this.validTill,
    required this.createdAt,
    required this.status,
    required this.subtotalMinor,
    required this.taxMinor,
    required this.totalMinor,
    required this.items,
  });
}

class QuoteItemVM {
  final int id;
  final String productName;
  final int qty;
  final int unitPriceMinor;
  final int? gstPct;

  QuoteItemVM({
    required this.id,
    required this.productName,
    required this.qty,
    required this.unitPriceMinor,
    this.gstPct,
  });
}

String _d(DateTime? d) =>
    d == null ? '--' : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _comma(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final fromRight = s.length - i - 1;
    buf.write(s[i]);
    if (fromRight > 0 && fromRight % 3 == 0) buf.write(',');
  }
  return buf.toString();
}
