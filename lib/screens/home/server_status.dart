import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:adguard_home_manager/screens/home/status_box.dart';

import 'package:adguard_home_manager/models/server_status.dart';

class ServerStatus extends StatelessWidget {
  final ServerStatusData serverStatus;

  const ServerStatus({
    Key? key,
    required this.serverStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.serverStatus,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface
            ),
          ),
          SizedBox(
            height: width > 700 ? 90 : 170,
            child: GridView(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: width > 700 ? 4 : 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 65
              ),
              children: [
                StatusBox(
                  icon: Icons.filter_list_rounded, 
                  label: AppLocalizations.of(context)!.ruleFilteringWidget, 
                  isEnabled: serverStatus.filteringEnabled
                ),
                StatusBox(
                  icon: Icons.vpn_lock_rounded, 
                  label: AppLocalizations.of(context)!.safeBrowsingWidget, 
                  isEnabled: serverStatus.safeBrowsingEnabled
                ),
                StatusBox(
                  icon: Icons.block, 
                  label: AppLocalizations.of(context)!.parentalFilteringWidget, 
                  isEnabled: serverStatus.parentalControlEnabled
                ),
                StatusBox(
                  icon: Icons.search_rounded, 
                  label: AppLocalizations.of(context)!.safeSearchWidget, 
                  isEnabled: serverStatus.safeSearchEnabled
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}