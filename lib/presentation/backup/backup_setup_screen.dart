import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'backup_view_model.dart';
import '../../theme/custom_colors.dart';
import '../widgets/custom_dialog.dart';
import '../timer/timer_view_model.dart';

class BackupSetupScreen extends ConsumerWidget {
  const BackupSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupSetupProvider);
    final viewModel = ref.read(backupSetupProvider.notifier);

    // Listen for errors
    ref.listen(backupSetupProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor:
                Theme.of(context).extension<SpecialColors>()?.warningColor ??
                Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Google Drive Backup'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: state.isSignedIn
          ? _ConnectedView(
              account: state.account!,
              onSignOut: viewModel.signOut,
            )
          : _SetupView(isLoading: state.isLoading, onSignIn: viewModel.signIn),
    );
  }
}

class _SetupView extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSignIn;

  const _SetupView({required this.isLoading, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Securely store your time tracking data in Google Drive. Your backups will be encrypted and automatically synced to the cloud.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                if (isLoading)
                  const CircularProgressIndicator()
                else
                  OutlinedButton.icon(
                    onPressed: onSignIn,
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in with Google'),
                    style: OutlinedButton.styleFrom(
                      iconColor: Theme.of(context).colorScheme.onSurface,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _BenefitsCard(),
          const SizedBox(height: 24),
          const _PrivacyNotice(),
        ],
      ),
    );
  }
}

class _ConnectedView extends StatelessWidget {
  final GoogleSignInAccount account;
  final VoidCallback onSignOut;

  const _ConnectedView({required this.account, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_done, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  'Connected to Google Drive',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(account.email),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: onSignOut,
                  child: const Text('Disconnect'),
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final state = ref.watch(backupSetupProvider);
                    final viewModel = ref.read(backupSetupProvider.notifier);

                    if (state.isRestoring) {
                      return const CircularProgressIndicator();
                    }

                    return TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => CustomDialog(
                            title: 'Restore Data?',
                            description:
                                'This will overwrite all your current app data with the backup from Google Drive. This action cannot be undone.',
                            primaryButtonText: 'Restore',
                            onPrimaryPressed: () async {
                              Navigator.pop(context);
                              final success = await viewModel.restoreBackup();
                              if (context.mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Data restored successfully. Refreshing...',
                                      ),
                                    ),
                                  );
                                  // Refresh timer provider to reload data
                                  ref.invalidate(timerProvider);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to restore data. Please try again.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            secondaryButtonText: 'Cancel',
                            onSecondaryPressed: () => Navigator.pop(context),
                            primaryButtonColor: Theme.of(
                              context,
                            ).extension<SpecialColors>()?.warningColor,
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.restore,
                        color: Theme.of(
                          context,
                        ).extension<SpecialColors>()?.warningColor,
                      ),
                      label: Text(
                        'Restore from Backup',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).extension<SpecialColors>()?.warningColor,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _BenefitsCard(),
        ],
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Benefits', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          const _BenefitItem(
            icon: Icons.cloud_upload_outlined,
            title: 'Automatic Cloud Backup',
            subtitle: 'Your data is backed up automatically every day',
          ),
          const SizedBox(height: 16),
          const _BenefitItem(
            icon: Icons.security_outlined,
            title: 'Secure & Encrypted',
            subtitle:
                'All backups are encrypted with industry-standard security',
          ),
          const SizedBox(height: 16),
          const _BenefitItem(
            icon: Icons.devices_outlined,
            title: 'Access Anywhere',
            subtitle:
                'Restore your data on any device with your Google account',
          ),
          const SizedBox(height: 16),
          const _BenefitItem(
            icon: Icons.history_outlined,
            title: 'Version History',
            subtitle: 'Keep multiple backup versions for easy recovery',
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Notice',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Time Tracker only accesses files it creates in your Drive. We never read or access your other files.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
