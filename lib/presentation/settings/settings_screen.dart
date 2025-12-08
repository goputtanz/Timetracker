import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/custom_colors.dart';
import 'settings_contract.dart';
import 'settings_view_model.dart';
import '../timer/timer_view_model.dart';
import '../backup/backup_setup_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../widgets/custom_dialog.dart';
import '../../services/notification_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final viewModel = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _ProfileCard(
                user: state.googleUser,
                onLogin: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BackupSetupScreen(),
                    ),
                  ).then((_) {
                    // Refresh logic if needed
                  });
                },
                onLogout: () {
                  viewModel.processIntent(DisconnectGoogleAccountIntent());
                },
              ),
              const SizedBox(height: 16),
              _FinancialSettingsCard(
                state: state,
                onIntent: viewModel.processIntent,
              ),
              const SizedBox(height: 16),
              _TimeSettingsCard(
                state: state,
                onIntent: viewModel.processIntent,
              ),
              const SizedBox(height: 16),
              _NotificationSettingsCard(
                state: state,
                onIntent: viewModel.processIntent,
              ),
              const SizedBox(height: 16),
              _BackupAndCloudCard(
                state: state,
                onIntent: viewModel.processIntent,
              ),
              const SizedBox(height: 16),
              const _ExportDataCard(),
              const SizedBox(height: 16),
              _ResetDataCard(
                onReset: () async {
                  await viewModel.resetData();
                  ref.invalidate(timerProvider);
                },
              ),
              const SizedBox(height: 24),
              const _AppVersionFooter(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final GoogleSignInAccount? user;
  final VoidCallback onLogin;
  final VoidCallback? onLogout;

  const _ProfileCard({this.user, required this.onLogin, this.onLogout});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not Signed In',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connect to backup data',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).extension<SpecialColors>()?.playButtonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Connect',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF333333),
                ),
                child: user!.photoUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(user!.photoUrl!),
                      )
                    : const Icon(
                        Icons.person_outline,
                        color: Colors.grey,
                        size: 32,
                      ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user!.displayName ?? 'User',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user!.email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Disconnect',
          ),
        ],
      ),
    );
  }
}

class _FinancialSettingsCard extends StatelessWidget {
  final SettingsState state;
  final Function(SettingsIntent) onIntent;

  const _FinancialSettingsCard({required this.state, required this.onIntent});

  @override
  Widget build(BuildContext context) {
    return _SettingsGroupCard(
      icon: Icons.attach_money_outlined,
      title: 'Financial Settings',
      children: [
        _SettingItem(
          label: 'Monthly Earnings',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color:
                  Theme.of(
                    context,
                  ).extension<SpecialColors>()?.customSurfaceColor ??
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: state.monthlyRate),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black
                          : Colors.white,
                      fontSize: 16,
                    ),
                    onSubmitted: (value) {
                      onIntent(UpdateMonthlyRateIntent(value));
                    },
                  ),
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.grey.withValues(alpha: 0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    onIntent(UpdateCurrencyIntent(value));
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'USD (\$)',
                      child: Text('USD (\$)'),
                    ),
                    const PopupMenuItem(
                      value: 'INR (₹)',
                      child: Text('INR (₹)'),
                    ),
                  ],
                  child: Row(
                    children: [
                      Text(
                        state.currency,
                        style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? Colors.black
                              : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.expand_more,
                        size: 20,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.grey
                            : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SettingSwitchItem(
          title: 'Show Earnings',
          subtitle: 'Display earnings in dashboard',
          checked: state.showEarnings,
          onCheckedChange: (value) => onIntent(ToggleShowEarningsIntent(value)),
        ),
        if (state.showEarnings) ...[
          const SizedBox(height: 16),
          _SettingSwitchItem(
            title: 'Show Fake Data',
            subtitle: 'Display fake earnings for privacy',
            checked: state.showFakeData,
            onCheckedChange: (value) =>
                onIntent(ToggleShowFakeDataIntent(value)),
          ),
        ],
      ],
    );
  }
}

