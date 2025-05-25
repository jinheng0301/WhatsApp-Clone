import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:whatsapppp/common/utils/color.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/status/controller/status_controller.dart';

class StatusContactsScreen extends ConsumerWidget {
  const StatusContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(statusControllerProvider).getStatus(context),
      builder: (context, snapshot) {
        print(
            'StatusContactsScreen: Connection state: ${snapshot.connectionState}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Loader();
        }

        // Handle errors
        if (snapshot.hasError) {
          print('StatusContactsScreen: Error occurred: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 50, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error loading statuses',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Trigger rebuild to retry
                    (context as Element).markNeedsBuild();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Handle null or empty data
        if (!snapshot.hasData || snapshot.data == null) {
          print('StatusContactsScreen: No data available');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info, size: 50, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No data available',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        final statuses = snapshot.data!;
        print('StatusContactsScreen: Found ${statuses.length} statuses');

        if (statuses.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 50, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No recent statuses',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Statuses from your contacts will appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 10),
          itemCount: statuses.length,
          separatorBuilder: (context, index) => Divider(
            color: dividerColor,
            indent: 85,
          ),
          itemBuilder: (context, index) {
            final status = statuses[index];
            
            print(
                'StatusContactsScreen: Building item $index for ${status.username}');

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: status.profilePic.isNotEmpty
                    ? NetworkImage(status.profilePic)
                    : null,
                radius: 24,
                child: status.profilePic.isEmpty ? Icon(Icons.person) : null,
              ),
              title: Text(status.username),
              subtitle: Text(
                DateFormat('h:mm a').format(status.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              onTap: () {
                print('StatusContactsScreen: Tapped on ${status.username}');
                // Add your navigation logic here
                Navigator.pushNamed(
                  context,
                  '/status-screen',
                  arguments: status,
                );
              },
            );
          },
        );
      },
    );
  }
}
