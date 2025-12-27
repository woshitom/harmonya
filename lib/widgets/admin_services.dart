import 'package:flutter/material.dart';
import 'admin_service_list.dart';

/// Services widget with tabs for Massages and Soins (Treatments)
class AdminServices extends StatefulWidget {
  const AdminServices({super.key});

  @override
  State<AdminServices> createState() => _AdminServicesState();
}

class _AdminServicesState extends State<AdminServices>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: [
            Tab(
              icon: const Icon(Icons.spa),
              text: isSmallScreen ? null : 'Massages',
              iconMargin: isSmallScreen
                  ? EdgeInsets.zero
                  : const EdgeInsets.only(bottom: 4),
            ),
            Tab(
              icon: const Icon(Icons.healing),
              text: isSmallScreen ? null : 'Soins',
              iconMargin: isSmallScreen
                  ? EdgeInsets.zero
                  : const EdgeInsets.only(bottom: 4),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              AdminServiceList(
                isTreatment: false,
                emptyMessage: 'Aucun massage enregistré',
                addButtonLabel: 'Ajouter un massage',
                addSuccessMessage: 'Massage ajouté avec succès',
                updateSuccessMessage: 'Massage modifié avec succès',
                deleteSuccessMessage: 'Massage supprimé avec succès',
                reorderSuccessMessage: 'Ordre des massages mis à jour',
              ),
              AdminServiceList(
                isTreatment: true,
                emptyMessage: 'Aucun soin enregistré',
                addButtonLabel: 'Ajouter un soin',
                addSuccessMessage: 'Soin ajouté avec succès',
                updateSuccessMessage: 'Soin modifié avec succès',
                deleteSuccessMessage: 'Soin supprimé avec succès',
                reorderSuccessMessage: 'Ordre des soins mis à jour',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