class _TimeSettingsCard extends ConsumerWidget {
  final SettingsState state;
  final Function(SettingsIntent) onIntent;

  const _TimeSettingsCard({required this.state, required this.onIntent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final hasData = timerState.weeklyStats.isNotEmpty;

    return _SettingsGroupCard(
      icon: Icons.schedule_outlined,
      title: 'Time Settings',
      children: [
        _SettingItem(
          label: 'Work Hours',
          child: Opacity(
            opacity: hasData ? 0.5 : 1.0,
            child: _CustomDropdown(
              value: '${state.workHours ~/ 60} hours',
              onClick: () {
                if (hasData) {
                  _showLockedDialog(context);
                } else {
                  // TODO: Show picker for work hours
                  // For simplicity, let's toggle between 8, 9, 10 hours
                  final current = state.workHours ~/ 60;
                  final next = current == 9 ? 10 : (current == 10 ? 8 : 9);
                  onIntent(UpdateWorkHoursIntent(next * 60));
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SettingItem(
          label: 'Work Interval',
          child: Opacity(
            opacity: hasData ? 0.5 : 1.0,
            child: _CustomDropdown(
              value: _getDurationLabel(state.workInterval),
              onClick: () async {
                if (hasData) {
                  _showLockedDialog(context);
                  return;
                }
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: state.workInterval ~/ 60,
                    minute: state.workInterval % 60,
                  ),
                  helpText: 'SELECT WORK INTERVAL',
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(alwaysUse24HourFormat: true),
                      child: child!,
                    );
                  },
                );
                if (time != null) {
                  final minutes = time.hour * 60 + time.minute;
                  onIntent(UpdateWorkIntervalIntent(minutes));
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showLockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Settings Locked',
        description:
            'You cannot change work settings while you have active data for this week. Please reset your data to change these settings.',
        primaryButtonText: 'OK',
        onPrimaryPressed: () => Navigator.pop(context),
        primaryButtonColor: Theme.of(
          context,
        ).extension<SpecialColors>()?.warningColor,
      ),
    );
  }
}

class _NotificationSettingsCard extends StatelessWidget {
  final SettingsState state;
  final Function(SettingsIntent) onIntent;

  const _NotificationSettingsCard({
    required this.state,
    required this.onIntent,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsGroupCard(
      icon: Icons.notifications_outlined,
      title: 'Notifications',
      children: [
        _SettingSwitchItem(
          title: 'Break Reminders',
          subtitle: 'Get notified to take breaks',
          checked: state.breakReminders,
          onCheckedChange: (value) async {
            if (value) {
              final granted = await NotificationService().requestPermissions();
              if (granted) {
                onIntent(ToggleBreakRemindersIntent(true));
              } else {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => CustomDialog(
                      title: 'Permission Required',
                      description:
                          'Please enable notifications to receive break reminders.',
                      primaryButtonText: 'OK',
                      onPrimaryPressed: () => Navigator.pop(context),
                      primaryButtonColor: Theme.of(
                        context,
                      ).extension<SpecialColors>()?.warningColor,
                    ),
                  );
                }
                onIntent(ToggleBreakRemindersIntent(false));
              }
            } else {
              onIntent(ToggleBreakRemindersIntent(false));
            }
          },
        ),
        if (state.breakReminders) ...[
          const SizedBox(height: 16),
          const Text(
            'Reminder Times',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...state.breakReminderTimes.map((time) {
                return Chip(
                  label: Text(time.format(context)),
                  onDeleted: () {
                    onIntent(RemoveBreakReminderTimeIntent(time));
                  },
                  deleteIcon: const Icon(Icons.close, size: 18),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHigh,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                );
              }),
              ActionChip(
                label: const Text('Add Time'),
                avatar: Icon(
                  Icons.add,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    onIntent(AddBreakReminderTimeIntent(picked));
                  }
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BackupAndCloudCard extends StatelessWidget {
  final SettingsState state;
  final Function(SettingsIntent) onIntent;

  const _BackupAndCloudCard({required this.state, required this.onIntent});

  @override
  Widget build(BuildContext context) {
    return _SettingsGroupCard(
      icon: Icons.cloud_outlined,
      title: 'Backup & Cloud',
      children: [
        _SettingSwitchItem(
          title: 'Google Drive Backup',
          subtitle: 'Backup data to Google Drive',
          checked: state.backupEnabled,
          onCheckedChange: (value) {
            if (value && state.googleUser == null) {
              showDialog(
                context: context,
                builder: (context) => CustomDialog(
                  title: 'Not Connected',
                  description:
                      'Please connect your Google account to enable backup.',
                  primaryButtonText: 'OK',
                  onPrimaryPressed: () => Navigator.pop(context),
                  primaryButtonColor: Theme.of(
                    context,
                  ).extension<SpecialColors>()?.warningColor,
                ),
              );
            } else {
              onIntent(ToggleBackupIntent(value));
            }
          },
        ),
      ],
    );
  }
}

class _ExportDataCard extends StatelessWidget {
  const _ExportDataCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsGroupCard(
      icon: Icons.download_outlined,
      title: 'Export Data',
      children: [
        const _ExportActionItem(text: 'Export as PDF'),
        Divider(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          height: 1,
        ),
        const _ExportActionItem(text: 'Export as CSV'),
      ],
    );
  }
}

class _ResetDataCard extends StatelessWidget {
  final VoidCallback onReset;

  const _ResetDataCard({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return _SettingsGroupCard(
      icon: Icons.delete_outline,
      title: 'Danger Zone',
      children: [
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => CustomDialog(
                title: 'Reset All Data?',
                description:
                    'This will permanently delete all your session history and timer data. This action cannot be undone.',
                primaryButtonText: 'Reset Everything',
                onPrimaryPressed: () {
                  Navigator.pop(context);
                  onReset();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data has been reset.')),
                  );
                },
                secondaryButtonText: 'Cancel',
                onSecondaryPressed: () => Navigator.pop(context),
                primaryButtonColor: Theme.of(
                  context,
                ).extension<SpecialColors>()?.warningColor,
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                const Icon(Icons.delete_forever, color: Colors.red),
                const SizedBox(width: 12),
                Text(
                  'Reset All Data',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AppVersionFooter extends StatelessWidget {
  const _AppVersionFooter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '...';
        final buildNumber = snapshot.data?.buildNumber ?? '';
        final versionString =
            'Staytics v$version${buildNumber.isNotEmpty ? '' : ''}';

        return Column(
          children: [
            Text(
              versionString,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Built with ',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const Icon(Icons.favorite, color: Colors.red, size: 14),
                Text(
                  ' for productivity',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SettingsGroupCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SettingsGroupCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingItem({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _CustomDropdown extends StatelessWidget {
  final String value;
  final VoidCallback onClick;

  const _CustomDropdown({required this.value, required this.onClick});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:
              Theme.of(
                context,
              ).extension<SpecialColors>()?.customSurfaceColor ??
              Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: TextStyle(color: isLight ? Colors.black : Colors.white),
            ),
            Icon(Icons.expand_more, color: isLight ? Colors.grey : Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _SettingSwitchItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool checked;
  final ValueChanged<bool> onCheckedChange;
  const _SettingSwitchItem({
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.onCheckedChange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
        Switch(
          value: checked,
          onChanged: onCheckedChange,
          activeThumbColor: Colors.white,
          activeTrackColor: Theme.of(
            context,
          ).extension<SpecialColors>()?.playButtonColor,
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: const Color(0xFF333333),
        ),
      ],
    );
  }
}

class _ExportActionItem extends StatelessWidget {
  final String text;

  const _ExportActionItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}

String _getDurationLabel(int minutes) {
  if (minutes == 0) return 'Disabled';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours > 0) {
    return '$hours h ${mins > 0 ? '$mins m' : ''}';
  }
  return '$mins m';
}
