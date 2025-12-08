import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gift_voucher.dart';
import '../services/firebase_service.dart';

class AdminVoucherList extends StatelessWidget {
  const AdminVoucherList({super.key});

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'paid':
        return 'Payé';
      case 'used':
        return 'Utilisé';
      case 'expired':
        return 'Expiré';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'used':
        return Colors.blue;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return StreamBuilder<List<GiftVoucher>>(
      stream: firebaseService.getGiftVouchers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final vouchers = snapshot.data ?? [];

        if (vouchers.isEmpty) {
          return const Center(
            child: Text(
              'Aucun bon cadeau pour le moment',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vouchers.length,
          itemBuilder: (context, index) {
            final voucher = vouchers[index];
            final isExpired = voucher.expiresAt.isBefore(DateTime.now());
            final status = isExpired && voucher.status == 'paid'
                ? 'expired'
                : voucher.status;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(status).withOpacity(0.2),
                  child: Icon(
                    status == 'paid'
                        ? Icons.card_giftcard
                        : status == 'used'
                            ? Icons.check_circle
                            : status == 'expired'
                                ? Icons.event_busy
                                : Icons.pending,
                    color: _getStatusColor(status),
                  ),
                ),
                title: Text(
                  '${NumberFormat.currency(symbol: '€', decimalDigits: 2).format(voucher.amount)} - ${voucher.recipientName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusLabel(status),
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Acheté le ${DateFormat('dd/MM/yyyy').format(voucher.createdAt)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          'Acheteur',
                          '${voucher.purchaserName} (${voucher.purchaserEmail})',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Destinataire',
                          '${voucher.recipientName} (${voucher.recipientEmail})',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Montant',
                          NumberFormat.currency(symbol: '€', decimalDigits: 2)
                              .format(voucher.amount),
                        ),
                        if (voucher.message != null &&
                            voucher.message!.isNotEmpty) ...[
                          const Divider(),
                          _buildInfoRow('Message', voucher.message!),
                        ],
                        const Divider(),
                        _buildInfoRow(
                          'Date d\'achat',
                          DateFormat('dd/MM/yyyy à HH:mm')
                              .format(voucher.createdAt),
                        ),
                        if (voucher.paidAt != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            'Date de paiement',
                            DateFormat('dd/MM/yyyy à HH:mm')
                                .format(voucher.paidAt!),
                          ),
                        ],
                        if (voucher.paypalOrderId != null &&
                            voucher.paypalOrderId!.isNotEmpty) ...[
                          const Divider(),
                          _buildInfoRow(
                            'ID PayPal',
                            voucher.paypalOrderId!,
                          ),
                        ],
                        const Divider(),
                        _buildInfoRow(
                          'Valable jusqu\'au',
                          DateFormat('dd/MM/yyyy').format(voucher.expiresAt),
                        ),
                        if (status == 'paid' && !isExpired) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  _markAsUsed(context, voucher, firebaseService);
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Marquer comme utilisé'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsUsed(
    BuildContext context,
    GiftVoucher voucher,
    FirebaseService firebaseService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Marquer comme utilisé'),
            content: Text(
              'Voulez-vous marquer ce bon cadeau de ${NumberFormat.currency(symbol: '€', decimalDigits: 2).format(voucher.amount)} comme utilisé ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmer'),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await firebaseService.updateGiftVoucher(voucher.id!, {
          'status': 'used',
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bon cadeau marqué comme utilisé'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

