// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:adguard_home_manager/screens/settings/access_settings/add_client_modal.dart';
import 'package:adguard_home_manager/screens/clients/remove_client_modal.dart';
import 'package:adguard_home_manager/widgets/tab_content_list.dart';

import 'package:adguard_home_manager/functions/snackbar.dart';
import 'package:adguard_home_manager/providers/app_config_provider.dart';
import 'package:adguard_home_manager/models/clients_allowed_blocked.dart';
import 'package:adguard_home_manager/providers/servers_provider.dart';
import 'package:adguard_home_manager/constants/enums.dart';
import 'package:adguard_home_manager/services/http_requests.dart';
import 'package:adguard_home_manager/classes/process_modal.dart';

class ClientsList extends StatefulWidget {
  final String type;
  final ScrollController scrollController;
  final LoadStatus loadStatus;
  final List<String> data;
  final Future Function() fetchClients;

  const ClientsList({
    Key? key,
    required this.type,
    required this.scrollController,
    required this.loadStatus,
    required this.data,
    required this.fetchClients
  }) : super(key: key);

  @override
  State<ClientsList> createState() => _ClientsListState();
}

class _ClientsListState extends State<ClientsList> {
  late bool isVisible;

  @override
  initState(){
    super.initState();

    isVisible = true;
    widget.scrollController.addListener(() {
      if (mounted) {
        if (widget.scrollController.position.userScrollDirection == ScrollDirection.reverse) {
          if (mounted && isVisible == true) {
            setState(() => isVisible = false);
          }
        } 
        else {
          if (widget.scrollController.position.userScrollDirection == ScrollDirection.forward) {
            if (mounted && isVisible == false) {
              setState(() => isVisible = true);
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final serversProvider = Provider.of<ServersProvider>(context);
    final appConfigProvider = Provider.of<AppConfigProvider>(context);

    final width = MediaQuery.of(context).size.width;

    void confirmRemoveItem(String client, String type) async {
      Map<String, List<String>> body = {
        "allowed_clients": serversProvider.clients.data!.clientsAllowedBlocked?.allowedClients ?? [],
        "disallowed_clients": serversProvider.clients.data!.clientsAllowedBlocked?.disallowedClients ?? [],
        "blocked_hosts": serversProvider.clients.data!.clientsAllowedBlocked?.blockedHosts ?? [],
      };

      if (type == 'allowed') {
        body['allowed_clients'] = body['allowed_clients']!.where((c) => c != client).toList();
      }
      else if (type == 'disallowed') {
        body['disallowed_clients'] = body['disallowed_clients']!.where((c) => c != client).toList();
      }
      else if (type == 'domains') {
        body['blocked_hosts'] = body['blocked_hosts']!.where((c) => c != client).toList();
      }

      ProcessModal processModal = ProcessModal(context: context);
      processModal.open(AppLocalizations.of(context)!.removingClient);

      final result = await requestAllowedBlockedClientsHosts(serversProvider.selectedServer!, body);

      processModal.close();

      if (result['result'] == 'success') {
        serversProvider.setAllowedDisallowedClientsBlockedDomains(
          ClientsAllowedBlocked(
            allowedClients: body['allowed_clients'] ?? [], 
            disallowedClients: body['disallowed_clients'] ?? [], 
            blockedHosts: body['blocked_hosts'] ?? [], 
          )
        );
      }
      else if (result['result'] == 'error' && result['message'] == 'client_another_list') {
        showSnacbkar(
          context: context, 
          appConfigProvider: appConfigProvider,
          label: AppLocalizations.of(context)!.clientAnotherList, 
          color: Colors.red
        );
      }
      else {
        appConfigProvider.addLog(result['log']);

        showSnacbkar(
          context: context, 
          appConfigProvider: appConfigProvider,
          label: AppLocalizations.of(context)!.clientNotRemoved, 
          color: Colors.red
        );
      }
    }

    void confirmAddItem(String item, String type) async {
      Map<String, List<String>> body = {
        "allowed_clients": serversProvider.clients.data!.clientsAllowedBlocked?.allowedClients ?? [],
        "disallowed_clients": serversProvider.clients.data!.clientsAllowedBlocked?.disallowedClients ?? [],
        "blocked_hosts": serversProvider.clients.data!.clientsAllowedBlocked?.blockedHosts ?? [],
      };

      if (type == 'allowed') {
        body['allowed_clients']!.add(item);
      }
      else if (type == 'disallowed') {
        body['disallowed_clients']!.add(item);
      }
      else if (type == 'domains') {
        body['blocked_hosts']!.add(item);
      }

      ProcessModal processModal = ProcessModal(context: context);
      processModal.open(AppLocalizations.of(context)!.removingClient);

      final result = await requestAllowedBlockedClientsHosts(serversProvider.selectedServer!, body);

      processModal.close();

      if (result['result'] == 'success') {
        serversProvider.setAllowedDisallowedClientsBlockedDomains(
          ClientsAllowedBlocked(
            allowedClients: body['allowed_clients'] ?? [], 
            disallowedClients: body['disallowed_clients'] ?? [], 
            blockedHosts: body['blocked_hosts'] ?? [], 
          )
        );
      }
      else if (result['result'] == 'error' && result['message'] == 'client_another_list') {
        showSnacbkar(
          context: context, 
          appConfigProvider: appConfigProvider,
          label: AppLocalizations.of(context)!.clientAnotherList, 
          color: Colors.red
        );
      }
      else {
        appConfigProvider.addLog(result['log']);

        showSnacbkar(
          context: context, 
          appConfigProvider: appConfigProvider,
          label: type == 'allowed' || type == 'blocked'
            ? AppLocalizations.of(context)!.clientNotRemoved
            : AppLocalizations.of(context)!.domainNotAdded,
          color: Colors.red
        );
      }
    }

    String description() {
      switch (widget.type) {
        case 'allowed':
          return AppLocalizations.of(context)!.allowedClientsDescription;

        case 'disallowed':
          return AppLocalizations.of(context)!.blockedClientsDescription;

        case 'domains':
          return AppLocalizations.of(context)!.disallowedDomainsDescription;

        default:
          return "";
      }
    }

    String noItems() {
      switch (widget.type) {
        case 'allowed':
          return AppLocalizations.of(context)!.noAllowedClients;

        case 'disallowed':
          return AppLocalizations.of(context)!.noBlockedClients;

        case 'domains':
          return AppLocalizations.of(context)!.noDisallowedDomains;

        default:
          return "";
      }
    }

    return CustomTabContentList(
      noSliver: !(Platform.isAndroid || Platform.isIOS) ? true : false,
      loadingGenerator: () => SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height-171,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 30),
            Text(
              AppLocalizations.of(context)!.loadingClients,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          ],
        ),
      ), 
      itemsCount: widget.data.isNotEmpty
        ? widget.data.length+1
        : 0, 
      contentWidget: (index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_rounded,
                      color: Theme.of(context).listTileTheme.iconColor,
                    ),
                    const SizedBox(width: 20),
                    Flexible(
                      child: Text(
                        description(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }
        else {
          return ListTile(
            title: Text(
              widget.data[index-1],
              style: TextStyle(
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurface
              ),
            ),
            trailing: IconButton(
              onPressed: () => {
                showDialog(
                  context: context, 
                  builder: (context) => RemoveClientModal(
                    onConfirm: () => confirmRemoveItem(widget.data[index-1], widget.type),
                  )
                )
              }, 
              icon: const Icon(Icons.delete_rounded)
            ),
          );
        }
      },
      noData: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_rounded,
                      color: Theme.of(context).listTileTheme.iconColor,
                    ),
                    const SizedBox(width: 20),
                    Flexible(
                      child: Text(
                        description(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  noItems(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 30),
                TextButton.icon(
                  onPressed: widget.fetchClients, 
                  icon: const Icon(Icons.refresh_rounded), 
                  label: Text(AppLocalizations.of(context)!.refresh),
                )
              ],
            ),
          ),
        ],
      ),
      errorGenerator: () => SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height-101,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.error,
              color: Colors.red,
              size: 50,
            ),
            const SizedBox(height: 30),
            Text(
              AppLocalizations.of(context)!.clientsNotLoaded,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          ],
        ),
      ), 
      loadStatus: widget.loadStatus, 
      onRefresh: widget.fetchClients,
      refreshIndicatorOffset: 0,
      fab: FloatingActionButton(
        onPressed: () {
          if (width > 900) {
            showDialog(
              context: context, 
              builder: (context) => AddClientModal(
                type: widget.type,
                onConfirm: confirmAddItem,
                dialog: true,
              ),
            );
          }
          else {
            showModalBottomSheet(
              context: context, 
              builder: (context) => AddClientModal(
                type: widget.type,
                onConfirm: confirmAddItem,
                dialog: false,
              ),
              backgroundColor: Colors.transparent,
              isScrollControlled: true
            );
          }
        },
        child: const Icon(Icons.add),
      ),
      fabVisible: isVisible,
    );
  }
}